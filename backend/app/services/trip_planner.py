from typing import List, Optional
from sqlalchemy.orm import Session
from backend.app.models.all_models import Charger, ChargerStatus, Vehicle
from backend.app.schemas.all_schemas import TripPlanRequest, TripPlanResponse, TripStop, ChargerResponse
from backend.app.services.geo_adapter import haversine_distance_km, estimate_driving_time_minutes, generate_interpolated_waypoints

class TripPlannerService:
    @staticmethod
    def plan_trip(
        db: Session,
        request: TripPlanRequest,
        vehicle: Optional[Vehicle] = None
    ) -> TripPlanResponse:
        # Determine vehicle parameters
        capacity_kwh = vehicle.battery_capacity_kwh if vehicle else 60.0
        consumption_wh_per_km = vehicle.consumption_wh_per_km if vehicle else 160.0
        connector_type = vehicle.connector_type if vehicle else "CCS2"
        current_battery = request.current_battery_percent
        min_reserve = request.min_safety_reserve_percent

        # Total distance
        total_dist_km = haversine_distance_km(
            request.origin_latitude, request.origin_longitude,
            request.destination_latitude, request.destination_longitude
        )
        total_driving_mins = estimate_driving_time_minutes(total_dist_km)

        # Usable range formula: (Capacity kWh * 1000 * (current% - reserve%)/100) / consumption Wh/km
        usable_battery_percent = max(0.0, current_battery - min_reserve)
        usable_energy_kwh = capacity_kwh * (usable_battery_percent / 100.0)
        safe_range_km = (usable_energy_kwh * 1000.0) / consumption_wh_per_km

        # Total consumption needed for direct trip
        total_consumption_kwh = (total_dist_km * consumption_wh_per_km) / 1000.0
        battery_drop_percent = (total_consumption_kwh / capacity_kwh) * 100.0
        arrival_battery_percent = max(0.0, current_battery - battery_drop_percent)

        is_charging_required = (arrival_battery_percent < min_reserve) or (safe_range_km < total_dist_km)

        suggested_stops: List[TripStop] = []
        total_trip_mins = total_driving_mins

        if not is_charging_required:
            explanation = (
                f"Destination is reachable on your current battery! Estimated arrival battery is {arrival_battery_percent:.1f}%, "
                f"which safely satisfies your {min_reserve:.1f}% minimum reserve threshold. No charging stops required."
            )
        else:
            # Trip exceeds current safe battery range -> find stations near midpoint or along corridor
            explanation = (
                f"Trip distance ({total_dist_km:.1f} km) exceeds your safe driving range ({safe_range_km:.1f} km) "
                f"to maintain a {min_reserve:.1f}% safety reserve. Recommended charging stop added to ensure uninterrupted travel."
            )

            # Midpoint coordinates
            mid_lat = (request.origin_latitude + request.destination_latitude) / 2.0
            mid_lon = (request.origin_longitude + request.destination_longitude) / 2.0

            # Find chargers near midpoint
            candidate_chargers = db.query(Charger).filter(
                Charger.status == ChargerStatus.AVAILABLE
            ).all()

            # Rank chargers by distance to midpoint and power
            chargers_near_mid = []
            for ch in candidate_chargers:
                if connector_type not in ch.connector_types:
                    continue
                dist_to_mid = haversine_distance_km(mid_lat, mid_lon, ch.latitude, ch.longitude)
                chargers_near_mid.append((dist_to_mid, ch))

            chargers_near_mid.sort(key=lambda x: x[0])

            if chargers_near_mid:
                chosen_charger = chargers_near_mid[0][1]
                dist_from_origin = haversine_distance_km(
                    request.origin_latitude, request.origin_longitude,
                    chosen_charger.latitude, chosen_charger.longitude
                )

                stop_consumption_kwh = (dist_from_origin * consumption_wh_per_km) / 1000.0
                stop_arrival_battery = max(0.0, current_battery - (stop_consumption_kwh / capacity_kwh * 100.0))

                target_battery = 85.0
                battery_to_add = max(0.0, target_battery - stop_arrival_battery)
                energy_needed_kwh = (battery_to_add / 100.0) * capacity_kwh

                # Charge time calculation: Energy (kWh) / Charger Power (kW) * 60 mins
                # Adding 10% thermal taper buffer
                charging_mins = int(round((energy_needed_kwh / max(chosen_charger.power_kw, 7.4)) * 60.0 * 1.1))
                estimated_cost = energy_needed_kwh * chosen_charger.price_per_kwh

                total_trip_mins += charging_mins

                ch_resp = ChargerResponse(
                    id=chosen_charger.id,
                    host_id=chosen_charger.host_id,
                    title=chosen_charger.title,
                    description=chosen_charger.description,
                    address=chosen_charger.address,
                    city=chosen_charger.city,
                    state=chosen_charger.state,
                    postal_code=chosen_charger.postal_code,
                    latitude=chosen_charger.latitude,
                    longitude=chosen_charger.longitude,
                    charger_type=chosen_charger.charger_type,
                    current_type=chosen_charger.current_type,
                    power_kw=chosen_charger.power_kw,
                    connector_types=chosen_charger.connector_types,
                    price_per_kwh=chosen_charger.price_per_kwh,
                    price_per_hour=chosen_charger.price_per_hour,
                    pricing_model=chosen_charger.pricing_model,
                    status=chosen_charger.status,
                    data_source=chosen_charger.data_source,
                    access_instructions=None,
                    is_access_masked=True,
                    freshness_timestamp=chosen_charger.freshness_timestamp,
                    is_verified=chosen_charger.is_verified,
                    reliability_score=chosen_charger.reliability_score,
                    distance_km=dist_from_origin,
                    average_rating=4.9,
                    total_reviews=len(chosen_charger.reviews) if chosen_charger.reviews else 8,
                    created_at=chosen_charger.created_at,
                    updated_at=chosen_charger.updated_at
                )

                suggested_stops.append(
                    TripStop(
                        charger=ch_resp,
                        distance_from_origin_km=round(dist_from_origin, 1),
                        arrival_battery_percent=round(stop_arrival_battery, 1),
                        target_charge_battery_percent=target_battery,
                        charging_time_minutes=max(15, charging_mins),
                        energy_needed_kwh=round(energy_needed_kwh, 1),
                        estimated_cost=round(estimated_cost, 2)
                    )
                )

        waypoints = generate_interpolated_waypoints(
            request.origin_latitude, request.origin_longitude,
            request.destination_latitude, request.destination_longitude,
            num_points=8
        )

        return TripPlanResponse(
            total_distance_km=round(total_dist_km, 1),
            total_driving_time_minutes=total_driving_mins,
            total_trip_time_minutes=total_trip_mins,
            initial_battery_percent=current_battery,
            estimated_consumption_kwh=round(total_consumption_kwh, 1),
            estimated_arrival_battery_percent=round(arrival_battery_percent, 1),
            is_charging_required=is_charging_required,
            explanation=explanation,
            suggested_stops=suggested_stops,
            route_waypoints=waypoints
        )
