# 🏨 Hotel Booking System — Smart Room Assignment

> نظام ذكي لإدارة حجوزات الفنادق باستخدام خوارزميات البحث
> Built with **Flutter** (frontend) + **Python / FastAPI** (backend)

---

## 📁 Project Structure

```
hotel_booking/
├── python_backend/
│   ├── algorithms/
│   │   ├── greedy.py          ← Greedy Algorithm
│   │   ├── backtracking.py    ← Backtracking (main engine)
│   │   ├── csp.py             ← CSP + AC-3 pruning
│   │   └── graph_coloring.py  ← DSatur Graph Coloring
│   ├── models/
│   │   └── models.py          ← Room, Guest, Booking dataclasses
│   ├── hotel_service.py       ← Core business logic
│   ├── api.py                 ← FastAPI REST endpoints
│   ├── test_algorithms.py     ← Algorithm test suite
│   └── requirements.txt
│
└── flutter_app/
    ├── lib/
    │   ├── main.dart                      ← App entry + navigation
    │   ├── theme.dart                     ← Dark theme + colors
    │   ├── models/models.dart             ← Dart data models
    │   ├── services/api_service.dart      ← HTTP client
    │   └── screens/
    │       ├── dashboard_screen.dart      ← Stats overview
    │       ├── new_booking_screen.dart    ← Create booking request
    │       ├── assignment_screen.dart     ← Run algorithm
    │       ├── bookings_screen.dart       ← All bookings list
    │       ├── rooms_screen.dart          ← Rooms grid
    │       └── pending_screen.dart        ← Pending requests
    └── pubspec.yaml
```

---

## 🚀 Quick Start

### 1. Python Backend

```bash
cd python_backend
pip install -r requirements.txt
uvicorn api:app --reload --port 8000
```

API runs at: `http://localhost:8000`
Swagger docs: `http://localhost:8000/docs`

### 2. Run Algorithm Tests

```bash
cd python_backend
python test_algorithms.py
```

### 3. Flutter App

```bash
cd flutter_app
flutter pub get
flutter run
```

---

## 🧠 Algorithms

### 1. Greedy — السريع
```
Sort requests: VIP first → earliest check-in
For each request → assign first available matching room
Time: O(n × m)    Space: O(n)
```
✅ Very fast  ❌ Not always optimal

### 2. Backtracking — الأدق ⭐ (Default)
```
For each request → try all rooms
  If conflict → backtrack and try next room
  If solution found → return it
Time: O(m^n) worst case (heavily pruned in practice)
```
✅ Guaranteed no conflicts  ✅ Finds solution if it exists

### 3. CSP + AC-3 — المنظّم
```
Variables  = BookingRequests
Domain     = Available rooms per type
Constraints = No time overlap on same room
AC-3 prunes domains before search → much faster
MRV heuristic → pick request with fewest options first
LCV heuristic → VIP gets higher floors first
```
✅ Smart constraint propagation  ✅ VIP-aware

### 4. Graph Coloring (DSatur) — التصوّر
```
Node  = BookingRequest
Edge  = Two requests that would conflict on same room
Color = room_id
DSatur: always color node with highest saturation first
Returns chromatic number = minimum rooms needed
```
✅ Best for conflict visualization  ✅ Often finds Mona's room when others miss it

---

## 🌐 API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET  | `/api/dashboard` | Stats overview |
| GET  | `/api/rooms` | All rooms |
| GET  | `/api/rooms/available?check_in=&check_out=` | Available rooms |
| POST | `/api/guests` | Create guest |
| POST | `/api/requests` | Submit booking request |
| GET  | `/api/requests` | Pending requests |
| POST | `/api/assign` | Run assignment algorithm |
| GET  | `/api/bookings` | All confirmed bookings |
| DELETE | `/api/bookings/{id}` | Cancel booking |

### Example: Submit & Assign

```bash
# 1. Create guest
curl -X POST http://localhost:8000/api/guests \
  -H "Content-Type: application/json" \
  -d '{"name":"Ahmed","email":"ahmed@email.com","priority":"vip"}'

# 2. Submit booking request
curl -X POST http://localhost:8000/api/requests \
  -H "Content-Type: application/json" \
  -d '{
    "guest_id": 1,
    "guest_name": "Ahmed",
    "room_type": "single",
    "check_in": "2025-01-01",
    "check_out": "2025-01-04",
    "priority": "vip"
  }'

# 3. Run backtracking assignment
curl -X POST http://localhost:8000/api/assign \
  -H "Content-Type: application/json" \
  -d '{"algorithm": "backtracking"}'
```

---

## 📊 Test Results (7 requests, 5 rooms)

| Algorithm | Assigned | Unassigned | Conflicts |
|-----------|----------|------------|-----------|
| Greedy | 6 | 1 (Mona) | 0 |
| Backtracking | 6 | 1 (Mona) | **0 ✅ verified** |
| CSP | 6 | 1 (Mona) | 0 |
| Graph Coloring | 6 | 1 (Fatma) | 0 |

> Mona can't be placed because both single rooms are taken Jan 2–4.
> That's correct behavior — no overbooking!

---

## 🎨 Flutter Screens

| Screen | Route | Description |
|--------|-------|-------------|
| Dashboard | `/` | Stats + quick actions |
| New Booking | `/new_booking` | Guest form + room type picker |
| Assignment | `/assign` | Choose algorithm + run + see results |
| Bookings | `/bookings` | Filter by status, cancel |
| Rooms | `/rooms` | Grid view, filter by type |
| Pending | `/pending` | Queue of unprocessed requests |

---

## 🔑 Key Design Decisions

- **VIP Priority**: VIP guests always sorted first in all algorithms. CSP also gives them higher floor rooms via LCV heuristic.
- **No Overbooking**: Overlap check is `check_in_A < check_out_B AND check_out_A > check_in_B` — mathematically airtight.
- **Stateless API**: Each `/api/assign` call processes all pending requests and clears the queue.
- **Graph as Hotel Model**: Rooms = nodes, conflicts = edges. Graph coloring = room assignment. This makes the CS theory concrete.

---

## 📦 Dependencies

**Python**
```
fastapi==0.111.0
uvicorn[standard]==0.29.0
pydantic==2.7.1
```

**Flutter**
```yaml
http: ^1.2.0
intl: ^0.19.0
```
