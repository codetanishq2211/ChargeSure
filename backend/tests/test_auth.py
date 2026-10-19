import pytest
from backend.app.models.all_models import UserRole

def test_health_endpoint(client):
    response = client.get("/api/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"
    assert data["tagline"] == "Always a Charge Ahead."

def test_login_seeded_users(client):
    # Driver login
    resp = client.post("/api/auth/login", json={"email": "driver@chargesure.com", "password": "Driver@123"})
    assert resp.status_code == 200
    data = resp.json()
    assert data["role"] == "driver"
    assert "access_token" in data

    # Host login
    resp = client.post("/api/auth/login", json={"email": "host@chargesure.com", "password": "Host@123"})
    assert resp.status_code == 200
    assert resp.json()["role"] == "host"

    # Admin login
    resp = client.post("/api/auth/login", json={"email": "admin@chargesure.com", "password": "Admin@123"})
    assert resp.status_code == 200
    assert resp.json()["role"] == "admin"

def test_login_invalid_password(client):
    resp = client.post("/api/auth/login", json={"email": "driver@chargesure.com", "password": "WrongPassword"})
    assert resp.status_code == 401

def test_register_new_driver(client):
    resp = client.post("/api/auth/register", json={
        "email": "newdriver@example.com",
        "password": "SecurePassword123",
        "full_name": "New Test Driver",
        "role": "driver"
    })
    assert resp.status_code == 201
    data = resp.json()
    assert data["email"] == "newdriver@example.com"
    assert "access_token" in data
