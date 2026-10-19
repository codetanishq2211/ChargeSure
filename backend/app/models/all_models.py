import enum
from datetime import datetime
from sqlalchemy import Column, Integer, String, Float, Boolean, DateTime, ForeignKey, Text, Enum as SQLEnum, JSON
from sqlalchemy.orm import relationship
from backend.app.database import Base

class UserRole(str, enum.Enum):
    DRIVER = "driver"
    HOST = "host"
    ADMIN = "admin"

class ChargerType(str, enum.Enum):
    PUBLIC = "public"
    BUSINESS = "business"
    HOME = "home"

class CurrentType(str, enum.Enum):
    AC = "AC"
    DC = "DC"

class ChargerStatus(str, enum.Enum):
    AVAILABLE = "available"
    IN_USE = "in_use"
    FAULTY = "faulty"
    OFFLINE = "offline"

class DataSource(str, enum.Enum):
    LIVE_OPERATOR = "live_operator"
    HOST_CONFIRMED = "host_confirmed"
    MANUALLY_REPORTED = "manually_reported"
    UNVERIFIED = "unverified"

class BookingStatus(str, enum.Enum):
    PENDING = "pending"
    CONFIRMED = "confirmed"
    REJECTED = "rejected"
    CANCELLED = "cancelled"
    IN_PROGRESS = "in_progress"
    COMPLETED = "completed"

class SessionStatus(str, enum.Enum):
    ACTIVE = "active"
    COMPLETED = "completed"
    INTERRUPTED = "interrupted"

class TelemetrySource(str, enum.Enum):
    USER_REPORTED = "user_reported"
    SIMULATED = "simulated"
    METER_VERIFIED = "meter_verified"

class SupportStatus(str, enum.Enum):
    OPEN = "open"
    IN_PROGRESS = "in_progress"
    RESOLVED = "resolved"

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String(255), unique=True, index=True, nullable=False)
    hashed_password = Column(String(255), nullable=False)
    full_name = Column(String(255), nullable=False)
    phone = Column(String(50), nullable=True)
    role = Column(SQLEnum(UserRole), default=UserRole.DRIVER, nullable=False)
    is_active = Column(Boolean, default=True, nullable=False)
    is_verified = Column(Boolean, default=False, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)

    vehicles = relationship("Vehicle", back_populates="owner", cascade="all, delete-orphan")
    chargers = relationship("Charger", back_populates="host", cascade="all, delete-orphan")
    bookings = relationship("Booking", foreign_keys="Booking.driver_id", back_populates="driver")
    host_bookings = relationship("Booking", foreign_keys="Booking.host_id", back_populates="host")
    reviews = relationship("Review", back_populates="author")
    fault_reports = relationship("FaultReport", back_populates="reporter")
    support_cases = relationship("SupportCase", back_populates="user")
    audit_logs = relationship("AuditLog", back_populates="actor")


class Vehicle(Base):
    __tablename__ = "vehicles"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    make = Column(String(100), nullable=False)
    model = Column(String(100), nullable=False)
    year = Column(Integer, default=2024)
    license_plate = Column(String(50), nullable=True)
    battery_capacity_kwh = Column(Float, nullable=False)  # e.g., 60.0 kWh
    connector_type = Column(String(50), nullable=False)   # e.g., "CCS2", "Type 2", "GB/T", "CHAdeMO"
    consumption_wh_per_km = Column(Float, default=160.0, nullable=False) # e.g. 160 Wh/km
    current_battery_percent = Column(Float, default=75.0, nullable=False) # 0 - 100%
    is_primary = Column(Boolean, default=True, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)

    owner = relationship("User", back_populates="vehicles")
    bookings = relationship("Booking", back_populates="vehicle")


class Charger(Base):
    __tablename__ = "chargers"

    id = Column(Integer, primary_key=True, index=True)
    host_id = Column(Integer, ForeignKey("users.id"), nullable=True, index=True)
    title = Column(String(255), nullable=False)
    description = Column(Text, nullable=True)
    address = Column(String(255), nullable=False)
    city = Column(String(100), nullable=False)
    state = Column(String(100), nullable=True)
    postal_code = Column(String(20), nullable=True)
    latitude = Column(Float, nullable=False, index=True)
    longitude = Column(Float, nullable=False, index=True)
    charger_type = Column(SQLEnum(ChargerType), default=ChargerType.PUBLIC, nullable=False)
    current_type = Column(SQLEnum(CurrentType), default=CurrentType.AC, nullable=False) # AC / DC
    power_kw = Column(Float, nullable=False)  # e.g., 7.4, 11, 22, 50, 60, 120, 150 kW
    connector_types = Column(JSON, nullable=False) # e.g., ["CCS2", "Type 2"]
    price_per_kwh = Column(Float, default=0.0, nullable=False) # e.g., 14.50 INR or USD
    price_per_hour = Column(Float, default=0.0, nullable=False)
    pricing_model = Column(String(50), default="per_kwh", nullable=False) # "per_kwh", "flat", "hourly"
    status = Column(SQLEnum(ChargerStatus), default=ChargerStatus.AVAILABLE, nullable=False)
    data_source = Column(SQLEnum(DataSource), default=DataSource.LIVE_OPERATOR, nullable=False)
    freshness_timestamp = Column(DateTime, default=datetime.utcnow, nullable=False)
    is_verified = Column(Boolean, default=True, nullable=False)
    access_instructions = Column(Text, nullable=True) # Protected: only revealed upon confirmed booking
    reliability_score = Column(Float, default=95.0, nullable=False) # 0 to 100%
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)

    host = relationship("User", back_populates="chargers")
    availability_slots = relationship("AvailabilitySlot", back_populates="charger", cascade="all, delete-orphan")
    bookings = relationship("Booking", back_populates="charger")
    sessions = relationship("ChargingSession", back_populates="charger")
    reviews = relationship("Review", back_populates="charger", cascade="all, delete-orphan")
    fault_reports = relationship("FaultReport", back_populates="charger", cascade="all, delete-orphan")


