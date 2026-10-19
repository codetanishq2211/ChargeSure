from datetime import datetime
from typing import Optional, List, Dict, Any
from pydantic import BaseModel, EmailStr, Field
from backend.app.models.all_models import (
    UserRole,
    ChargerType,
    CurrentType,
    ChargerStatus,
    DataSource,
    BookingStatus,
    SessionStatus,
    TelemetrySource,
    SupportStatus,
)

# ----------------- AUTH SCHEMAS -----------------
class RegisterRequest(BaseModel):
    email: EmailStr
    password: str = Field(..., min_length=6)
    full_name: str = Field(..., min_length=2)
    phone: Optional[str] = None
    role: UserRole = UserRole.DRIVER

class LoginRequest(BaseModel):
    email: EmailStr
    password: str

class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user_id: int
    email: str
    full_name: str
    role: UserRole

# ----------------- USER SCHEMAS -----------------
class UserResponse(BaseModel):
    id: int
    email: str
    full_name: str
    phone: Optional[str] = None
    role: UserRole
    is_active: bool
    is_verified: bool
    created_at: datetime

    class Config:
        from_attributes = True

class UserUpdate(BaseModel):
    full_name: Optional[str] = None
    phone: Optional[str] = None
    password: Optional[str] = None

# ----------------- VEHICLE SCHEMAS -----------------
class VehicleBase(BaseModel):
    make: str
    model: str
    year: int = 2024
    license_plate: Optional[str] = None
    battery_capacity_kwh: float = Field(..., gt=0, description="Usable battery pack capacity in kWh")
    connector_type: str = Field(..., description="e.g. CCS2, Type 2, GB/T, CHAdeMO")
    consumption_wh_per_km: float = Field(default=160.0, gt=0, description="Average energy consumption in Wh/km")
    current_battery_percent: float = Field(default=75.0, ge=0, le=100)
    is_primary: bool = True

class VehicleCreate(VehicleBase):
    pass

class VehicleUpdate(BaseModel):
    make: Optional[str] = None
    model: Optional[str] = None
    year: Optional[int] = None
    license_plate: Optional[str] = None
    battery_capacity_kwh: Optional[float] = None
    connector_type: Optional[str] = None
    consumption_wh_per_km: Optional[float] = None
    current_battery_percent: Optional[float] = None
    is_primary: Optional[bool] = None

class VehicleResponse(VehicleBase):
    id: int
    user_id: int
    estimated_range_km: float
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

# ----------------- CHARGER SCHEMAS -----------------
class AvailabilitySlotCreate(BaseModel):
    day_of_week: Optional[int] = None
    start_time: str
    end_time: str
    is_active: bool = True
    specific_date: Optional[str] = None

class AvailabilitySlotResponse(AvailabilitySlotCreate):
    id: int
    charger_id: int

    class Config:
        from_attributes = True

class ChargerBase(BaseModel):
    title: str
    description: Optional[str] = None
    address: str
    city: str
    state: Optional[str] = None
    postal_code: Optional[str] = None
    latitude: float
    longitude: float
    charger_type: ChargerType = ChargerType.PUBLIC
    current_type: CurrentType = CurrentType.AC
    power_kw: float = Field(..., gt=0)
    connector_types: List[str]
    price_per_kwh: float = Field(default=0.0, ge=0)
    price_per_hour: float = Field(default=0.0, ge=0)
    pricing_model: str = "per_kwh"
    status: ChargerStatus = ChargerStatus.AVAILABLE
    data_source: DataSource = DataSource.LIVE_OPERATOR
    access_instructions: Optional[str] = None

class ChargerCreate(ChargerBase):
    pass

class ChargerUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    address: Optional[str] = None
    city: Optional[str] = None
    state: Optional[str] = None
    postal_code: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    charger_type: Optional[ChargerType] = None
    current_type: Optional[CurrentType] = None
    power_kw: Optional[float] = None
    connector_types: Optional[List[str]] = None
    price_per_kwh: Optional[float] = None
    price_per_hour: Optional[float] = None
    pricing_model: Optional[str] = None
    status: Optional[ChargerStatus] = None
    data_source: Optional[DataSource] = None
    access_instructions: Optional[str] = None
    is_verified: Optional[bool] = None

class ChargerResponse(ChargerBase):
    id: int
    host_id: Optional[int] = None
    freshness_timestamp: datetime
    is_verified: bool
    reliability_score: float
    distance_km: Optional[float] = None
    is_access_masked: bool = False
    average_rating: Optional[float] = 4.8
    total_reviews: int = 0
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

# ----------------- BOOKING SCHEMAS -----------------
class BookingCreate(BaseModel):
    charger_id: int
    vehicle_id: Optional[int] = None
    start_time: datetime
    end_time: datetime
    is_backup_booking: bool = False
    backup_trigger_reason: Optional[str] = None

class BookingResponse(BaseModel):
    id: int
    booking_code: str
    driver_id: int
    host_id: Optional[int] = None
    charger_id: int
    vehicle_id: Optional[int] = None
    start_time: datetime
    end_time: datetime
    status: BookingStatus
    total_price_snapshot: float
    cancellation_reason: Optional[str] = None
    is_backup_booking: bool
    backup_trigger_reason: Optional[str] = None
    charger: Optional[ChargerResponse] = None
    vehicle: Optional[VehicleResponse] = None
    driver_name: Optional[str] = None
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

class BookingStatusAction(BaseModel):
    reason: Optional[str] = None

