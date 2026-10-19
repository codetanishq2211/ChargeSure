from datetime import datetime, timedelta
import pytest
from backend.app.models.all_models import User, Charger, Booking, BookingStatus
from backend.app.services.booking_service import BookingService
from backend.app.schemas.all_schemas import BookingCreate

def test_booking_creation_and_double_booking_prevention(db_session):
    driver = db_session.query(User).filter(User.email == "driver@chargesure.com").first()
    charger = db_session.query(Charger).filter(Charger.id == 1).first()

    start = datetime.utcnow() + timedelta(days=5, hours=10)
    end = datetime.utcnow() + timedelta(days=5, hours=11)

    req1 = BookingCreate(
        charger_id=charger.id,
        start_time=start,
        end_time=end,
        is_backup_booking=False
    )
    b1 = BookingService.create_booking(db=db_session, driver=driver, request=req1)
    assert b1.id is not None
    assert b1.booking_code.startswith("CS-")

    # Attempt overlapping booking on same charger
    req2 = BookingCreate(
        charger_id=charger.id,
        start_time=start + timedelta(minutes=15),
        end_time=end + timedelta(minutes=30),
        is_backup_booking=False
    )
    with pytest.raises(Exception) as excinfo:
        BookingService.create_booking(db=db_session, driver=driver, request=req2)
    assert "already reserved" in str(excinfo.value.detail)

def test_booking_host_accept_reject_transitions(db_session):
    driver = db_session.query(User).filter(User.email == "driver@chargesure.com").first()
    host = db_session.query(User).filter(User.email == "host@chargesure.com").first()
    # Patel Residence is home charger (id=3)
    charger = db_session.query(Charger).filter(Charger.id == 3).first()

    start = datetime.utcnow() + timedelta(days=6, hours=14)
    end = datetime.utcnow() + timedelta(days=6, hours=16)

    req = BookingCreate(
        charger_id=charger.id,
        start_time=start,
        end_time=end
    )
    # Home charger creates a PENDING request
    b = BookingService.create_booking(db=db_session, driver=driver, request=req)
    assert b.status == BookingStatus.PENDING

    # Host accepts booking
    b_accepted = BookingService.accept_booking(db=db_session, booking_id=b.id, host_or_admin=host)
    assert b_accepted.status == BookingStatus.CONFIRMED

    # Verification: Access notes now revealed to driver in response DTO
    dto = BookingService.to_response_dto(b_accepted, viewer=driver)
    assert "Garage keypad" in dto.charger.access_instructions
    assert dto.charger.is_access_masked is False
