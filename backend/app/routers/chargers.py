from typing import List, Optional
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session
from backend.app.database import get_db
from backend.app.models.all_models import (
    Charger, ChargerType, CurrentType, ChargerStatus, DataSource,
    AvailabilitySlot, Review, FaultReport, User, UserRole, Booking, BookingStatus
)
from backend.app.schemas.all_schemas import (
    ChargerCreate, ChargerUpdate, ChargerResponse,
    AvailabilitySlotCreate, AvailabilitySlotResponse,
    ReviewCreate, ReviewResponse, FaultReportCreate, FaultReportResponse
)
from backend.app.core.dependencies import get_current_active_user
from backend.app.services.geo_adapter import haversine_distance_km

router = APIRouter(prefix="/chargers", tags=["Chargers"])

def _to_charger_dto(ch: Charger, viewer_lat: Optional[float] = None, viewer_lon: Optional[float] = None, is_revealed: bool = False) -> ChargerResponse:
    dist = None
    if viewer_lat is not None and viewer_lon is not None:
        dist = haversine_distance_km(viewer_lat, viewer_lon, ch.latitude, ch.longitude)

    # Calculate average rating
    ratings = [r.rating for r in ch.reviews] if ch.reviews else [5]
    avg_rating = round(sum(ratings) / len(ratings), 1)

    return ChargerResponse(
        id=ch.id,
        host_id=ch.host_id,
        title=ch.title,
        description=ch.description,
        address=ch.address if is_revealed or ch.charger_type != ChargerType.HOME else f"Near {ch.city}, {ch.state or ''}",
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
        access_instructions=ch.access_instructions if is_revealed else None,
        is_access_masked=not is_revealed and ch.charger_type == ChargerType.HOME,
        freshness_timestamp=ch.freshness_timestamp,
        is_verified=ch.is_verified,
        reliability_score=ch.reliability_score,
        distance_km=dist,
        average_rating=avg_rating,
        total_reviews=len(ch.reviews) if ch.reviews else 0,
        created_at=ch.created_at,
        updated_at=ch.updated_at
    )

@router.get("/nearby", response_model=List[ChargerResponse])
def get_nearby_chargers(
    latitude: float = Query(..., ge=-90, le=90),
    longitude: float = Query(..., ge=-180, le=180),
    radius_km: float = Query(50.0, ge=1.0, le=500.0),
    charger_type: Optional[ChargerType] = None,
    current_type: Optional[CurrentType] = None,
    connector: Optional[str] = None,
    status_filter: Optional[ChargerStatus] = None,
    max_price: Optional[float] = None,
    db: Session = Depends(get_db)
):
    query = db.query(Charger)

    if charger_type:
        query = query.filter(Charger.charger_type == charger_type)
    if current_type:
        query = query.filter(Charger.current_type == current_type)
    if status_filter:
        query = query.filter(Charger.status == status_filter)
    if max_price is not None:
        query = query.filter(Charger.price_per_kwh <= max_price)

    all_chargers = query.all()
    results = []
    for ch in all_chargers:
        if connector and connector not in ch.connector_types:
            continue
        dist = haversine_distance_km(latitude, longitude, ch.latitude, ch.longitude)
        if dist <= radius_km:
            dto = _to_charger_dto(ch, viewer_lat=latitude, viewer_lon=longitude, is_revealed=False)
            results.append((dist, dto))

    results.sort(key=lambda x: x[0])
    return [item[1] for item in results]

@router.get("/{id}", response_model=ChargerResponse)
def get_charger_by_id(
    id: int,
    latitude: Optional[float] = None,
    longitude: Optional[float] = None,
    db: Session = Depends(get_db)
):
    charger = db.query(Charger).filter(Charger.id == id).first()
    if not charger:
        raise HTTPException(status_code=404, detail="Charger not found")
    return _to_charger_dto(charger, viewer_lat=latitude, viewer_lon=longitude, is_revealed=False)

