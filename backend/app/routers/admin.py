from typing import List, Dict, Any, Optional
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session
from backend.app.config import settings
from backend.app.database import get_db
from backend.app.models.all_models import (
    User, UserRole, Charger, ChargerStatus, Booking, BookingStatus,
    ChargingSession, SessionStatus, FaultReport, SupportCase, SupportStatus, AuditLog
)
from backend.app.schemas.all_schemas import (
    UserResponse, ChargerResponse, BookingResponse, FaultReportResponse,
    SupportCaseResponse, AdminAnalyticsResponse, AuditLogResponse
)
from backend.app.core.dependencies import require_role
from backend.app.services.booking_service import BookingService

router = APIRouter(prefix="/admin", tags=["Admin Web Dashboard"])

@router.get("/analytics", response_model=AdminAnalyticsResponse)
def get_admin_analytics(
    db: Session = Depends(get_db),
    admin_user: User = Depends(require_role([UserRole.ADMIN]))
):
    total_users = db.query(User).count()
    total_drivers = db.query(User).filter(User.role == UserRole.DRIVER).count()
    total_hosts = db.query(User).filter(User.role == UserRole.HOST).count()

    total_chargers = db.query(Charger).count()
    verified_chargers = db.query(Charger).filter(Charger.is_verified == True).count()

    total_bookings = db.query(Booking).count()
    completed_bookings = db.query(Booking).filter(Booking.status == BookingStatus.COMPLETED).count()
    backup_triggers = db.query(Booking).filter(Booking.is_backup_booking == True).count()

    active_sessions = db.query(ChargingSession).filter(ChargingSession.status == SessionStatus.ACTIVE).count()
    all_sessions = db.query(ChargingSession).all()
    total_energy = sum(s.energy_delivered_kwh for s in all_sessions)
    total_revenue = sum(s.total_cost for s in all_sessions) + sum(b.total_price_snapshot for b in db.query(Booking).filter(Booking.status == BookingStatus.COMPLETED).all())

    pending_faults = db.query(FaultReport).filter(FaultReport.status == "pending").count()
    open_support = db.query(SupportCase).filter(SupportCase.status == SupportStatus.OPEN).count()

    return AdminAnalyticsResponse(
        total_users=total_users,
        total_drivers=total_drivers,
        total_hosts=total_hosts,
        total_chargers=total_chargers,
        verified_chargers=verified_chargers,
        total_bookings=total_bookings,
        completed_bookings=completed_bookings,
        backup_triggers_count=backup_triggers,
        active_sessions=active_sessions,
        pending_fault_reports=pending_faults,
        open_support_cases=open_support,
        total_energy_delivered_kwh=round(total_energy, 1),
        total_platform_revenue=round(total_revenue, 2),
        demo_mode=settings.DEMO_MODE
    )

@router.get("/users", response_model=List[UserResponse])
def get_all_users(
    role: Optional[UserRole] = None,
    db: Session = Depends(get_db),
    admin_user: User = Depends(require_role([UserRole.ADMIN]))
):
    q = db.query(User)
    if role:
        q = q.filter(User.role == role)
    return q.order_by(User.created_at.desc()).all()

@router.patch("/users/{id}/verify", response_model=UserResponse)
def verify_user(
    id: int,
    db: Session = Depends(get_db),
    admin_user: User = Depends(require_role([UserRole.ADMIN]))
):
    target = db.query(User).filter(User.id == id).first()
    if not target:
        raise HTTPException(status_code=404, detail="User not found")
    target.is_verified = True
    
    # Audit log
    audit = AuditLog(
        actor_id=admin_user.id,
        action="USER_VERIFIED",
        entity_type="User",
        entity_id=target.id,
        details_json={"verified_email": target.email}
    )
    db.add(audit)
    db.commit()
    db.refresh(target)
    return target

@router.get("/chargers", response_model=List[ChargerResponse])
def get_admin_chargers(
    db: Session = Depends(get_db),
    admin_user: User = Depends(require_role([UserRole.ADMIN]))
):
    chargers = db.query(Charger).order_by(Charger.created_at.desc()).all()
    res = []
    for ch in chargers:
        ratings = [r.rating for r in ch.reviews] if ch.reviews else [5]
        avg_rating = round(sum(ratings) / len(ratings), 1)
        res.append(ChargerResponse(
            id=ch.id,
            host_id=ch.host_id,
            title=ch.title,
            description=ch.description,
            address=ch.address, # Admin sees full address
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

@router.patch("/chargers/{id}/status")
def admin_set_charger_status(
    id: int,
    new_status: ChargerStatus,
    is_verified: Optional[bool] = None,
    db: Session = Depends(get_db),
    admin_user: User = Depends(require_role([UserRole.ADMIN]))
):
    charger = db.query(Charger).filter(Charger.id == id).first()
    if not charger:
        raise HTTPException(status_code=404, detail="Charger not found")

    charger.status = new_status
    if is_verified is not None:
        charger.is_verified = is_verified

    audit = AuditLog(
        actor_id=admin_user.id,
        action="CHARGER_STATUS_OVERRIDE",
        entity_type="Charger",
        entity_id=charger.id,
        details_json={"new_status": new_status.value, "is_verified": charger.is_verified}
    )
    db.add(audit)
    db.commit()
    db.refresh(charger)
    return {"id": charger.id, "status": charger.status.value, "is_verified": charger.is_verified}

@router.get("/bookings", response_model=List[BookingResponse])
def get_all_bookings(
    status_filter: Optional[BookingStatus] = None,
    db: Session = Depends(get_db),
    admin_user: User = Depends(require_role([UserRole.ADMIN]))
):
    q = db.query(Booking)
    if status_filter:
        q = q.filter(Booking.status == status_filter)
    bookings = q.order_by(Booking.created_at.desc()).all()
    return [BookingService.to_response_dto(b, viewer=admin_user) for b in bookings]

@router.get("/fault-reports", response_model=List[FaultReportResponse])
def get_fault_reports(
    db: Session = Depends(get_db),
    admin_user: User = Depends(require_role([UserRole.ADMIN]))
):
    return db.query(FaultReport).order_by(FaultReport.created_at.desc()).all()

@router.patch("/fault-reports/{id}/resolve")
def resolve_fault_report(
    id: int,
    db: Session = Depends(get_db),
    admin_user: User = Depends(require_role([UserRole.ADMIN]))
):
    report = db.query(FaultReport).filter(FaultReport.id == id).first()
    if not report:
        raise HTTPException(status_code=404, detail="Report not found")
    report.status = "resolved"
    db.commit()
    return {"id": report.id, "status": "resolved"}

@router.get("/support-cases", response_model=List[SupportCaseResponse])
def get_all_support_cases(
    db: Session = Depends(get_db),
    admin_user: User = Depends(require_role([UserRole.ADMIN]))
):
    return db.query(SupportCase).order_by(SupportCase.created_at.desc()).all()

@router.get("/audit-logs", response_model=List[AuditLogResponse])
def get_audit_logs(
    db: Session = Depends(get_db),
    admin_user: User = Depends(require_role([UserRole.ADMIN]))
):
    logs = db.query(AuditLog).order_by(AuditLog.timestamp.desc()).limit(100).all()
    resp = []
    for l in logs:
        resp.append(AuditLogResponse(
            id=l.id,
            actor_id=l.actor_id,
            actor_email=l.actor.email if l.actor else "System",
            action=l.action,
            entity_type=l.entity_type,
            entity_id=l.entity_id,
            details_json=l.details_json,
            ip_address=l.ip_address,
            timestamp=l.timestamp
        ))
    return resp
