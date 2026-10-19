from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session
from backend.app.database import get_db
from backend.app.models.all_models import Booking, BookingStatus, User, UserRole
from backend.app.schemas.all_schemas import BookingCreate, BookingResponse, BookingStatusAction
from backend.app.core.dependencies import get_current_active_user
from backend.app.services.booking_service import BookingService

router = APIRouter(prefix="/bookings", tags=["Bookings"])

@router.post("", response_model=BookingResponse, status_code=status.HTTP_201_CREATED)
def create_booking(
    request: BookingCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    booking = BookingService.create_booking(db=db, driver=current_user, request=request)
    return BookingService.to_response_dto(booking, viewer=current_user)

@router.get("", response_model=List[BookingResponse])
def get_user_bookings(
    status_filter: Optional[BookingStatus] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    query = db.query(Booking).filter(Booking.driver_id == current_user.id)
    if status_filter:
        query = query.filter(Booking.status == status_filter)
    bookings = query.order_by(Booking.start_time.desc()).all()
    return [BookingService.to_response_dto(b, viewer=current_user) for b in bookings]

@router.get("/{id}", response_model=BookingResponse)
def get_booking_details(
    id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    booking = db.query(Booking).filter(Booking.id == id).first()
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")

    # Access control
    if current_user.role != UserRole.ADMIN and booking.driver_id != current_user.id and booking.host_id != current_user.id:
        raise HTTPException(status_code=403, detail="Unauthorized")

    return BookingService.to_response_dto(booking, viewer=current_user)

@router.post("/{id}/accept", response_model=BookingResponse)
def accept_booking(
    id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    booking = BookingService.accept_booking(db=db, booking_id=id, host_or_admin=current_user)
    return BookingService.to_response_dto(booking, viewer=current_user)

@router.post("/{id}/reject", response_model=BookingResponse)
def reject_booking(
    id: int,
    action: BookingStatusAction = BookingStatusAction(reason="Host unavailable"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    booking = BookingService.reject_booking(db=db, booking_id=id, host_or_admin=current_user, reason=action.reason or "Host unavailable")
    return BookingService.to_response_dto(booking, viewer=current_user)

@router.post("/{id}/cancel", response_model=BookingResponse)
def cancel_booking(
    id: int,
    action: BookingStatusAction = BookingStatusAction(reason="Driver cancelled"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    booking = BookingService.cancel_booking(db=db, booking_id=id, user=current_user, reason=action.reason or "Driver cancelled")
    return BookingService.to_response_dto(booking, viewer=current_user)
