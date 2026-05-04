import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});
  @override State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  final _api = ApiService();
  List<Booking> _bookings = [];
  bool _loading = true;

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final b = await _api.getBookingTable();
      setState(() { _bookings = b; _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  Future<void> _cancel(int id) async {
    final ok = await showDialog<bool>(context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.card,
        title: const Text('إلغاء الحجز', style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text('هل أنت متأكد؟', style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('لا')),
          TextButton(onPressed: () => Navigator.pop(context, true),
              child: const Text('نعم، إلغاء', style: TextStyle(color: Colors.red))),
        ]));
    if (ok != true) return;
    try { await _api.cancelBooking(id); _load(); } catch (_) {}
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('جدول الحجوزات'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.gold))
          : _bookings.isEmpty ? _empty()
          : Column(children: [
              _header(),
              Expanded(child: RefreshIndicator(onRefresh: _load, color: AppTheme.gold,
                child: ListView.builder(
                  padding: const EdgeInsets.all(14),
                  itemCount: _bookings.length,
                  itemBuilder: (_, i) => _row(_bookings[i])))),
            ]),
    );
  }

  Widget _header() {
    final rev = _bookings.fold(0.0, (s, b) => s + b.totalPrice);
    return Container(
      color: AppTheme.card,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(children: [
        _chip('${_bookings.length} حجز', AppTheme.gold),
        const SizedBox(width: 8),
        _chip('\$${rev.toStringAsFixed(0)}', AppTheme.teal),
        const SizedBox(width: 8),
        _chip('مرتب بالدخول ↑', AppTheme.textSecondary),
      ]));
  }

  Widget _chip(String l, Color c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: c.withOpacity(0.1),
      border: Border.all(color: c.withOpacity(0.3)), borderRadius: BorderRadius.circular(20)),
    child: Text(l, style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w700)));

  Widget _row(Booking b) {
    final color = RoomTypeConfig.colors[b.room.roomType.name] ?? AppTheme.gold;
    final isVip = b.guest.priority == Priority.vip;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: AppTheme.card,
        border: Border.all(color: isVip ? AppTheme.gold.withOpacity(0.4) : color.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: Container(width: 46, height: 46,
          decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
          child: Center(child: Text(b.room.roomNumber,
              style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 15)))),
        title: Row(children: [
          Text(b.guest.name, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700)),
          if (isVip) ...[const SizedBox(width: 5), const Icon(Icons.star, color: AppTheme.gold, size: 13)],
        ]),
        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 3),
          Text('${b.room.typeLabel} · طابق ${b.room.floor}',
              style: TextStyle(color: color.withOpacity(0.8), fontSize: 12)),
          Text('${_fmt(b.checkIn)} → ${_fmt(b.checkOut)} · ${b.nights} ليالي',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
        ]),
        trailing: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('\$${b.totalPrice.toStringAsFixed(0)}',
              style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 15)),
          const SizedBox(height: 4),
          GestureDetector(onTap: () => _cancel(b.bookingId),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
              child: const Text('إلغاء', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.w700)))),
        ]),
      ));
  }

  Widget _empty() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    const Icon(Icons.calendar_today_outlined, color: AppTheme.textSecondary, size: 52),
    const SizedBox(height: 14),
    const Text('لا توجد حجوزات', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
    const SizedBox(height: 8),
    const Text('ابدأ بإضافة حجز جديد', style: TextStyle(color: AppTheme.textSecondary)),
    const SizedBox(height: 20),
    ElevatedButton.icon(
      onPressed: () => Navigator.pushNamed(context, '/new_booking').then((_) => _load()),
      icon: const Icon(Icons.add), label: const Text('حجز جديد')),
  ]));
}
