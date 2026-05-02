"""
Greedy Algorithm for Hotel Room Assignment
==========================================
Strategy: Sort requests by priority (VIP first) then check-in date.
For each request, assign the first available room that matches the type.

Time Complexity:  O(n * m) where n = bookings, m = rooms
Space Complexity: O(n) for assignments dict

Pros:  Very fast, good for large hotels
Cons:  Not always optimal — may leave better rooms unused
"""

from typing import Dict, List, Optional, Tuple
from datetime import date
from models.models import Room, BookingRequest, Priority, RoomType


def is_room_available(
    room: Room,
    request: BookingRequest,
    assignments: Dict[int, List[BookingRequest]],
) -> bool:
    """Check if a room has no time conflicts with the given request."""
    if not room.is_active:
        return False
    if room.room_type != request.room_type:
        return False

    existing = assignments.get(room.room_id, [])
    for booked in existing:
        # Overlap check: [check_in1, check_out1) overlaps [check_in2, check_out2)
        if request.check_in < booked.check_out and request.check_out > booked.check_in:
            return False
    return True


def greedy_assign(
    requests: List[BookingRequest],
    rooms: List[Room],
) -> Tuple[Dict[int, int], List[BookingRequest]]:
    """
    Assign rooms greedily.

    Returns:
        assignments: { request_id -> room_id }
        unassigned:  list of BookingRequest that couldn't be assigned
    """
    # Sort: VIP first, then by check-in date
    priority_order = {Priority.VIP: 0, Priority.NORMAL: 1}
    sorted_requests = sorted(
        requests,
        key=lambda r: (priority_order[r.priority], r.check_in),
    )

    # Group rooms by type for faster lookup
    rooms_by_type: Dict[RoomType, List[Room]] = {}
    for room in rooms:
        rooms_by_type.setdefault(room.room_type, []).append(room)

    assignments: Dict[int, int] = {}          # request_id -> room_id
    room_bookings: Dict[int, List[BookingRequest]] = {}  # room_id -> [requests]
    unassigned: List[BookingRequest] = []

    for req in sorted_requests:
        assigned = False
        candidate_rooms = rooms_by_type.get(req.room_type, [])

        for room in candidate_rooms:
            if is_room_available(room, req, room_bookings):
                assignments[req.request_id] = room.room_id
                room_bookings.setdefault(room.room_id, []).append(req)
                assigned = True
                break

        if not assigned:
            unassigned.append(req)

    return assignments, unassigned


def greedy_utilization(
    assignments: Dict[int, int],
    requests: List[BookingRequest],
    rooms: List[Room],
    date_range: Tuple[date, date],
) -> Dict[str, float]:
    """Calculate hotel utilization metrics after greedy assignment."""
    total_room_nights = len(rooms) * (date_range[1] - date_range[0]).days
    assigned_nights = sum(
        r.nights()
        for r in requests
        if r.request_id in assignments
    )
    return {
        "total_room_nights": total_room_nights,
        "assigned_nights": assigned_nights,
        "utilization_pct": round(assigned_nights / total_room_nights * 100, 2) if total_room_nights else 0,
        "assigned_count": len(assignments),
        "unassigned_count": len(requests) - len(assignments),
    }
