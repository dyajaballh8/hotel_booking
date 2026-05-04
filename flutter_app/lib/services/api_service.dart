import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';
import '../models/csp_report_model.dart';

class ApiService {
  // ── غيّر الـ IP ده لـ IP جهازك على الـ WiFi ──────────────────────────
  // شغّل ipconfig على Windows → خد IPv4 Address تحت Wi-Fi
  // مثال: 'http://192.168.1.5:8000'
  // لو Emulator: 'http://10.0.2.2:8000'
  static const String _base = 'http://192.168.1.3:8000';

  // FIX 1: Changed return type from Map<String, dynamic> to dynamic
  Future<dynamic> _get(String path) async {
    final res = await http.get(Uri.parse('$_base$path'));
    if (res.statusCode != 200) throw Exception('GET $path → ${res.statusCode}: ${res.body}');
    return json.decode(utf8.decode(res.bodyBytes));
  }

  // FIX 1: Changed return type from Map<String, dynamic> to dynamic
  Future<dynamic> _post(String path, Map<String, dynamic> body) async {
    final res = await http.post(Uri.parse('$_base$path'),
        headers: {'Content-Type': 'application/json'}, body: json.encode(body));
    if (res.statusCode != 200) throw Exception('POST $path → ${res.statusCode}: ${res.body}');
    return json.decode(utf8.decode(res.bodyBytes));
  }

  // FIX 1: Changed return type from Map<String, dynamic> to dynamic
  Future<dynamic> _delete(String path) async {
    final res = await http.delete(Uri.parse('$_base$path'));
    if (res.statusCode != 200) throw Exception('DELETE $path → ${res.statusCode}');
    return json.decode(res.body);
  }

  String _fmt(DateTime d) => d.toIso8601String().substring(0, 10);

  // ── Dashboard ─────────────────────────────────────────────────────────
  Future<DashboardStats> getDashboard() async =>
      DashboardStats.fromJson(await _get('/api/dashboard'));

  // ── Rooms ─────────────────────────────────────────────────────────────
  Future<List<Room>> getRooms() async {
    final d = await _get('/api/rooms');
    return (d['rooms'] as List).map((e) => Room.fromJson(e)).toList();
  }

  Future<List<Room>> getRoomsWithStatus(DateTime checkIn, DateTime checkOut) async {
    final d = await _get('/api/rooms/status?check_in=${_fmt(checkIn)}&check_out=${_fmt(checkOut)}');
    return (d['rooms'] as List).map((e) => Room.fromJson(e)).toList();
  }

  Future<List<Room>> getRoomsAllBookings() async {
    final d = await _get('/api/rooms/all-bookings');
    return (d['rooms'] as List).map((e) => Room.fromJson(e)).toList();
  }

  // ── CSP Booking ───────────────────────────────────────────────────────
  Future<BookResult> bookWithCsp({
    required String guestName,
    required String email,
    required String roomType,
    required DateTime checkIn,
    required DateTime checkOut,
    String priority = 'normal',
  }) async {
    final d = await _post('/api/book', {
      'guest_name': guestName, 'email': email,
      'room_type': roomType, 'priority': priority,
      'check_in': _fmt(checkIn), 'check_out': _fmt(checkOut),
    });
    return BookResult.fromJson(d);
  }

  // ── Bookings ──────────────────────────────────────────────────────────
  Future<List<Booking>> getBookings() async {
    final d = await _get('/api/bookings');
    return (d['bookings'] as List).map((e) => Booking.fromJson(e)).toList();
  }

  Future<List<Booking>> getBookingTable() async {
    final d = await _get('/api/bookings/table');
    return (d['bookings'] as List).map((e) => Booking.fromJson(e)).toList();
  }

  Future<void> cancelBooking(int id) async => await _delete('/api/bookings/$id');

  // ── CSP Report ────────────────────────────────────────────────────────
  // FIX 2: Safely handle whether the API returns a List [] or an Object {}
  Future<dynamic> getCspReport() async {
    return await _get('/api/csp-report');
  }
}