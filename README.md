# ChargeSure — Intelligent EV Charging Assurance
> **Tagline:** *“Always a Charge Ahead.”*

ChargeSure is a complete, production-grade, full-stack EV mobility assurance platform. It empowers EV drivers to discover compatible charging stations, transparently calculate reachable routes based on battery range, reserve charging slots across public, business, and residential home-host chargers, and **autonomously recover with alternative stations if their primary charger is disrupted or rejected**.

Inspired by clean, minimal healthcare applications (such as MedSuraksha), ChargeSure pairs a calming visual aesthetic with mission-critical reliability for automobile manufacturers, fleet operators, and drivers.

---

## 1. Visual System & Design Direction

- **Primary:** Deep Teal (`#087F70`)
- **Secondary:** Navy (`#152B45`)
- **Accent:** Sky Blue (`#EAF4FF`)
- **Background:** Clean Soft Gray (`#F7F9FC`)
- **Surfaces / Cards:** Pure White (`#FFFFFF`)
- **Success:** Forest Green (`#16845B`)
- **Warning:** Amber (`#E6A23C`)
- **Error:** Crimson (`#DC5252`)
- **Primary Text:** Dark Slate (`#17263C`)
- **Secondary Text:** Slate Gray (`#718096`)
- **Typography:** Inter (Modern geometric sans-serif)
- **Geometry:** 16px rounded cards, subtle `#E2E8F0` borders, soft shadows, 8-point spacing.

---

## 2. Core Architectural Components

### A. Driver Mobile / Web Application (12 Screens)
1. **Onboarding Screen:** Brand introduction, zero-anxiety charging promise, skip & get started actions.
2. **Authentication Screen:** Registration & Login with secure password hashing, role selection (Driver/Host), and **1-Click Demo Account Switcher** (`driver@chargesure.com`, `host@chargesure.com`, `admin@chargesure.com`).
3. **Home Dashboard:** Active vehicle card, real-time battery percentage, estimated driving range, upcoming reservation cards, quick actions, and nearby stations.
4. **Vehicle Management (Garage):** Multi-vehicle support (Make, Model, Pack kWh, Connector, Wh/km consumption). Interactive battery slider with transparent range recalculation.
5. **Charger Map & Finder:** Interactive OpenStreetMap integration with custom markers (DC Fast, AC, Host, Faulty). Filter by type (Public/Business/Home), power (AC/DC), connectors, and freshness indicators (`Live Operator`, `Host Confirmed`, `Reported`, `Unverified`).
6. **Trip Planner:** Origin to destination corridor planning, safety reserve selector (5% - 30%), transparent range formula, and automatic recommendation of corridor charging stops with charge time and arrival battery estimates.
7. **Charger Details & Reservation:** Tariff breakdown, connector types, available time slots, problem reporting, and booking workflow with privacy protection (masked residential access until confirmed).
8. **Booking Management:** Filterable bookings (Upcoming, Confirmed, Pending, Completed, Cancelled), snapshot price tracking, directions, and **1-tap Backup Engine recovery if a primary booking is rejected or disrupted**.
9. **Charging Session:** Live charging screen with animated gauge, active telemetry timer, energy delivered (kWh), cost accumulator, explicit simulated/user-reported telemetry badge, and session completion receipts.
10. **ChargeSure Backup Engine (Core Differentiator):** Deterministic evaluation service that calculates alternative station reachability, arrival battery reserve, detour penalty, power speed bonus, and reliability scoring when a station is rejected or faulty.
11. **Emergency EV Assistance:** 24/7 mobile dispatch, roadside flatbed transport, and unverified host emergency hotline with direct dialing.
12. **Profile & Settings:** User profile, vehicle preferences, terms, and **instant role mode switching** between Driver, Host, and Admin modes.

### B. Host Partner Portal
- **Host Profile & Verification:** Verified host badge and partner status.
- **Listing Management:** Add/edit home wallbox or commercial chargers with power rating, connector types, tariffs, and confidential access notes (gate codes, keypad pins) revealed only to confirmed drivers.
- **Request Management:** Review pending driver requests with 1-tap **Accept** or **Reject** (with reason). Overlapping booking prevention enforced in database transactions.
- **Host Analytics:** Active chargers count, completed sessions, and estimated earnings.

