// ─── csp_report_model.dart ─────────────────────────────────────────────────
// Data models for the CSP step-by-step report returned by /api/csp-report

class CspReportSummary {
  final int totalRequests;
  final int confirmed;
  final int unassigned;
  final double totalRevenue;
  final int totalNights;
  final int conflictsFound;
  final bool ac3Consistent;

  const CspReportSummary({
    required this.totalRequests,
    required this.confirmed,
    required this.unassigned,
    required this.totalRevenue,
    required this.totalNights,
    required this.conflictsFound,
    required this.ac3Consistent,
  });

  factory CspReportSummary.fromJson(Map<String, dynamic> j) => CspReportSummary(
        totalRequests: j['total_requests'],
        confirmed: j['confirmed'],
        unassigned: j['unassigned'],
        totalRevenue: (j['total_revenue'] as num).toDouble(),
        totalNights: j['total_nights'],
        conflictsFound: j['conflicts_found'],
        ac3Consistent: j['ac3_consistent'],
      );
}

class DomainRow {
  final int requestId;
  final String guestName;
  final String priority;
  final String roomType;
  final int capacity;
  final String checkIn;
  final String checkOut;
  final int nights;
  final List<String> initialDomain;

  const DomainRow({
    required this.requestId,
    required this.guestName,
    required this.priority,
    required this.roomType,
    required this.capacity,
    required this.checkIn,
    required this.checkOut,
    required this.nights,
    required this.initialDomain,
  });

  factory DomainRow.fromJson(Map<String, dynamic> j) => DomainRow(
        requestId: j['request_id'],
        guestName: j['guest_name'],
        priority: j['priority'],
        roomType: j['room_type'],
        capacity: j['capacity'],
        checkIn: j['check_in'],
        checkOut: j['check_out'],
        nights: j['nights'],
        initialDomain: List<String>.from(j['initial_domain']),
      );
}

class Ac3Row {
  final int requestId;
  final String guestName;
  final List<String> domainBefore;
  final List<String> domainAfter;
  final List<String> pruned;
  final int prunedCount;
  final String reason;

  const Ac3Row({
    required this.requestId,
    required this.guestName,
    required this.domainBefore,
    required this.domainAfter,
    required this.pruned,
    required this.prunedCount,
    required this.reason,
  });

  factory Ac3Row.fromJson(Map<String, dynamic> j) => Ac3Row(
        requestId: j['request_id'],
        guestName: j['guest_name'],
        domainBefore: List<String>.from(j['domain_before']),
        domainAfter: List<String>.from(j['domain_after']),
        pruned: List<String>.from(j['pruned']),
        prunedCount: j['pruned_count'],
        reason: j['reason'],
      );
}

class AssignmentStep {
  final int step;
  final int requestId;
  final String guestName;
  final String priority;
  final String roomType;
  final int capacity;
  final String checkIn;
  final String checkOut;
  final int nights;
  final List<String> triedRooms;
  final List<String> rejectedRooms;
  final String? assignedRoom;
  final String reason;
  final String status; // "assigned" | "unassigned"

  const AssignmentStep({
    required this.step,
    required this.requestId,
    required this.guestName,
    required this.priority,
    required this.roomType,
    required this.capacity,
    required this.checkIn,
    required this.checkOut,
    required this.nights,
    required this.triedRooms,
    required this.rejectedRooms,
    required this.assignedRoom,
    required this.reason,
    required this.status,
  });

  bool get isAssigned => status == 'assigned';

  factory AssignmentStep.fromJson(Map<String, dynamic> j) => AssignmentStep(
        step: j['step'],
        requestId: j['request_id'],
        guestName: j['guest_name'],
        priority: j['priority'],
        roomType: j['room_type'],
        capacity: j['capacity'],
        checkIn: j['check_in'],
        checkOut: j['check_out'],
        nights: j['nights'],
        triedRooms: List<String>.from(j['tried_rooms']),
        rejectedRooms: List<String>.from(j['rejected_rooms']),
        assignedRoom: j['assigned_room'],
        reason: j['reason'],
        status: j['status'],
      );
}

class FinalStateRow {
  final int requestId;
  final String guestName;
  final String priority;
  final String roomType;
  final int capacity;
  final String checkIn;
  final String checkOut;
  final int nights;
  final String? assignedRoom;
  final int? floor;
  final double pricePerNight;
  final double totalPrice;
  final String status;

  const FinalStateRow({
    required this.requestId,
    required this.guestName,
    required this.priority,
    required this.roomType,
    required this.capacity,
    required this.checkIn,
    required this.checkOut,
    required this.nights,
    required this.assignedRoom,
    required this.floor,
    required this.pricePerNight,
    required this.totalPrice,
    required this.status,
  });

  bool get isConfirmed => status == 'confirmed';

  factory FinalStateRow.fromJson(Map<String, dynamic> j) => FinalStateRow(
        requestId: j['request_id'],
        guestName: j['guest_name'],
        priority: j['priority'],
        roomType: j['room_type'],
        capacity: j['capacity'],
        checkIn: j['check_in'],
        checkOut: j['check_out'],
        nights: j['nights'],
        assignedRoom: j['assigned_room'],
        floor: j['floor'],
        pricePerNight: (j['price_per_night'] as num).toDouble(),
        totalPrice: (j['total_price'] as num).toDouble(),
        status: j['status'],
      );
}

class ConstraintCheck {
  final String constraint;
  final String description;
  final bool passed;
  final String detail;

  const ConstraintCheck({
    required this.constraint,
    required this.description,
    required this.passed,
    required this.detail,
  });

  factory ConstraintCheck.fromJson(Map<String, dynamic> j) => ConstraintCheck(
        constraint: j['constraint'],
        description: j['description'],
        passed: j['passed'],
        detail: j['detail'],
      );
}

class CspReport {
  final String algorithm;
  final List<DomainRow> step1InitialDomains;
  final List<Ac3Row> step2Ac3Pruning;
  final List<AssignmentStep> step3AssignmentSteps;
  final List<FinalStateRow> finalState;
  final List<ConstraintCheck> constraintChecks;
  final CspReportSummary summary;

  const CspReport({
    required this.algorithm,
    required this.step1InitialDomains,
    required this.step2Ac3Pruning,
    required this.step3AssignmentSteps,
    required this.finalState,
    required this.constraintChecks,
    required this.summary,
  });

  factory CspReport.fromJson(Map<String, dynamic> j) => CspReport(
        algorithm: j['algorithm'],
        step1InitialDomains: (j['step1_initial_domains'] as List)
            .map((e) => DomainRow.fromJson(e))
            .toList(),
        step2Ac3Pruning: (j['step2_ac3_pruning'] as List)
            .map((e) => Ac3Row.fromJson(e))
            .toList(),
        step3AssignmentSteps: (j['step3_assignment_steps'] as List)
            .map((e) => AssignmentStep.fromJson(e))
            .toList(),
        finalState: (j['final_state'] as List)
            .map((e) => FinalStateRow.fromJson(e))
            .toList(),
        constraintChecks: (j['constraint_checks'] as List)
            .map((e) => ConstraintCheck.fromJson(e))
            .toList(),
        summary: CspReportSummary.fromJson(j['summary']),
      );
}