class AvailabilitySlot(Base):
    __tablename__ = "availability_slots"

    id = Column(Integer, primary_key=True, index=True)
    charger_id = Column(Integer, ForeignKey("chargers.id"), nullable=False, index=True)
    day_of_week = Column(Integer, nullable=True) # 0=Monday ... 6=Sunday
    start_time = Column(String(10), nullable=False) # e.g. "08:00"
    end_time = Column(String(10), nullable=False)   # e.g. "20:00"
    is_active = Column(Boolean, default=True, nullable=False)
    specific_date = Column(String(20), nullable=True) # Optional ISO date "2026-10-25"

    charger = relationship("Charger", back_populates="availability_slots")


class Booking(Base):
    __tablename__ = "bookings"

    id = Column(Integer, primary_key=True, index=True)
    booking_code = Column(String(32), unique=True, index=True, nullable=False)
    driver_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    host_id = Column(Integer, ForeignKey("users.id"), nullable=True, index=True)
    charger_id = Column(Integer, ForeignKey("chargers.id"), nullable=False, index=True)
    vehicle_id = Column(Integer, ForeignKey("vehicles.id"), nullable=True, index=True)
    start_time = Column(DateTime, nullable=False)
    end_time = Column(DateTime, nullable=False)
    status = Column(SQLEnum(BookingStatus), default=BookingStatus.PENDING, nullable=False)
    total_price_snapshot = Column(Float, default=0.0, nullable=False) # Snapshot price at confirmation
    cancellation_reason = Column(String(255), nullable=True)
    is_backup_booking = Column(Boolean, default=False, nullable=False)
    backup_trigger_reason = Column(String(255), nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)

    driver = relationship("User", foreign_keys=[driver_id], back_populates="bookings")
    host = relationship("User", foreign_keys=[host_id], back_populates="host_bookings")
    charger = relationship("Charger", back_populates="bookings")
    vehicle = relationship("Vehicle", back_populates="bookings")
    session = relationship("ChargingSession", back_populates="booking", uselist=False)
    reviews = relationship("Review", back_populates="booking")


class ChargingSession(Base):
    __tablename__ = "charging_sessions"

    id = Column(Integer, primary_key=True, index=True)
    booking_id = Column(Integer, ForeignKey("bookings.id"), nullable=True, index=True)
    driver_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    charger_id = Column(Integer, ForeignKey("chargers.id"), nullable=False, index=True)
    vehicle_id = Column(Integer, ForeignKey("vehicles.id"), nullable=True, index=True)
    start_time = Column(DateTime, default=datetime.utcnow, nullable=False)
    end_time = Column(DateTime, nullable=True)
    initial_battery_percent = Column(Float, nullable=False)
    final_battery_percent = Column(Float, nullable=True)
    energy_delivered_kwh = Column(Float, default=0.0, nullable=False)
    total_cost = Column(Float, default=0.0, nullable=False)
    status = Column(SQLEnum(SessionStatus), default=SessionStatus.ACTIVE, nullable=False)
    telemetry_source = Column(SQLEnum(TelemetrySource), default=TelemetrySource.SIMULATED, nullable=False)
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)

    booking = relationship("Booking", back_populates="session")
    charger = relationship("Charger", back_populates="sessions")


class Review(Base):
    __tablename__ = "reviews"

    id = Column(Integer, primary_key=True, index=True)
    booking_id = Column(Integer, ForeignKey("bookings.id"), nullable=True, index=True)
    charger_id = Column(Integer, ForeignKey("chargers.id"), nullable=False, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    rating = Column(Integer, nullable=False) # 1 to 5
    comment = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)

    charger = relationship("Charger", back_populates="reviews")
    author = relationship("User", back_populates="reviews")
    booking = relationship("Booking", back_populates="reviews")


class FaultReport(Base):
    __tablename__ = "fault_reports"

    id = Column(Integer, primary_key=True, index=True)
    charger_id = Column(Integer, ForeignKey("chargers.id"), nullable=False, index=True)
    reported_by_user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    issue_type = Column(String(100), nullable=False) # "Connector broken", "No power", "Blocked by ICE", "Offline"
    description = Column(Text, nullable=True)
    status = Column(String(50), default="pending", nullable=False) # "pending", "investigating", "resolved"
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)

    charger = relationship("Charger", back_populates="fault_reports")
    reporter = relationship("User", back_populates="fault_reports")


class SupportCase(Base):
    __tablename__ = "support_cases"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    booking_id = Column(Integer, ForeignKey("bookings.id"), nullable=True)
    subject = Column(String(255), nullable=False)
    message = Column(Text, nullable=False)
    priority = Column(String(50), default="medium", nullable=False) # "low", "medium", "urgent"
    status = Column(SQLEnum(SupportStatus), default=SupportStatus.OPEN, nullable=False)
    resolution_notes = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)

    user = relationship("User", back_populates="support_cases")


class AuditLog(Base):
    __tablename__ = "audit_logs"

    id = Column(Integer, primary_key=True, index=True)
    actor_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    action = Column(String(100), nullable=False) # "USER_SUSPENDED", "CHARGER_APPROVED", "BOOKING_OVERRIDE"
    entity_type = Column(String(100), nullable=False) # "User", "Charger", "Booking"
    entity_id = Column(Integer, nullable=True)
    details_json = Column(JSON, nullable=True)
    ip_address = Column(String(50), nullable=True)
    timestamp = Column(DateTime, default=datetime.utcnow, nullable=False)

    actor = relationship("User", back_populates="audit_logs")