### C. Admin Web Dashboard
- **Responsive Console:** Overview KPI cards computed from actual database records (Total Users, Verified Hosts, Network Stations, Energy Delivered, Backup Triggers).
- **User & Host Verification:** 1-tap host approval.
- **Station Fleet Management:** Override charger status (Available, Offline, Suspended).
- **Fault Reports & Complaints:** Review driver-reported connector or power issues and mark as resolved.
- **Security Audit Logs:** Trace administrative overrides and critical actions.

### D. FastAPI Backend & Database
- Modular architecture with SQLAlchemy ORM, Pydantic v2 validation, JWT authentication, and PBKDF2/bcrypt password security.
- Comprehensive REST endpoints (`/api/auth`, `/api/users`, `/api/vehicles`, `/api/chargers`, `/api/bookings`, `/api/sessions`, `/api/backup`, `/api/trip`, `/api/host`, `/api/admin`, `/api/support`).
- Pre-seeded SQLite database (`chargesure.db`) with realistic vehicles (Tesla Model 3, Hyundai Ioniq 5, Tata Nexon EV), chargers, bookings, and fault reports. PostgreSQL / PostGIS ready.

---

## 3. Quick Start Setup Guide (Windows)

### Prerequisites
- Python 3.10+ (Installed at `python`)
- Flutter 3.24+ (Installed at `flutter`)
- Git

### Step 1: Clone & Environment Setup
Open PowerShell in the project root `D:\ChargeSure`:
```powershell
# Create Python virtual environment
python -m venv backend/.venv

# Activate virtual environment
.\backend\.venv\Scripts\Activate.ps1

# Install backend dependencies
pip install -r backend/requirements.txt
```

### Step 2: Seed Demonstration Database
```powershell
# Populate database with test vehicles, chargers, and bookings
python -c "from backend.app.seed.seed_data import seed_database_if_empty; seed_database_if_empty()"
```

### Step 3: Run Backend Unit Tests
```powershell
# Run the complete test suite (11 test cases covering auth, backup engine, range formula, bookings)
pytest backend/tests -v
```

