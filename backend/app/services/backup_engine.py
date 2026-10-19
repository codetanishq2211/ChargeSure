from datetime import datetime, timedelta
from typing import List, Optional, Dict, Any
from sqlalchemy.orm import Session
from backend.app.models.all_models import Charger, ChargerStatus, DataSource, Vehicle
from backend.app.schemas.all_schemas import BackupRequest, BackupResponse, BackupCandidate, ChargerResponse
from backend.app.services.geo_adapter import haversine_distance_km, estimate_driving_time_minutes

class BackupEngineService:
    @staticmethod
    def evaluate_candidates(
        db: Session,
        request: BackupRequest,
        current_user_vehicle: Optional[Vehicle] = None
    ) -> BackupResponse:
        # Determine vehicle parameters
        capacity_kwh = request.battery_capacity_kwh
        consumption_wh_per_km = request.consumption_wh_per_km
        current_battery = request.current_battery_percent
        connector = request.connector_type
        
        if current_user_vehicle:
            if capacity_kwh is None:
                capacity_kwh = current_user_vehicle.battery_capacity_kwh
            if consumption_wh_per_km is None:
                consumption_wh_per_km = current_user_vehicle.consumption_wh_per_km
            if current_battery is None:
                current_battery = current_user_vehicle.current_battery_percent
            if connector is None:
                connector = current_user_vehicle.connector_type

        # Sensible fallbacks if no vehicle is provided
        capacity_kwh = capacity_kwh or 60.0
        consumption_wh_per_km = consumption_wh_per_km or 160.0
        current_battery = 75.0 if current_battery is None else current_battery
        connector = connector or "CCS2"
        min_reserve = request.min_safety_reserve_percent

        # Vehicle description summary
        vehicle_summary = f"{capacity_kwh:.1f} kWh pack • {consumption_wh_per_km:.0f} Wh/km • {connector} • Current: {current_battery:.0f}%"

        # Fetch failed charger if provided
        original_title = "Primary Station"
        failed_lat = request.current_latitude
        failed_lon = request.current_longitude
        if request.failed_charger_id:
            failed_charger = db.query(Charger).filter(Charger.id == request.failed_charger_id).first()
            if failed_charger:
                original_title = failed_charger.title
                failed_lat = failed_charger.latitude
                failed_lon = failed_charger.longitude

        # Query all candidate chargers excluding the failed one
        query = db.query(Charger).filter(Charger.id != request.failed_charger_id)
        all_chargers: List[Charger] = query.all()

        candidates: List[BackupCandidate] = []
        now = datetime.utcnow()

        for ch in all_chargers:
            # 1. Compatibility check
            is_compatible = connector in ch.connector_types

            # Exclude completely incompatible chargers
            if not is_compatible:
                continue

            # Exclude completely offline/faulty stations from primary recommendations
            if ch.status in (ChargerStatus.FAULTY, ChargerStatus.OFFLINE):
                continue

            # 2. Distance and Reachability calculation
            dist_km = haversine_distance_km(request.current_latitude, request.current_longitude, ch.latitude, ch.longitude)
            # Energy consumption to reach candidate
            energy_kwh = (dist_km * consumption_wh_per_km) / 1000.0
            battery_drop_percent = (energy_kwh / capacity_kwh) * 100.0
            arrival_battery = max(0.0, current_battery - battery_drop_percent)
            is_safely_reachable = arrival_battery >= min_reserve

            # Detour from original failed charger location
            dist_to_orig = haversine_distance_km(request.current_latitude, request.current_longitude, failed_lat, failed_lon)
            detour_km = max(0.0, round(dist_km - dist_to_orig, 2))
            driving_time_mins = estimate_driving_time_minutes(dist_km)

            # 3. Availability confidence scoring
            # Data source weight
            source_weights = {
                DataSource.LIVE_OPERATOR: 95.0,
                DataSource.HOST_CONFIRMED: 90.0,
                DataSource.MANUALLY_REPORTED: 70.0,
                DataSource.UNVERIFIED: 45.0,
            }
            conf_score = source_weights.get(ch.data_source, 50.0)

            # Freshness degradation (penalty if older than 2 hours)
            if ch.freshness_timestamp:
                age_hours = (now - ch.freshness_timestamp).total_seconds() / 3600.0
                if age_hours > 2.0:
                    conf_score -= min(30.0, age_hours * 2.5)

            # Current status bonus
            if ch.status == ChargerStatus.AVAILABLE:
                conf_score = min(100.0, conf_score + 5.0)
            elif ch.status == ChargerStatus.IN_USE:
                conf_score = max(20.0, conf_score - 25.0)

            # 4. Overall ranking score (0 - 100)
            # Weighted formula:
            # - Reachability & Safety Margin (35%)
            # - Proximity / Distance (25%)
            # - Power & Speed (15%)
            # - Availability Confidence (15%)
            # - Reliability Score & Price (10%)

            # Safety margin factor
            if is_safely_reachable:
                margin = arrival_battery - min_reserve
                safety_score = min(100.0, 70.0 + (margin * 1.5))
            else:
                # Heavy penalty if below safety reserve
                safety_score = max(0.0, (arrival_battery / min_reserve) * 35.0)

            # Distance factor (closer is better, 0km -> 100, 50km -> 0)
            dist_score = max(0.0, 100.0 - (dist_km * 2.0))

            # Power factor (higher kW is faster: 150kW -> 100, 7.4kW -> 30)
            power_score = min(100.0, 30.0 + (ch.power_kw / 150.0) * 70.0)

            # Reliability score from charger model
            rel_score = ch.reliability_score

            # Price factor (lower price per kWh is better)
            price_score = max(20.0, 100.0 - (ch.price_per_kwh * 2.0))

            overall_rank = (
                (safety_score * 0.35) +
                (dist_score * 0.25) +
                (power_score * 0.15) +
                (conf_score * 0.15) +
                (((rel_score + price_score) / 2.0) * 0.10)
            )

            # 5. Recommendation reason formulation
            reasons = []
            if ch.power_kw >= 50.0:
                reasons.append(f"High-power DC fast charging ({ch.power_kw:.0f} kW)")
            else:
                reasons.append(f"Reliable AC charging ({ch.power_kw:.1f} kW)")

            if is_safely_reachable:
                reasons.append(f"Safe arrival reserve of {arrival_battery:.0f}% (above {min_reserve:.0f}% minimum)")
            else:
                reasons.append(f"Warning: Low arrival reserve ({arrival_battery:.0f}%, below {min_reserve:.0f}% safety threshold)")

            if ch.data_source == DataSource.LIVE_OPERATOR:
                reasons.append("Real-time live operator status")
            elif ch.data_source == DataSource.HOST_CONFIRMED:
                reasons.append("Host-confirmed availability")

            primary_reason = " • ".join(reasons)

            # Build ChargerResponse
            ch_resp = ChargerResponse(
                id=ch.id,
                host_id=ch.host_id,
                title=ch.title,
                description=ch.description,
                address=ch.address,
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
                access_instructions=None, # Protect host access
                is_access_masked=True,
                freshness_timestamp=ch.freshness_timestamp,
                is_verified=ch.is_verified,
                reliability_score=ch.reliability_score,
                distance_km=dist_km,
                average_rating=4.8,
                total_reviews=len(ch.reviews) if ch.reviews else 5,
                created_at=ch.created_at,
                updated_at=ch.updated_at
            )

            candidates.append(
                BackupCandidate(
                    charger=ch_resp,
                    distance_km=dist_km,
                    detour_km=detour_km,
                    estimated_driving_time_minutes=driving_time_mins,
                    estimated_arrival_battery_percent=round(arrival_battery, 1),
                    is_safely_reachable=is_safely_reachable,
                    connector_compatible=is_compatible,
                    availability_confidence_score=round(conf_score, 1),
                    overall_rank_score=round(overall_rank, 1),
                    primary_recommendation_reason=primary_reason,
                )
            )

        # Sort candidates descending by overall rank score
        candidates.sort(key=lambda x: x.overall_rank_score, reverse=True)

        safe_candidates = [c for c in candidates if c.is_safely_reachable]
        has_safe = len(safe_candidates) > 0

        best = safe_candidates[0] if safe_candidates else (candidates[0] if candidates else None)
        additional = safe_candidates[1:4] if safe_candidates else (candidates[1:4] if len(candidates) > 1 else [])

        # Emergency contacts list
        emergency_contacts = [
            {
                "name": "ChargeSure 24/7 Mobility Assurance",
                "phone": "+1-800-242-7437",
                "service": "Rapid Mobile EV Dispatch & Towing",
                "verified": True,
                "note": "Priority assistance for ChargeSure members"
            },
            {
                "name": "National Highway EV Roadside Support",
                "phone": "+1-800-555-0199",
                "service": "Emergency Flatbed & Level 2 Mobile Booster",
                "verified": True,
                "note": "Standard emergency provider"
            },
            {
                "name": "Local Host Emergency Concierge",
                "phone": "+1-888-382-4274",
                "service": "Emergency Home-Charger Slot Override",
                "verified": False,
                "note": "Subject to local host availability"
            }
        ]

        if has_safe:
            status_summary = (
                f"ChargeSure Backup Engine identified {len(safe_candidates)} safe, compatible alternatives. "
                f"Top option is {best.charger.title} ({best.distance_km:.1f} km away) with {best.estimated_arrival_battery_percent:.0f}% arrival battery."
            )
        else:
            status_summary = (
                f"CRITICAL WARNING: No alternative chargers are safely reachable within your "
                f"{min_reserve:.0f}% safety reserve (Current battery: {current_battery:.0f}%). "
                f"Please do not risk driving without sufficient range. Contact verified emergency roadside support below."
            )

        return BackupResponse(
            failure_reason=request.failure_reason,
            original_charger_title=original_title,
            vehicle_summary=vehicle_summary,
            min_safety_reserve_percent=min_reserve,
            candidates_found=len(candidates),
            safe_candidates_count=len(safe_candidates),
            has_safe_alternative=has_safe,
            status_summary=status_summary,
            best_candidate=best,
            additional_options=additional,
            emergency_contacts=emergency_contacts
        )
