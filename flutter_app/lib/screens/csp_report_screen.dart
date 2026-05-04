import 'package:flutter/material.dart';
import 'package:flutter_app/models/csp_report_model.dart';
import 'package:flutter_app/services/api_service.dart';

class CspTableScreen extends StatefulWidget {
  const CspTableScreen({super.key});

  @override
  State<CspTableScreen> createState() => _CspTableScreenState();
}

class _CspTableScreenState extends State<CspTableScreen> {
  final _api = ApiService();

  List<FinalStateRow> _rows = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      final response = await _api.getCspReport();
      List<FinalStateRow> parsedRows = [];

      if (response is List) {
        parsedRows = response.map((data) {
          return FinalStateRow(
            requestId: data['booking_id'] ?? 0,
            guestName: data['guest']?['name'] ?? 'Unknown',
            assignedRoom:
                data['room']?['room_number']?.toString() ?? 'Unassigned',
            totalPrice: (data['total_price'] as num?)?.toDouble() ?? 0.0,
            status: data['status'] ?? 'unknown',
            priority: data['guest']?['priority'] ?? 'normal',
            roomType: data['room']?['room_type'] ?? '-',
            capacity: 0,
            checkIn: data['check_in'] ?? '',
            checkOut: data['check_out'] ?? '',
            nights: data['nights'] ?? 0,
            floor: data['room']?['floor'],
            pricePerNight:
                (data['room']?['price_per_night'] as num?)?.toDouble() ?? 0.0,
          );
        }).toList();
      } else if (response is CspReport) {
        parsedRows = response.finalState;
      }

      setState(() {
        _rows = parsedRows;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  // تصميم شكل خانة (الحالة)
  Widget _buildStatusBadge(String status) {
    Color color;
    if (status.toLowerCase() == 'confirmed') {
      color = Colors.green;
    } else if (status.toLowerCase() == 'unassigned' ||
        status.toLowerCase() == 'cancelled') {
      color = Colors.red;
    } else {
      color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  // تصميم شكل خانة (الأولوية VIP وغيرها)
  Widget _buildPriorityBadge(String priority) {
    Color color = priority.toLowerCase() == 'vip'
        ? Colors.deepPurple
        : Colors.blueGrey;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        priority.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildTable() {
    if (_rows.isEmpty) {
      return const Center(
        child: Text(
          "لا توجد بيانات للعرض",
          style: TextStyle(
            color: Colors.grey,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      physics: const BouncingScrollPhysics(), // تأثير سحب ناعم
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          // ─── إطار شيك حوالين الجدول بظل وحواف دائرية ───
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05), // ظل خفيف جداً
                  blurRadius: 10,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: Colors.grey.shade300, width: 1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(
                12,
              ), // عشان الجدول مياكلش الحواف الدائرية
              child: DataTable(
                // ─── تسطير داخلي ناعم وشيك ───
                border: TableBorder(
                  horizontalInside: BorderSide(
                    color: Colors.grey.shade200,
                    width: 1,
                  ),
                  verticalInside: BorderSide(
                    color: Colors.grey.shade200,
                    width: 1,
                  ),
                ),
                // لون صف العناوين
                headingRowColor: MaterialStateProperty.all(
                  const Color(0xFFF4F6F8),
                ),
                headingTextStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                  fontSize: 14,
                ),
                dataRowMinHeight: 65,
                dataRowMaxHeight: 70,
                columnSpacing: 24,
                columns: const [
                  DataColumn(label: Text("ID")),
                  DataColumn(label: Text("Guest")),
                  DataColumn(label: Text("Priority")),
                  DataColumn(label: Text("Room Type")),
                  DataColumn(label: Text("Room #")),
                  DataColumn(label: Text("Check In")),
                  DataColumn(label: Text("Check Out")),
                  DataColumn(label: Text("Nights")),
                  DataColumn(label: Text("Total Price")),
                  DataColumn(label: Text("Status")),
                ],
                // استخدام asMap عشان نلون صف أبيض وصف رمادي (Zebra Style)
                rows: _rows.asMap().entries.map((entry) {
                  int index = entry.key;
                  FinalStateRow r = entry.value;

                  return DataRow(
                    // تلوين تبادلي للصفوف
                    color: MaterialStateProperty.all(
                      index.isEven ? Colors.white : const Color(0xFFFAFAFA),
                    ),
                    cells: [
                      DataCell(
                        Text(
                          r.requestId.toString(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          r.guestName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      DataCell(_buildPriorityBadge(r.priority)),
                      DataCell(
                        Text(
                          r.roomType.toUpperCase(),
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ),
                      DataCell(
                        Text(
                          r.assignedRoom ?? "Unassigned",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color:
                                r.assignedRoom == null ||
                                    r.assignedRoom == 'Unassigned'
                                ? Colors.red.shade400
                                : Colors.black87,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          r.checkIn,
                          style: const TextStyle(color: Colors.black87),
                        ),
                      ),
                      DataCell(
                        Text(
                          r.checkOut,
                          style: const TextStyle(color: Colors.black87),
                        ),
                      ),
                      DataCell(
                        Text(
                          r.nights.toString(),
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ),
                      DataCell(
                        Text(
                          "\$${r.totalPrice.toStringAsFixed(2)}",
                          style: const TextStyle(
                            color: Color(0xFF2E7D32),
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      DataCell(_buildStatusBadge(r.status)),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("CSP Report"),
        elevation: 0,
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : _buildTable(),
    );
  }
}
