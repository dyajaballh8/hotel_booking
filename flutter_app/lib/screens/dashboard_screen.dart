// ─── dashboard_screen.dart ─────────────────────────────────────────────────
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _api = ApiService();
  DashboardStats? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final stats = await _api.getDashboard();
      setState(() { _stats = stats; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connection error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        title: const Text('🏨  Hotel Dashboard'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.gold))
          : _stats == null
              ? const Center(child: Text('Failed to load', style: TextStyle(color: AppTheme.textSecondary)))
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppTheme.gold,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatGrid(),
                        const SizedBox(height: 24),
                        _buildRoomTypeBreakdown(),
                        const SizedBox(height: 24),
                        _buildQuickActions(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildStatGrid() {
    final stats = _stats!;
    final items = [
      _StatItem('Total Rooms', stats.totalRooms.toString(), Icons.meeting_room, AppTheme.gold),
      _StatItem('Bookings', stats.totalBookings.toString(), Icons.book_online, AppTheme.teal),
      _StatItem('Active Stays', stats.activeStays.toString(), Icons.person, const Color(0xFF9B6FD4)),
      _StatItem('Revenue', '\$${stats.totalRevenue.toStringAsFixed(0)}', Icons.attach_money, const Color(0xFF4CAF50)),
      _StatItem('Pending', stats.pendingRequests.toString(), Icons.pending_actions, const Color(0xFFFF9800)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Overview', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.6,
          children: items.map(_buildStatCard).toList(),
        ),
      ],
    );
  }

  Widget _buildStatCard(_StatItem item) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: item.color.withOpacity(0.3)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(item.icon, color: item.color, size: 22),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.value, style: TextStyle(color: item.color, fontSize: 24, fontWeight: FontWeight.w900)),
              Text(item.label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoomTypeBreakdown() {
    final byType = _stats!.roomsByType;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Rooms by Type', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        ...byType.entries.map((e) {
          final color = RoomTypeConfig.colors[e.key] ?? AppTheme.gold;
          final icon = RoomTypeConfig.icons[e.key] ?? Icons.bed;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.card,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 12),
                Text(e.key.toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13)),
                const Spacer(),
                Text('${e.value} rooms', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quick Actions', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                label: 'New Booking',
                icon: Icons.add,
                color: AppTheme.gold,
                onTap: () => Navigator.pushNamed(context, '/new_booking').then((_) => _load()),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionButton(
                label: 'Run Algorithm',
                icon: Icons.play_arrow,
                color: AppTheme.teal,
                onTap: () => Navigator.pushNamed(context, '/assign').then((_) => _load()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                label: 'All Bookings',
                icon: Icons.list_alt,
                color: const Color(0xFF9B6FD4),
                onTap: () => Navigator.pushNamed(context, '/bookings'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionButton(
                label: 'Pending',
                icon: Icons.pending_actions,
                color: const Color(0xFFFF9800),
                onTap: () => Navigator.pushNamed(context, '/pending'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: _ActionButton(
            label: 'CSP — تقرير التوزيع التفصيلي',
            icon: Icons.table_chart,
            color: const Color(0xFF4A9FD4),
            onTap: () => Navigator.pushNamed(context, '/csp_report'),
          ),
        ),
      ],
    );
  }
}

class _StatItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatItem(this.label, this.value, this.icon, this.color);
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          border: Border.all(color: color.withOpacity(0.4)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
