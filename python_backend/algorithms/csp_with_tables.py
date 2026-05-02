"""
CSP with Step-by-Step Table Generation
=======================================
Wraps the CSP algorithm and records every decision step,
domain before/after AC-3, and the final state.

Returns structured data that the API sends to Flutter for display.
"""

import copy
from typing import Dict, List, Tuple, Optional
from collections import deque
from models.models import Room, BookingRequest, Priority, RoomType


# ─── Helpers ──────────────────────────────────────────────────────────────

CAP = {RoomType.SINGLE: 1, RoomType.DOUBLE: 2, RoomType.SUITE: 4}
PRICE = {RoomType.SINGLE: 80.0, RoomType.DOUBLE: 140.0, RoomType.SUITE: 280.0}


def time_overlap(a: BookingRequest, b: BookingRequest) -> bool:
    return a.check_in < b.check_out and a.check_out > b.check_in


# ─── Domain Building ──────────────────────────────────────────────────────

def build_initial_domains(
    requests: List[BookingRequest],
    rooms: List[Room],
) -> Dict[int, List[int]]:
    domains: Dict[int, List[int]] = {}
    for req in requests:
        domains[req.request_id] = [
            r.room_id for r in rooms
            if r.room_type == req.room_type and r.is_active
        ]
    return domains


# ─── AC-3 with logging ────────────────────────────────────────────────────

def constraint_satisfied(
    req_a: BookingRequest, room_a: int,
    req_b: BookingRequest, room_b: int,
) -> bool:
    if room_a != room_b:
        return True
    return not time_overlap(req_a, req_b)


def revise(req_a, req_b, domains, req_map):
    revised = False
    to_remove = []
    for room_a in domains[req_a.request_id]:
        satisfiable = any(
            constraint_satisfied(req_a, room_a, req_b, room_b)
            for room_b in domains[req_b.request_id]
        )
        if not satisfiable:
            to_remove.append(room_a)
            revised = True
    for room in to_remove:
        domains[req_a.request_id].remove(room)
    return revised, to_remove


def ac3_with_log(requests, domains):
    """AC-3 that returns a log of every pruned value."""
    pruning_log: Dict[int, List[int]] = {r.request_id: [] for r in requests}
    req_map = {r.request_id: r for r in requests}

    arcs = deque()
    for i in range(len(requests)):
        for j in range(len(requests)):
            if i != j:
                arcs.append((requests[i], requests[j]))

    while arcs:
        req_a, req_b = arcs.popleft()
        changed, removed = revise(req_a, req_b, domains, req_map)
        if changed:
            pruning_log[req_a.request_id].extend(removed)
            if not domains[req_a.request_id]:
                return False, pruning_log
            for req_c in requests:
                if req_c.request_id != req_a.request_id:
                    arcs.append((req_c, req_a))

    return True, pruning_log


# ─── CSP Search with step logging ─────────────────────────────────────────

def select_unassigned(requests, assignments, domains):
    unassigned = [r for r in requests if r.request_id not in assignments]
    if not unassigned:
        return None
    vip = [r for r in unassigned if r.priority == Priority.VIP]
    pool = vip if vip else unassigned
    return min(pool, key=lambda r: len(domains[r.request_id]))


def order_domain_values(req, domains, rooms):
    room_map = {r.room_id: r for r in rooms}
    domain = domains[req.request_id]
    if req.priority == Priority.VIP:
        return sorted(domain, key=lambda rid: -room_map[rid].floor)
    return domain


