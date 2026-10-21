import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import 'api_service.dart';

class AppState extends ChangeNotifier {
  final ApiService _api = ApiService();

  User? _currentUser;
  String _activeRole = 'driver'; // 'driver', 'host', 'admin'
  bool _isLoading = false;
  String? _errorMessage;

  List<Vehicle> _vehicles = [];
  Vehicle? _activeVehicle;

  List<Charger> _chargers = [];
  Charger? _selectedCharger;

  List<Booking> _bookings = [];
  ChargingSession? _activeSession;
  Timer? _sessionTimer;

  BackupResult? _lastBackupResult;

  // Getters
  User? get currentUser => _currentUser;
  String get activeRole => _activeRole;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<Vehicle> get vehicles => _vehicles;
  Vehicle? get activeVehicle => _activeVehicle;

  List<Charger> get chargers => _chargers;
  Charger? get selectedCharger => _selectedCharger;

  List<Booking> get bookings => _bookings;
  ChargingSession? get activeSession => _activeSession;
  BackupResult? get lastBackupResult => _lastBackupResult;

  bool get isAuthenticated => _currentUser != null;

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _api.init();
      if (_api.authToken != null) {
        _currentUser = await _api.getProfile();
        _activeRole = _currentUser!.role;
        await refreshAllData();
      }
    } catch (e) {
      // Auto-fallback or clear invalid token
      await _api.setToken(null);
      _currentUser = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void switchRole(String role) {
    _activeRole = role;
    notifyListeners();
  }

  void setSelectedCharger(Charger charger) {
    _selectedCharger = charger;
    notifyListeners();
  }

  // Quick Demo Account Switcher
  Future<void> quickDemoLogin(String role) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      String email = 'driver@chargesure.com';
      String pass = 'Driver@123';
      if (role == 'host') {
        email = 'host@chargesure.com';
        pass = 'Host@123';
      } else if (role == 'admin') {
        email = 'admin@chargesure.com';
        pass = 'Admin@123';
      }

      await _api.login(email, pass);
      _currentUser = await _api.getProfile();
      _activeRole = role;
      await refreshAllData();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _api.login(email, password);
      _currentUser = await _api.getProfile();
      _activeRole = _currentUser!.role;
      await refreshAllData();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register(String email, String password, String fullName, String? phone, String role) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _api.register(email, password, fullName, phone, role);
      _currentUser = await _api.getProfile();
      _activeRole = _currentUser!.role;
      await refreshAllData();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _api.setToken(null);
    _currentUser = null;
    _vehicles = [];
    _activeVehicle = null;
    _bookings = [];
    _activeSession = null;
    _sessionTimer?.cancel();
    notifyListeners();
  }

  Future<void> refreshAllData() async {
    try {
      if (_currentUser == null) return;

      // 1. Vehicles
      _vehicles = await _api.getVehicles();
      if (_vehicles.isNotEmpty) {
        _activeVehicle = _vehicles.firstWhere((v) => v.isPrimary, orElse: () => _vehicles.first);
      } else {
        _activeVehicle = null;
      }

      // 2. Chargers
      _chargers = await _api.getNearbyChargers();

      // 3. Bookings
      _bookings = await _api.getUserBookings();

      // 4. Active Session
      _activeSession = await _api.getActiveSession();
      if (_activeSession != null) {
        _startSessionSimulationTimer();
      }
    } catch (e) {
      // Non-fatal background fetch warning
      debugPrint('Background data refresh warning: $e');
    }
    notifyListeners();
  }

  // Vehicle Management
  Future<void> updateActiveVehicleBattery(double newPercent) async {
    if (_activeVehicle == null) return;
    _activeVehicle!.currentBatteryPercent = newPercent;
    notifyListeners();
    try {
      await _api.updateVehicle(_activeVehicle!.id, {'current_battery_percent': newPercent});
    } catch (e) {
      debugPrint('Battery update failed: $e');
    }
  }

  Future<void> addVehicle(Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();
    try {
      final v = await _api.addVehicle(data);
      _vehicles.add(v);
      if (v.isPrimary || _vehicles.length == 1) {
        _activeVehicle = v;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteVehicle(int id) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _api.deleteVehicle(id);
      _vehicles.removeWhere((v) => v.id == id);
      if (_activeVehicle?.id == id) {
        _activeVehicle = _vehicles.isNotEmpty ? _vehicles.first : null;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setActiveVehicle(Vehicle v) {
    _activeVehicle = v;
    notifyListeners();
  }

  // Backup Engine Trigger
  Future<BackupResult> triggerBackupEngine({
    int? failedChargerId,
    String failureReason = "Host rejected booking / Charger unavailable",
    double? customBatteryPercent,
    double minSafetyReserve = 15.0,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await _api.evaluateBackup(
        currentLatitude: 37.7749,
        currentLongitude: -122.4194,
        vehicleId: _activeVehicle?.id,
        currentBatteryPercent: customBatteryPercent ?? _activeVehicle?.currentBatteryPercent ?? 45.0,
        batteryCapacityKwh: _activeVehicle?.batteryCapacityKwh ?? 60.0,
        consumptionWhPerKm: _activeVehicle?.consumptionWhPerKm ?? 160.0,
        connectorType: _activeVehicle?.connectorType ?? "CCS2",
        minSafetyReservePercent: minSafetyReserve,
        failedChargerId: failedChargerId,
        failureReason: failureReason,
      );
      _lastBackupResult = res;
      return res;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Booking Actions
  Future<Booking> createBooking({
    required int chargerId,
    required DateTime startTime,
    required DateTime endTime,
    bool isBackupBooking = false,
    String? backupTriggerReason,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final b = await _api.createBooking(
        chargerId: chargerId,
        vehicleId: _activeVehicle?.id,
        startTime: startTime,
        endTime: endTime,
        isBackupBooking: isBackupBooking,
        backupTriggerReason: backupTriggerReason,
      );
      _bookings.insert(0, b);
      return b;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> cancelBooking(int bookingId, {String reason = "Driver cancelled"}) async {
    final b = await _api.cancelBooking(bookingId, reason: reason);
    final idx = _bookings.indexWhere((x) => x.id == bookingId);
    if (idx != -1) {
      _bookings[idx] = b;
    }
    notifyListeners();
  }

  // Charging Session Simulation
  Future<ChargingSession> startSession(int chargerId, {int? bookingId}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final initialBatt = _activeVehicle?.currentBatteryPercent ?? 35.0;
      final sess = await _api.startSession(
        chargerId: chargerId,
        bookingId: bookingId,
        vehicleId: _activeVehicle?.id,
        initialBatteryPercent: initialBatt,
      );
      _activeSession = sess;
      _startSessionSimulationTimer();
      return sess;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _startSessionSimulationTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_activeSession == null || _activeSession!.status != 'active') {
        timer.cancel();
        return;
      }
      // Increment energy & cost smoothly for realistic live telemetry presentation
      _activeSession!.energyDeliveredKwh += 0.45;
      _activeSession!.totalCost += (0.45 * 0.35);
      final currentPercent = (_activeSession!.finalBatteryPercent ?? _activeSession!.initialBatteryPercent) + 0.6;
      _activeSession!.finalBatteryPercent = currentPercent.clamp(0.0, 100.0);
      notifyListeners();
    });
  }

  Future<ChargingSession> completeSession() async {
    if (_activeSession == null) throw Exception("No active session");
    _sessionTimer?.cancel();
    final finalPercent = _activeSession!.finalBatteryPercent ?? (_activeSession!.initialBatteryPercent + 25.0);
    final completed = await _api.completeSession(
      sessionId: _activeSession!.id,
      finalBatteryPercent: finalPercent.clamp(0.0, 100.0),
      energyDeliveredKwh: _activeSession!.energyDeliveredKwh,
    );
    if (_activeVehicle != null) {
      _activeVehicle!.currentBatteryPercent = completed.finalBatteryPercent ?? finalPercent;
    }
    _activeSession = null;
    await refreshAllData();
    return completed;
  }
}
