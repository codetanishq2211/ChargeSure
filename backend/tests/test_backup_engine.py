import pytest
from backend.app.services.backup_engine import BackupEngineService
from backend.app.schemas.all_schemas import BackupRequest
from backend.app.models.all_models import Charger, ChargerStatus

def test_backup_engine_normal_ranking(db_session):
    # San Francisco central coordinates
    request = BackupRequest(
        current_latitude=37.7749,
        current_longitude=-122.4194,
        current_battery_percent=45.0,
        battery_capacity_kwh=75.0,
        consumption_wh_per_km=160.0,
        connector_type="CCS2",
        min_safety_reserve_percent=15.0,
        failed_charger_id=4, # station 4 was faulty
        failure_reason="Host rejected booking / Charger unavailable"
    )

    response = BackupEngineService.evaluate_candidates(db=db_session, request=request)

    assert response.has_safe_alternative is True
    assert response.safe_candidates_count >= 1
    assert response.best_candidate is not None
    # Failed charger (id=4) must not be recommended
    assert response.best_candidate.charger.id != 4
    for opt in response.additional_options:
        assert opt.charger.id != 4

    # Best candidate should have high score and connector compatibility
    assert response.best_candidate.connector_compatible is True
    assert response.best_candidate.is_safely_reachable is True
    assert response.best_candidate.overall_rank_score > 50.0
    assert len(response.best_candidate.primary_recommendation_reason) > 0

def test_backup_engine_no_safe_alternative_critical(db_session):
    # Critically low battery (e.g. 5%) where safe minimum is 15%
    request = BackupRequest(
        current_latitude=37.7749,
        current_longitude=-122.4194,
        current_battery_percent=5.0,
        battery_capacity_kwh=60.0,
        consumption_wh_per_km=180.0,
        connector_type="CCS2",
        min_safety_reserve_percent=15.0,
        failed_charger_id=1,
        failure_reason="Connector failure"
    )

    response = BackupEngineService.evaluate_candidates(db=db_session, request=request)

    # Cannot safely reach any station while maintaining 15% reserve
    assert response.has_safe_alternative is False
    assert response.safe_candidates_count == 0
    assert "CRITICAL WARNING" in response.status_summary
    # Emergency roadside assistance contacts must be provided
    assert len(response.emergency_contacts) >= 2

def test_backup_engine_connector_compatibility(db_session):
    # Requesting an exotic connector (e.g. "GB/T-Exotic") not supported by standard stations
    request = BackupRequest(
        current_latitude=37.7749,
        current_longitude=-122.4194,
        current_battery_percent=50.0,
        battery_capacity_kwh=60.0,
        consumption_wh_per_km=160.0,
        connector_type="Exotic-Incompatible-Plug",
        min_safety_reserve_percent=15.0,
        failure_reason="Incompatible test"
    )

    response = BackupEngineService.evaluate_candidates(db=db_session, request=request)
    assert response.candidates_found == 0
    assert response.best_candidate is None
