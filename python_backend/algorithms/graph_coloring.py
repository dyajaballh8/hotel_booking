"""
Graph Coloring for Hotel Booking Conflict Visualization
========================================================
Models the booking problem as a graph coloring problem:

  - Node   = BookingRequest
  - Edge   = Two requests conflict (same room type + overlapping dates)
  - Color  = Assigned room_id

Two adjacent nodes (conflicting requests) cannot have the same color (room).
Uses DSatur (Dynamic Saturation) algorithm — one of the best greedy
graph-coloring heuristics.

Primary use: Conflict detection & visualization
Secondary use: Room assignment (alternative to backtracking)

Time Complexity:  O(n² + n*m) where n = requests, m = rooms
Space Complexity: O(n²) for adjacency matrix
"""

from typing import Dict, List, Set, Tuple
from models.models import Room, BookingRequest, Priority, RoomType


# ─── Graph Construction ────────────────────────────────────────────────────


def build_conflict_graph(
    requests: List[BookingRequest],
) -> Dict[int, Set[int]]:
    """
    Build adjacency list of conflicting requests.
    Two requests conflict if: same room_type AND overlapping dates.

    Returns: { request_id -> set of conflicting request_ids }
    """
    graph: Dict[int, Set[int]] = {r.request_id: set() for r in requests}

    for i in range(len(requests)):
        for j in range(i + 1, len(requests)):
            a, b = requests[i], requests[j]
            if a.room_type == b.room_type:
                if a.check_in < b.check_out and a.check_out > b.check_in:
                    graph[a.request_id].add(b.request_id)
                    graph[b.request_id].add(a.request_id)

    return graph


def get_conflict_edges(
    requests: List[BookingRequest],
) -> List[Tuple[int, int, str]]:
    """
    Get all conflict edges for visualization.
    Returns: [(request_id_a, request_id_b, overlap_description)]
    """
    edges = []
    for i in range(len(requests)):
        for j in range(i + 1, len(requests)):
            a, b = requests[i], requests[j]
            if a.room_type == b.room_type:
                overlap_start = max(a.check_in, b.check_in)
                overlap_end = min(a.check_out, b.check_out)
                if overlap_start < overlap_end:
                    desc = f"Overlap: {overlap_start} → {overlap_end}"
                    edges.append((a.request_id, b.request_id, desc))
    return edges


# ─── DSatur Coloring ───────────────────────────────────────────────────────


def dsatur_coloring(
    requests: List[BookingRequest],
    rooms: List[Room],
    graph: Dict[int, Set[int]],
) -> Tuple[Dict[int, int], List[BookingRequest]]:
    """
    DSatur graph coloring algorithm.
    Saturation degree = number of distinct colors used by neighbors.
    Always color the node with the highest saturation first.

    Returns:
        coloring:   { request_id -> room_id }
        unassigned: requests that couldn't be colored
    """
    # Group rooms by type
    rooms_by_type: Dict[RoomType, List[Room]] = {}
    for room in rooms:
        if room.is_active:
            rooms_by_type.setdefault(room.room_type, []).append(room)

    coloring: Dict[int, int] = {}         # request_id -> room_id
    saturation: Dict[int, Set[int]] = {   # request_id -> set of neighbor room_ids
        r.request_id: set() for r in requests
    }
    uncolored = set(r.request_id for r in requests)
    req_map = {r.request_id: r for r in requests}

    priority_order = {Priority.VIP: 0, Priority.NORMAL: 1}

    while uncolored:
        # Pick node with highest saturation; break ties by priority then degree
        node_id = max(
            uncolored,
            key=lambda rid: (
                len(saturation[rid]),
                priority_order[req_map[rid].priority] == 0,  # VIP gets boost
                len(graph[rid]),
            ),
        )
        req = req_map[node_id]

        # Colors used by neighbors
        neighbor_colors = {
            coloring[n] for n in graph[node_id] if n in coloring
        }

        # Find a room (color) not used by any neighbor
        assigned = False
        for room in rooms_by_type.get(req.room_type, []):
            if room.room_id not in neighbor_colors:
                coloring[node_id] = room.room_id
                assigned = True
                # Update saturation of uncolored neighbors
                for neighbor_id in graph[node_id]:
                    if neighbor_id in uncolored:
                        saturation[neighbor_id].add(room.room_id)
                break

        uncolored.discard(node_id)
        if not assigned:
            coloring[node_id] = -1  # unassignable

    final = {k: v for k, v in coloring.items() if v != -1}
    unassigned = [req_map[rid] for rid, room in coloring.items() if room == -1]
    return final, unassigned


# ─── Chromatic Number ──────────────────────────────────────────────────────


def chromatic_number(graph: Dict[int, Set[int]], coloring: Dict[int, int]) -> int:
    """Minimum number of distinct rooms needed (= chromatic number of graph)."""
    return len(set(coloring.values()) - {-1})


# ─── Graph Stats ───────────────────────────────────────────────────────────


def graph_stats(
    requests: List[BookingRequest],
    graph: Dict[int, Set[int]],
) -> Dict:
    """Return useful stats about the conflict graph."""
    degrees = {rid: len(neighbors) for rid, neighbors in graph.items()}
    edge_count = sum(degrees.values()) // 2
    return {
        "nodes": len(requests),
        "edges": edge_count,
        "max_degree": max(degrees.values(), default=0),
        "avg_degree": round(sum(degrees.values()) / len(degrees), 2) if degrees else 0,
        "density": round(
            edge_count / (len(requests) * (len(requests) - 1) / 2), 3
        ) if len(requests) > 1 else 0,
    }


# ─── Public Entry Point ────────────────────────────────────────────────────


def graph_coloring_assign(
    requests: List[BookingRequest],
    rooms: List[Room],
) -> Tuple[Dict[int, int], List[BookingRequest], Dict]:
    """
    Full graph coloring pipeline.

    Returns:
        assignments: { request_id -> room_id }
        unassigned:  unplaceable requests
        metadata:    graph stats + chromatic number
    """
    graph = build_conflict_graph(requests)
    coloring, unassigned = dsatur_coloring(requests, rooms, graph)
    edges = get_conflict_edges(requests)
    stats = graph_stats(requests, graph)
    stats["chromatic_number"] = chromatic_number(graph, coloring)
    stats["conflict_edges"] = [
        {"from": a, "to": b, "description": d} for a, b, d in edges
    ]
    return coloring, unassigned, stats