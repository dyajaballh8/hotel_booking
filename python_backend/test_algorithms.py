"""
test_algorithms.py
==================
Run with:  python test_algorithms.py
Tests all 4 algorithms on a sample hotel dataset.
"""

import sys, os
sys.path.insert(0, os.path.dirname(__file__))

from datetime import date
from models.models import Room, BookingRequest, RoomType, Priority
from algorithms.greedy import greedy_assign
from algorithms.backtracking import backtracking_assign, verify_no_conflicts
from algorithms.csp import csp_assign
from algorithms.graph_coloring import graph_coloring_assign


# ─── Test Data ────────────────────────────────────────────────────────────

ROOMS = [
    Room(1, "101", RoomType.SINGLE, 1, 80.0),
    Room(2, "102", RoomType.SINGLE, 1, 80.0),
    Room(3, "201", RoomType.DOUBLE, 2, 140.0),
    Room(4, "202", RoomType.DOUBLE, 2, 140.0),
    Room(5, "301", RoomType.SUITE,  3, 280.0),
]

REQUESTS = [
    BookingRequest(1, "Ahmed",   RoomType.SINGLE, date(2025,1,1),  date(2025,1,4),  Priority.VIP,    1),
    BookingRequest(2, "Sara",    RoomType.DOUBLE, date(2025,1,2),  date(2025,1,5),  Priority.NORMAL, 2),
    BookingRequest(3, "Mona",    RoomType.SINGLE, date(2025,1,2),  date(2025,1,6),  Priority.NORMAL, 3),
    BookingRequest(4, "Khalid",  RoomType.SUITE,  date(2025,1,1),  date(2025,1,3),  Priority.VIP,    4),
    BookingRequest(5, "Laila",   RoomType.DOUBLE, date(2025,1,3),  date(2025,1,7),  Priority.NORMAL, 5),
    BookingRequest(6, "Omar",    RoomType.SINGLE, date(2025,1,5),  date(2025,1,8),  Priority.NORMAL, 6),
    # Conflict test: overlaps with Ahmed on same room type
    BookingRequest(7, "Fatma",   RoomType.SINGLE, date(2025,1,1),  date(2025,1,4),  Priority.NORMAL, 7),
]

ROOM_MAP = {r.room_id: r for r in ROOMS}


def print_section(title: str):
    print(f"\n{'═'*55}")
    print(f"  {title}")
    print(f"{'═'*55}")


def print_assignments(assignments, requests, algo_name):
    req_map = {r.request_id: r for r in requests}
    print(f"\n  {'Guest':<12} {'Room':<8} {'Type':<8} {'Check-in':<12} {'Nights':<8} {'Priority'}")
    print(f"  {'-'*60}")
    for req_id, room_id in assignments.items():
        req = req_map[req_id]
        room = ROOM_MAP.get(room_id)
        room_str = room.room_number if room else "N/A"
        print(f"  {req.guest_name:<12} {room_str:<8} {req.room_type.value:<8} {str(req.check_in):<12} {req.nights():<8} {req.priority.value}")


def run_test(name, assign_fn, extra_check=None):
    print_section(f"Algorithm: {name}")
    if name == "Graph Coloring":
        assignments, unassigned, meta = assign_fn(REQUESTS, ROOMS)
        print(f"\n  Graph Stats: {meta.get('nodes')} nodes, {meta.get('edges')} edges")
        print(f"  Chromatic number: {meta.get('chromatic_number')}")
    else:
        assignments, unassigned = assign_fn(REQUESTS, ROOMS)

    print_assignments(assignments, REQUESTS, name)

    if unassigned:
        print(f"\n  ⚠  Unassigned ({len(unassigned)}): {[r.guest_name for r in unassigned]}")
    else:
        print(f"\n  ✅ All {len(assignments)} requests assigned!")

    if extra_check:
        conflicts = extra_check(assignments, REQUESTS)
        if conflicts:
            print(f"\n  ❌ CONFLICTS FOUND:")
            for c in conflicts:
                print(f"     {c}")
        else:
            print(f"  ✅ Zero conflicts verified.")

    print(f"\n  Assigned: {len(assignments)}  |  Unassigned: {len(unassigned)}")


if __name__ == "__main__":
    print("\n🏨  HOTEL BOOKING ALGORITHM TEST SUITE")
    print(f"   {len(ROOMS)} rooms  |  {len(REQUESTS)} requests")

    run_test("Greedy",         greedy_assign)
    run_test("Backtracking",   backtracking_assign, verify_no_conflicts)
    run_test("CSP",            csp_assign)
    run_test("Graph Coloring", graph_coloring_assign)

    print(f"\n{'═'*55}")
    print("  All tests complete.")
    print(f"{'═'*55}\n")