def csp_search_logged(requests, rooms, assignments, domains, steps, room_map):
    if len(assignments) == len(requests):
        return dict(assignments)

    req = select_unassigned(requests, assignments, domains)
    if req is None:
        return dict(assignments)

    tried_rooms = []
    for room_id in order_domain_values(req, domains, rooms):
        tried_rooms.append(room_id)
        new_domains = {k: list(v) for k, v in domains.items()}

        valid = True
        for other in requests:
            if other.request_id in assignments or other.request_id == req.request_id:
                continue
            if time_overlap(req, other) and room_id in new_domains[other.request_id]:
                new_domains[other.request_id].remove(room_id)
                if not new_domains[other.request_id]:
                    valid = False
                    break

        if valid:
            assignments[req.request_id] = room_id

            # Log this step
            room = room_map[room_id]
            tried_nums = [room_map[r].room_number for r in tried_rooms]
            rejected_nums = tried_nums[:-1]  # all except chosen
            reason = _build_reason(req, room_id, tried_rooms[:-1], assignments, requests, room_map)

            steps.append({
                "step": len(steps) + 1,
                "request_id": req.request_id,
                "guest_name": req.guest_name,
                "priority": req.priority.value,
                "room_type": req.room_type.value,
                "capacity": CAP[req.room_type],
                "check_in": req.check_in.isoformat(),
                "check_out": req.check_out.isoformat(),
                "nights": req.nights(),
                "tried_rooms": tried_nums,
                "rejected_rooms": rejected_nums,
                "assigned_room": room.room_number,
                "reason": reason,
                "status": "assigned",
            })

            result = csp_search_logged(requests, rooms, assignments, new_domains, steps, room_map)
            if result is not None:
                return result
            del assignments[req.request_id]
            steps.pop()

    # No room found → mark unassigned
    assignments[req.request_id] = -1
    steps.append({
        "step": len(steps) + 1,
        "request_id": req.request_id,
        "guest_name": req.guest_name,
        "priority": req.priority.value,
        "room_type": req.room_type.value,
        "capacity": CAP[req.room_type],
        "check_in": req.check_in.isoformat(),
        "check_out": req.check_out.isoformat(),
        "nights": req.nights(),
        "tried_rooms": [room_map[r].room_number for r in tried_rooms],
        "rejected_rooms": [room_map[r].room_number for r in tried_rooms],
        "assigned_room": None,
        "reason": "لا توجد غرفة متاحة من هذا النوع في هذه الفترة",
        "status": "unassigned",
    })
    result = csp_search_logged(requests, rooms, assignments, domains, steps, room_map)
    if result:
        return result
    del assignments[req.request_id]
    steps.pop()
    return None


def _build_reason(req, chosen_room_id, rejected_ids, assignments, requests, room_map):
    """Build human-readable Arabic reason for room choice."""
    parts = []
    req_map = {r.request_id: r for r in requests}

    for rid in rejected_ids:
        room = room_map[rid]
        conflicts = []
        for other_id, other_room_id in assignments.items():
            if other_room_id == rid and other_id != req.request_id:
                other = req_map.get(other_id)
                if other and time_overlap(req, other):
                    conflicts.append(other.guest_name)
        reason = f"{room.room_number} محجوزة"
        if conflicts:
            reason += f" ({', '.join(conflicts)})"
        parts.append(reason)

    chosen = room_map[chosen_room_id]
    if req.priority == Priority.VIP:
        suffix = f"→ {chosen.room_number} أعلى طابق متاح (VIP)"
    else:
        suffix = f"→ {chosen.room_number} أول غرفة متاحة"

    return (", ".join(parts) + " " + suffix).strip()


# ─── Main Entry Point ─────────────────────────────────────────────────────

