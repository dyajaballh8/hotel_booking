import 'package:flutter/material.dart';
import '../theme.dart';

class AssignmentScreen extends StatelessWidget {
  const AssignmentScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('التوزيع')),
      body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.auto_awesome, color: AppTheme.gold, size: 56),
        const SizedBox(height: 16),
        const Text('CSP يعمل تلقائياً', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        const Text('كل حجز يتأكد فوراً عبر CSP\nلا حاجة لتشغيل التوزيع يدوياً',
            textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () => Navigator.pushNamed(context, '/new_booking'),
          icon: const Icon(Icons.add), label: const Text('حجز جديد')),
      ])),
    );
  }
}
