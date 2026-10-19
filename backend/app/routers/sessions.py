from datetime import datetime
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from backend.app.database import get_db
from backend.app.models.all_models import ChargingSession, SessionStatus, TelemetrySource, Charger, Booking, BookingStatus, Vehicle, User
from backend.app.schemas.all_schemas import SessionStartRequest, SessionCompleteRequest, SessionResponse
from backend.app.core.dependencies import get_current_active_user

router = APIRouter(prefix="/sessions", tags=["Charging Sessions"])

def _to_session_dto(s: ChargingSession) -> SessionResponse:
    dur = None
    if s.end_time and s.start_time:
        dur = int((s.end_time - s.start_time).total_seconds() / 60.0)
    elif s.start_time:
        dur = int((datetime.utcnow() - s.start_time).total_seconds() / 60.0)

    return SessionResponse(
        id=s.id,
        booking_id=s.booking_id,
        driver_id=s.driver_id,
        charger_id=s.charger_id,
        vehicle_id=s.vehicle_id,
        start_time=s.start_time,
        end_time=s.end_time,
        duration_minutes=dur,
        initial_battery_percent=s.initial_battery_percent,
        final_battery_percent=s.final_battery_percent,
        energy_delivered_kwh=s.energy_delivered_kwh,
        total_cost=s.total_cost,
        status=s.status,
        telemetry_source=s.telemetry_source,
        notes=s.notes,
        created_at=s.created_at
    )

@router.post("", response_model=SessionResponse, status_code=status.HTTP_201_CREATED)
def start_session(
    request: SessionStartRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    # Check if user already has an active session
    active = db.query(ChargingSession).filter(
        ChargingSession.driver_id == current_user.id,
        ChargingSession.status == SessionStatus.ACTIVE
    ).first()
    if active:
        raise HTTPException(status_code=400, detail="You already have an active charging session.")

    charger = db.query(Charger).filter(Charger.id == request.charger_id).first()
    if not charger:
        raise HTTPException(status_code=404, detail="Charger not found.")

    # If linked to a booking, transition status to in_progress
    if request.booking_id:
        booking = db.query(Booking).filter(Booking.id == request.booking_id).first()
        if booking and booking.driver_id == current_user.id:
            booking.status = BookingStatus.IN_PROGRESS

    session = ChargingSession(
        booking_id=request.booking_id,
        driver_id=current_user.id,
        charger_id=request.charger_id,
        vehicle_id=request.vehicle_id,
        start_time=datetime.utcnow(),
        initial_battery_percent=request.initial_battery_percent,
        status=SessionStatus.ACTIVE,
        telemetry_source=TelemetrySource.SIMULATED,
        notes=request.notes or "Session initiated via ChargeSure Mobile"
    )
    db.add(session)
    db.commit()
    db.refresh(session)
    return _to_session_dto(session)

@router.get("/active", response_model=Optional[SessionResponse])
def get_active_session(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    active = db.query(ChargingSession).filter(
        ChargingSession.driver_id == current_user.id,
        ChargingSession.status == SessionStatus.ACTIVE
    ).first()
    if not active:
        return None
    return _to_session_dto(active)

@router.get("/{id}", response_model=SessionResponse)
def get_session_details(
    id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    session = db.query(ChargingSession).filter(ChargingSession.id == id).first()
    if not session:
        raise HTTPException(status_code=404, detail="Session not found.")
    return _to_session_dto(session)

@router.post("/{id}/complete", response_model=SessionResponse)
def complete_session(
    id: int,
    request: SessionCompleteRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    session = db.query(ChargingSession).filter(ChargingSession.id == id).first()
    if not session:
        raise HTTPException(status_code=404, detail="Session not found.")
    if session.driver_id != current_user.id:
        raise HTTPException(status_code=403, detail="Unauthorized.")
    if session.status != SessionStatus.ACTIVE:
        raise HTTPException(status_code=400, detail="Session is not currently active.")

    session.end_time = datetime.utcnow()
    session.final_battery_percent = request.final_battery_percent
    session.status = SessionStatus.COMPLETED

    charger = db.query(Charger).filter(Charger.id == session.charger_id).first()
    price_rate = charger.price_per_kwh if charger else 12.0

    # Calculate energy delivered if not explicitly provided
    if request.energy_delivered_kwh is not None:
        energy_kwh = request.energy_delivered_kwh
    else:
        # Estimate from vehicle capacity if available
        vehicle = db.query(Vehicle).filter(Vehicle.id == session.vehicle_id).first() if session.vehicle_id else None
        capacity = vehicle.battery_capacity_kwh if vehicle else 60.0
        delta_percent = max(0.0, request.final_battery_percent - session.initial_battery_percent)
        energy_kwh = round((delta_percent / 100.0) * capacity, 2)
        if energy_kwh <= 0:
            energy_kwh = 14.5 # Default simulated energy

    session.energy_delivered_kwh = energy_kwh
    session.total_cost = round(energy_kwh * price_rate, 2)
    if request.notes:
        session.notes = request.notes

    # Update vehicle's battery percentage
    if session.vehicle_id:
        veh = db.query(Vehicle).filter(Vehicle.id == session.vehicle_id).first()
        if veh:
            veh.current_battery_percent = request.final_battery_percent

    # Complete booking if attached
    if session.booking_id:
        b = db.query(Booking).filter(Booking.id == session.booking_id).first()
        if b:
            b.status = BookingStatus.COMPLETED

    db.commit()
    db.refresh(session)
    return _to_session_dto(session)
