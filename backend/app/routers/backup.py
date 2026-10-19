from typing import Optional
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from backend.app.database import get_db
from backend.app.models.all_models import Vehicle, User
from backend.app.schemas.all_schemas import BackupRequest, BackupResponse
from backend.app.core.dependencies import get_current_user
from backend.app.services.backup_engine import BackupEngineService

router = APIRouter(prefix="/backup", tags=["Backup Recommendation Engine"])

@router.post("/recommend", response_model=BackupResponse)
def evaluate_backup_options(
    request: BackupRequest,
    db: Session = Depends(get_db),
    current_user: Optional[User] = Depends(get_current_user)
):
    """
    Core ChargeSure differentiator:
    Deterministically evaluates, scores, and ranks alternative compatible chargers
    when primary charger is faulty, unavailable, or rejected by host.
    """
    user_vehicle = None
    if current_user:
        if request.vehicle_id:
            user_vehicle = db.query(Vehicle).filter(Vehicle.id == request.vehicle_id, Vehicle.user_id == current_user.id).first()
        if not user_vehicle:
            user_vehicle = db.query(Vehicle).filter(Vehicle.user_id == current_user.id, Vehicle.is_primary == True).first()

    return BackupEngineService.evaluate_candidates(
        db=db,
        request=request,
        current_user_vehicle=user_vehicle
    )
