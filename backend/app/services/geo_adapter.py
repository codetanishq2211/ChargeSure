import math
from typing import List, Dict, Tuple

def haversine_distance_km(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """
    Calculate the great circle distance between two points 
    on the earth (specified in decimal degrees)
    """
    r = 6371.0 # Radius of the earth in km

    d_lat = math.radians(lat2 - lat1)
    d_lon = math.radians(lon2 - lon1)

    a = (math.sin(d_lat / 2.0) ** 2 +
         math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) *
         math.sin(d_lon / 2.0) ** 2)
    c = 2.0 * math.atan2(math.sqrt(a), math.sqrt(1.0 - a))
    distance = r * c
    return round(distance, 2)

def estimate_driving_time_minutes(distance_km: float) -> int:
    """
    Estimate driving time considering average urban/highway speed mix (~45 km/h)
    """
    if distance_km <= 0:
        return 0
    speed_kmh = 45.0
    minutes = (distance_km / speed_kmh) * 60.0
    return max(1, int(round(minutes)))

def calculate_detour_km(current_lat: float, current_lon: float,
                         target_lat: float, target_lon: float,
                         failed_lat: float, failed_lon: float) -> float:
    """
    Calculate additional detour distance from failed charger position to candidate charger
    """
    dist_direct = haversine_distance_km(current_lat, current_lon, failed_lat, failed_lon)
    dist_to_candidate = haversine_distance_km(current_lat, current_lon, target_lat, target_lon)
    detour = max(0.0, dist_to_candidate - dist_direct)
    return round(detour, 2)

def generate_interpolated_waypoints(lat1: float, lon1: float, lat2: float, lon2: float, num_points: int = 6) -> List[Dict[str, float]]:
    """
    Generate realistic route waypoints between two points for map visualization
    """
    waypoints = []
    for i in range(num_points + 1):
        fraction = i / float(num_points)
        # Add slight natural road curvature
        curve_offset = math.sin(fraction * math.pi) * 0.005
        lat = lat1 + (lat2 - lat1) * fraction + curve_offset
        lon = lon1 + (lon2 - lon1) * fraction - curve_offset
        waypoints.append({"latitude": round(lat, 5), "longitude": round(lon, 5)})
    return waypoints
