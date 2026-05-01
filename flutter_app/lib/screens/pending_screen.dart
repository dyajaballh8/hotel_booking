// ─── pending_screen.dart ───────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_app/core/theme/theme.dart';
import 'package:flutter_app/services/api_services.dart';
import '../models/models.dart';

class PendingScreen extends StatefulWidget {
  const PendingScreen({super.key});

  @override
  State<PendingScreen> createState() => _PendingScreenState();
}

class _PendingScreenState extends State<PendingScreen> {
  final _api = ApiService();
  List<BookingRequest> _requests = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await _api.getPendingRequests();
      setState(() { _requests = r; _loading = false; });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Requests'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.gold))
          : _requests.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_outline, color: AppTheme.teal, size: 56),
                      const SizedBox(height: 16),
                      const Text('No pending requests', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      const Text('All requests have been processed', style: TextStyle(color: AppTheme.textSecondary)),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.pushNamed(context, '/new_booking').then((_) => _load()),
                        icon: const Icon(Icons.add),
                        label: const Text('Add New Request'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Banner
                    Container(
                      color: const Color(0xFFFF9800).withOpacity(0.08),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.pending_actions, color: Color(0xFFFF9800), size: 18),
                          const SizedBox(width: 10),
                          Text(
                            '${_requests.length} request${_requests.length > 1 ? 's' : ''} waiting for assignment',
                            style: const TextStyle(color: Color(0xFFFF9800), fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => Navigator.pushNamed(context, '/assign').then((_) => _load()),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppTheme.gold.withOpacity(0.15),
                                border: Border.all(color: AppTheme.gold.withOpacity(0.4)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text('Assign Now', style: TextStyle(color: AppTheme.gold, fontSize: 12, fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _load,
                        color: AppTheme.gold,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _requests.length,
                          itemBuilder: (_, i) => _buildTile(_requests[i]),
                        ),
                      ),
                    ),
                  ],
                ),
      floatingActionButton: _requests.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.pushNamed(context, '/assign').then((_) => _load()),
              backgroundColor: AppTheme.gold,
              foregroundColor: Colors.black,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Run Assignment', style: TextStyle(fontWeight: FontWeight.w700)),
            )
          : null,
    );
  }

  Widget _buildTile(BookingRequest req) {
    final color = RoomTypeConfig.colors[req.roomType.name] ?? AppTheme.gold;
    final icon = RoomTypeConfig.icons[req.roomType.name] ?? Icons.bed;
    final isVip = req.priority == Priority.vip;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        border: Border.all(color: isVip ? AppTheme.gold.withOpacity(0.4) : AppTheme.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(req.guestName, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 15)),
                    if (isVip) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.gold.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('VIP', style: TextStyle(color: AppTheme.gold, fontSize: 10, fontWeight: FontWeight.w900)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${req.roomType.name[0].toUpperCase()}${req.roomType.name.substring(1)} room',
                  style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
                ),
                Text(
                  '${_fmt(req.checkIn)} → ${_fmt(req.checkOut)}  ·  ${req.nights} nights',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFF9800).withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text('Pending', style: TextStyle(color: Color(0xFFFF9800), fontSize: 11, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}