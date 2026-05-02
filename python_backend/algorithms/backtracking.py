"""
Backtracking Algorithm for Hotel Room Assignment
=================================================
Strategy: Try every possible assignment. If a conflict is found,
backtrack and try a different room. Guarantees finding a solution
if one exists.

Time Complexity:  O(m^n) worst case — exponential but pruned heavily
Space Complexity: O(n) recursion depth

Pros:  Always finds optimal solution (no conflicts guaranteed)
Cons:  Slower for large inputs — use for ≤ 50 rooms
"""

from typing import Dict, List, Optional, Tuple
from models.models import Room, BookingRequest, Priority, RoomType


def has_conflict(
    room_id: int,
    request: BookingRequest,
    assignments: Dict[int, int],
    requests: List[BookingRequest],
) -> bool:
    """Check if assigning request to room_id conflicts with existing assignments."""
    for other_req in requests:
        if other_req.request_id == request.request_id:
            continue
        assigned_room = assignments.get(other_req.request_id)
        if assigned_room == room_id:
            # Same room — check time overlap
            if request.check_in < other_req.check_out and request.check_out > other_req.check_in:
                return True
    return False


def backtrack(
    requests: List[BookingRequest],
    rooms: List[Room],
    index: int,
    assignments: Dict[int, int],
    rooms_by_type: Dict[RoomType, List[Room]],
) -> Optional[Dict[int, int]]:
    """
    Recursive backtracking.

    Args:
        requests:      All booking requests (sorted by priority)
        rooms:         Available rooms
        index:         Current request index being processed
        assignments:   Current partial assignments { request_id -> room_id }
        rooms_by_type: Rooms grouped by type for pruning

    Returns:
        Complete assignments dict if solution found, else None
    """
    # Base case: all requests assigned
    if index == len(requests):
        return dict(assignments)

    current = requests[index]
    candidates = rooms_by_type.get(current.room_type, [])

    for room in candidates:
        if not room.is_active:
            continue

        if not has_conflict(room.room_id, current, assignments, requests):
            # Choose
            assignments[current.request_id] = room.room_id

            # Explore
            result = backtrack(requests, rooms, index + 1, assignments, rooms_by_type)
            if result is not None:
                return result

            # Unchoose (backtrack)
            del assignments[current.request_id]

    # No room worked for this request — mark as unassigned and continue
    assignments[current.request_id] = -1  # -1 = no room available
    result = backtrack(requests, rooms, index + 1, assignments, rooms_by_type)
    if result is not None:
        return result
    del assignments[current.request_id]

    return None


def backtracking_assign(
    requests: List[BookingRequest],
    rooms: List[Room],
) -> Tuple[Dict[int, int], List[BookingRequest]]:
    """
    Main entry point for backtracking assignment.

    Returns:
        assignments: { request_id -> room_id }  (-1 means unassigned)
        unassigned:  BookingRequests with no available room
    """
    # VIP first, then earliest check-in
    priority_order = {Priority.VIP: 0, Priority.NORMAL: 1}
    sorted_requests = sorted(
        requests,
        key=lambda r: (priority_order[r.priority], r.check_in),
    )

    rooms_by_type: Dict[RoomType, List[Room]] = {}
    for room in rooms:
        rooms_by_type.setdefault(room.room_type, []).append(room)

    assignments: Dict[int, int] = {}
    result = backtrack(sorted_requests, rooms, 0, assignments, rooms_by_type)

    if result is None:
        result = {}

    # Separate assigned vs unassigned
    final_assignments = {k: v for k, v in result.items() if v != -1}
    unassigned = [r for r in requests if result.get(r.request_id, -1) == -1]

    return final_assignments, unassigned


def verify_no_conflicts(
    assignments: Dict[int, int],
    requests: List[BookingRequest],
) -> List[str]:
    """
    Verify the solution has zero conflicts.
    Returns list of conflict descriptions (empty = perfect solution).
    """
    conflicts = []
    req_map = {r.request_id: r for r in requests}

    room_bookings: Dict[int, List[BookingRequest]] = {}
    for req_id, room_id in assignments.items():
        room_bookings.setdefault(room_id, []).append(req_map[req_id])

    for room_id, booked in room_bookings.items():
        for i in range(len(booked)):
            for j in range(i + 1, len(booked)):
                a, b = booked[i], booked[j]
                if a.check_in < b.check_out and a.check_out > b.check_in:
                    conflicts.append(
                        f"CONFLICT: Room {room_id} — "
                        f"{a.guest_name}({a.check_in}→{a.check_out}) vs "
                        f"{b.guest_name}({b.check_in}→{b.check_out})"
                    )
    return conflicts
