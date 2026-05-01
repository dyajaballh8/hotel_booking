// ─── new_booking_screen.dart ───────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_app/core/theme/theme.dart';
import 'package:flutter_app/services/api_services.dart';
import '../models/models.dart';

class NewBookingScreen extends StatefulWidget {
  const NewBookingScreen({super.key});

  @override
  State<NewBookingScreen> createState() => _NewBookingScreenState();
}

class _NewBookingScreenState extends State<NewBookingScreen> {
  final _api = ApiService();
  final _formKey = GlobalKey<FormState>();

  // Form fields
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  RoomType _roomType = RoomType.single;
  Priority _priority = Priority.normal;
  DateTime _checkIn = DateTime.now().add(const Duration(days: 1));
  DateTime _checkOut = DateTime.now().add(const Duration(days: 3));
  bool _submitting = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isCheckIn) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isCheckIn ? _checkIn : _checkOut,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: AppTheme.gold),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (isCheckIn) {
        _checkIn = picked;
        if (_checkOut.isBefore(_checkIn.add(const Duration(days: 1)))) {
          _checkOut = _checkIn.add(const Duration(days: 1));
        }
      } else {
        _checkOut = picked;
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_checkOut.isAfter(_checkIn)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Check-out must be after check-in'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      // Create guest first
      final guest = await _api.createGuest(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        priority: _priority,
      );

      // Submit booking request
      final req = BookingRequest(
        guestId: guest.guestId,
        guestName: guest.name,
        roomType: _roomType,
        checkIn: _checkIn,
        checkOut: _checkOut,
        priority: _priority,
        nights: _checkOut.difference(_checkIn).inDays,
      );
      await _api.submitRequest(req);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Request submitted! Run assignment to confirm.'),
            backgroundColor: AppTheme.teal,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nights = _checkOut.difference(_checkIn).inDays;

    return Scaffold(
      appBar: AppBar(title: const Text('New Booking Request')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle('Guest Information'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameCtrl,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person, color: AppTheme.gold)),
                validator: (v) => v == null || v.trim().isEmpty ? 'Name required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailCtrl,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email, color: AppTheme.gold)),
                keyboardType: TextInputType.emailAddress,
                validator: (v) => v != null && v.contains('@') ? null : 'Valid email required',
              ),
              const SizedBox(height: 24),
              _sectionTitle('Priority'),
              const SizedBox(height: 12),
              Row(
                children: Priority.values.map((p) {
                  final selected = _priority == p;
                  final color = p == Priority.vip ? AppTheme.gold : AppTheme.teal;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: GestureDetector(
                      onTap: () => setState(() => _priority = p),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: selected ? color.withOpacity(0.15) : AppTheme.card,
                          border: Border.all(color: selected ? color : AppTheme.border, width: selected ? 1.5 : 1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(p == Priority.vip ? Icons.star : Icons.person_outline, color: selected ? color : AppTheme.textSecondary, size: 16),
                            const SizedBox(width: 6),
                            Text(p.name.toUpperCase(), style: TextStyle(color: selected ? color : AppTheme.textSecondary, fontWeight: FontWeight.w700, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              _sectionTitle('Room Type'),
              const SizedBox(height: 12),
              ...RoomType.values.map((rt) {
                final selected = _roomType == rt;
                final color = RoomTypeConfig.colors[rt.name] ?? AppTheme.gold;
                final icon = RoomTypeConfig.icons[rt.name] ?? Icons.bed;
                const prices = {'single': 80, 'double': 140, 'suite': 280};
                return GestureDetector(
                  onTap: () => setState(() => _roomType = rt),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: selected ? color.withOpacity(0.08) : AppTheme.card,
                      border: Border.all(color: selected ? color : AppTheme.border, width: selected ? 1.5 : 1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(icon, color: color, size: 24),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(rt.name[0].toUpperCase() + rt.name.substring(1), style: TextStyle(color: selected ? color : AppTheme.textPrimary, fontWeight: FontWeight.w700)),
                              Text('\$${prices[rt.name]}/night', style: TextStyle(color: color.withOpacity(0.7), fontSize: 12)),
                            ],
                          ),
                        ),
                        if (selected) Icon(Icons.check_circle, color: color, size: 20),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 24),
              _sectionTitle('Dates'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _DateButton(label: 'Check-in', date: _checkIn, onTap: () => _pickDate(true))),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Icon(Icons.arrow_forward, color: AppTheme.textSecondary, size: 18),
                  ),
                  Expanded(child: _DateButton(label: 'Check-out', date: _checkOut, onTap: () => _pickDate(false))),
                ],
              ),
              if (nights > 0)
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.teal.withOpacity(0.08),
                    border: Border.all(color: AppTheme.teal.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('$nights nights', style: const TextStyle(color: AppTheme.tealLight)),
                      Text(
                        'Est. total: \$${nights * (const {'single': 80, 'double': 140, 'suite': 280}[_roomType.name] ?? 0)}',
                        style: const TextStyle(color: AppTheme.tealLight, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      : const Text('Submit Booking Request'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) => Text(
        title,
        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
      );
}

class _DateButton extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;

  const _DateButton({required this.label, required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final fmt = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.card,
          border: Border.all(color: AppTheme.border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today, color: AppTheme.gold, size: 14),
                const SizedBox(width: 6),
                Text(fmt, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}