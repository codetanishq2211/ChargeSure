import logging
from fastapi import FastAPI, Depends
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from sqlalchemy import text
from backend.app.config import settings
from backend.app.database import engine, Base, get_db
from backend.app.routers import (
    auth, users, vehicles, chargers, bookings, sessions,
    backup, trip, host, admin, support
)
from backend.app.seed.seed_data import seed_database_if_empty

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("chargesure")

from contextlib import asynccontextmanager

@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("ChargeSure API starting up...")
    seed_database_if_empty()
    logger.info("ChargeSure database verified and ready.")
    yield
    logger.info("ChargeSure API shutting down...")

app = FastAPI(
    title=settings.PROJECT_NAME,
    description="Backend API service for ChargeSure — Intelligent EV Charging Assurance. Tagline: 'Always a Charge Ahead.'",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
    openapi_url="/openapi.json",
    lifespan=lifespan
)

# CORS Middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Register routers
prefix = settings.API_V1_PREFIX
app.include_router(auth.router, prefix=prefix)
app.include_router(users.router, prefix=prefix)
app.include_router(vehicles.router, prefix=prefix)
app.include_router(chargers.router, prefix=prefix)
app.include_router(bookings.router, prefix=prefix)
app.include_router(sessions.router, prefix=prefix)
app.include_router(backup.router, prefix=prefix)
app.include_router(trip.router, prefix=prefix)
app.include_router(host.router, prefix=prefix)
app.include_router(admin.router, prefix=prefix)
app.include_router(support.router, prefix=prefix)

import os
from fastapi.staticfiles import StaticFiles

web_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "../../frontend/build/web"))
if os.path.exists(web_dir):
    app.mount("/app", StaticFiles(directory=web_dir, html=True), name="frontend")

@app.get("/api/health", tags=["Health"])
def health_check(db: Session = Depends(get_db)):
    """Health-check endpoint verifying API server and database connection"""
    db_status = "connected"
    try:
        db.execute(text("SELECT 1"))
    except Exception as e:
        db_status = f"unhealthy: {str(e)}"

    return {
        "status": "healthy" if db_status == "connected" else "degraded",
        "app_name": settings.PROJECT_NAME,
        "tagline": settings.TAGLINE,
        "database": db_status,
        "demo_mode": settings.DEMO_MODE,
        "version": "1.0.0"
    }

@app.get("/", tags=["Root"])
def root():
    return {
        "message": "Welcome to ChargeSure — Intelligent EV Charging Assurance",
        "tagline": "Always a Charge Ahead.",
        "web_app": "/app/",
        "api_docs": "/docs",
        "health": "/api/health"
    }
