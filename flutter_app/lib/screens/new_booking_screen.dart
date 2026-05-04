// ─── new_booking_screen.dart ───────────────────────────────────────────────
// CSP-powered booking form. Shows full CSP trace after submission.

import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme.dart';

class NewBookingScreen extends StatefulWidget {
  const NewBookingScreen({super.key});
  @override State<NewBookingScreen> createState() => _NewBookingScreenState();
}

class _NewBookingScreenState extends State<NewBookingScreen> {
  final _api = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  RoomType _roomType = RoomType.single;
  Priority _priority = Priority.normal;
  DateTime _checkIn  = DateTime.now().add(const Duration(days: 1));
  DateTime _checkOut = DateTime.now().add(const Duration(days: 3));
  bool _submitting = false;
  BookResult? _result;

  @override
  void dispose() { _nameCtrl.dispose(); _emailCtrl.dispose(); super.dispose(); }

  Future<void> _pickDate(bool isCheckIn) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isCheckIn ? _checkIn : _checkOut,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: AppTheme.gold)),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (isCheckIn) {
        _checkIn = picked;
        if (!_checkOut.isAfter(_checkIn)) _checkOut = _checkIn.add(const Duration(days: 1));
      } else {
        _checkOut = picked;
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _submitting = true; _result = null; });
    try {
      final result = await _api.bookWithCsp(
        guestName: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        roomType: _roomType.name,
        checkIn: _checkIn, checkOut: _checkOut,
        priority: _priority.name,
      );
      setState(() { _result = result; _submitting = false; });
    } catch (e) {
      setState(() => _submitting = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('حجز جديد — CSP')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _label('بيانات الضيف'),
            const SizedBox(height: 10),
            TextFormField(controller: _nameCtrl,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(labelText: 'الاسم', prefixIcon: Icon(Icons.person, color: AppTheme.gold)),
              validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null),
            const SizedBox(height: 12),
            TextFormField(controller: _emailCtrl,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(labelText: 'البريد الإلكتروني', prefixIcon: Icon(Icons.email, color: AppTheme.gold)),
              keyboardType: TextInputType.emailAddress,
              validator: (v) => v != null && v.contains('@') ? null : 'بريد غير صحيح'),
            const SizedBox(height: 20),
            _label('الأولوية'),
            const SizedBox(height: 10),
            Row(children: Priority.values.map((p) {
              final sel = _priority == p;
              final color = p == Priority.vip ? AppTheme.gold : AppTheme.teal;
              return Padding(padding: const EdgeInsets.only(right: 10),
                child: GestureDetector(onTap: () => setState(() => _priority = p),
                  child: AnimatedContainer(duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: sel ? color.withOpacity(0.15) : AppTheme.card,
                      border: Border.all(color: sel ? color : AppTheme.border, width: sel ? 1.5 : 1),
                      borderRadius: BorderRadius.circular(10)),
                    child: Row(children: [
                      Icon(p == Priority.vip ? Icons.star : Icons.person_outline,
                          color: sel ? color : AppTheme.textSecondary, size: 16),
                      const SizedBox(width: 6),
                      Text(p.name.toUpperCase(),
                          style: TextStyle(color: sel ? color : AppTheme.textSecondary,
                              fontWeight: FontWeight.w700, fontSize: 13)),
                    ]))));
            }).toList()),
            const SizedBox(height: 20),
            _label('نوع الغرفة'),
            const SizedBox(height: 10),
            ...RoomType.values.map((rt) {
              final sel = _roomType == rt;
              final color = RoomTypeConfig.colors[rt.name] ?? AppTheme.gold;
              final icon  = RoomTypeConfig.icons[rt.name]  ?? Icons.bed;
              const prices = {'single': 80, 'double': 140, 'suite': 280};
              return GestureDetector(onTap: () => setState(() => _roomType = rt),
                child: AnimatedContainer(duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: sel ? color.withOpacity(0.08) : AppTheme.card,
                    border: Border.all(color: sel ? color : AppTheme.border, width: sel ? 1.5 : 1),
                    borderRadius: BorderRadius.circular(12)),
                  child: Row(children: [
                    Icon(icon, color: color, size: 22),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(rt.name[0].toUpperCase() + rt.name.substring(1),
                          style: TextStyle(color: sel ? color : AppTheme.textPrimary, fontWeight: FontWeight.w700)),
                      Text('\$${prices[rt.name]}/ليلة',
                          style: TextStyle(color: color.withOpacity(0.7), fontSize: 12)),
                    ])),
                    if (sel) Icon(Icons.check_circle, color: color, size: 20),
                  ])));
            }),
            const SizedBox(height: 20),
            _label('التواريخ'),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _DateButton(label: 'الدخول', date: _checkIn, onTap: () => _pickDate(true))),
              const Padding(padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Icon(Icons.arrow_forward, color: AppTheme.textSecondary, size: 18)),
              Expanded(child: _DateButton(label: 'الخروج', date: _checkOut, onTap: () => _pickDate(false))),
            ]),
            const SizedBox(height: 8),
            _nightsSummary(),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                    : const Text('تأكيد الحجز عبر CSP ✓'),
              )),
          ])),
          if (_result != null) ...[
            const SizedBox(height: 24),
            _CspResultWidget(result: _result!),
          ],
        ]),
      ),
    );
  }

  Widget _label(String t) => Text(t,
      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w700));

  Widget _nightsSummary() {
    final n = _checkOut.difference(_checkIn).inDays;
    if (n <= 0) return const SizedBox();
    const prices = {'single': 80, 'double': 140, 'suite': 280};
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.teal.withOpacity(0.08),
        border: Border.all(color: AppTheme.teal.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(10)),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('$n ليالي', style: const TextStyle(color: AppTheme.tealLight)),
        Text('التقدير: \$${n * (prices[_roomType.name] ?? 0)}',
            style: const TextStyle(color: AppTheme.tealLight, fontWeight: FontWeight.w700)),
      ]));
  }
}

