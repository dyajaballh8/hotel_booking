"""
HotelService — Central booking engine
All data lives here. CSP is the ONLY way to confirm bookings.
"""

from typing import Dict, List, Optional
from datetime import date
from models.models import (
    Room, Guest, Booking, BookingRequest,
    BookingStatus, RoomType, Priority
)
from algorithms.csp_booking import csp_book_single


class HotelService:
    def __init__(self):
        self._rooms: Dict[int, Room] = {}
        self._guests: Dict[int, Guest] = {}
        self._bookings: Dict[int, Booking] = {}
        self._next_room_id = 1
        self._next_guest_id = 1
        self._next_booking_id = 1
        self._seed_rooms()

    # ─── Seed ─────────────────────────────────────────────────────────────

    def _seed_rooms(self):
        for num, rtype, floor, price in [
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
        ]:
            self._add_room(num, rtype, floor, price)

    def _add_room(self, number, room_type, floor, price):
        room = Room(self._next_room_id, number, room_type, floor, price)
        self._rooms[room.room_id] = room
        self._next_room_id += 1
        return room

    # ─── Rooms ────────────────────────────────────────────────────────────

    def get_rooms(self) -> List[Room]:
        return list(self._rooms.values())

    def get_rooms_with_status(self, check_in: date, check_out: date) -> List[Dict]:
        """Each room with availability status for the given period."""
        result = []
        confirmed = [b for b in self._bookings.values() if b.status == BookingStatus.CONFIRMED]
        for room in self._rooms.values():
            occupied_by = None
            for b in confirmed:
                if b.room.room_id == room.room_id:
                    if check_in < b.check_out and check_out > b.check_in:
                        occupied_by = {
                            "guest_name": b.guest.name,
                            "check_in": b.check_in.isoformat(),
                            "check_out": b.check_out.isoformat(),
                            "booking_id": b.booking_id,
                        }
                        break
            r = room.to_dict()
            r["available"] = occupied_by is None
            r["occupied_by"] = occupied_by
            result.append(r)
        return result

    def get_all_rooms_status(self) -> List[Dict]:
        """All rooms with all their confirmed bookings listed."""
        confirmed = [b for b in self._bookings.values() if b.status == BookingStatus.CONFIRMED]
        result = []
        for room in self._rooms.values():
            bookings = [
                {
                    "booking_id": b.booking_id,
                    "guest_name": b.guest.name,
                    "priority": b.guest.priority.value,
                    "check_in": b.check_in.isoformat(),
                    "check_out": b.check_out.isoformat(),
                    "nights": (b.check_out - b.check_in).days,
                    "total_price": b.total_price,
                }
                for b in confirmed if b.room.room_id == room.room_id
            ]
            r = room.to_dict()
            r["bookings"] = sorted(bookings, key=lambda x: x["check_in"])
            r["total_bookings"] = len(bookings)
            result.append(r)
        return result

    # ─── Guests ───────────────────────────────────────────────────────────

    def get_or_create_guest(self, name: str, email: str, priority: Priority) -> Guest:
        for g in self._guests.values():
            if g.email == email:
                # 🚨 هنا تم إضافة التعديل 🚨
                # تحديث بيانات الضيف بالاسم والأولوية الجديدة لو اتغيروا لنفس الإيميل
                g.name = name 
                g.priority = priority
                return g
                
        guest = Guest(self._next_guest_id, name, email, priority)
        self._guests[guest.guest_id] = guest
        self._next_guest_id += 1
        return guest

    # ─── CSP Booking ──────────────────────────────────────────────────────

    def book_with_csp(
        self,
        guest_name: str,
        email: str,
        room_type: RoomType,
        check_in: date,
        check_out: date,
        priority: Priority = Priority.NORMAL,
    ) -> Dict:
        """
        The ONLY booking method. Uses CSP to find and confirm a room.
        Returns full CSP trace + result.
        """
        guest = self.get_or_create_guest(guest_name, email, priority)

        request = BookingRequest(
            guest_id=guest.guest_id,
            guest_name=guest_name,
            room_type=room_type,
            check_in=check_in,
            check_out=check_out,
            priority=priority,
            request_id=self._next_booking_id,
        )

        confirmed = list(self._bookings.values())
        rooms = list(self._rooms.values())

        # Run CSP
        csp_result = csp_book_single(request, rooms, confirmed)

        booking_data = None
        if csp_result["status"] == "confirmed":
            room = self._rooms[csp_result["assigned_room"]["room_id"]]
            booking = Booking(
                booking_id=self._next_booking_id,
                guest=guest,
                room=room,
                check_in=check_in,
                check_out=check_out,
                status=BookingStatus.CONFIRMED,
            )
            self._bookings[booking.booking_id] = booking
            self._next_booking_id += 1
            booking_data = booking.to_dict()

        return {
            "csp_result": csp_result,
            "booking": booking_data,
        }

    # ─── Bookings ─────────────────────────────────────────────────────────

    def get_all_bookings(self) -> List[Dict]:
        return [b.to_dict() for b in self._bookings.values()]

    def get_booking_table(self) -> List[Dict]:
        """Live table sorted by check_in — updates on every new booking."""
        confirmed = [b for b in self._bookings.values() if b.status == BookingStatus.CONFIRMED]
        return sorted(
            [b.to_dict() for b in confirmed],
            key=lambda x: x["check_in"],
        )

    def cancel_booking(self, booking_id: int) -> bool:
        b = self._bookings.get(booking_id)
        if not b:
            return False
        b.status = BookingStatus.CANCELLED
        return True

    # ─── Dashboard ────────────────────────────────────────────────────────

    def dashboard_stats(self) -> Dict:
        confirmed = [b for b in self._bookings.values() if b.status == BookingStatus.CONFIRMED]
        today = date.today()
        return {
            "total_rooms": len(self._rooms),
            "total_bookings": len(confirmed),
            "active_stays": sum(1 for b in confirmed if b.check_in <= today <= b.check_out),
            "total_revenue": round(sum(b.total_price for b in confirmed), 2),
            "rooms_by_type": {
                rt.value: sum(1 for r in self._rooms.values() if r.room_type == rt)
                for rt in RoomType
            },
            "pending_requests": 0,
        }

    # ─── CSP Report (demo) ────────────────────────────────────────────────
    
    def get_real_csp_report(self):
        from algorithms.csp_with_tables import csp_full_report
        from models.models import BookingRequest

        requests = []

        for b in self._bookings.values():
            requests.append(
                BookingRequest(
                    guest_id=b.guest.guest_id,
                    guest_name=b.guest.name,
                    room_type=b.room.room_type,   # تأكد إنها Enum صح
                    check_in=b.check_in,
                    check_out=b.check_out,
                    priority=b.guest.priority,     # نفس الكلام هنا
                    request_id=b.booking_id,
                )
            )

        rooms = list(self._rooms.values())

        return csp_full_report(requests, rooms)