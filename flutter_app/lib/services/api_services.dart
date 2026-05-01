import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class ApiService {
static const String _base = 'http://192.168.1.3:8000';
 
  Future<Map<String, dynamic>> _get(String path) async {
    final res = await http.get(Uri.parse('$_base$path'));
    if (res.statusCode != 200) {
      throw Exception('GET $path failed: ${res.statusCode} ${res.body}');
    }
    return json.decode(res.body);
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final res = await http.post(
      Uri.parse('$_base$path'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );
    if (res.statusCode != 200) {
      throw Exception('POST $path failed: ${res.statusCode} ${res.body}');
    }
    return json.decode(res.body);
  }

  Future<Map<String, dynamic>> _delete(String path) async {
    final res = await http.delete(Uri.parse('$_base$path'));
    if (res.statusCode != 200) {
      throw Exception('DELETE $path failed: ${res.statusCode} ${res.body}');
    }
    return json.decode(res.body);
  }

  // ── Dashboard ───────────────────────────────────────

  Future<DashboardStats> getDashboard() async {
    final data = await _get('/api/dashboard');
    return DashboardStats.fromJson(data);
  }

  // ── Rooms ───────────────────────────────────────────

  Future<List<Room>> getRooms() async {
    final data = await _get('/api/rooms');
    return (data['rooms'] as List).map((e) => Room.fromJson(e)).toList();
  }

  Future<List<Room>> getAvailableRooms({
    required DateTime checkIn,
    required DateTime checkOut,
    RoomType? roomType,
  }) async {
    String path =
        '/api/rooms/available?check_in=${_fmt(checkIn)}&check_out=${_fmt(checkOut)}';
    if (roomType != null) path += '&room_type=${roomType.name}';
    final data = await _get(path);
    return (data['rooms'] as List).map((e) => Room.fromJson(e)).toList();
  }

  // ── Guests ──────────────────────────────────────────

  Future<Guest> createGuest({
    required String name,
    required String email,
    Priority priority = Priority.normal,
  }) async {
    final data = await _post('/api/guests', {
      'name': name,
      'email': email,
      'priority': priority.name,
    });
    return Guest.fromJson(data);
  }

  // ── Booking Requests ────────────────────────────────

  Future<BookingRequest> submitRequest(BookingRequest req) async {
    final data = await _post('/api/requests', req.toJson());
    return BookingRequest.fromJson(data['request']);
  }

  Future<List<BookingRequest>> getPendingRequests() async {
    final data = await _get('/api/requests');
    return (data['requests'] as List)
        .map((e) => BookingRequest.fromJson(e))
        .toList();
  }

  // ── Assignment ──────────────────────────────────────

  Future<AssignmentResult> runAssignment({
    String algorithm = 'backtracking',
  }) async {
    final data = await _post('/api/assign', {'algorithm': algorithm});
    return AssignmentResult.fromJson(data);
  }

  // ── Bookings ───────────────────────────────────────

  Future<List<Booking>> getBookings() async {
    final data = await _get('/api/bookings');
    return (data['bookings'] as List).map((e) => Booking.fromJson(e)).toList();
  }

  Future<void> cancelBooking(int bookingId) async {
    await _delete('/api/bookings/$bookingId');
  }

  // ── Util ───────────────────────────────────────────

  String _fmt(DateTime d) => d.toIso8601String().substring(0, 10);
}