# ----------------- CHARGING SESSION SCHEMAS -----------------
class SessionStartRequest(BaseModel):
    booking_id: Optional[int] = None
    charger_id: int
    vehicle_id: Optional[int] = None
    initial_battery_percent: float = Field(..., ge=0, le=100)
    notes: Optional[str] = None

class SessionCompleteRequest(BaseModel):
    final_battery_percent: float = Field(..., ge=0, le=100)
    energy_delivered_kwh: Optional[float] = None
    notes: Optional[str] = None

class SessionResponse(BaseModel):
    id: int
    booking_id: Optional[int] = None
    driver_id: int
    charger_id: int
    vehicle_id: Optional[int] = None
    start_time: datetime
    end_time: Optional[datetime] = None
    duration_minutes: Optional[int] = None
    initial_battery_percent: float
    final_battery_percent: Optional[float] = None
    energy_delivered_kwh: float
    total_cost: float
    status: SessionStatus
    telemetry_source: TelemetrySource
    notes: Optional[str] = None
    created_at: datetime

    class Config:
        from_attributes = True

# ----------------- BACKUP RECOMMENDATION SCHEMAS -----------------
class BackupRequest(BaseModel):
    current_latitude: float
    current_longitude: float
    vehicle_id: Optional[int] = None
    current_battery_percent: Optional[float] = None
    battery_capacity_kwh: Optional[float] = None
    consumption_wh_per_km: Optional[float] = None
    connector_type: Optional[str] = None
    min_safety_reserve_percent: float = Field(default=15.0, ge=5, le=50)
    failed_charger_id: Optional[int] = None
    failure_reason: str = "Host rejected booking / Charger unavailable"

class BackupCandidate(BaseModel):
    charger: ChargerResponse
    distance_km: float
    detour_km: float
    estimated_driving_time_minutes: int
    estimated_arrival_battery_percent: float
    is_safely_reachable: bool
    connector_compatible: bool
    availability_confidence_score: float # 0 to 100%
    overall_rank_score: float # 0 to 100%
    primary_recommendation_reason: str

class BackupResponse(BaseModel):
    failure_reason: str
    original_charger_title: Optional[str] = None
    vehicle_summary: str
    min_safety_reserve_percent: float
    candidates_found: int
    safe_candidates_count: int
    has_safe_alternative: bool
    status_summary: str
    best_candidate: Optional[BackupCandidate] = None
    additional_options: List[BackupCandidate] = []
    emergency_contacts: List[Dict[str, Any]] = []

# ----------------- TRIP PLANNER SCHEMAS -----------------
class TripPlanRequest(BaseModel):
    origin_latitude: float
    origin_longitude: float
    destination_latitude: float
    destination_longitude: float
    vehicle_id: Optional[int] = None
    current_battery_percent: float = Field(..., ge=0, le=100)
    min_safety_reserve_percent: float = Field(default=15.0, ge=5, le=50)

class TripStop(BaseModel):
    charger: ChargerResponse
    distance_from_origin_km: float
    arrival_battery_percent: float
    target_charge_battery_percent: float
    charging_time_minutes: int
    energy_needed_kwh: float
    estimated_cost: float

class TripPlanResponse(BaseModel):
    total_distance_km: float
    total_driving_time_minutes: int
    total_trip_time_minutes: int
    initial_battery_percent: float
    estimated_consumption_kwh: float
    estimated_arrival_battery_percent: float
    is_charging_required: bool
    explanation: str
    suggested_stops: List[TripStop] = []
    route_waypoints: List[Dict[str, float]] = []

# ----------------- REVIEWS & SUPPORT SCHEMAS -----------------
class ReviewCreate(BaseModel):
    charger_id: int
    booking_id: Optional[int] = None
    rating: int = Field(..., ge=1, le=5)
    comment: Optional[str] = None

class ReviewResponse(BaseModel):
    id: int
    charger_id: int
    booking_id: Optional[int] = None
    user_id: int
    author_name: str
    rating: int
    comment: Optional[str] = None
    created_at: datetime

    class Config:
        from_attributes = True

class FaultReportCreate(BaseModel):
    charger_id: int
    issue_type: str
    description: Optional[str] = None

class FaultReportResponse(BaseModel):
    id: int
    charger_id: int
    reported_by_user_id: int
    issue_type: str
    description: Optional[str] = None
    status: str
    created_at: datetime

    class Config:
        from_attributes = True

class SupportCaseCreate(BaseModel):
    booking_id: Optional[int] = None
    subject: str
    message: str
    priority: str = "medium"

class SupportCaseResponse(BaseModel):
    id: int
    user_id: int
    booking_id: Optional[int] = None
    subject: str
    message: str
    priority: str
    status: SupportStatus
    resolution_notes: Optional[str] = None
    created_at: datetime

    class Config:
        from_attributes = True

# ----------------- ADMIN SCHEMAS -----------------
class AdminAnalyticsResponse(BaseModel):
    total_users: int
    total_drivers: int
    total_hosts: int
    total_chargers: int
    verified_chargers: int
    total_bookings: int
    completed_bookings: int
    backup_triggers_count: int
    active_sessions: int
    pending_fault_reports: int
    open_support_cases: int
    total_energy_delivered_kwh: float
    total_platform_revenue: float
    demo_mode: bool

class AuditLogResponse(BaseModel):
    id: int
    actor_id: Optional[int] = None
    actor_email: Optional[str] = None
    action: str
    entity_type: str
    entity_id: Optional[int] = None
    details_json: Optional[Dict[str, Any]] = None
    ip_address: Optional[str] = None
    timestamp: datetime

    class Config:
        from_attributes = True
