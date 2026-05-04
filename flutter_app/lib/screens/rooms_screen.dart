import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme.dart';

class RoomsScreen extends StatefulWidget {
  const RoomsScreen({super.key});
  @override
  State<RoomsScreen> createState() => _RoomsScreenState();
}

class _RoomsScreenState extends State<RoomsScreen>
    with SingleTickerProviderStateMixin {
  final _api = ApiService();
  List<Room> _rooms = [];
  bool _loading = true;
  String _filterType = 'all';
  String _filterAvail = 'all';
  DateTime _checkIn = DateTime.now();
  DateTime _checkOut = DateTime.now().add(const Duration(days: 1));
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final rooms = _tabs.index == 0
          ? await _api.getRoomsWithStatus(_checkIn, _checkOut)
          : await _api.getRoomsAllBookings();
      setState(() {
        _rooms = rooms;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _pickDate(bool isIn) async {
    final p = await showDatePicker(
      context: context,
      initialDate: isIn ? _checkIn : _checkOut,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: AppTheme.gold),
        ),
        child: child!,
      ),
    );
    if (p == null) return;
    setState(() {
      if (isIn) {
        _checkIn = p;
        if (!_checkOut.isAfter(_checkIn))
          _checkOut = _checkIn.add(const Duration(days: 1));
      } else
        _checkOut = p;
    });
    _load();
  }

  List<Room> get _filtered {
    var r = _rooms;
    if (_filterType != 'all')
      r = r.where((x) => x.roomType.name == _filterType).toList();
    if (_filterAvail == 'available') r = r.where((x) => x.isAvailable).toList();
    if (_filterAvail == 'occupied') r = r.where((x) => !x.isAvailable).toList();
    return r;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الغرف'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
        bottom: TabBar(
          controller: _tabs,
          onTap: (_) => _load(),
          labelColor: AppTheme.gold,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.gold,
          tabs: const [
            Tab(text: '🟢 التوافر'),
            Tab(text: '📋 جدول الحجوزات'),
          ],
        ),
      ),
      body: TabBarView(controller: _tabs, children: [_availTab(), _tableTab()]),
    );
  }

  Widget _availTab() => Column(
    children: [
      _dateBar(),
      _filterBar(),
      Expanded(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.gold),
              )
            : RefreshIndicator(
                onRefresh: _load,
                color: AppTheme.gold,
                child: GridView.builder(
                  padding: const EdgeInsets.all(14),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: .9,
                  ),
                  itemCount: _filtered.length,
                  itemBuilder: (_, i) => _roomCard(_filtered[i]),
                ),
              ),
      ),
    ],
  );

  Widget _dateBar() => Container(
    color: AppTheme.card,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    child: Row(
      children: [
        Expanded(child: _dateBtn('الدخول', _checkIn, () => _pickDate(true))),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Icon(
            Icons.arrow_forward,
            color: AppTheme.textSecondary,
            size: 16,
          ),
        ),
        Expanded(child: _dateBtn('الخروج', _checkOut, () => _pickDate(false))),
      ],
    ),
  );

  Widget _dateBtn(String label, DateTime d, VoidCallback onTap) {
    final fmt =
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.card2,
          border: Border.all(color: AppTheme.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: AppTheme.gold, size: 13),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 10,
                  ),
                ),
                Text(
                  fmt,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterBar() => Container(
    color: AppTheme.bgDark,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _fchip('all', 'الكل', AppTheme.gold, true),
          _fchip('single', 'Single', const Color(0xFF4A9FD4), true),
          _fchip('double', 'Double', AppTheme.teal, true),
          _fchip('suite', 'Suite', AppTheme.gold, true),
          const SizedBox(width: 12),
          _fchip('all', 'الكل', AppTheme.textSecondary, false),
          _fchip('available', '🟢 متاحة', AppTheme.teal, false),
          _fchip('occupied', '🔴 مشغولة', Colors.red, false),
        ],
      ),
    ),
  );

  Widget _fchip(String val, String label, Color color, bool isType) {
    final cur = isType ? _filterType : _filterAvail;
    final active = cur == val;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: () => setState(() {
          if (isType)
            _filterType = val;
          else
            _filterAvail = val;
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: active ? color.withOpacity(0.15) : AppTheme.card,
            border: Border.all(color: active ? color : AppTheme.border),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: active ? color : AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _roomCard(Room room) {
    final color = RoomTypeConfig.colors[room.roomType.name] ?? AppTheme.gold;
    final icon = RoomTypeConfig.icons[room.roomType.name] ?? Icons.bed;
    final avail = room.isAvailable;
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.card,
        border: Border.all(
          color: avail ? color.withOpacity(0.3) : Colors.red.withOpacity(0.5),
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: color, size: 17),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: (avail ? AppTheme.teal : Colors.red).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  avail ? '🟢' : '🔴',
                  style: TextStyle(
                    color: avail ? AppTheme.tealLight : Colors.red,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            'غرفة ${room.roomNumber}',
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            room.typeLabel,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
          ),
          Text(
            '\$${room.pricePerNight.toStringAsFixed(0)}/ليلة',
            style: TextStyle(
              color: color.withOpacity(0.8),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            'طابق ${room.floor}',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
          ),
          if (!avail && room.occupiedBy != null) ...[
            const SizedBox(height: 5),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                room.occupiedBy!['guest_name'] ?? '',
                style: const TextStyle(color: Colors.redAccent, fontSize: 10),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _tableTab() {
    if (_loading)
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.gold),
      );
    return RefreshIndicator(
      onRefresh: _load,
      color: AppTheme.gold,
      child: ListView.builder(
        padding: const EdgeInsets.all(14),
        itemCount: _rooms.length,
        itemBuilder: (_, i) => _roomTableCard(_rooms[i]),
      ),
    );
  }

  Widget _roomTableCard(Room room) {
    final color = RoomTypeConfig.colors[room.roomType.name] ?? AppTheme.gold;
    final bookings = room.bookings;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.card,
        border: Border.all(
          color: bookings.isEmpty ? AppTheme.border : color.withOpacity(0.3),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTheme.border)),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Center(
                    child: Text(
                      room.roomNumber,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'غرفة ${room.roomNumber} — ${room.typeLabel}',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'طابق ${room.floor} · \$${room.pricePerNight.toStringAsFixed(0)}/ليلة',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${bookings.length} حجز',
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (bookings.isEmpty)
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: AppTheme.teal.withOpacity(0.5),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'لا توجد حجوزات',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            )
          else
            ...bookings.map((b) => _bookingRow(b, color)),
        ],
      ),
    );
  }

  Widget _bookingRow(Map<String, dynamic> b, Color color) {
    final isVip = b['priority'] == 'vip';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppTheme.border.withOpacity(0.4)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: AppTheme.gold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                '#${b['booking_id']}',
                style: const TextStyle(
                  color: AppTheme.gold,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      b['guest_name'],
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (isVip) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.star, color: AppTheme.gold, size: 12),
                    ],
                  ],
                ),
                Text(
                  '${b['check_in']} → ${b['check_out']} · ${b['nights']} ليالي',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '\$${(b['total_price'] as num).toStringAsFixed(0)}',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
