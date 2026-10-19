from typing import Optional
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from backend.app.database import get_db
from backend.app.models.all_models import Vehicle, User
from backend.app.schemas.all_schemas import TripPlanRequest, TripPlanResponse
from backend.app.core.dependencies import get_current_user
from backend.app.services.trip_planner import TripPlannerService

router = APIRouter(prefix="/trip", tags=["Trip Planner"])

@router.post("/plan", response_model=TripPlanResponse)
def plan_trip(
    request: TripPlanRequest,
    db: Session = Depends(get_db),
    current_user: Optional[User] = Depends(get_current_user)
):
    """
    Transparent route and battery range planning formula.
    Calculates arrival battery % based on real battery pack capacity and consumption,
    evaluates against safety reserve, and plans charging stops when required.
    """
    vehicle = None
    if current_user:
        if request.vehicle_id:
            vehicle = db.query(Vehicle).filter(Vehicle.id == request.vehicle_id, Vehicle.user_id == current_user.id).first()
        if not vehicle:
            vehicle = db.query(Vehicle).filter(Vehicle.user_id == current_user.id, Vehicle.is_primary == True).first()

    return TripPlannerService.plan_trip(
        db=db,
        request=request,
        vehicle=vehicle
    )