### Step 4: Start Backend API Server
```powershell
# Start Uvicorn server on port 8000
python backend/run.py
```
- Interactive API Docs (Swagger): [http://127.0.0.1:8000/docs](http://127.0.0.1:8000/docs)
- Alternative Docs (ReDoc): [http://127.0.0.1:8000/redoc](http://127.0.0.1:8000/redoc)
- System Health Check: [http://127.0.0.1:8000/api/health](http://127.0.0.1:8000/api/health)
- Built Web App Mount: [http://127.0.0.1:8000/app/](http://127.0.0.1:8000/app/)

### Step 5: Launch Frontend Application
In a separate PowerShell window:
```powershell
cd D:\ChargeSure\frontend

# Install Flutter dependencies
flutter pub get

# Run on Chrome (Web)
flutter run -d chrome

# Or run natively on Windows Desktop
flutter run -d windows
```

---

## 4. Preloaded Demo Accounts

The app features a **1-Click Quick Demo Sign-In** on the login screen. You can also sign in manually with these preloaded credentials:

| Role | Email | Password | Pre-seeded Assets |
| :--- | :--- | :--- | :--- |
| **Driver** | `driver@chargesure.com` | `Driver@123` | Hyundai Ioniq 5 (77.4 kWh), Tesla Model 3 (75 kWh), Tata Nexon EV (40.5 kWh), active bookings |
| **Host** | `host@chargesure.com` | `Host@123` | BayTech Commercial FastCharger (60 kW), Patel Residence EcoWallbox (11 kW) |
| **Admin** | `admin@chargesure.com` | `Admin@123` | Complete platform analytics, fleet overrides, fault resolution, audit trail |

---

## 5. ChargeSure Backup Recommendation Engine: Logic & Math

The backup engine is **deterministic, transparent, and unit-tested**. It operates when a primary charger fails, is occupied, or is rejected:

$$\text{Usable Battery \%} = \max(0, \text{Current Battery \%} - \text{Minimum Safety Reserve \%})$$

$$\text{Energy to Candidate (kWh)} = \frac{\text{Haversine Distance (km)} \times \text{Consumption (Wh/km)}}{1000}$$

$$\text{Arrival Battery \%} = \text{Current Battery \%} - \left(\frac{\text{Energy (kWh)}}{\text{Battery Capacity (kWh)}} \times 100\right)$$

$$\text{Is Safely Reachable} = \text{Arrival Battery \%} \ge \text{Minimum Safety Reserve \%}$$

### Scoring Formula (0 to 100 points):
- **Safety Margin (35%):** Bonus for arrival battery above minimum threshold; severe penalty if reserve breached.
- **Proximity (25%):** Shorter distance from current position receives higher score.
- **Power & Speed (15%):** High-power DC fast charging (50–150 kW) prioritized over slow AC.
- **Availability Confidence (15%):** `Live Operator` (95 pts) > `Host Confirmed` (90 pts) > `Manually Reported` (70 pts) > `Unverified` (45 pts), with time-degradation penalties for stale reports.
- **Reliability & Price (10%):** Historical uptime percentage and lower tariff rate.

**Critical Safety Protection:** If vehicle battery is too low to safely reach any candidate without breaching safety reserve, the system **explicitly refuses to label any station as safe** and displays 24/7 mobile dispatch and flatbed emergency towing contacts.

---

## 6. Project Directory Tree

```
D:\ChargeSure\
├── backend/
│   ├── app/
│   │   ├── core/           # Security, JWT tokens, RBAC dependencies
│   │   ├── models/         # SQLAlchemy models (User, Vehicle, Charger, Booking, Session, etc.)
│   │   ├── routers/        # REST endpoints (auth, users, vehicles, chargers, bookings, backup, trip, etc.)
│   │   ├── schemas/        # Pydantic request/response models
│   │   ├── seed/           # Demo dataset seeder
│   │   ├── services/       # Backup engine, trip planner, booking state machines, geo-math
│   │   ├── config.py       # Pydantic settings & environment configuration
│   │   ├── database.py     # Database engine & sessionmaker
│   │   └── main.py         # FastAPI application & static mount
│   ├── tests/              # 11 Unit tests (pytest)
│   ├── Dockerfile          # Backend containerization
│   ├── requirements.txt    # Python dependencies
│   └── run.py              # Uvicorn execution entrypoint
├── frontend/
│   ├── lib/
│   │   ├── models/         # Dart data models
│   │   ├── screens/
│   │   │   ├── onboarding/ # Screen 1: Onboarding
│   │   │   ├── auth/       # Screen 2: Authentication & Demo switch
│   │   │   ├── driver/     # Screens 3-12: Dashboard, Garage, Map, Planner, Bookings, Session, Backup, Emergency
│   │   │   ├── host/       # Host App Portal & Add Charger listing
│   │   │   └── admin/      # Section 5: Admin Web Dashboard
│   │   ├── services/       # ApiService & AppState provider
│   │   ├── theme/          # MedSuraksha-inspired teal/navy theme
│   │   ├── widgets/        # StatusBadge, BatteryGauge, InteractiveChargerMap, StatCard
│   │   └── main.dart       # App initialization
│   ├── test/               # Widget tests
│   └── pubspec.yaml        # Flutter packages (http, provider, flutter_map, etc.)
├── docker-compose.yml      # Multi-container setup (PostGIS + FastAPI)
├── .env.example            # Environment variables template
├── .gitignore              # Git ignore rules
└── README.md               # Complete project documentation
```

---

## 7. Quality Checklist & Verification Results

- [x] **Backend Dependencies:** All packages installed cleanly in `backend/.venv`.
- [x] **Database Schema & Migrations:** SQLite local database initialized and seeded with demo chargers, vehicles, and bookings. PostGIS schema ready.
- [x] **Automated Tests:**
  - `pytest backend/tests`: **11 passed** (100% success covering auth, backup engine, connector compatibility, double-booking prevention, range calculations).
  - `flutter test`: **All tests passed**.
  - `flutter analyze`: **Zero errors**.
- [x] **Production Web Compilation:** `flutter build web` built into `frontend/build/web`.
- [x] **FastAPI Health Verification:** `GET /api/health` returns `status: healthy`, `database: connected`, `demo_mode: True`.
- [x] **Driver Journey Verified:** Register → Add Vehicle → Find Charger → Plan Route → Request Booking → Host Approval → Live Session Telemetry → Backup Engine Recovery.
- [x] **Privacy & Address Protection:** Residential addresses and gate passes hidden until booking confirmation.
- [x] **External Integrations:** Clear adapter interfaces with graceful offline/demo mode when API keys are unconfigured.

---
*ChargeSure — Always a Charge Ahead.*
