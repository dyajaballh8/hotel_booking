"""
HotelService — Central booking engine
======================================
Manages rooms, guests, and bookings.
Delegates assignment to the chosen algorithm.
"""

from typing import Dict, List, Optional, Tuple
from datetime import date
from models.models import Room, Guest, Booking, BookingRequest, BookingStatus, RoomType, Priority
from algorithms.greedy import greedy_assign
from algorithms.backtracking import backtracking_assign, verify_no_conflicts
from algorithms.csp import csp_assign
from algorithms.graph_coloring import graph_coloring_assign, build_conflict_graph


class HotelService:
    def __init__(self):
        self._rooms: Dict[int, Room] = {}
        self._guests: Dict[int, Guest] = {}
        self._bookings: Dict[int, Booking] = {}
        self._pending_requests: List[BookingRequest] = []
        self._next_room_id = 1
        self._next_guest_id = 1
        self._next_booking_id = 1
        self._next_request_id = 1
        self._seed_demo_data()

    # ─── Seeding ──────────────────────────────────────────────────────────

    def _seed_demo_data(self):
        """Add 10 sample rooms (3 singles, 4 doubles, 3 suites)."""
        demo_rooms = [
            ("101", RoomType.SINGLE, 1, 80.0),
            ("102", RoomType.SINGLE, 1, 80.0),
            ("103", RoomType.SINGLE, 1, 80.0),
            ("201", RoomType.DOUBLE, 2, 140.0),
            ("202", RoomType.DOUBLE, 2, 140.0),
            ("203", RoomType.DOUBLE, 2, 140.0),
            ("204", RoomType.DOUBLE, 2, 140.0),
            ("301", RoomType.SUITE,  3, 280.0),
            ("302", RoomType.SUITE,  3, 280.0),
            ("303", RoomType.SUITE,  3, 280.0),
        ]
        for num, rtype, floor, price in demo_rooms:
            self.add_room(num, rtype, floor, price)

    # ─── Rooms ────────────────────────────────────────────────────────────

    def add_room(self, number: str, room_type: RoomType, floor: int, price: float) -> Room:
        room = Room(self._next_room_id, number, room_type, floor, price)
        self._rooms[room.room_id] = room
        self._next_room_id += 1
        return room

    def get_rooms(self) -> List[Room]:
        return list(self._rooms.values())

    def get_available_rooms(self, check_in: date, check_out: date, room_type: Optional[RoomType] = None) -> List[Room]:
        available = []
        for room in self._rooms.values():
            if not room.is_active:
                continue
            if room_type and room.room_type != room_type:
                continue
            # Check no confirmed booking overlaps
            conflict = False
            for booking in self._bookings.values():
                if (booking.room.room_id == room.room_id
                        and booking.status == BookingStatus.CONFIRMED
                        and check_in < booking.check_out
                        and check_out > booking.check_in):
                    conflict = True
                    break
            if not conflict:
                available.append(room)
        return available

    # ─── Guests ───────────────────────────────────────────────────────────

    def add_guest(self, name: str, email: str, priority: Priority = Priority.NORMAL) -> Guest:
        guest = Guest(self._next_guest_id, name, email, priority)
        self._guests[guest.guest_id] = guest
        self._next_guest_id += 1
        return guest

    def get_guest(self, guest_id: int) -> Optional[Guest]:
        return self._guests.get(guest_id)

    # ─── Booking Requests ─────────────────────────────────────────────────

    def submit_request(
        self,
        guest_id: int,
        guest_name: str,
        room_type: RoomType,
        check_in: date,
        check_out: date,
        priority: Priority = Priority.NORMAL,
    ) -> BookingRequest:
        req = BookingRequest(
            guest_id=guest_id,
            guest_name=guest_name,
            room_type=room_type,
            check_in=check_in,
            check_out=check_out,
            priority=priority,
            request_id=self._next_request_id,
        )
        self._pending_requests.append(req)
        self._next_request_id += 1
        return req

    def get_pending_requests(self) -> List[BookingRequest]:
        return list(self._pending_requests)

    # ─── Assignment Engine ────────────────────────────────────────────────

    def run_assignment(self, algorithm: str = "backtracking") -> Dict:
        """
        Run the chosen algorithm on all pending requests.

        algorithm: 'greedy' | 'backtracking' | 'csp' | 'graph_coloring'
        """
        requests = list(self._pending_requests)
        rooms = list(self._rooms.values())

        if not requests:
            return {"status": "no_requests", "bookings": [], "unassigned": []}

        metadata = {}

        if algorithm == "greedy":
            assignments, unassigned = greedy_assign(requests, rooms)
        elif algorithm == "backtracking":
            assignments, unassigned = backtracking_assign(requests, rooms)
            conflicts = verify_no_conflicts(assignments, requests)
            metadata["conflicts"] = conflicts
        elif algorithm == "csp":
            assignments, unassigned = csp_assign(requests, rooms)
        elif algorithm == "graph_coloring":
            assignments, unassigned, graph_meta = graph_coloring_assign(requests, rooms)
            metadata["graph"] = graph_meta
        else:
            raise ValueError(f"Unknown algorithm: {algorithm}")

        # Commit confirmed bookings
        confirmed_bookings = []
        for req in requests:
            room_id = assignments.get(req.request_id)
            if room_id:
                guest = self._guests.get(req.guest_id) or Guest(
                    req.guest_id, req.guest_name, "", req.priority
                )
                room = self._rooms[room_id]
                booking = Booking(
                    booking_id=self._next_booking_id,
                    guest=guest,
                    room=room,
                    check_in=req.check_in,
                    check_out=req.check_out,
                    status=BookingStatus.CONFIRMED,
                )
                self._bookings[booking.booking_id] = booking
                self._next_booking_id += 1
                confirmed_bookings.append(booking)

        # Clear processed requests
        self._pending_requests = []

        return {
            "status": "ok",
            "algorithm": algorithm,
            "bookings": [b.to_dict() for b in confirmed_bookings],
            "unassigned": [r.to_dict() for r in unassigned],
            "total_assigned": len(confirmed_bookings),
            "total_unassigned": len(unassigned),
            **metadata,
        }

    # ─── Cancel & Reassign ────────────────────────────────────────────────

    def cancel_booking(self, booking_id: int) -> bool:
        booking = self._bookings.get(booking_id)
        if not booking:
            return False
        booking.status = BookingStatus.CANCELLED
        return True

    # ─── Dashboard Stats ─────────────────────────────────────────────────

    def dashboard_stats(self) -> Dict:
        confirmed = [b for b in self._bookings.values() if b.status == BookingStatus.CONFIRMED]
        today = date.today()
        active = [b for b in confirmed if b.check_in <= today <= b.check_out]
        revenue = sum(b.total_price for b in confirmed)

        rooms_by_type = {}
        for room in self._rooms.values():
            rooms_by_type[room.room_type.value] = rooms_by_type.get(room.room_type.value, 0) + 1

        return {
            "total_rooms": len(self._rooms),
            "total_bookings": len(confirmed),
            "active_stays": len(active),
            "total_revenue": round(revenue, 2),
            "rooms_by_type": rooms_by_type,
            "pending_requests": len(self._pending_requests),
        }

    def get_all_bookings(self) -> List[Dict]:
        return [b.to_dict() for b in self._bookings.values()]