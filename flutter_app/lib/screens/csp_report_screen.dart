// ─── csp_report_screen.dart ────────────────────────────────────────────────
// Displays the full CSP step-by-step report fetched from the Python backend.
// Shows 4 tabs: Initial Domains | AC-3 Pruning | Assignment Steps | Final State

import 'package:flutter/material.dart';
import '../models/csp_report_model.dart';
import '../services/api_service.dart';
import '../theme.dart';

class CspReportScreen extends StatefulWidget {
  const CspReportScreen({super.key});
  @override
  State<CspReportScreen> createState() => _CspReportScreenState();
}

class _CspReportScreenState extends State<CspReportScreen>
    with SingleTickerProviderStateMixin {
  final _api = ApiService();
  CspReport? _report;
  bool _loading = true;
  String? _error;
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final report = await _api.getCspReport();
      setState(() { _report = report; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        title: const Text('CSP — تقرير التوزيع التفصيلي'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
        bottom: _report == null
            ? null
            : TabBar(
                controller: _tabs,
                isScrollable: true,
                labelColor: AppTheme.gold,
                unselectedLabelColor: AppTheme.textSecondary,
                indicatorColor: AppTheme.gold,
                labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                tabs: const [
                  Tab(text: '1. المتغيرات'),
                  Tab(text: '2. AC-3 Pruning'),
                  Tab(text: '3. خطوات التوزيع'),
                  Tab(text: '4. الحالة النهائية'),
                ],
              ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.gold))
          : _error != null
              ? _buildError()
              : Column(
                  children: [
                    _buildSummaryBar(),
                    Expanded(
                      child: TabBarView(
                        controller: _tabs,
                        children: [
                          _buildStep1(),
                          _buildStep2(),
                          _buildStep3(),
                          _buildFinalState(),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  // ── Error ─────────────────────────────────────────────────────────────────

  Widget _buildError() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _load, child: const Text('إعادة المحاولة')),
          ],
        ),
      );

  // ── Summary Bar ───────────────────────────────────────────────────────────

  Widget _buildSummaryBar() {
    final s = _report!.summary;
    return Container(
      color: AppTheme.card,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _chip('${s.confirmed}/${s.totalRequests} مؤكد', AppTheme.teal),
          const SizedBox(width: 8),
          _chip('\$${s.totalRevenue.toStringAsFixed(0)}', AppTheme.gold),
          const SizedBox(width: 8),
          _chip('${s.conflictsFound} تعارض', s.conflictsFound == 0 ? AppTheme.teal : Colors.red),
          const SizedBox(width: 8),
          _chip('AC-3 ${s.ac3Consistent ? "✓" : "✗"}', s.ac3Consistent ? AppTheme.teal : Colors.red),
        ],
      ),
    );
  }

  Widget _chip(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          border: Border.all(color: color.withOpacity(0.4)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
      );

  // ── Step 1: Initial Domains ───────────────────────────────────────────────

  Widget _buildStep1() {
    final rows = _report!.step1InitialDomains;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionHeader(
          '1',
          'تعريف المتغيرات والـ Domain الأولي',
          'كل حجز = variable — domain = كل الغرف التي تطابق النوع المطلوب',
          const Color(0xFF185FA5),
        ),
        const SizedBox(height: 12),
        _tableCard(
          headers: ['#', 'الضيف', 'الأولوية', 'النوع', 'السعة', 'من', 'إلى', 'ليالي', 'Domain الأولي'],
          rows: rows.map((r) => [
            '#${r.requestId}',
            r.guestName,
            r.priority,
            r.roomType,
            '${r.capacity} فرد',
            r.checkIn,
            r.checkOut,
            '${r.nights}',
            r.initialDomain.join('، '),
          ]).toList(),
          highlightCol: 8,
          colColors: rows.map((r) => r.priority == 'vip' ? AppTheme.gold.withOpacity(0.06) : Colors.transparent).toList(),
        ),
      ],
    );
  }

  // ── Step 2: AC-3 ─────────────────────────────────────────────────────────

  Widget _buildStep2() {
    final rows = _report!.step2Ac3Pruning;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionHeader(
          '2',
          'AC-3 Arc Consistency — تقليص الـ Domain',
          'حذف القيم من الـ domain التي لا يوجد لها قيمة متوافقة في الـ domain المجاور',
          const Color(0xFF3C3489),
        ),
        const SizedBox(height: 12),
        ...rows.map((r) => _ac3Card(r)),
      ],
    );
  }

  Widget _ac3Card(Ac3Row r) {
    final hasPruning = r.prunedCount > 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.card,
        border: Border.all(color: hasPruning ? Colors.red.withOpacity(0.3) : AppTheme.border),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('#${r.requestId}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
              const SizedBox(width: 8),
              Text(r.guestName, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700)),
              const Spacer(),
              if (hasPruning)
                _statusBadge('حُذف ${r.prunedCount}', Colors.red)
              else
                _statusBadge('لا تغيير', AppTheme.teal),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _domainBlock('قبل', r.domainBefore, AppTheme.textSecondary)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Icon(Icons.arrow_forward, color: AppTheme.textSecondary, size: 14),
              ),
              Expanded(child: _domainBlock('بعد', r.domainAfter, AppTheme.tealLight)),
              if (hasPruning) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Icon(Icons.block, color: Colors.red, size: 14),
                ),
                Expanded(child: _domainBlock('محذوف', r.pruned, Colors.red)),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(r.reason, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _domainBlock(String label, List<String> rooms, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: color.withOpacity(0.7), fontSize: 10, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: rooms.map((r) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              border: Border.all(color: color.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(r, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
          )).toList(),
        ),
      ],
    );
  }

  // ── Step 3: Assignment Steps ──────────────────────────────────────────────

  Widget _buildStep3() {
    final steps = _report!.step3AssignmentSteps;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionHeader(
          '3',
          'CSP Search — خطوات التوزيع',
          'MRV: أقل domain أولاً — VIP يُقدَّم — Forward Checking بعد كل تعيين',
          const Color(0xFF27500A),
        ),
        const SizedBox(height: 12),
        ...steps.asMap().entries.map((e) => _stepCard(e.value, e.key)),
      ],
    );
  }

  Widget _stepCard(AssignmentStep s, int idx) {
    final typeColor = _typeColor(s.roomType);
    final isVip = s.priority == 'vip';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.card,
        border: Border.all(
          color: s.isAssigned
              ? (isVip ? AppTheme.gold.withOpacity(0.5) : AppTheme.teal.withOpacity(0.3))
              : Colors.red.withOpacity(0.3),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: (s.isAssigned ? AppTheme.teal : Colors.red).withOpacity(0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              border: Border(
                bottom: BorderSide(color: AppTheme.border),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: AppTheme.gold.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text('${s.step}', style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.w900, fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 10),
                Text(s.guestName, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 15)),
                if (isVip) ...[
                  const SizedBox(width: 6),
                  _statusBadge('⭐ VIP', AppTheme.gold),
                ],
                const Spacer(),
                _statusBadge(
                  s.isAssigned ? '✓ ${s.assignedRoom}' : '✗ لا غرفة',
                  s.isAssigned ? AppTheme.teal : Colors.red,
                ),
              ],
            ),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info row
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _infoChip('النوع', s.roomType, typeColor),
                    _infoChip('السعة', '${s.capacity} فرد', AppTheme.textSecondary),
                    _infoChip('الدخول', s.checkIn, AppTheme.textSecondary),
                    _infoChip('الخروج', s.checkOut, AppTheme.textSecondary),
                    _infoChip('الليالي', '${s.nights}', AppTheme.textSecondary),
                  ],
                ),
                const SizedBox(height: 12),
                // Tried rooms
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('جُربت: ', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    Expanded(
                      child: Wrap(
                        spacing: 4,
                        children: s.triedRooms.map((room) {
                          final rejected = s.rejectedRooms.contains(room);
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: rejected ? Colors.red.withOpacity(0.1) : AppTheme.teal.withOpacity(0.1),
                              border: Border.all(
                                color: rejected ? Colors.red.withOpacity(0.4) : AppTheme.teal.withOpacity(0.4),
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              room,
                              style: TextStyle(
                                color: rejected ? Colors.red : AppTheme.tealLight,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                decoration: rejected ? TextDecoration.lineThrough : null,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Reason
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.card.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, size: 14, color: AppTheme.gold.withOpacity(0.7)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(s.reason, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(String label, String value, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.card,
          border: Border.all(color: AppTheme.border),
          borderRadius: BorderRadius.circular(6),
        ),
        child: RichText(
          text: TextSpan(
            children: [
              TextSpan(text: '$label: ', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
              TextSpan(text: value, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      );

  // ── Step 4: Final State ───────────────────────────────────────────────────

  Widget _buildFinalState() {
    final rows = _report!.finalState;
    final checks = _report!.constraintChecks;
    final s = _report!.summary;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionHeader('4', 'الحالة النهائية — Final State',
            'ملخص كامل للتوزيع + التحقق من القيود', const Color(0xFF633806)),
        const SizedBox(height: 12),
        // Metric cards
        Row(
          children: [
            _metricCard('مؤكد', '${s.confirmed}', AppTheme.teal),
            const SizedBox(width: 10),
            _metricCard('غير مؤكد', '${s.unassigned}', s.unassigned == 0 ? AppTheme.textSecondary : Colors.red),
            const SizedBox(width: 10),
            _metricCard('الإيرادات', '\$${s.totalRevenue.toStringAsFixed(0)}', AppTheme.gold),
            const SizedBox(width: 10),
            _metricCard('الليالي', '${s.totalNights}', const Color(0xFF9B6FD4)),
          ],
        ),
        const SizedBox(height: 16),
        // Final table
        ...rows.map((r) => _finalRow(r)),
        const SizedBox(height: 20),
        // Constraint checks
        _constraintSection(checks),
      ],
    );
  }

  Widget _metricCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _finalRow(FinalStateRow r) {
    final typeColor = _typeColor(r.roomType);
    final isVip = r.priority == 'vip';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.card,
        border: Border.all(
          color: r.isConfirmed
              ? (isVip ? AppTheme.gold.withOpacity(0.4) : typeColor.withOpacity(0.25))
              : Colors.red.withOpacity(0.3),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Room number badge
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(
              color: typeColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                r.assignedRoom ?? '—',
                style: TextStyle(color: typeColor, fontWeight: FontWeight.w900, fontSize: r.assignedRoom != null ? 16 : 20),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(r.guestName, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
                    if (isVip) ...[
                      const SizedBox(width: 5),
                      const Icon(Icons.star, color: AppTheme.gold, size: 13),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${_typeArabic(r.roomType)} · السعة: ${r.capacity} · الطابق ${r.floor ?? "—"}',
                  style: TextStyle(color: typeColor.withOpacity(0.8), fontSize: 12),
                ),
                Text(
                  '${r.checkIn} → ${r.checkOut} · ${r.nights} ليالي · \$${r.totalPrice.toStringAsFixed(0)}',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
          _statusBadge(
            r.isConfirmed ? '✓ مؤكد' : '✗ لا يوجد',
            r.isConfirmed ? AppTheme.teal : Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _constraintSection(List<ConstraintCheck> checks) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('التحقق من القيود', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        ...checks.map((c) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.card,
            border: Border.all(
              color: c.passed ? AppTheme.teal.withOpacity(0.3) : Colors.red.withOpacity(0.3),
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(c.passed ? Icons.check_circle : Icons.cancel,
                  color: c.passed ? AppTheme.teal : Colors.red, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.constraint, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 13)),
                    Text(c.description, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (c.passed ? AppTheme.teal : Colors.red).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(c.detail,
                    style: TextStyle(
                      color: c.passed ? AppTheme.tealLight : Colors.red,
                      fontSize: 11, fontWeight: FontWeight.w600,
                    )),
              ),
            ],
          ),
        )),
      ],
    );
  }

  // ── Shared Widgets ────────────────────────────────────────────────────────

  Widget _sectionHeader(String num, String title, String subtitle, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.4)),
          ),
          child: Center(
            child: Text(num, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 14)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
              Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tableCard({
    required List<String> headers,
    required List<List<String>> rows,
    int? highlightCol,
    List<Color>? colColors,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.card,
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.hardEdge,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(AppTheme.card),
          dataRowColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) return AppTheme.card;
            return Colors.transparent;
          }),
          headingTextStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w700),
          dataTextStyle: const TextStyle(color: AppTheme.textPrimary, fontSize: 12),
          columnSpacing: 16,
          dividerThickness: 0.5,
          columns: headers.map((h) => DataColumn(label: Text(h))).toList(),
          rows: rows.asMap().entries.map((entry) {
            final i = entry.key;
            final row = entry.value;
            final bg = colColors != null && i < colColors.length ? colColors[i] : Colors.transparent;
            return DataRow(
              color: WidgetStateProperty.all(bg),
              cells: row.asMap().entries.map((ce) {
                final isHL = highlightCol != null && ce.key == highlightCol;
                return DataCell(Text(
                  ce.value,
                  style: TextStyle(
                    color: isHL ? AppTheme.tealLight : AppTheme.textPrimary,
                    fontWeight: isHL ? FontWeight.w700 : FontWeight.w400,
                    fontSize: 12,
                  ),
                ));
              }).toList(),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _statusBadge(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
      );

  Color _typeColor(String t) => switch (t) {
        'single' => const Color(0xFF4A9FD4),
        'double' => AppTheme.teal,
        'suite'  => AppTheme.gold,
        _        => AppTheme.textSecondary,
      };

  String _typeArabic(String t) => switch (t) {
        'single' => 'غرفة فردية',
        'double' => 'غرفة مزدوجة',
        'suite'  => 'جناح',
        _        => t,
      };
}
