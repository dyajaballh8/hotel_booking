// ─── assignment_screen.dart ────────────────────────────────────────────────
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme.dart';

class AssignmentScreen extends StatefulWidget {
  const AssignmentScreen({super.key});

  @override
  State<AssignmentScreen> createState() => _AssignmentScreenState();
}

class _AssignmentScreenState extends State<AssignmentScreen> {
  final _api = ApiService();
  String _algorithm = 'backtracking';
  bool _running = false;
  AssignmentResult? _result;
  List<BookingRequest> _pending = [];

  @override
  void initState() {
    super.initState();
    _loadPending();
  }

  Future<void> _loadPending() async {
    try {
      final p = await _api.getPendingRequests();
      setState(() => _pending = p);
    } catch (_) {}
  }

  Future<void> _run() async {
    setState(() { _running = true; _result = null; });
    try {
      final result = await _api.runAssignment(algorithm: _algorithm);
      setState(() => _result = result);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Run Assignment Algorithm')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPendingBanner(),
            const SizedBox(height: 24),
            _buildAlgorithmPicker(),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (_running || _pending.isEmpty) ? null : _run,
                icon: _running
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                    : const Icon(Icons.play_arrow),
                label: Text(_running ? 'Running...' : 'Run Assignment'),
              ),
            ),
            if (_result != null) ...[
              const SizedBox(height: 28),
              _buildResult(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPendingBanner() {
    final count = _pending.length;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: count == 0 ? AppTheme.card : const Color(0xFFFF9800).withOpacity(0.08),
        border: Border.all(color: count == 0 ? AppTheme.border : const Color(0xFFFF9800).withOpacity(0.4)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(count == 0 ? Icons.check_circle : Icons.pending_actions,
              color: count == 0 ? AppTheme.teal : const Color(0xFFFF9800), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count == 0 ? 'No Pending Requests' : '$count Pending Request${count > 1 ? 's' : ''}',
                  style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700),
                ),
                Text(
                  count == 0 ? 'Submit booking requests first' : 'Ready to assign rooms',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          if (count > 0)
            TextButton(onPressed: _loadPending, child: const Text('Refresh', style: TextStyle(color: AppTheme.gold))),
        ],
      ),
    );
  }

  Widget _buildAlgorithmPicker() {
    final algos = [
      _AlgoInfo('backtracking', 'Backtracking', 'Guaranteed optimal — no conflicts', Icons.undo, AppTheme.gold),
      _AlgoInfo('greedy', 'Greedy', 'Fastest — first available room', Icons.flash_on, AppTheme.teal),
      _AlgoInfo('csp', 'CSP', 'Constraint-based — VIP aware', Icons.grid_on, const Color(0xFF9B6FD4)),
      _AlgoInfo('graph_coloring', 'Graph Coloring', 'DSatur — conflict visualization', Icons.bubble_chart, const Color(0xFF4A9FD4)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Choose Algorithm', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        ...algos.map((a) {
          final selected = _algorithm == a.id;
          return GestureDetector(
            onTap: () => setState(() => _algorithm = a.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: selected ? a.color.withOpacity(0.08) : AppTheme.card,
                border: Border.all(color: selected ? a.color : AppTheme.border, width: selected ? 1.5 : 1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(color: a.color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                    child: Icon(a.icon, color: a.color, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a.name, style: TextStyle(color: selected ? a.color : AppTheme.textPrimary, fontWeight: FontWeight.w700)),
                        Text(a.desc, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                  if (selected) Icon(Icons.check_circle, color: a.color, size: 20),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildResult() {
    final r = _result!;
    final allGood = r.totalUnassigned == 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(allGood ? Icons.check_circle : Icons.warning, color: allGood ? AppTheme.teal : Colors.orange),
            const SizedBox(width: 10),
            Text(
              allGood ? 'Assignment Complete!' : '${r.totalUnassigned} unassigned',
              style: TextStyle(color: allGood ? AppTheme.teal : Colors.orange, fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _resultChip('${r.totalAssigned} assigned', AppTheme.teal),
            const SizedBox(width: 10),
            _resultChip('${r.totalUnassigned} unassigned', Colors.orange),
            const SizedBox(width: 10),
            _resultChip(r.algorithm, AppTheme.gold),
          ],
        ),
        const SizedBox(height: 16),
        if (r.bookings.isNotEmpty) ...[
          const Text('Assignments', style: TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          ...r.bookings.map(_buildBookingTile),
        ],
        if (r.unassigned.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text('Unassigned Requests', style: TextStyle(color: Colors.orange, fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          ...r.unassigned.map(_buildUnassignedTile),
        ],
      ],
    );
  }

  Widget _buildBookingTile(Booking b) {
    final color = RoomTypeConfig.colors[b.room.roomType.name] ?? AppTheme.gold;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.card,
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
            child: Text(b.room.roomNumber, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 16)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(b.guest.name, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700)),
                    if (b.guest.priority == Priority.vip) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.star, color: AppTheme.gold, size: 14),
                    ],
                  ],
                ),
                Text('${_fmt(b.checkIn)} → ${_fmt(b.checkOut)} · ${b.nights}n · \$${b.totalPrice.toStringAsFixed(0)}',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: AppTheme.teal.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
            child: const Text('✓', style: TextStyle(color: AppTheme.teal, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildUnassignedTile(BookingRequest r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.card,
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber, color: Colors.orange, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.guestName, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700)),
                Text('${r.roomType.name} · ${_fmt(r.checkIn)} → ${_fmt(r.checkOut)}',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: Colors.orange.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
            child: const Text('No room', style: TextStyle(color: Colors.orange, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _resultChip(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      );

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

class _AlgoInfo {
  final String id, name, desc;
  final IconData icon;
  final Color color;
  const _AlgoInfo(this.id, this.name, this.desc, this.icon, this.color);
}
