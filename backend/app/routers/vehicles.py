from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from backend.app.database import get_db
from backend.app.models.all_models import Vehicle, User
from backend.app.schemas.all_schemas import VehicleCreate, VehicleUpdate, VehicleResponse
from backend.app.core.dependencies import get_current_active_user

router = APIRouter(prefix="/vehicles", tags=["Vehicles"])

def _to_vehicle_response(v: Vehicle) -> VehicleResponse:
    est_range = (v.battery_capacity_kwh * 1000.0 * (v.current_battery_percent / 100.0)) / max(v.consumption_wh_per_km, 1.0)
    return VehicleResponse(
        id=v.id,
        user_id=v.user_id,
        make=v.make,
        model=v.model,
        year=v.year,
        license_plate=v.license_plate,
        battery_capacity_kwh=v.battery_capacity_kwh,
        connector_type=v.connector_type,
        consumption_wh_per_km=v.consumption_wh_per_km,
        current_battery_percent=v.current_battery_percent,
        is_primary=v.is_primary,
        estimated_range_km=round(est_range, 1),
        created_at=v.created_at,
        updated_at=v.updated_at
    )

@router.get("", response_model=List[VehicleResponse])
def get_user_vehicles(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    vehicles = db.query(Vehicle).filter(Vehicle.user_id == current_user.id).order_by(Vehicle.is_primary.desc()).all()
    return [_to_vehicle_response(v) for v in vehicles]

@router.post("", response_model=VehicleResponse, status_code=status.HTTP_201_CREATED)
def add_vehicle(
    vehicle_in: VehicleCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    # If set as primary, unset other vehicles
    if vehicle_in.is_primary:
        db.query(Vehicle).filter(Vehicle.user_id == current_user.id).update({"is_primary": False})
    
    vehicle = Vehicle(
        user_id=current_user.id,
        make=vehicle_in.make,
        model=vehicle_in.model,
        year=vehicle_in.year,
        license_plate=vehicle_in.license_plate,
        battery_capacity_kwh=vehicle_in.battery_capacity_kwh,
        connector_type=vehicle_in.connector_type,
        consumption_wh_per_km=vehicle_in.consumption_wh_per_km,
        current_battery_percent=vehicle_in.current_battery_percent,
        is_primary=vehicle_in.is_primary
    )
    db.add(vehicle)
    db.commit()
    db.refresh(vehicle)
    return _to_vehicle_response(vehicle)

@router.get("/{id}", response_model=VehicleResponse)
def get_vehicle(
    id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    vehicle = db.query(Vehicle).filter(Vehicle.id == id, Vehicle.user_id == current_user.id).first()
    if not vehicle:
        raise HTTPException(status_code=404, detail="Vehicle not found")
    return _to_vehicle_response(vehicle)

@router.patch("/{id}", response_model=VehicleResponse)
def update_vehicle(
    id: int,
    update_data: VehicleUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    vehicle = db.query(Vehicle).filter(Vehicle.id == id, Vehicle.user_id == current_user.id).first()
    if not vehicle:
        raise HTTPException(status_code=404, detail="Vehicle not found")

    if update_data.is_primary is True:
        db.query(Vehicle).filter(Vehicle.user_id == current_user.id).update({"is_primary": False})

    update_dict = update_data.model_dump(exclude_unset=True)
    for field, val in update_dict.items():
        setattr(vehicle, field, val)

    db.commit()
    db.refresh(vehicle)
    return _to_vehicle_response(vehicle)

@router.delete("/{id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_vehicle(
    id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    vehicle = db.query(Vehicle).filter(Vehicle.id == id, Vehicle.user_id == current_user.id).first()
    if not vehicle:
        raise HTTPException(status_code=404, detail="Vehicle not found")
    db.delete(vehicle)
    db.commit()
    return None