@router.post("", response_model=ChargerResponse, status_code=status.HTTP_201_CREATED)
def create_charger(
    charger_in: ChargerCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    # Determine verification status
    is_verified = True if current_user.role == UserRole.ADMIN else False
    data_src = DataSource.HOST_CONFIRMED if charger_in.charger_type == ChargerType.HOME else charger_in.data_source

    charger = Charger(
        host_id=current_user.id,
        title=charger_in.title,
        description=charger_in.description,
        address=charger_in.address,
        city=charger_in.city,
        state=charger_in.state,
        postal_code=charger_in.postal_code,
        latitude=charger_in.latitude,
        longitude=charger_in.longitude,
        charger_type=charger_in.charger_type,
        current_type=charger_in.current_type,
        power_kw=charger_in.power_kw,
        connector_types=charger_in.connector_types,
        price_per_kwh=charger_in.price_per_kwh,
        price_per_hour=charger_in.price_per_hour,
        pricing_model=charger_in.pricing_model,
        status=charger_in.status,
        data_source=data_src,
        freshness_timestamp=datetime.utcnow(),
        is_verified=is_verified,
        access_instructions=charger_in.access_instructions,
        reliability_score=95.0
    )
    db.add(charger)
    db.commit()
    db.refresh(charger)
    return _to_charger_dto(charger, is_revealed=True)

@router.patch("/{id}", response_model=ChargerResponse)
def update_charger(
    id: int,
    update_data: ChargerUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    charger = db.query(Charger).filter(Charger.id == id).first()
    if not charger:
        raise HTTPException(status_code=404, detail="Charger not found")

    if current_user.role != UserRole.ADMIN and charger.host_id != current_user.id:
        raise HTTPException(status_code=403, detail="Unauthorized to modify this charger listing.")

    update_dict = update_data.model_dump(exclude_unset=True)
    for field, val in update_dict.items():
        setattr(charger, field, val)

    charger.freshness_timestamp = datetime.utcnow()
    db.commit()
    db.refresh(charger)
    return _to_charger_dto(charger, is_revealed=True)

@router.get("/{id}/availability", response_model=List[AvailabilitySlotResponse])
def get_availability_slots(id: int, db: Session = Depends(get_db)):
    slots = db.query(AvailabilitySlot).filter(AvailabilitySlot.charger_id == id, AvailabilitySlot.is_active == True).all()
    return slots

@router.post("/{id}/availability", response_model=AvailabilitySlotResponse, status_code=status.HTTP_201_CREATED)
def add_availability_slot(
    id: int,
    slot_in: AvailabilitySlotCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    charger = db.query(Charger).filter(Charger.id == id).first()
    if not charger:
        raise HTTPException(status_code=404, detail="Charger not found")
    if current_user.role != UserRole.ADMIN and charger.host_id != current_user.id:
        raise HTTPException(status_code=403, detail="Unauthorized.")

    slot = AvailabilitySlot(
        charger_id=id,
        day_of_week=slot_in.day_of_week,
        start_time=slot_in.start_time,
        end_time=slot_in.end_time,
        is_active=slot_in.is_active,
        specific_date=slot_in.specific_date
    )
    db.add(slot)
    db.commit()
    db.refresh(slot)
    return slot

@router.post("/{id}/report", response_model=FaultReportResponse, status_code=status.HTTP_201_CREATED)
def report_fault(
    id: int,
    report_in: FaultReportCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    charger = db.query(Charger).filter(Charger.id == id).first()
    if not charger:
        raise HTTPException(status_code=404, detail="Charger not found")

    report = FaultReport(
        charger_id=id,
        reported_by_user_id=current_user.id,
        issue_type=report_in.issue_type,
        description=report_in.description,
        status="pending"
    )
    db.add(report)
    
    # Degrade reliability score slightly upon fault report
    charger.reliability_score = max(50.0, charger.reliability_score - 5.0)
    db.commit()
    db.refresh(report)
    return report

@router.get("/{id}/reviews", response_model=List[ReviewResponse])
def get_charger_reviews(id: int, db: Session = Depends(get_db)):
    reviews = db.query(Review).filter(Review.charger_id == id).order_by(Review.created_at.desc()).all()
    resp = []
    for r in reviews:
        resp.append(ReviewResponse(
            id=r.id,
            charger_id=r.charger_id,
            booking_id=r.booking_id,
            user_id=r.user_id,
            author_name=r.author.full_name if r.author else "Driver",
            rating=r.rating,
            comment=r.comment,
            created_at=r.created_at
        ))
    return resp

@router.post("/{id}/reviews", response_model=ReviewResponse, status_code=status.HTTP_201_CREATED)
def add_review(
    id: int,
    review_in: ReviewCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    charger = db.query(Charger).filter(Charger.id == id).first()
    if not charger:
        raise HTTPException(status_code=404, detail="Charger not found")

    rev = Review(
        charger_id=id,
        booking_id=review_in.booking_id,
        user_id=current_user.id,
        rating=review_in.rating,
        comment=review_in.comment
    )
    db.add(rev)
    db.commit()
    db.refresh(rev)

    return ReviewResponse(
        id=rev.id,
        charger_id=rev.charger_id,
        booking_id=rev.booking_id,
        user_id=rev.user_id,
        author_name=current_user.full_name,
        rating=rev.rating,
        comment=rev.comment,
        created_at=rev.created_at
    )