// ── CSP Result Widget ─────────────────────────────────────────────────────

class _CspResultWidget extends StatelessWidget {
  final BookResult result;
  const _CspResultWidget({required this.result});

  @override
  Widget build(BuildContext context) {
    final csp = result.cspResult;
    final ok  = csp.isConfirmed;
    final color = ok ? AppTheme.teal : Colors.red;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Status banner
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          border: Border.all(color: color.withOpacity(0.4)),
          borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          Icon(ok ? Icons.check_circle : Icons.cancel, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(ok ? '✅ تم تأكيد الحجز' : '❌ تم رفض الحجز',
                style: TextStyle(color: color, fontSize: 17, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(csp.reason, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          ])),
        ])),
      // Booking details if confirmed
      if (ok && result.booking != null) ...[
        const SizedBox(height: 12),
        _bookingCard(result.booking!),
      ],
      const SizedBox(height: 16),
      // CSP trace
      const Text('تتبع قرار CSP', style: TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      ...csp.constraintLog.map((log) => _constraintRow(log)),
    ]);
  }

  Widget _bookingCard(Booking b) {
    final color = RoomTypeConfig.colors[b.room.roomType.name] ?? AppTheme.gold;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        border: Border.all(color: color.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Container(width: 50, height: 50,
          decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
          child: Center(child: Text(b.room.roomNumber,
              style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 18)))),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(b.guest.name, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700)),
          Text('${b.room.typeLabel} · طابق ${b.room.floor} · ${b.nights} ليالي',
              style: TextStyle(color: color.withOpacity(0.8), fontSize: 12)),
          Text('${_fmt(b.checkIn)} → ${_fmt(b.checkOut)} · \$${b.totalPrice.toStringAsFixed(0)}',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
        ])),
        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: AppTheme.teal.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
          child: Text('#${b.bookingId}', style: const TextStyle(color: AppTheme.tealLight, fontSize: 11, fontWeight: FontWeight.w700))),
      ]));
  }

  Widget _constraintRow(CspConstraintLog log) {
    final color = log.passed ? AppTheme.teal : Colors.red;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.card,
        border: Border.all(color: color.withOpacity(0.25)),
        borderRadius: BorderRadius.circular(10)),
      child: Row(children: [
        Container(width: 36, height: 36,
          decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
          child: Center(child: Text(log.room,
              style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 13)))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('غرفة ${log.room} · طابق ${log.floor} · \$${log.pricePerNight.toStringAsFixed(0)}/ليلة',
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
          Text(log.reason, style: TextStyle(color: color.withOpacity(0.8), fontSize: 11)),
        ])),
        Icon(log.passed ? Icons.check_circle : Icons.cancel, color: color, size: 18),
      ]));
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
}

class _DateButton extends StatelessWidget {
  final String label; final DateTime date; final VoidCallback onTap;
  const _DateButton({required this.label, required this.date, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final fmt = '${date.year}-${date.month.toString().padLeft(2,'0')}-${date.day.toString().padLeft(2,'0')}';
    return GestureDetector(onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(color: AppTheme.card,
          border: Border.all(color: AppTheme.border), borderRadius: BorderRadius.circular(10)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.calendar_today, color: AppTheme.gold, size: 14),
            const SizedBox(width: 6),
            Text(fmt, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
          ]),
        ])));
  }
}