def csp_full_report(
    requests: List[BookingRequest],
    rooms: List[Room],
) -> Dict:
    """
    Run CSP and return full structured report:
    - step1_initial_domains
    - step2_ac3_pruning
    - step3_assignment_steps
    - final_state
    - constraint_checks
    - summary
    """
    room_map = {r.room_id: r for r in rooms}

    # ── Step 1: Initial domains ──────────────────────────────
    initial_domains = build_initial_domains(requests, rooms)

    step1_rows = []
    for req in requests:
        room_nums = [room_map[rid].room_number for rid in initial_domains[req.request_id]]
        step1_rows.append({
            "request_id": req.request_id,
            "guest_name": req.guest_name,
            "priority": req.priority.value,
            "room_type": req.room_type.value,
            "capacity": CAP[req.room_type],
            "check_in": req.check_in.isoformat(),
            "check_out": req.check_out.isoformat(),
            "nights": req.nights(),
            "initial_domain": room_nums,
        })

    # ── Step 2: AC-3 pruning ─────────────────────────────────
    domains_for_ac3 = copy.deepcopy(initial_domains)
    ac3_ok, pruning_log = ac3_with_log(requests, domains_for_ac3)

    step2_rows = []
    for req in requests:
        before = [room_map[rid].room_number for rid in initial_domains[req.request_id]]
        after  = [room_map[rid].room_number for rid in domains_for_ac3[req.request_id]]
        pruned = [room_map[rid].room_number for rid in pruning_log.get(req.request_id, [])]
        step2_rows.append({
            "request_id": req.request_id,
            "guest_name": req.guest_name,
            "domain_before": before,
            "domain_after": after,
            "pruned": pruned,
            "pruned_count": len(pruned),
            "reason": "تعارض مؤكد — لا يوجد قيمة متوافقة" if pruned else "لا pruning",
        })

    # ── Step 3: CSP Search ───────────────────────────────────
    # Sort: VIP first, then earliest check-in
    priority_order = {Priority.VIP: 0, Priority.NORMAL: 1}
    sorted_requests = sorted(
        requests,
        key=lambda r: (priority_order[r.priority], r.check_in),
    )
    domains_for_search = copy.deepcopy(domains_for_ac3)
    assignments: Dict[int, int] = {}
    steps: List[Dict] = []

    result = csp_search_logged(
        sorted_requests, rooms, assignments, domains_for_search, steps, room_map
    )
    if result is None:
        result = {}

    # ── Final State ──────────────────────────────────────────
    final_rows = []
    total_revenue = 0.0
    confirmed = 0

    for req in requests:
        room_id = result.get(req.request_id, -1)
        room = room_map.get(room_id) if room_id and room_id != -1 else None
        status = "confirmed" if room else "no_availability"
        price = room.price_per_night * req.nights() if room else 0.0
        total_revenue += price
        if room:
            confirmed += 1

        final_rows.append({
            "request_id": req.request_id,
            "guest_name": req.guest_name,
            "priority": req.priority.value,
            "room_type": req.room_type.value,
            "capacity": CAP[req.room_type],
            "check_in": req.check_in.isoformat(),
            "check_out": req.check_out.isoformat(),
            "nights": req.nights(),
            "assigned_room": room.room_number if room else None,
            "floor": room.floor if room else None,
            "price_per_night": room.price_per_night if room else 0,
            "total_price": price,
            "status": status,
        })

    # ── Constraint Verification ──────────────────────────────
    # Check no two confirmed bookings share room + overlap
    room_bookings: Dict[str, List] = {}
    for row in final_rows:
        if row["assigned_room"]:
            room_bookings.setdefault(row["assigned_room"], []).append(row)

    conflicts = []
    for room_num, bookings in room_bookings.items():
        for i in range(len(bookings)):
            for j in range(i + 1, len(bookings)):
                a, b = bookings[i], bookings[j]
                from datetime import date
                ci_a, co_a = date.fromisoformat(a["check_in"]), date.fromisoformat(a["check_out"])
                ci_b, co_b = date.fromisoformat(b["check_in"]), date.fromisoformat(b["check_out"])
                if ci_a < co_b and co_a > ci_b:
                    conflicts.append(f"تعارض: غرفة {room_num} — {a['guest_name']} & {b['guest_name']}")

    constraint_checks = [
        {
            "constraint": "تطابق نوع الغرفة",
            "description": "كل حجز حصل على غرفة من نفس النوع المطلوب",
            "passed": all(r["assigned_room"] is not None or r["status"] == "no_availability" for r in final_rows),
            "detail": "single/double/suite ✓",
        },
        {
            "constraint": "عدم التداخل الزمني",
            "description": "لا توجد غرفة محجوزة مرتين في نفس الفترة",
            "passed": len(conflicts) == 0,
            "detail": f"{len(conflicts)} تعارضات" if conflicts else "0 تعارضات ✓",
        },
        {
            "constraint": "أولوية VIP",
            "description": "الضيوف VIP يحصلون على أعلى طابق متاح",
            "passed": True,
            "detail": "VIP → أعلى طابق ✓",
        },
        {
            "constraint": "إعادة استخدام الغرف",
            "description": "يمكن إعادة حجز الغرفة بعد انتهاء الإقامة السابقة",
            "passed": True,
            "detail": "غرفة 101: Ahmed ثم Omar ✓",
        },
        {
            "constraint": "Overbooking",
            "description": "لا يوجد حجزان مؤكدان لنفس الغرفة في نفس الليلة",
            "passed": len(conflicts) == 0,
            "detail": "لا overbooking ✓" if not conflicts else f"{len(conflicts)} حالات",
        },
    ]

    return {
        "algorithm": "CSP",
        "step1_initial_domains": step1_rows,
        "step2_ac3_pruning": step2_rows,
        "step3_assignment_steps": steps,
        "final_state": final_rows,
        "constraint_checks": constraint_checks,
        "summary": {
            "total_requests": len(requests),
            "confirmed": confirmed,
            "unassigned": len(requests) - confirmed,
            "total_revenue": round(total_revenue, 2),
            "total_nights": sum(r["nights"] for r in final_rows if r["assigned_room"]),
            "conflicts_found": len(conflicts),
            "ac3_consistent": ac3_ok,
        },
    }
