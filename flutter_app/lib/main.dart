import 'package:flutter/material.dart';
import 'theme.dart';
import 'screens/dashboard_screen.dart';
import 'screens/new_booking_screen.dart';
import 'screens/bookings_screen.dart';
import 'screens/rooms_screen.dart';
import 'screens/csp_report_screen.dart';
import 'screens/pending_screen.dart';
import 'screens/assignment_screen.dart';

void main() => runApp(const HotelBookingApp());

class HotelBookingApp extends StatelessWidget {
  const HotelBookingApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hotel Booking — CSP',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      initialRoute: '/',
      routes: {
        '/': (_) => const MainShell(),
        '/new_booking': (_) => const NewBookingScreen(),
        '/bookings': (_) => const BookingsScreen(),
        '/rooms': (_) => const RoomsScreen(),
        '/csp_report': (_) => const CspTableScreen(),
        '/pending': (_) => const PendingScreen(),
        '/assign': (_) => const AssignmentScreen(),
      },
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  final _screens = const [DashboardScreen(), BookingsScreen(), RoomsScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppTheme.border)),
        ),
        child: BottomNavigationBar(
          currentIndex: _index,
          onTap: (i) => setState(() => _index = i),
          backgroundColor: AppTheme.bgDark,
          selectedItemColor: AppTheme.gold,
          unselectedItemColor: AppTheme.textSecondary,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              label: 'الرئيسية',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.list_alt),
              label: 'الجدول',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.meeting_room),
              label: 'الغرف',
            ),
          ],
        ),
      ),
    );
  }
}
