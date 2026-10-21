import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class ApiService {
  static const String defaultBaseUrl = 'http://127.0.0.1:8000/api';
  String baseUrl = defaultBaseUrl;
  String? _authToken;

  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? get authToken => _authToken;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('auth_token');
  }

  Future<void> setToken(String? token) async {
    _authToken = token;
    final prefs = await SharedPreferences.getInstance();
    if (token != null) {
      await prefs.setString('auth_token', token);
    } else {
      await prefs.remove('auth_token');
    }
  }

  Map<String, String> _headers() {
    final map = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_authToken != null) {
      map['Authorization'] = 'Bearer $_authToken';
    }
    return map;
  }

  // ---------------- AUTH ----------------
  Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/auth/login');
    final resp = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      await setToken(data['access_token'] as String);
      return data;
    } else {
      final error = jsonDecode(resp.body);
      throw Exception(error['detail'] ?? 'Login failed');
    }
  }

  Future<Map<String, dynamic>> register(
      String email, String password, String fullName, String? phone, String role) async {
    final url = Uri.parse('$baseUrl/auth/register');
    final resp = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'full_name': fullName,
        'phone': phone,
        'role': role,
      }),
    );
    if (resp.statusCode == 201) {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      await setToken(data['access_token'] as String);
      return data;
    } else {
      final error = jsonDecode(resp.body);
      throw Exception(error['detail'] ?? 'Registration failed');
    }
  }

  Future<User> getProfile() async {
    final url = Uri.parse('$baseUrl/users/me');
    final resp = await http.get(url, headers: _headers());
    if (resp.statusCode == 200) {
      return User.fromJson(jsonDecode(resp.body));
    }
    throw Exception('Failed to load user profile');
  }

  // ---------------- VEHICLES ----------------
  Future<List<Vehicle>> getVehicles() async {
    final url = Uri.parse('$baseUrl/vehicles');
    final resp = await http.get(url, headers: _headers());
    if (resp.statusCode == 200) {
      final list = jsonDecode(resp.body) as List;
      return list.map((e) => Vehicle.fromJson(e)).toList();
    }
    throw Exception('Failed to load vehicles');
  }

  Future<Vehicle> addVehicle(Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/vehicles');
    final resp = await http.post(url, headers: _headers(), body: jsonEncode(data));
    if (resp.statusCode == 201) {
      return Vehicle.fromJson(jsonDecode(resp.body));
    }
    throw Exception('Failed to add vehicle');
  }

  Future<Vehicle> updateVehicle(int id, Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/vehicles/$id');
    final resp = await http.patch(url, headers: _headers(), body: jsonEncode(data));
    if (resp.statusCode == 200) {
      return Vehicle.fromJson(jsonDecode(resp.body));
    }
    throw Exception('Failed to update vehicle');
  }

  Future<void> deleteVehicle(int id) async {
    final url = Uri.parse('$baseUrl/vehicles/$id');
    final resp = await http.delete(url, headers: _headers());
    if (resp.statusCode != 204) {
      throw Exception('Failed to delete vehicle');
    }
  }

  // ---------------- CHARGERS ----------------
  Future<List<Charger>> getNearbyChargers({
    double latitude = 37.7749,
    double longitude = -122.4194,
    double radiusKm = 50.0,
    String? chargerType,
    String? currentType,
    String? connector,
  }) async {
    var query = 'latitude=$latitude&longitude=$longitude&radius_km=$radiusKm';
    if (chargerType != null && chargerType.isNotEmpty && chargerType != 'all') {
      query += '&charger_type=$chargerType';
    }
    if (currentType != null && currentType.isNotEmpty && currentType != 'all') {
      query += '&current_type=$currentType';
    }
    if (connector != null && connector.isNotEmpty && connector != 'all') {
      query += '&connector=$connector';
    }

    final url = Uri.parse('$baseUrl/chargers/nearby?$query');
    final resp = await http.get(url, headers: _headers());
    if (resp.statusCode == 200) {
      final list = jsonDecode(resp.body) as List;
      return list.map((e) => Charger.fromJson(e)).toList();
    }
    throw Exception('Failed to load nearby chargers');
  }

  Future<Charger> getChargerById(int id) async {
    final url = Uri.parse('$baseUrl/chargers/$id');
    final resp = await http.get(url, headers: _headers());
    if (resp.statusCode == 200) {
      return Charger.fromJson(jsonDecode(resp.body));
    }
    throw Exception('Failed to load charger details');
  }

  Future<void> reportChargerFault(int chargerId, String issueType, String? description) async {
    final url = Uri.parse('$baseUrl/chargers/$chargerId/report');
    final resp = await http.post(
      url,
      headers: _headers(),
      body: jsonEncode({'charger_id': chargerId, 'issue_type': issueType, 'description': description}),
    );
    if (resp.statusCode != 201) {
      throw Exception('Failed to submit fault report');
    }
  }

  // ---------------- BOOKINGS ----------------
  Future<Booking> createBooking({
    required int chargerId,
    int? vehicleId,
    required DateTime startTime,
    required DateTime endTime,
    bool isBackupBooking = false,
    String? backupTriggerReason,
  }) async {
    final url = Uri.parse('$baseUrl/bookings');
    final resp = await http.post(
      url,
      headers: _headers(),
      body: jsonEncode({
        'charger_id': chargerId,
        'vehicle_id': vehicleId,
        'start_time': startTime.toIso8601String(),
        'end_time': endTime.toIso8601String(),
        'is_backup_booking': isBackupBooking,
        'backup_trigger_reason': backupTriggerReason,
      }),
    );
    if (resp.statusCode == 201) {
      return Booking.fromJson(jsonDecode(resp.body));
    } else {
      final error = jsonDecode(resp.body);
      throw Exception(error['detail'] ?? 'Booking creation failed');
    }
  }

  Future<List<Booking>> getUserBookings({String? statusFilter}) async {
    var query = '';
    if (statusFilter != null && statusFilter.isNotEmpty && statusFilter != 'all') {
      query = '?status_filter=$statusFilter';
    }
    final url = Uri.parse('$baseUrl/bookings$query');
    final resp = await http.get(url, headers: _headers());
    if (resp.statusCode == 200) {
      final list = jsonDecode(resp.body) as List;
      return list.map((e) => Booking.fromJson(e)).toList();
    }
    throw Exception('Failed to load bookings');
  }

  Future<Booking> acceptBooking(int id) async {
    final url = Uri.parse('$baseUrl/bookings/$id/accept');
    final resp = await http.post(url, headers: _headers());
    if (resp.statusCode == 200) {
      return Booking.fromJson(jsonDecode(resp.body));
    }
    throw Exception('Failed to accept booking');
  }

  Future<Booking> rejectBooking(int id, {String reason = "Host unavailable"}) async {
    final url = Uri.parse('$baseUrl/bookings/$id/reject');
    final resp = await http.post(url, headers: _headers(), body: jsonEncode({'reason': reason}));
    if (resp.statusCode == 200) {
      return Booking.fromJson(jsonDecode(resp.body));
    }
    throw Exception('Failed to reject booking');
  }

  Future<Booking> cancelBooking(int id, {String reason = "Driver cancelled"}) async {
    final url = Uri.parse('$baseUrl/bookings/$id/cancel');
    final resp = await http.post(url, headers: _headers(), body: jsonEncode({'reason': reason}));
    if (resp.statusCode == 200) {
      return Booking.fromJson(jsonDecode(resp.body));
    }
    throw Exception('Failed to cancel booking');
  }

  // ---------------- SESSIONS ----------------
  Future<ChargingSession> startSession({
    required int chargerId,
    int? bookingId,
    int? vehicleId,
    required double initialBatteryPercent,
    String? notes,
  }) async {
    final url = Uri.parse('$baseUrl/sessions');
    final resp = await http.post(
      url,
      headers: _headers(),
      body: jsonEncode({
        'charger_id': chargerId,
        'booking_id': bookingId,
        'vehicle_id': vehicleId,
        'initial_battery_percent': initialBatteryPercent,
        'notes': notes,
      }),
    );
    if (resp.statusCode == 201) {
      return ChargingSession.fromJson(jsonDecode(resp.body));
    }
    final error = jsonDecode(resp.body);
    throw Exception(error['detail'] ?? 'Failed to start charging session');
  }

  Future<ChargingSession?> getActiveSession() async {
    final url = Uri.parse('$baseUrl/sessions/active');
    final resp = await http.get(url, headers: _headers());
    if (resp.statusCode == 200) {
      if (resp.body.isEmpty || resp.body == 'null') return null;
      return ChargingSession.fromJson(jsonDecode(resp.body));
    }
    return null;
  }

  Future<ChargingSession> completeSession({
    required int sessionId,
    required double finalBatteryPercent,
    double? energyDeliveredKwh,
    String? notes,
  }) async {
    final url = Uri.parse('$baseUrl/sessions/$sessionId/complete');
    final resp = await http.post(
      url,
      headers: _headers(),
      body: jsonEncode({
        'final_battery_percent': finalBatteryPercent,
        'energy_delivered_kwh': energyDeliveredKwh,
        'notes': notes,
      }),
    );
    if (resp.statusCode == 200) {
      return ChargingSession.fromJson(jsonDecode(resp.body));
    }
    throw Exception('Failed to complete charging session');
  }

  // ---------------- BACKUP ENGINE ----------------
  Future<BackupResult> evaluateBackup({
    required double currentLatitude,
    required double currentLongitude,
    int? vehicleId,
    double? currentBatteryPercent,
    double? batteryCapacityKwh,
    double? consumptionWhPerKm,
    String? connectorType,
    double minSafetyReservePercent = 15.0,
    int? failedChargerId,
    String failureReason = "Host rejected booking / Charger unavailable",
  }) async {
    final url = Uri.parse('$baseUrl/backup/recommend');
    final resp = await http.post(
      url,
      headers: _headers(),
      body: jsonEncode({
        'current_latitude': currentLatitude,
        'current_longitude': currentLongitude,
        'vehicle_id': vehicleId,
        'current_battery_percent': currentBatteryPercent,
        'battery_capacity_kwh': batteryCapacityKwh,
        'consumption_wh_per_km': consumptionWhPerKm,
        'connector_type': connectorType,
        'min_safety_reserve_percent': minSafetyReservePercent,
        'failed_charger_id': failedChargerId,
        'failure_reason': failureReason,
      }),
    );
    if (resp.statusCode == 200) {
      return BackupResult.fromJson(jsonDecode(resp.body));
    }
    throw Exception('Failed to evaluate backup options');
  }

  // ---------------- TRIP PLANNER ----------------
  Future<TripPlan> planTrip({
    required double originLatitude,
    required double originLongitude,
    required double destinationLatitude,
    required double destinationLongitude,
    int? vehicleId,
    required double currentBatteryPercent,
    double minSafetyReservePercent = 15.0,
  }) async {
    final url = Uri.parse('$baseUrl/trip/plan');
    final resp = await http.post(
      url,
      headers: _headers(),
      body: jsonEncode({
        'origin_latitude': originLatitude,
        'origin_longitude': originLongitude,
        'destination_latitude': destinationLatitude,
        'destination_longitude': destinationLongitude,
        'vehicle_id': vehicleId,
        'current_battery_percent': currentBatteryPercent,
        'min_safety_reserve_percent': minSafetyReservePercent,
      }),
    );
    if (resp.statusCode == 200) {
      return TripPlan.fromJson(jsonDecode(resp.body));
    }
    throw Exception('Failed to plan trip');
  }

  // ---------------- HOST ----------------
  Future<List<Charger>> getHostChargers() async {
    final url = Uri.parse('$baseUrl/host/chargers');
    final resp = await http.get(url, headers: _headers());
    if (resp.statusCode == 200) {
      final list = jsonDecode(resp.body) as List;
      return list.map((e) => Charger.fromJson(e)).toList();
    }
    throw Exception('Failed to load host chargers');
  }

  Future<List<Booking>> getHostBookings() async {
    final url = Uri.parse('$baseUrl/host/bookings');
    final resp = await http.get(url, headers: _headers());
    if (resp.statusCode == 200) {
      final list = jsonDecode(resp.body) as List;
      return list.map((e) => Booking.fromJson(e)).toList();
    }
    throw Exception('Failed to load host bookings');
  }

  Future<Map<String, dynamic>> getHostAnalytics() async {
    final url = Uri.parse('$baseUrl/host/analytics');
    final resp = await http.get(url, headers: _headers());
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to load host analytics');
  }

  // ---------------- ADMIN ----------------
  Future<Map<String, dynamic>> getAdminAnalytics() async {
    final url = Uri.parse('$baseUrl/admin/analytics');
    final resp = await http.get(url, headers: _headers());
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to load admin analytics');
  }

  Future<List<User>> getAdminUsers() async {
    final url = Uri.parse('$baseUrl/admin/users');
    final resp = await http.get(url, headers: _headers());
    if (resp.statusCode == 200) {
      final list = jsonDecode(resp.body) as List;
      return list.map((e) => User.fromJson(e)).toList();
    }
    throw Exception('Failed to load users');
  }

  Future<void> verifyUser(int id) async {
    final url = Uri.parse('$baseUrl/admin/users/$id/verify');
    final resp = await http.patch(url, headers: _headers());
    if (resp.statusCode != 200) {
      throw Exception('Failed to verify user');
    }
  }

  Future<List<Charger>> getAdminChargers() async {
    final url = Uri.parse('$baseUrl/admin/chargers');
    final resp = await http.get(url, headers: _headers());
    if (resp.statusCode == 200) {
      final list = jsonDecode(resp.body) as List;
      return list.map((e) => Charger.fromJson(e)).toList();
    }
    throw Exception('Failed to load admin chargers');
  }

  Future<void> setAdminChargerStatus(int id, String newStatus) async {
    final url = Uri.parse('$baseUrl/admin/chargers/$id/status?new_status=$newStatus');
    final resp = await http.patch(url, headers: _headers());
    if (resp.statusCode != 200) {
      throw Exception('Failed to update charger status');
    }
  }

  Future<List<Map<String, dynamic>>> getAdminFaultReports() async {
    final url = Uri.parse('$baseUrl/admin/fault-reports');
    final resp = await http.get(url, headers: _headers());
    if (resp.statusCode == 200) {
      final list = jsonDecode(resp.body) as List;
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    throw Exception('Failed to load fault reports');
  }

  Future<void> resolveFaultReport(int id) async {
    final url = Uri.parse('$baseUrl/admin/fault-reports/$id/resolve');
    final resp = await http.patch(url, headers: _headers());
    if (resp.statusCode != 200) {
      throw Exception('Failed to resolve fault report');
    }
  }

  Future<List<Map<String, dynamic>>> getAdminAuditLogs() async {
    final url = Uri.parse('$baseUrl/admin/audit-logs');
    final resp = await http.get(url, headers: _headers());
    if (resp.statusCode == 200) {
      final list = jsonDecode(resp.body) as List;
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    throw Exception('Failed to load audit logs');
  }
}
