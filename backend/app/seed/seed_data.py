from datetime import datetime, timedelta
from sqlalchemy.orm import Session
from backend.app.database import SessionLocal
from backend.app.models.all_models import (
    User, UserRole, Vehicle, Charger, ChargerType, CurrentType,
    ChargerStatus, DataSource, AvailabilitySlot, Booking, BookingStatus,
    ChargingSession, SessionStatus, TelemetrySource, Review, FaultReport,
    SupportCase, SupportStatus, AuditLog
)
from backend.app.core.security import get_password_hash

def seed_database_if_empty():
    db: Session = SessionLocal()
    try:
        if db.query(User).count() > 0:
            return  # Already seeded

        print("Seeding initial ChargeSure demonstration dataset...")

        # 1. USERS
        admin_user = User(
            email="admin@chargesure.com",
            hashed_password=get_password_hash("Admin@123"),
            full_name="ChargeSure System Administrator",
            phone="+1-800-555-0100",
            role=UserRole.ADMIN,
            is_active=True,
            is_verified=True
        )

        host_user = User(
            email="host@chargesure.com",
            hashed_password=get_password_hash("Host@123"),
            full_name="Rajesh Patel (Host & Business Partner)",
            phone="+1-800-555-0200",
            role=UserRole.HOST,
            is_active=True,
            is_verified=True
        )

        driver_user = User(
            email="driver@chargesure.com",
            hashed_password=get_password_hash("Driver@123"),
            full_name="Sarah Jenkins (EV Driver)",
            phone="+1-800-555-0300",
            role=UserRole.DRIVER,
            is_active=True,
            is_verified=True
        )

        db.add_all([admin_user, host_user, driver_user])
        db.commit()
        db.refresh(admin_user)
        db.refresh(host_user)
        db.refresh(driver_user)

        # 2. VEHICLES
        v1 = Vehicle(
            user_id=driver_user.id,
            make="Hyundai",
            model="Ioniq 5 AWD",
            year=2024,
            license_plate="EV-502-CS",
            battery_capacity_kwh=77.4,
            connector_type="CCS2",
            consumption_wh_per_km=170.0,
            current_battery_percent=42.0,
            is_primary=True
        )

        v2 = Vehicle(
            user_id=driver_user.id,
            make="Tesla",
            model="Model 3 Long Range",
            year=2023,
            license_plate="TS-309-LR",
            battery_capacity_kwh=75.0,
            connector_type="CCS2",
            consumption_wh_per_km=150.0,
            current_battery_percent=85.0,
            is_primary=False
        )

        v3 = Vehicle(
            user_id=driver_user.id,
            make="Tata",
            model="Nexon EV Empowered",
            year=2024,
            license_plate="MH-12-NX-8821",
            battery_capacity_kwh=40.5,
            connector_type="CCS2",
            consumption_wh_per_km=145.0,
            current_battery_percent=60.0,
            is_primary=False
        )

        db.add_all([v1, v2, v3])
        db.commit()
        db.refresh(v1)

        # 3. CHARGERS (Centered around realistic metropolitan coordinates: 37.7749, -122.4194 / San Francisco corridor)
        # 1. Supercharger Hub (Live Operator, high power)
        c1 = Charger(
            host_id=None,
            title="ChargeSure Central SuperHub",
            description="Ultra-fast DC charging corridor hub with 6 dedicated bays, cafe, and lounge amenities.",
            address="450 Mission Street",
            city="San Francisco",
            state="CA",
            postal_code="94105",
            latitude=37.7905,
            longitude=-122.3995,
            charger_type=ChargerType.PUBLIC,
            current_type=CurrentType.DC,
            power_kw=150.0,
            connector_types=["CCS2", "Type 2", "CHAdeMO"],
            price_per_kwh=0.38,
            price_per_hour=0.0,
            pricing_model="per_kwh",
            status=ChargerStatus.AVAILABLE,
            data_source=DataSource.LIVE_OPERATOR,
            freshness_timestamp=datetime.utcnow() - timedelta(minutes=5),
            is_verified=True,
            access_instructions="Public multi-story parking level P1, dedicated EV charging bays 1-6.",
            reliability_score=98.5
        )

        # 2. Business Hub (Host Confirmed, 60kW DC)
        c2 = Charger(
            host_id=host_user.id,
            title="BayTech Commercial FastCharger",
            description="Corporate campus charging station open to ChargeSure verified members.",
            address="800 Market St",
            city="San Francisco",
            state="CA",
            postal_code="94102",
            latitude=37.7845,
            longitude=-122.4068,
            charger_type=ChargerType.BUSINESS,
            current_type=CurrentType.DC,
            power_kw=60.0,
            connector_types=["CCS2", "Type 2"],
            price_per_kwh=0.32,
            price_per_hour=0.0,
            pricing_model="per_kwh",
            status=ChargerStatus.AVAILABLE,
            data_source=DataSource.HOST_CONFIRMED,
            freshness_timestamp=datetime.utcnow() - timedelta(minutes=15),
            is_verified=True,
            access_instructions="Enter visitor gate via intercom. Security will direct you to bay 4B.",
            reliability_score=95.0
        )

        # 3. Home Host Charger (Verified residential host, 11 kW AC)
        c3 = Charger(
            host_id=host_user.id,
            title="Patel Residence EcoWallbox",
            description="Safe, private residential driveway charging with 24/7 security lighting and camera surveillance.",
            address="1420 Hayes St",
            city="San Francisco",
            state="CA",
            postal_code="94117",
            latitude=37.7758,
            longitude=-122.4382,
            charger_type=ChargerType.HOME,
            current_type=CurrentType.AC,
            power_kw=11.0,
            connector_types=["Type 2", "CCS2"],
            price_per_kwh=0.22,
            price_per_hour=2.0,
            pricing_model="per_kwh",
            status=ChargerStatus.AVAILABLE,
            data_source=DataSource.HOST_CONFIRMED,
            freshness_timestamp=datetime.utcnow() - timedelta(minutes=30),
            is_verified=True,
            access_instructions="Driveway on left of property. Garage keypad code is 4821#.",
            reliability_score=92.0
        )

        # 4. Problematic / Faulty station (for backup engine trigger testing)
        c4 = Charger(
            host_id=None,
            title="SoMa Urban Rapid Station (Reported Issue)",
            description="Urban roadside dual charger. Currently reported with connector latch malfunction.",
            address="220 4th Street",
            city="San Francisco",
            state="CA",
            postal_code="94103",
            latitude=37.7820,
            longitude=-122.4030,
            charger_type=ChargerType.PUBLIC,
            current_type=CurrentType.DC,
            power_kw=50.0,
            connector_types=["CCS2"],
            price_per_kwh=0.29,
            price_per_hour=0.0,
            pricing_model="per_kwh",
            status=ChargerStatus.FAULTY,
            data_source=DataSource.MANUALLY_REPORTED,
            freshness_timestamp=datetime.utcnow() - timedelta(minutes=40),
            is_verified=True,
            access_instructions="Curbside station opposite convention center.",
            reliability_score=62.0
        )

        # 5. Backup Haven Fast Station
        c5 = Charger(
            host_id=host_user.id,
            title="Presidio CleanEnergy Depot",
            description="High-availability backup charging hub nestled near highway 101 exit.",
            address="102 Montgomery St",
            city="San Francisco",
            state="CA",
            postal_code="94129",
            latitude=37.8010,
            longitude=-122.4580,
            charger_type=ChargerType.PUBLIC,
            current_type=CurrentType.DC,
            power_kw=120.0,
            connector_types=["CCS2", "Type 2"],
            price_per_kwh=0.35,
            price_per_hour=0.0,
            pricing_model="per_kwh",
            status=ChargerStatus.AVAILABLE,
            data_source=DataSource.LIVE_OPERATOR,
            freshness_timestamp=datetime.utcnow() - timedelta(minutes=10),
            is_verified=True,
            access_instructions="North lot bay 12. Free parking while charging.",
            reliability_score=97.0
        )

        db.add_all([c1, c2, c3, c4, c5])
        db.commit()
        db.refresh(c1)
        db.refresh(c2)
        db.refresh(c3)
        db.refresh(c4)
        db.refresh(c5)

        # 4. AVAILABILITY SLOTS FOR HOME & BUSINESS CHARGERS
        for day in range(7):
            s1 = AvailabilitySlot(charger_id=c2.id, day_of_week=day, start_time="08:00", end_time="20:00", is_active=True)
            s2 = AvailabilitySlot(charger_id=c3.id, day_of_week=day, start_time="06:00", end_time="23:00", is_active=True)
            db.add_all([s1, s2])
        db.commit()

        # 5. SEED BOOKINGS
        # An upcoming confirmed booking
        now = datetime.utcnow()
        b_upcoming = Booking(
            booking_code="CS-UPCOMING1",
            driver_id=driver_user.id,
            host_id=host_user.id,
            charger_id=c2.id,
            vehicle_id=v1.id,
            start_time=now + timedelta(hours=2),
            end_time=now + timedelta(hours=3),
            status=BookingStatus.CONFIRMED,
            total_price_snapshot=19.20,
            is_backup_booking=False
        )

        # A pending request on home charger
        b_pending = Booking(
            booking_code="CS-PENDING02",
            driver_id=driver_user.id,
            host_id=host_user.id,
            charger_id=c3.id,
            vehicle_id=v1.id,
            start_time=now + timedelta(days=1, hours=10),
            end_time=now + timedelta(days=1, hours=12),
            status=BookingStatus.PENDING,
            total_price_snapshot=8.80,
            is_backup_booking=False
        )

        # A completed session from yesterday
        b_completed = Booking(
            booking_code="CS-HISTORY99",
            driver_id=driver_user.id,
            host_id=None,
            charger_id=c1.id,
            vehicle_id=v1.id,
            start_time=now - timedelta(days=1, hours=3),
            end_time=now - timedelta(days=1, hours=2),
            status=BookingStatus.COMPLETED,
            total_price_snapshot=14.50,
            is_backup_booking=False
        )

        db.add_all([b_upcoming, b_pending, b_completed])
        db.commit()
        db.refresh(b_completed)

        # 6. CHARGING SESSION
        sess = ChargingSession(
            booking_id=b_completed.id,
            driver_id=driver_user.id,
            charger_id=c1.id,
            vehicle_id=v1.id,
            start_time=now - timedelta(days=1, hours=3),
            end_time=now - timedelta(days=1, hours=2),
            initial_battery_percent=25.0,
            final_battery_percent=78.0,
            energy_delivered_kwh=38.2,
            total_cost=14.50,
            status=SessionStatus.COMPLETED,
            telemetry_source=TelemetrySource.SIMULATED,
            notes="Session completed smoothly at ChargeSure Central SuperHub"
        )
        db.add(sess)

        # 7. REVIEWS
        r1 = Review(
            charger_id=c1.id,
            booking_id=b_completed.id,
            user_id=driver_user.id,
            rating=5,
            comment="Remarkable charging speed! Plugged in at 25% and reached 78% in under 45 minutes."
        )
        r2 = Review(
            charger_id=c3.id,
            user_id=driver_user.id,
            rating=5,
            comment="Host Rajesh was very welcoming and the driveway spot was clean, safe, and easily accessible."
        )
        db.add_all([r1, r2])

        # 8. FAULT REPORT ON STATION 4
        f1 = FaultReport(
            charger_id=c4.id,
            reported_by_user_id=driver_user.id,
            issue_type="Connector latch mechanism jammed",
            description="CCS2 plug would not lock into vehicle port, throwing communication error code 402.",
            status="pending"
        )
        db.add(f1)

        # 9. SUPPORT CASE
        s_case = SupportCase(
            user_id=driver_user.id,
            subject="Verification of Roadside Assistance Policy",
            message="Hi team, I wanted to verify whether ChargeSure 24/7 roadside assistance covers rural mountain highways?",
            priority="medium",
            status=SupportStatus.OPEN
        )
        db.add(s_case)

        # 10. AUDIT LOG
        audit1 = AuditLog(
            actor_id=admin_user.id,
            action="SYSTEM_INITIALIZED",
            entity_type="System",
            entity_id=1,
            details_json={"demo_seed": True, "chargers_loaded": 5}
        )
        db.add(audit1)

        db.commit()
        print("ChargeSure database successfully populated with demonstration data!")

    except Exception as e:
        db.rollback()
        print(f"Error seeding database: {e}")
    finally:
        db.close()
