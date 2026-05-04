import 'package:flutter/material.dart';
import '../theme.dart';

class PendingScreen extends StatelessWidget {
  const PendingScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الطلبات المعلقة')),
      body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.check_circle_outline, color: AppTheme.teal, size: 56),
        const SizedBox(height: 16),
        const Text('لا يوجد طلبات معلقة', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        const Text('CSP يؤكد الحجوزات فوراً بدون طلبات معلقة', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () => Navigator.pushNamed(context, '/new_booking'),
          icon: const Icon(Icons.add), label: const Text('حجز جديد عبر CSP')),
      ])),
    );
  }
}
