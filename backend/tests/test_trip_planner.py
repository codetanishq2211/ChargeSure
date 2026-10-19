import pytest
from backend.app.services.trip_planner import TripPlannerService
from backend.app.schemas.all_schemas import TripPlanRequest
from backend.app.models.all_models import Vehicle

def test_trip_planner_short_trip_no_stop_needed(db_session):
    # Short 10km trip in SF with 80% battery
    request = TripPlanRequest(
        origin_latitude=37.7749,
        origin_longitude=-122.4194,
        destination_latitude=37.8044,
        destination_longitude=-122.2712,
        current_battery_percent=80.0,
        min_safety_reserve_percent=15.0
    )

    plan = TripPlannerService.plan_trip(db=db_session, request=request)
    assert plan.is_charging_required is False
    assert len(plan.suggested_stops) == 0
    assert "No charging stops required" in plan.explanation
    assert plan.estimated_arrival_battery_percent > 70.0

def test_trip_planner_long_trip_charging_stop_required(db_session):
    # Long trip (~350 km to Lake Tahoe or Fresno) with 25% battery
    request = TripPlanRequest(
        origin_latitude=37.7749,
        origin_longitude=-122.4194,
        destination_latitude=39.0968,
        destination_longitude=-120.0324,
        current_battery_percent=25.0,
        min_safety_reserve_percent=15.0
    )

    plan = TripPlannerService.plan_trip(db=db_session, request=request)
    assert plan.is_charging_required is True
    assert "charging stop added" in plan.explanation
    assert len(plan.suggested_stops) >= 1
    assert plan.suggested_stops[0].charging_time_minutes > 0
