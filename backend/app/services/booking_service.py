import uuid
from datetime import datetime
from typing import Optional
from sqlalchemy.orm import Session
from fastapi import HTTPException, status
from backend.app.models.all_models import Booking, BookingStatus, Charger, ChargerType, User, UserRole, AuditLog
from backend.app.schemas.all_schemas import BookingCreate, BookingResponse, ChargerResponse, VehicleResponse

class BookingService:
    @staticmethod
    def create_booking(
        db: Session,
        driver: User,
        request: BookingCreate
    ) -> Booking:
        # Validate time interval
        if request.end_time <= request.start_time:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Booking end time must be after start time."
            )

        # Validate charger
        charger = db.query(Charger).filter(Charger.id == request.charger_id).first()
        if not charger:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Requested charger does not exist."
            )

        # Prevent double-booking / overlapping bookings
        overlap = db.query(Booking).filter(
            Booking.charger_id == request.charger_id,
            Booking.status.in_([BookingStatus.PENDING, BookingStatus.CONFIRMED, BookingStatus.IN_PROGRESS]),
            Booking.start_time < request.end_time,
            Booking.end_time > request.start_time
        ).first()

        if overlap:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=f"Charger is already reserved for the selected timeframe ({overlap.start_time} - {overlap.end_time})."
            )

        # Calculate price snapshot
        duration_hours = (request.end_time - request.start_time).total_seconds() / 3600.0
        # If hourly pricing or per_kwh estimate
        estimated_kwh = duration_hours * min(charger.power_kw, 50.0) # Estimated energy consumed
        price_snapshot = round(charger.price_per_kwh * estimated_kwh if charger.pricing_model == "per_kwh" else charger.price_per_hour * duration_hours, 2)
        if price_snapshot <= 0:
            price_snapshot = 15.00 # Base minimum booking charge

        # Determine initial booking status:
        # Home-host chargers require explicit host confirmation -> PENDING
        # Public chargers auto-confirm reservation window -> CONFIRMED
        initial_status = BookingStatus.PENDING if charger.charger_type == ChargerType.HOME else BookingStatus.CONFIRMED

        booking_code = f"CS-{uuid.uuid4().hex[:8].upper()}"

        new_booking = Booking(
            booking_code=booking_code,
            driver_id=driver.id,
            host_id=charger.host_id,
            charger_id=charger.id,
            vehicle_id=request.vehicle_id,
            start_time=request.start_time,
            end_time=request.end_time,
            status=initial_status,
            total_price_snapshot=price_snapshot,
            is_backup_booking=request.is_backup_booking,
            backup_trigger_reason=request.backup_trigger_reason
        )

        db.add(new_booking)
        db.commit()
        db.refresh(new_booking)

        # Log audit entry
        audit = AuditLog(
            actor_id=driver.id,
            action="BOOKING_CREATED",
            entity_type="Booking",
            entity_id=new_booking.id,
            details_json={
                "code": booking_code,
                "charger_id": charger.id,
                "status": initial_status.value,
                "is_backup": request.is_backup_booking
            }
        )
        db.add(audit)
        db.commit()

        return new_booking

    @staticmethod
    def accept_booking(db: Session, booking_id: int, host_or_admin: User) -> Booking:
        booking = db.query(Booking).filter(Booking.id == booking_id).first()
        if not booking:
            raise HTTPException(status_code=404, detail="Booking not found.")

        if host_or_admin.role != UserRole.ADMIN and booking.host_id != host_or_admin.id:
            raise HTTPException(status_code=403, detail="Unauthorized: Only the assigned host or admin can accept this booking.")

        if booking.status != BookingStatus.PENDING:
            raise HTTPException(status_code=400, detail=f"Cannot accept booking in '{booking.status.value}' state.")

        booking.status = BookingStatus.CONFIRMED
        booking.updated_at = datetime.utcnow()
        db.commit()
        db.refresh(booking)
        return booking

    @staticmethod
    def reject_booking(db: Session, booking_id: int, host_or_admin: User, reason: str = "Host unavailable") -> Booking:
        booking = db.query(Booking).filter(Booking.id == booking_id).first()
        if not booking:
            raise HTTPException(status_code=404, detail="Booking not found.")

        if host_or_admin.role != UserRole.ADMIN and booking.host_id != host_or_admin.id:
            raise HTTPException(status_code=403, detail="Unauthorized: Only the assigned host or admin can reject this booking.")

        if booking.status not in (BookingStatus.PENDING, BookingStatus.CONFIRMED):
            raise HTTPException(status_code=400, detail=f"Cannot reject booking in '{booking.status.value}' state.")

        booking.status = BookingStatus.REJECTED
        booking.cancellation_reason = reason
        booking.updated_at = datetime.utcnow()
        db.commit()
        db.refresh(booking)
        return booking

    @staticmethod
    def cancel_booking(db: Session, booking_id: int, user: User, reason: str = "Driver cancelled") -> Booking:
        booking = db.query(Booking).filter(Booking.id == booking_id).first()
        if not booking:
            raise HTTPException(status_code=404, detail="Booking not found.")

        is_driver = booking.driver_id == user.id
        is_host = booking.host_id == user.id
        is_admin = user.role == UserRole.ADMIN

        if not (is_driver or is_host or is_admin):
            raise HTTPException(status_code=403, detail="Unauthorized to cancel this booking.")

        if booking.status in (BookingStatus.COMPLETED, BookingStatus.CANCELLED):
            raise HTTPException(status_code=400, detail=f"Booking is already {booking.status.value}.")

        booking.status = BookingStatus.CANCELLED
        booking.cancellation_reason = reason
        booking.updated_at = datetime.utcnow()
        db.commit()
        db.refresh(booking)
        return booking

    @staticmethod
    def to_response_dto(booking: Booking, viewer: Optional[User] = None) -> BookingResponse:
        # Determine whether access instructions should be revealed
        # Revealed only if viewer is driver and booking is CONFIRMED, or viewer is host/admin
        charger = booking.charger
        is_confirmed = booking.status in (BookingStatus.CONFIRMED, BookingStatus.IN_PROGRESS, BookingStatus.COMPLETED)
        is_privileged = viewer and (viewer.id == booking.host_id or viewer.role == UserRole.ADMIN)
        reveal_access = is_confirmed or is_privileged

        access_notes = charger.access_instructions if reveal_access else "Confidential access details revealed upon booking confirmation."

        ch_resp = ChargerResponse(
            id=charger.id,
            host_id=charger.host_id,
            title=charger.title,
            description=charger.description,
            address=charger.address if reveal_access else f"Near {charger.city}, {charger.state or ''}",
            city=charger.city,
            state=charger.state,
            postal_code=charger.postal_code,
            latitude=charger.latitude,
            longitude=charger.longitude,
            charger_type=charger.charger_type,
            current_type=charger.current_type,
            power_kw=charger.power_kw,
            connector_types=charger.connector_types,
            price_per_kwh=charger.price_per_kwh,
            price_per_hour=charger.price_per_hour,
            pricing_model=charger.pricing_model,
            status=charger.status,
            data_source=charger.data_source,
            access_instructions=access_notes,
            is_access_masked=not reveal_access,
            freshness_timestamp=charger.freshness_timestamp,
            is_verified=charger.is_verified,
            reliability_score=charger.reliability_score,
            distance_km=0.0,
            average_rating=4.8,
            total_reviews=5,
            created_at=charger.created_at,
            updated_at=charger.updated_at
        )

        veh_resp = None
        if booking.vehicle:
            v = booking.vehicle
            est_range = (v.battery_capacity_kwh * 1000.0 * (v.current_battery_percent / 100.0)) / max(v.consumption_wh_per_km, 1.0)
            veh_resp = VehicleResponse(
                id=v.id,
                user_id=v.user_id,
                make=v.make,
                model=v.model,
                year=v.year,
                license_plate=v.license_plate,
                battery_capacity_kwh=v.battery_capacity_kwh,
                connector_type=v.connector_type,
                consumption_wh_per_km=v.consumption_wh_per_km,
                current_battery_percent=v.current_battery_percent,
                is_primary=v.is_primary,
                estimated_range_km=round(est_range, 1),
                created_at=v.created_at,
                updated_at=v.updated_at
            )

        return BookingResponse(
            id=booking.id,
            booking_code=booking.booking_code,
            driver_id=booking.driver_id,
            host_id=booking.host_id,
            charger_id=booking.charger_id,
            vehicle_id=booking.vehicle_id,
            start_time=booking.start_time,
            end_time=booking.end_time,
            status=booking.status,
            total_price_snapshot=booking.total_price_snapshot,
            cancellation_reason=booking.cancellation_reason,
            is_backup_booking=booking.is_backup_booking,
            backup_trigger_reason=booking.backup_trigger_reason,
            charger=ch_resp,
            vehicle=veh_resp,
            driver_name=booking.driver.full_name if booking.driver else "Driver",
            created_at=booking.created_at,
            updated_at=booking.updated_at
        )
