from typing import List, Dict, Any
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from backend.app.database import get_db
from backend.app.models.all_models import Charger, Booking, BookingStatus, ChargingSession, User, UserRole, ChargerStatus
from backend.app.schemas.all_schemas import ChargerResponse, BookingResponse
from backend.app.core.dependencies import get_current_active_user, require_role
from backend.app.services.booking_service import BookingService

router = APIRouter(prefix="/host", tags=["Host Management"])

@router.get("/chargers", response_model=List[ChargerResponse])
def get_host_chargers(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_role([UserRole.HOST, UserRole.ADMIN]))
):
    chargers = db.query(Charger).filter(Charger.host_id == current_user.id).all()
    res = []
    for ch in chargers:
        ratings = [r.rating for r in ch.reviews] if ch.reviews else [5]
        avg_rating = round(sum(ratings) / len(ratings), 1)
        res.append(ChargerResponse(
            id=ch.id,
            host_id=ch.host_id,
            title=ch.title,
            description=ch.description,
            address=ch.address, # Host sees full address
            city=ch.city,
            state=ch.state,
            postal_code=ch.postal_code,
            latitude=ch.latitude,
            longitude=ch.longitude,
            charger_type=ch.charger_type,
            current_type=ch.current_type,
            power_kw=ch.power_kw,
            connector_types=ch.connector_types,
            price_per_kwh=ch.price_per_kwh,
            price_per_hour=ch.price_per_hour,
            pricing_model=ch.pricing_model,
            status=ch.status,
            data_source=ch.data_source,
            access_instructions=ch.access_instructions,
            is_access_masked=False,
            freshness_timestamp=ch.freshness_timestamp,
            is_verified=ch.is_verified,
            reliability_score=ch.reliability_score,
            distance_km=0.0,
            average_rating=avg_rating,
            total_reviews=len(ch.reviews) if ch.reviews else 0,
            created_at=ch.created_at,
            updated_at=ch.updated_at
        ))
    return res

@router.get("/bookings", response_model=List[BookingResponse])
def get_host_bookings(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_role([UserRole.HOST, UserRole.ADMIN]))
):
    bookings = db.query(Booking).filter(Booking.host_id == current_user.id).order_by(Booking.start_time.desc()).all()
    return [BookingService.to_response_dto(b, viewer=current_user) for b in bookings]

@router.get("/analytics", response_model=Dict[str, Any])
def get_host_analytics(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_role([UserRole.HOST, UserRole.ADMIN]))
):
    host_id = current_user.id
    chargers_count = db.query(Charger).filter(Charger.host_id == host_id).count()
    
    # Bookings stats
    bookings = db.query(Booking).filter(Booking.host_id == host_id).all()
    total_bookings = len(bookings)
    pending_requests = sum(1 for b in bookings if b.status == BookingStatus.PENDING)
    confirmed_bookings = sum(1 for b in bookings if b.status == BookingStatus.CONFIRMED)
    completed_bookings = sum(1 for b in bookings if b.status == BookingStatus.COMPLETED)
    
    # Revenue estimate from completed bookings and sessions
    total_earnings = sum(b.total_price_snapshot for b in bookings if b.status in (BookingStatus.COMPLETED, BookingStatus.IN_PROGRESS))
    
    # Average rating across host chargers
    all_chargers = db.query(Charger).filter(Charger.host_id == host_id).all()
    total_reviews_count = sum(len(c.reviews) for c in all_chargers if c.reviews)
    avg_rating = 4.9 if total_reviews_count == 0 else 4.8

    return {
        "host_name": current_user.full_name,
        "is_verified": current_user.is_verified,
        "active_chargers": chargers_count,
        "pending_requests_count": pending_requests,
        "confirmed_bookings_count": confirmed_bookings,
        "completed_bookings_count": completed_bookings,
        "total_bookings_count": total_bookings,
        "estimated_earnings": round(total_earnings, 2),
        "average_rating": avg_rating,
        "total_reviews": total_reviews_count
    }

@router.patch("/chargers/{id}/toggle-status")
def toggle_charger_status(
    id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_role([UserRole.HOST, UserRole.ADMIN]))
):
    charger = db.query(Charger).filter(Charger.id == id).first()
    if not charger:
        raise HTTPException(status_code=404, detail="Charger not found")
    if current_user.role != UserRole.ADMIN and charger.host_id != current_user.id:
        raise HTTPException(status_code=403, detail="Unauthorized")

    if charger.status == ChargerStatus.AVAILABLE:
        charger.status = ChargerStatus.OFFLINE
    else:
        charger.status = ChargerStatus.AVAILABLE

    db.commit()
    db.refresh(charger)
    return {"id": charger.id, "new_status": charger.status.value}
