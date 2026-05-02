// ─── main.dart ─────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'theme.dart';
import 'screens/dashboard_screen.dart';
import 'screens/new_booking_screen.dart';
import 'screens/assignment_screen.dart';
import 'screens/bookings_screen.dart';
import 'screens/rooms_screen.dart';
import 'screens/pending_screen.dart';
import 'screens/csp_report_screen.dart';

void main() {
  runApp(const HotelBookingApp());
}

class HotelBookingApp extends StatelessWidget {
  const HotelBookingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hotel Booking',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      initialRoute: '/',
      routes: {
        '/':            (_) => const MainShell(),
        '/new_booking': (_) => const NewBookingScreen(),
        '/assign':      (_) => const AssignmentScreen(),
        '/bookings':    (_) => const BookingsScreen(),
        '/pending':     (_) => const PendingScreen(),
        '/rooms':       (_) => const RoomsScreen(),
        '/csp_report':  (_) => const CspReportScreen(),
      },
    );
  }
}

// ── Bottom Nav Shell ───────────────────────────────────────────────────────

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  final _screens = const [
    DashboardScreen(),
    BookingsScreen(),
    RoomsScreen(),
  ];

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
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
            BottomNavigationBarItem(icon: Icon(Icons.book_online), label: 'Bookings'),
            BottomNavigationBarItem(icon: Icon(Icons.meeting_room), label: 'Rooms'),
          ],
        ),
      ),
      floatingActionButton: _index == 0
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.pushNamed(context, '/new_booking'),
              backgroundColor: AppTheme.gold,
              foregroundColor: Colors.black,
              icon: const Icon(Icons.add),
              label: const Text('New Booking', style: TextStyle(fontWeight: FontWeight.w700)),
            )
          : null,
    );
  }
}
