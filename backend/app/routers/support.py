from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from backend.app.database import get_db
from backend.app.models.all_models import SupportCase, SupportStatus, User
from backend.app.schemas.all_schemas import SupportCaseCreate, SupportCaseResponse
from backend.app.core.dependencies import get_current_active_user

router = APIRouter(prefix="/support", tags=["Support"])

@router.post("", response_model=SupportCaseResponse, status_code=status.HTTP_201_CREATED)
def create_support_ticket(
    request: SupportCaseCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    case = SupportCase(
        user_id=current_user.id,
        booking_id=request.booking_id,
        subject=request.subject,
        message=request.message,
        priority=request.priority,
        status=SupportStatus.OPEN
    )
    db.add(case)
    db.commit()
    db.refresh(case)
    return case

@router.get("", response_model=List[SupportCaseResponse])
def get_user_support_cases(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    return db.query(SupportCase).filter(SupportCase.user_id == current_user.id).order_by(SupportCase.created_at.desc()).all()
