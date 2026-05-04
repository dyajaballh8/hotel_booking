// ─── models.dart ───────────────────────────────────────────────────────────

enum RoomType { single, double, suite }

enum Priority { normal, vip }

enum BookingStatus { confirmed, pending, cancelled, no_availability }

class Room {
  final int roomId;
  final String roomNumber;
  final RoomType roomType;
  final int floor;
  final double pricePerNight;
  final bool isActive;
  final bool? available;
  final Map<String, dynamic>? occupiedBy;
  final List<Map<String, dynamic>> bookings;

  const Room({
    required this.roomId,
    required this.roomNumber,
    required this.roomType,
    required this.floor,
    required this.pricePerNight,
    this.isActive = true,
    this.available,
    this.occupiedBy,
    this.bookings = const [],
  });

  factory Room.fromJson(Map<String, dynamic> j) => Room(
    roomId: j['room_id'],
    roomNumber: j['room_number'],
    roomType: RoomType.values.firstWhere((e) => e.name == j['room_type']),
    floor: j['floor'],
    pricePerNight: (j['price_per_night'] as num).toDouble(),
    isActive: j['is_active'] ?? true,
    available: j['available'],
    occupiedBy: j['occupied_by'],
    bookings: j['bookings'] != null
        ? List<Map<String, dynamic>>.from(j['bookings'])
        : [],
  );

  String get typeLabel => switch (roomType) {
    RoomType.single => 'Single',
    RoomType.double => 'Double',
    RoomType.suite => 'Suite',
  };
  bool get isAvailable => available ?? true;
}

class Guest {
  final int guestId;
  final String name, email;
  final Priority priority;
  const Guest({
    required this.guestId,
    required this.name,
    required this.email,
    this.priority = Priority.normal,
  });
  factory Guest.fromJson(Map<String, dynamic> j) => Guest(
    guestId: j['guest_id'],
    name: j['name'],
    email: j['email'],
    priority: Priority.values.firstWhere((e) => e.name == j['priority']),
  );
}

class Booking {
  final int bookingId, nights;
  final Guest guest;
  final Room room;
  final DateTime checkIn, checkOut;
  final BookingStatus status;
  final double totalPrice;
  const Booking({
    required this.bookingId,
    required this.guest,
    required this.room,
    required this.checkIn,
    required this.checkOut,
    required this.status,
    required this.totalPrice,
    required this.nights,
  });
  factory Booking.fromJson(Map<String, dynamic> j) => Booking(
    bookingId: j['booking_id'],
    guest: Guest.fromJson(j['guest']),
    room: Room.fromJson(j['room']),
    checkIn: DateTime.parse(j['check_in']),
    checkOut: DateTime.parse(j['check_out']),
    status: BookingStatus.values.firstWhere((e) => e.name == j['status']),
    totalPrice: (j['total_price'] as num).toDouble(),
    nights: j['nights'],
  );
}

class CspConstraintLog {
  final String room, roomType, reason;
  final int floor;
  final double pricePerNight;
  final bool passed;
  const CspConstraintLog({
    required this.room,
    required this.floor,
    required this.roomType,
    required this.pricePerNight,
    required this.passed,
    required this.reason,
  });
  factory CspConstraintLog.fromJson(Map<String, dynamic> j) => CspConstraintLog(
    room: j['room'],
    floor: j['floor'],
    roomType: j['room_type'],
    pricePerNight: (j['price_per_night'] as num).toDouble(),
    passed: j['passed'],
    reason: j['reason'],
  );
}

class CspBookingResult {
  final String status, reason;
  final Map<String, dynamic>? assignedRoom;
  final List<String> triedRooms;
  final List<Map<String, dynamic>> rejectedRooms;
  final List<CspConstraintLog> constraintLog;
  bool get isConfirmed => status == 'confirmed';
  const CspBookingResult({
    required this.status,
    required this.assignedRoom,
    required this.reason,
    required this.triedRooms,
    required this.rejectedRooms,
    required this.constraintLog,
  });
  factory CspBookingResult.fromJson(Map<String, dynamic> j) => CspBookingResult(
    status: j['status'],
    assignedRoom: j['assigned_room'],
    reason: j['reason'],
    triedRooms: List<String>.from(j['tried_rooms']),
    rejectedRooms: List<Map<String, dynamic>>.from(j['rejected_rooms']),
    constraintLog: (j['constraint_log'] as List)
        .map((e) => CspConstraintLog.fromJson(e))
        .toList(),
  );
}

class BookResult {
  final CspBookingResult cspResult;
  final Booking? booking;
  const BookResult({required this.cspResult, this.booking});
  factory BookResult.fromJson(Map<String, dynamic> j) => BookResult(
    cspResult: CspBookingResult.fromJson(j['csp_result']),
    booking: j['booking'] != null ? Booking.fromJson(j['booking']) : null,
  );
}

class DashboardStats {
  final int totalRooms, totalBookings, activeStays, pendingRequests;
  final double totalRevenue;
  final Map<String, int> roomsByType;
  const DashboardStats({
    required this.totalRooms,
    required this.totalBookings,
    required this.activeStays,
    required this.totalRevenue,
    required this.roomsByType,
    required this.pendingRequests,
  });
  factory DashboardStats.fromJson(Map<String, dynamic> j) => DashboardStats(
    totalRooms: j['total_rooms'],
    totalBookings: j['total_bookings'],
    activeStays: j['active_stays'],
    totalRevenue: (j['total_revenue'] as num).toDouble(),
    roomsByType: Map<String, int>.from(j['rooms_by_type']),
    pendingRequests: j['pending_requests'],
  );
}
