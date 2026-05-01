// ─── bookings_screen.dart ──────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_app/core/theme/theme.dart';
import 'package:flutter_app/services/api_services.dart';
import '../models/models.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  final _api = ApiService();
  List<Booking> _bookings = [];
  bool _loading = true;
  String _filter = 'all'; // all | confirmed | cancelled

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final bookings = await _api.getBookings();
      setState(() { _bookings = bookings; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _cancel(int bookingId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.card,
        title: const Text('Cancel Booking', style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text('Are you sure?', style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _api.cancelBooking(bookingId);
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking cancelled'), backgroundColor: Colors.orange),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  List<Booking> get _filtered {
    if (_filter == 'confirmed') return _bookings.where((b) => b.status == BookingStatus.confirmed).toList();
    if (_filter == 'cancelled') return _bookings.where((b) => b.status == BookingStatus.cancelled).toList();
    return _bookings;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Bookings'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.gold))
                : _filtered.isEmpty
                    ? const Center(child: Text('No bookings', style: TextStyle(color: AppTheme.textSecondary)))
                    : RefreshIndicator(
                        onRefresh: _load,
                        color: AppTheme.gold,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) => _buildTile(_filtered[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    final filters = [
      ('all', 'All (${_bookings.length})'),
      ('confirmed', 'Confirmed'),
      ('cancelled', 'Cancelled'),
    ];
    return Container(
      color: AppTheme.bgDark,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: filters.map((f) {
          final active = _filter == f.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _filter = f.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: active ? AppTheme.gold.withOpacity(0.15) : AppTheme.card,
                  border: Border.all(color: active ? AppTheme.gold : AppTheme.border),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(f.$2, style: TextStyle(color: active ? AppTheme.gold : AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTile(Booking b) {
    final color = RoomTypeConfig.colors[b.room.roomType.name] ?? AppTheme.gold;
    final cancelled = b.status == BookingStatus.cancelled;

    return Opacity(
      opacity: cancelled ? 0.5 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppTheme.card,
          border: Border.all(color: cancelled ? AppTheme.border : color.withOpacity(0.25)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(14),
          leading: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                child: Center(
                  child: Text(b.room.roomNumber, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 14)),
                ),
              ),
            ],
          ),
          title: Row(
            children: [
              Text(b.guest.name, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700)),
              if (b.guest.priority == Priority.vip) ...[
                const SizedBox(width: 5),
                const Icon(Icons.star, color: AppTheme.gold, size: 13),
              ],
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text('${b.room.typeLabel} · ${_fmt(b.checkIn)} → ${_fmt(b.checkOut)}',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              Text('${b.nights} nights · \$${b.totalPrice.toStringAsFixed(0)}',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            ],
          ),
          trailing: cancelled
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.red.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                  child: const Text('Cancelled', style: TextStyle(color: Colors.red, fontSize: 11)),
                )
              : IconButton(
                  icon: const Icon(Icons.cancel_outlined, color: AppTheme.textSecondary),
                  onPressed: () => _cancel(b.bookingId),
                  tooltip: 'Cancel',
                ),
        ),
      ),
    );
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}