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
      final s = await _api.getDashboard();
      setState(() {
        _stats = s;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تعذر الاتصال: $e'),
            backgroundColor: Colors.red,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        title: const Text('🏨  لوحة التحكم'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.gold))
          : _stats == null
          ? const Center(
              child: Text(
                'فشل التحميل',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              color: AppTheme.gold,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _statGrid(),
                    const SizedBox(height: 24),
                    _roomTypeBreakdown(),
                    const SizedBox(height: 24),
                    _quickActions(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _statGrid() {
    final s = _stats!;
    final items = [
      _Stat(
        'الغرف',
        s.totalRooms.toString(),
        Icons.meeting_room,
        AppTheme.gold,
      ),
      _Stat(
        'الحجوزات',
        s.totalBookings.toString(),
        Icons.book_online,
        AppTheme.teal,
      ),
      _Stat(
        'نزلاء الآن',
        s.activeStays.toString(),
        Icons.person,
        const Color(0xFF9B6FD4),
      ),
      _Stat(
        'الإيرادات',
        '\$${s.totalRevenue.toStringAsFixed(0)}',
        Icons.attach_money,
        const Color(0xFF4CAF50),
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'نظرة عامة',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.3,
          children: items.map((s) => _statCard(s)).toList(),
        ),
      ],
    );
  }

  Widget _statCard(_Stat s) => Container(
    decoration: BoxDecoration(
      color: AppTheme.card,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: s.color.withOpacity(0.3)),
    ),
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Icon(s.icon, color: s.color, size: 22),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.value,
              style: TextStyle(
                color: s.color,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              s.label,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _roomTypeBreakdown() {
    final byType = _stats!.roomsByType;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'الغرف حسب النوع',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
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
                Text(
                  e.key.toUpperCase(),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                Text(
                  '${e.value} غرف',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _quickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'إجراءات سريعة',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ActionBtn(
                'حجز جديد',
                Icons.add,
                AppTheme.gold,
                () => Navigator.pushNamed(
                  context,
                  '/new_booking',
                ).then((_) => _load()),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionBtn(
                'الجدول',
                Icons.list_alt,
                AppTheme.teal,
                () => Navigator.pushNamed(context, '/bookings'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ActionBtn(
                'الغرف',
                Icons.meeting_room,
                const Color(0xFF4A9FD4),
                () => Navigator.pushNamed(context, '/rooms'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionBtn(
                'تقرير CSP',
                Icons.analytics,
                const Color(0xFF9B6FD4),
                () => Navigator.pushNamed(context, '/csp_report'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _ActionBtn(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) => InkWell(
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
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    ),
  );
}

class _Stat {
  final String label, value;
  final IconData icon;
  final Color color;
  const _Stat(this.label, this.value, this.icon, this.color);
}
