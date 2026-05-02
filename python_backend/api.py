"""
FastAPI Backend — Hotel Booking System
=======================================
Run with:  uvicorn api:app --reload --port 8000
Flutter connects to: http://localhost:8000
"""

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, field_validator
from datetime import date
from typing import Optional, List
from hotel_service import HotelService
from models.models import RoomType, Priority, Room, BookingRequest
from algorithms.csp_with_tables import csp_full_report

app = FastAPI(title="Hotel Booking API", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

service = HotelService()


# ─── Request / Response Schemas ───────────────────────────────────────────


class BookingRequestBody(BaseModel):
    guest_id: int
    guest_name: str
    room_type: str           # "single" | "double" | "suite"
    check_in: date
    check_out: date
    priority: str = "normal"  # "normal" | "vip"

    @field_validator("check_out")
    @classmethod
    def check_out_after_check_in(cls, v, info):
        if "check_in" in info.data and v <= info.data["check_in"]:
            raise ValueError("check_out must be after check_in")
        return v


class GuestBody(BaseModel):
    name: str
    email: str
    priority: str = "normal"


class RunAlgorithmBody(BaseModel):
    algorithm: str = "backtracking"  # greedy | backtracking | csp | graph_coloring


# ─── Endpoints ────────────────────────────────────────────────────────────


@app.get("/")
def root():
    return {"message": "Hotel Booking API is running ✓"}


@app.get("/api/dashboard")
def dashboard():
    return service.dashboard_stats()


# ── Rooms ──────────────────────────────────────────────────────────────────

@app.get("/api/rooms")
def get_rooms():
    return {"rooms": [r.to_dict() for r in service.get_rooms()]}


@app.get("/api/rooms/available")
def available_rooms(check_in: date, check_out: date, room_type: Optional[str] = None):
    rtype = RoomType(room_type) if room_type else None
    rooms = service.get_available_rooms(check_in, check_out, rtype)
    return {"rooms": [r.to_dict() for r in rooms], "count": len(rooms)}


# ── Guests ─────────────────────────────────────────────────────────────────

@app.post("/api/guests")
def create_guest(body: GuestBody):
    try:
        priority = Priority(body.priority)
    except ValueError:
        raise HTTPException(400, "priority must be 'normal' or 'vip'")
    guest = service.add_guest(body.name, body.email, priority)
    return guest.to_dict()


# ── Booking Requests ───────────────────────────────────────────────────────

@app.post("/api/requests")
def submit_request(body: BookingRequestBody):
    try:
        room_type = RoomType(body.room_type)
        priority = Priority(body.priority)
    except ValueError as e:
        raise HTTPException(400, str(e))

    req = service.submit_request(
        guest_id=body.guest_id,
        guest_name=body.guest_name,
        room_type=room_type,
        check_in=body.check_in,
        check_out=body.check_out,
        priority=priority,
    )
    return {"status": "queued", "request": req.to_dict()}


@app.get("/api/requests")
def get_pending():
    return {"requests": [r.to_dict() for r in service.get_pending_requests()]}


# ── Assignment ─────────────────────────────────────────────────────────────

@app.post("/api/assign")
def run_assignment(body: RunAlgorithmBody):
    valid = {"greedy", "backtracking", "csp", "graph_coloring"}
    if body.algorithm not in valid:
        raise HTTPException(400, f"algorithm must be one of {valid}")
    try:
        result = service.run_assignment(body.algorithm)
        return result
    except Exception as e:
        raise HTTPException(500, str(e))


# ── Bookings ───────────────────────────────────────────────────────────────

@app.get("/api/bookings")
def get_bookings():
    return {"bookings": service.get_all_bookings()}


@app.get("/api/csp-report")
def csp_report():
    """
    Run CSP on current pending requests and return full step-by-step report:
    - step1_initial_domains
    - step2_ac3_pruning
    - step3_assignment_steps
    - final_state
    - constraint_checks
    - summary
    """
    requests = service.get_pending_requests()
    if not requests:
        # Use demo data if no pending requests
        from datetime import date as d
        requests = [
            BookingRequest(1, "Ahmed Ali",    RoomType.SINGLE, d(2025,1,1), d(2025,1,4), Priority.VIP,    1),
            BookingRequest(2, "Sara Mohamed", RoomType.DOUBLE, d(2025,1,2), d(2025,1,5), Priority.NORMAL, 2),
            BookingRequest(3, "Mona Hassan",  RoomType.SINGLE, d(2025,1,2), d(2025,1,6), Priority.NORMAL, 3),
            BookingRequest(4, "Khalid Omar",  RoomType.SUITE,  d(2025,1,1), d(2025,1,3), Priority.VIP,    4),
            BookingRequest(5, "Laila Nasser", RoomType.DOUBLE, d(2025,1,3), d(2025,1,7), Priority.NORMAL, 5),
            BookingRequest(6, "Omar Farouk",  RoomType.SINGLE, d(2025,1,5), d(2025,1,8), Priority.NORMAL, 6),
            BookingRequest(7, "Fatma Said",   RoomType.SINGLE, d(2025,1,1), d(2025,1,4), Priority.NORMAL, 7),
        ]
    rooms = service.get_rooms()
    try:
        report = csp_full_report(requests, rooms)
        return report
    except Exception as e:
        raise HTTPException(500, str(e))


@app.delete("/api/bookings/{booking_id}")
def cancel_booking(booking_id: int):
    ok = service.cancel_booking(booking_id)
    if not ok:
        raise HTTPException(404, "Booking not found")
    return {"status": "cancelled", "booking_id": booking_id}
