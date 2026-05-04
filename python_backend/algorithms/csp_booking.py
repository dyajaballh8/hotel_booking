"""
CSP Real-Time Booking Engine
=============================
يستخدم CSP لتأكيد أو رفض حجز واحد في الوقت الفعلي.

الـ Constraints:
  1. الغرفة من نفس النوع المطلوب
  2. لا يوجد تداخل زمني مع حجز مؤكد موجود
  3. VIP يحصل على أعلى طابق متاح من نفس النوع

Returns:
  assigned_room  — الغرفة المخصصة أو None
  reason         — سبب القرار
  tried_rooms    — الغرف التي جربها CSP
  rejected_rooms — الغرف المرفوضة وسبب كل رفض
"""

from typing import Dict, List, Optional, Tuple
from models.models import Room, BookingRequest, Booking, BookingStatus, Priority, RoomType


def check_room_available(
    room: Room,
    request: BookingRequest,
    confirmed_bookings: List[Booking],
) -> Tuple[bool, Optional[str]]:
    """
    Returns (is_available, reason_if_not).
    """
    if not room.is_active:
        return False, "الغرفة غير نشطة"

    if room.room_type != request.room_type:
        return False, f"النوع لا يطابق ({room.room_type.value} != {request.room_type.value})"

    for b in confirmed_bookings:
        if b.room.room_id == room.room_id and b.status == BookingStatus.CONFIRMED:
            if request.check_in < b.check_out and request.check_out > b.check_in:
                return False, (
                    f"محجوزة من {b.check_in.isoformat()} إلى {b.check_out.isoformat()} "
                    f"({b.guest.name})"
                )
    return True, None


def csp_book_single(
    request: BookingRequest,
    rooms: List[Room],
    confirmed_bookings: List[Booking],
) -> Dict:
    """
    CSP engine for a single booking request.

    Algorithm:
      1. Filter domain: rooms matching request.room_type
      2. Order domain: VIP → highest floor first, Normal → lowest first
      3. Forward check: pick first room with no conflicts
      4. Return decision with full trace
    """
    # Step 1: Build domain
    domain = [r for r in rooms if r.room_type == request.room_type and r.is_active]

    if not domain:
        return {
            "status": "rejected",
            "assigned_room": None,
            "reason": f"لا توجد غرف من نوع {request.room_type.value} في الفندق",
            "tried_rooms": [],
            "rejected_rooms": [],
            "constraint_log": [],
        }

    # Step 2: Order by floor (VIP → descending, Normal → ascending)
    if request.priority == Priority.VIP:
        domain = sorted(domain, key=lambda r: -r.floor)
    else:
        domain = sorted(domain, key=lambda r: r.floor)

    # Step 3: Try each room (CSP forward checking)
    tried = []
    rejected = []
    constraint_log = []

    for room in domain:
        tried.append(room.room_number)
        available, reason = check_room_available(room, request, confirmed_bookings)

        constraint_log.append({
            "room": room.room_number,
            "floor": room.floor,
            "room_type": room.room_type.value,
            "price_per_night": room.price_per_night,
            "passed": available,
            "reason": reason or "✓ لا تعارض",
        })

        if available:
            nights = (request.check_out - request.check_in).days
            return {
                "status": "confirmed",
                "assigned_room": {
                    "room_id": room.room_id,
                    "room_number": room.room_number,
                    "room_type": room.room_type.value,
                    "floor": room.floor,
                    "price_per_night": room.price_per_night,
                    "total_price": round(room.price_per_night * nights, 2),
                },
                "reason": (
                    f"{'VIP → أعلى طابق متاح' if request.priority == Priority.VIP else 'أول غرفة متاحة'}: "
                    f"غرفة {room.room_number} (طابق {room.floor})"
                ),
                "tried_rooms": tried,
                "rejected_rooms": rejected,
                "constraint_log": constraint_log,
            }
        else:
            rejected.append({"room": room.room_number, "reason": reason})

    # No room found
    return {
        "status": "rejected",
        "assigned_room": None,
        "reason": f"لا توجد غرفة {request.room_type.value} متاحة من {request.check_in} إلى {request.check_out}",
        "tried_rooms": tried,
        "rejected_rooms": rejected,
        "constraint_log": constraint_log,
    }
