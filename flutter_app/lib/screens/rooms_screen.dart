// ─── rooms_screen.dart ─────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_app/core/theme/theme.dart';
import 'package:flutter_app/services/api_services.dart';
import '../models/models.dart';

class RoomsScreen extends StatefulWidget {
  const RoomsScreen({super.key});

  @override
  State<RoomsScreen> createState() => _RoomsScreenState();
}

class _RoomsScreenState extends State<RoomsScreen> {
  final _api = ApiService();
  List<Room> _rooms = [];
  bool _loading = true;
  String _filterType = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final rooms = await _api.getRooms();
      setState(() {
        _rooms = rooms;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  List<Room> get _filtered {
    if (_filterType == 'all') return _rooms;
    return _rooms.where((r) => r.roomType.name == _filterType).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🏨  Rooms'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.gold),
                  )
                : RefreshIndicator(
                    onRefresh: _load,
                    color: AppTheme.gold,
                    child: GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1,
                          ),
                      itemCount: _filtered.length,
                      itemBuilder: (_, i) => _buildRoomCard(_filtered[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    final types = [
      ('all', 'All'),
      ('single', 'Single'),
      ('double', 'Double'),
      ('suite', 'Suite'),
    ];
    return Container(
      color: AppTheme.bgDark,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: types.map((t) {
          final active = _filterType == t.$1;
          final color = RoomTypeConfig.colors[t.$1] ?? AppTheme.gold;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _filterType = t.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: active ? color.withOpacity(0.15) : AppTheme.card,
                  border: Border.all(color: active ? color : AppTheme.border),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  t.$2,
                  style: TextStyle(
                    color: active ? color : AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRoomCard(Room room) {
    final color = RoomTypeConfig.colors[room.roomType.name] ?? AppTheme.gold;
    final icon = RoomTypeConfig.icons[room.roomType.name] ?? Icons.bed;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.card,
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.teal.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Available',
                  style: TextStyle(
                    color: AppTheme.tealLight,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            'Room ${room.roomNumber}',
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            room.typeLabel,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            '\$${room.pricePerNight.toStringAsFixed(0)}/night',
            style: TextStyle(
              color: color.withOpacity(0.8),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            'Floor ${room.floor}',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
