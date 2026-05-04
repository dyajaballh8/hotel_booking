"""
FastAPI Backend — Hotel Booking System
Run: python -m uvicorn api:app --reload --host 0.0.0.0 --port 8000
"""

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, field_validator
from datetime import date
from typing import Optional
from hotel_service import HotelService
from models.models import RoomType, Priority

app = FastAPI(title="Hotel Booking API", version="2.0.0")
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])

service = HotelService()


# ─── Schemas ──────────────────────────────────────────────────────────────

class CspBookBody(BaseModel):
    guest_name: str
    email: str
    room_type: str          # single | double | suite
    check_in: date
    check_out: date
    priority: str = "normal"

    @field_validator("check_out")
    @classmethod
    def validate_dates(cls, v, info):
        if "check_in" in info.data and v <= info.data["check_in"]:
            raise ValueError("check_out must be after check_in")
        return v


# ─── Health ───────────────────────────────────────────────────────────────

@app.get("/")
def root():
    return {"message": "Hotel Booking API v2 ✓ — CSP powered"}


# ─── Dashboard ────────────────────────────────────────────────────────────

@app.get("/api/dashboard")
def dashboard():
    return service.dashboard_stats()


# ─── Rooms ────────────────────────────────────────────────────────────────

@app.get("/api/rooms")
def get_rooms():
    """All rooms (no date filter)."""
    return {"rooms": [r.to_dict() for r in service.get_rooms()]}


@app.get("/api/rooms/status")
def rooms_status(check_in: date, check_out: date):
    """
    All rooms with availability flag for the given period.
    available=true/false + occupied_by info if taken.
    Used by Flutter rooms screen to show green/red status.
    """
    return {"rooms": service.get_rooms_with_status(check_in, check_out)}


@app.get("/api/rooms/all-bookings")
def rooms_all_bookings():
    """
    All rooms with all their confirmed bookings listed.
    Used to build the live booking grid/table.
    """
    return {"rooms": service.get_all_rooms_status()}


# ─── CSP Booking ──────────────────────────────────────────────────────────

@app.post("/api/book")
def book(body: CspBookBody):
    """
    Book a room using CSP.
    CSP tries rooms, checks constraints, confirms or rejects.
    Returns full CSP trace so Flutter can show step-by-step decisions.
    """
    try:
        room_type = RoomType(body.room_type)
        priority  = Priority(body.priority)
    except ValueError as e:
        raise HTTPException(400, str(e))

    result = service.book_with_csp(
        guest_name=body.guest_name,
        email=body.email,
        room_type=room_type,
        check_in=body.check_in,
        check_out=body.check_out,
        priority=priority,
    )
    return result


# ─── Bookings Table ───────────────────────────────────────────────────────

@app.get("/api/bookings")
def get_bookings():
    return {"bookings": service.get_all_bookings()}


@app.get("/api/bookings/table")
def booking_table():
    """
    Live sorted booking table.
    Updates automatically on every new confirmed booking.
    """
    return {"bookings": service.get_booking_table()}


@app.delete("/api/bookings/{booking_id}")
def cancel_booking(booking_id: int):
    if not service.cancel_booking(booking_id):
        raise HTTPException(404, "Booking not found")
    return {"status": "cancelled", "booking_id": booking_id}


# ─── CSP Report (demo) ────────────────────────────────────────────────────

@app.get("/api/csp-report")
def csp_report():
    """Full step-by-step CSP report using demo data. Always available."""
    try:
        return service.get_booking_table()
    except Exception as e:
        raise HTTPException(500, str(e))
