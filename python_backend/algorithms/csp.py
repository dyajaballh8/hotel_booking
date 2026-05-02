"""
CSP (Constraint Satisfaction Problem) for Hotel Room Assignment
===============================================================
Variables:   Each BookingRequest
Domain:      Available rooms matching the request's type
Constraints:
  1. Room type must match request type
  2. No time overlap on same room
  3. VIP requests prefer suite/high-floor rooms

Uses Arc Consistency (AC-3) to prune domains before backtracking search,
making the search much faster than plain backtracking.

Time Complexity:  O(n * m) for AC-3 pruning + backtracking on reduced domains
Space Complexity: O(n * m) for domain storage
"""

from typing import Dict, List, Set, Tuple, Optional
from collections import deque
from models.models import Room, BookingRequest, Priority, RoomType


# ─── Domain Management ─────────────────────────────────────────────────────


def build_initial_domains(
    requests: List[BookingRequest],
    rooms: List[Room],
) -> Dict[int, List[int]]:
    """
    Build initial domain for each request:
    domain[request_id] = [room_ids that match the type]
    """
    domains: Dict[int, List[int]] = {}
    for req in requests:
        domains[req.request_id] = [
            r.room_id for r in rooms
            if r.room_type == req.room_type and r.is_active
        ]
    return domains


# ─── Constraint Checks ─────────────────────────────────────────────────────


def time_overlap(a: BookingRequest, b: BookingRequest) -> bool:
    return a.check_in < b.check_out and a.check_out > b.check_in


def constraint_satisfied(
    req_a: BookingRequest,
    room_a: int,
    req_b: BookingRequest,
    room_b: int,
) -> bool:
    """Return True if assigning room_a→req_a and room_b→req_b is valid."""
    if room_a != room_b:
        return True                   # Different rooms — always valid
    return not time_overlap(req_a, req_b)  # Same room — must not overlap


# ─── AC-3 Arc Consistency ──────────────────────────────────────────────────


def ac3(
    requests: List[BookingRequest],
    domains: Dict[int, List[int]],
) -> bool:
    """
    AC-3 algorithm: prune domains to enforce arc consistency.
    Returns False if any domain becomes empty (problem unsolvable).
    """
    # Build arcs: pairs of requests that could conflict
    arcs: deque = deque()
    for i in range(len(requests)):
        for j in range(len(requests)):
            if i != j:
                arcs.append((requests[i], requests[j]))

    req_map = {r.request_id: r for r in requests}

    while arcs:
        req_a, req_b = arcs.popleft()

        if revise(req_a, req_b, domains, req_map):
            if not domains[req_a.request_id]:
                return False  # Domain wiped out — no solution
            # Re-add arcs pointing to req_a
            for req_c in requests:
                if req_c.request_id != req_a.request_id:
                    arcs.append((req_c, req_a))

    return True


def revise(
    req_a: BookingRequest,
    req_b: BookingRequest,
    domains: Dict[int, List[int]],
    req_map: Dict[int, BookingRequest],
) -> bool:
    """
    Remove values from domain[req_a] that have no consistent value in domain[req_b].
    Returns True if any value was removed.
    """
    revised = False
    to_remove = []

    for room_a in domains[req_a.request_id]:
        # Check if there's at least one room_b that satisfies the constraint
        satisfiable = any(
            constraint_satisfied(req_a, room_a, req_b, room_b)
            for room_b in domains[req_b.request_id]
        )
        if not satisfiable:
            to_remove.append(room_a)
            revised = True

    for room in to_remove:
        domains[req_a.request_id].remove(room)

    return revised


# ─── CSP Backtracking Search ───────────────────────────────────────────────


def select_unassigned(
    requests: List[BookingRequest],
    assignments: Dict[int, int],
    domains: Dict[int, List[int]],
) -> Optional[BookingRequest]:
    """
    MRV (Minimum Remaining Values) heuristic:
    Pick the request with the smallest domain (fewest options).
    VIP requests are always prioritised first.
    """
    unassigned = [r for r in requests if r.request_id not in assignments]
    if not unassigned:
        return None

    # VIP first
    vip = [r for r in unassigned if r.priority == Priority.VIP]
    if vip:
        return min(vip, key=lambda r: len(domains[r.request_id]))

    return min(unassigned, key=lambda r: len(domains[r.request_id]))


def order_domain_values(
    req: BookingRequest,
    domains: Dict[int, List[int]],
    rooms: List[Room],
) -> List[int]:
    """
    LCV (Least Constraining Value): order room choices so the one that
    leaves most options for others comes first.
    For VIP guests, prefer higher floors.
    """
    room_map = {r.room_id: r for r in rooms}
    domain = domains[req.request_id]

    if req.priority == Priority.VIP:
        return sorted(domain, key=lambda rid: -room_map[rid].floor)
    return domain


def csp_search(
    requests: List[BookingRequest],
    rooms: List[Room],
    assignments: Dict[int, int],
    domains: Dict[int, List[int]],
) -> Optional[Dict[int, int]]:
    """Recursive CSP search with forward checking."""
    if len(assignments) == len(requests):
        return dict(assignments)

    req = select_unassigned(requests, assignments, domains)
    if req is None:
        return dict(assignments)

    for room_id in order_domain_values(req, domains, rooms):
        # Forward check: will this assignment break any future domain?
        new_domains = {k: list(v) for k, v in domains.items()}

        # Propagate: remove this room from domains of conflicting future requests
        valid = True
        for other in requests:
            if other.request_id in assignments or other.request_id == req.request_id:
                continue
            if time_overlap(req, other) and room_id in new_domains[other.request_id]:
                new_domains[other.request_id].remove(room_id)
                if not new_domains[other.request_id]:
                    valid = False
                    break

        if valid:
            assignments[req.request_id] = room_id
            result = csp_search(requests, rooms, assignments, new_domains)
            if result is not None:
                return result
            del assignments[req.request_id]

    # Mark as unassignable and continue
    assignments[req.request_id] = -1
    result = csp_search(requests, rooms, assignments, domains)
    if result:
        return result
    del assignments[req.request_id]
    return None


# ─── Public Entry Point ────────────────────────────────────────────────────


def csp_assign(
    requests: List[BookingRequest],
    rooms: List[Room],
) -> Tuple[Dict[int, int], List[BookingRequest]]:
    """
    Main CSP assignment function.

    Returns:
        assignments: { request_id -> room_id }
        unassigned:  requests with no available room
    """
    domains = build_initial_domains(requests, rooms)

    # AC-3 pruning
    ac3(requests, domains)

    assignments: Dict[int, int] = {}
    result = csp_search(requests, rooms, assignments, domains)

    if result is None:
        result = {}

    final = {k: v for k, v in result.items() if v != -1}
    unassigned = [r for r in requests if result.get(r.request_id, -1) == -1]
    return final, unassigned
