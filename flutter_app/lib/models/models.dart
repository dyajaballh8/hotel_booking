// ─── models.dart ──────────────────────────────────────────────────────────
// Data models matching the Python backend exactly.

enum RoomType { single, double, suite }

enum Priority { normal, vip }

enum BookingStatus { confirmed, pending, cancelled, no_availability }

// ── Room ──────────────────────────────────────────────────────────────────

class Room {
  final int roomId;
  final String roomNumber;
  final RoomType roomType;
  final int floor;
  final double pricePerNight;
  final bool isActive;

  const Room({
    required this.roomId,
    required this.roomNumber,
    required this.roomType,
    required this.floor,
    required this.pricePerNight,
    this.isActive = true,
  });

  factory Room.fromJson(Map<String, dynamic> json) => Room(
    roomId: json['room_id'],
    roomNumber: json['room_number'],
    roomType: RoomType.values.firstWhere((e) => e.name == json['room_type']),
    floor: json['floor'],
    pricePerNight: (json['price_per_night'] as num).toDouble(),
    isActive: json['is_active'] ?? true,
  );

  String get typeLabel => switch (roomType) {
    RoomType.single => 'Single',
    RoomType.double => 'Double',
    RoomType.suite => 'Suite',
  };
}

// ── Guest ─────────────────────────────────────────────────────────────────

class Guest {
  final int guestId;
  final String name;
  final String email;
  final Priority priority;

  const Guest({
    required this.guestId,
    required this.name,
    required this.email,
    this.priority = Priority.normal,
  });

  factory Guest.fromJson(Map<String, dynamic> json) => Guest(
    guestId: json['guest_id'],
    name: json['name'],
    email: json['email'],
    priority: Priority.values.firstWhere((e) => e.name == json['priority']),
  );
}

// ── Booking ───────────────────────────────────────────────────────────────
class Booking {
  final int bookingId;
  final Guest guest;
  final Room room;
  final DateTime checkIn;
  final DateTime checkOut;
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
  });

  int get nights => checkOut.difference(checkIn).inDays;

  factory Booking.fromJson(Map<String, dynamic> json) => Booking(
    bookingId: json['booking_id'],
    guest: Guest.fromJson(json['guest']),
    room: Room.fromJson(json['room']),
    checkIn: DateTime.parse(json['check_in']),
    checkOut: DateTime.parse(json['check_out']),
    status: BookingStatus.values.firstWhere((e) => e.name == json['status']),
    totalPrice: (json['total_price'] as num).toDouble(),
  );
}

// ── BookingRequest ────────────────────────────────────────────────────────

class BookingRequest {
  final int? requestId;
  final int guestId;
  final String guestName;
  final RoomType roomType;
  final DateTime checkIn;
  final DateTime checkOut;
  final Priority priority;
  final int nights;

  const BookingRequest({
    this.requestId,
    required this.guestId,
    required this.guestName,
    required this.roomType,
    required this.checkIn,
    required this.checkOut,
    this.priority = Priority.normal,
    required this.nights,
  });

  factory BookingRequest.fromJson(Map<String, dynamic> json) => BookingRequest(
    requestId: json['request_id'],
    guestId: json['guest_id'],
    guestName: json['guest_name'],
    roomType: RoomType.values.firstWhere((e) => e.name == json['room_type']),
    checkIn: DateTime.parse(json['check_in']),
    checkOut: DateTime.parse(json['check_out']),
    priority: Priority.values.firstWhere((e) => e.name == json['priority']),
    nights: json['nights'],
  );

  Map<String, dynamic> toJson() => {
    "guest_id": guestId,
    "guest_name": guestName,
    "room_type": roomType.name.toLowerCase(),
    "check_in": checkIn.toIso8601String().split('T')[0],
    "check_out": checkOut.toIso8601String().split('T')[0],
    "priority": priority.name.toLowerCase(),
  };
}

// ── DashboardStats ────────────────────────────────────────────────────────

class DashboardStats {
  final int totalRooms;
  final int totalBookings;
  final int activeStays;
  final double totalRevenue;
  final Map<String, int> roomsByType;
  final int pendingRequests;

  const DashboardStats({
    required this.totalRooms,
    required this.totalBookings,
    required this.activeStays,
    required this.totalRevenue,
    required this.roomsByType,
    required this.pendingRequests,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) => DashboardStats(
    totalRooms: json['total_rooms'],
    totalBookings: json['total_bookings'],
    activeStays: json['active_stays'],
    totalRevenue: (json['total_revenue'] as num).toDouble(),
    roomsByType: Map<String, int>.from(json['rooms_by_type']),
    pendingRequests: json['pending_requests'],
  );
}

// ── AssignmentResult ──────────────────────────────────────────────────────

class AssignmentResult {
  final String status;
  final String algorithm;
  final List<Booking> bookings;
  final List<BookingRequest> unassigned;
  final int totalAssigned;
  final int totalUnassigned;

  const AssignmentResult({
    required this.status,
    required this.algorithm,
    required this.bookings,
    required this.unassigned,
    required this.totalAssigned,
    required this.totalUnassigned,
  });

  factory AssignmentResult.fromJson(Map<String, dynamic> json) =>
      AssignmentResult(
        status: json['status'],
        algorithm: json['algorithm'] ?? '',
        bookings: (json['bookings'] as List)
            .map((e) => Booking.fromJson(e))
            .toList(),
        unassigned: (json['unassigned'] as List)
            .map((e) => BookingRequest.fromJson(e))
            .toList(),
        totalAssigned: json['total_assigned'] ?? 0,
        totalUnassigned: json['total_unassigned'] ?? 0,
      );
}
