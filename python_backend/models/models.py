from dataclasses import dataclass, field
from datetime import date
from typing import Optional
from enum import Enum


class RoomType(str, Enum):
    SINGLE = "single"
    DOUBLE = "double"
    SUITE = "suite"


class Priority(str, Enum):
    NORMAL = "normal"
    VIP = "vip"


class BookingStatus(str, Enum):
    CONFIRMED = "confirmed"
    PENDING = "pending"
    CANCELLED = "cancelled"
    NO_AVAILABILITY = "no_availability"


@dataclass
class Room:
    room_id: int
    room_number: str
    room_type: RoomType
    floor: int
    price_per_night: float
    is_active: bool = True

    def to_dict(self):
        return {
            "room_id": self.room_id,
            "room_number": self.room_number,
            "room_type": self.room_type.value,
            "floor": self.floor,
            "price_per_night": self.price_per_night,
            "is_active": self.is_active,
        }


@dataclass
class Guest:
    guest_id: int
    name: str
    email: str
    priority: Priority = Priority.NORMAL

    def to_dict(self):
        return {
            "guest_id": self.guest_id,
            "name": self.name,
            "email": self.email,
            "priority": self.priority.value,
        }


@dataclass
class BookingRequest:
    guest_id: int
    guest_name: str
    room_type: RoomType
    check_in: date
    check_out: date
    priority: Priority = Priority.NORMAL
    request_id: Optional[int] = None

    def nights(self) -> int:
        return (self.check_out - self.check_in).days

    def overlaps(self, other: "BookingRequest") -> bool:
        return self.check_in < other.check_out and self.check_out > other.check_in

    def to_dict(self):
        return {
            "request_id": self.request_id,
            "guest_id": self.guest_id,
            "guest_name": self.guest_name,
            "room_type": self.room_type.value,
            "check_in": self.check_in.isoformat(),
            "check_out": self.check_out.isoformat(),
            "priority": self.priority.value,
            "nights": self.nights(),
        }


@dataclass
class Booking:
    booking_id: int
    guest: Guest
    room: Room
    check_in: date
    check_out: date
    status: BookingStatus = BookingStatus.CONFIRMED
    total_price: float = 0.0

    def __post_init__(self):
        if self.total_price == 0.0:
            nights = (self.check_out - self.check_in).days
            self.total_price = nights * self.room.price_per_night

    def to_dict(self):
        return {
            "booking_id": self.booking_id,
            "guest": self.guest.to_dict(),
            "room": self.room.to_dict(),
            "check_in": self.check_in.isoformat(),
            "check_out": self.check_out.isoformat(),
            "status": self.status.value,
            "total_price": self.total_price,
            "nights": (self.check_out - self.check_in).days,
        }