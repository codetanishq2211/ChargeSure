import 'dart:convert';

class User {
  final int id;
  final String email;
  final String fullName;
  final String? phone;
  final String role; // "driver", "host", "admin"
  final bool isActive;
  final bool isVerified;

  User({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
    required this.role,
    required this.isActive,
    required this.isVerified,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      email: json['email'] as String,
      fullName: json['full_name'] as String,
      phone: json['phone'] as String?,
      role: json['role'] as String? ?? 'driver',
      isActive: json['is_active'] as bool? ?? true,
      isVerified: json['is_verified'] as bool? ?? false,
    );
  }
}

class Vehicle {
  final int id;
  final int userId;
  final String make;
  final String model;
  final int year;
  final String? licensePlate;
  final double batteryCapacityKwh;
  final String connectorType;
  final double consumptionWhPerKm;
  double currentBatteryPercent;
  final bool isPrimary;
  final double estimatedRangeKm;

  Vehicle({
    required this.id,
    required this.userId,
    required this.make,
    required this.model,
    required this.year,
    this.licensePlate,
    required this.batteryCapacityKwh,
    required this.connectorType,
    required this.consumptionWhPerKm,
    required this.currentBatteryPercent,
    required this.isPrimary,
    required this.estimatedRangeKm,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      make: json['make'] as String,
      model: json['model'] as String,
      year: json['year'] as int? ?? 2024,
      licensePlate: json['license_plate'] as String?,
      batteryCapacityKwh: (json['battery_capacity_kwh'] as num).toDouble(),
      connectorType: json['connector_type'] as String? ?? 'CCS2',
      consumptionWhPerKm: (json['consumption_wh_per_km'] as num?)?.toDouble() ?? 160.0,
      currentBatteryPercent: (json['current_battery_percent'] as num).toDouble(),
      isPrimary: json['is_primary'] as bool? ?? false,
      estimatedRangeKm: (json['estimated_range_km'] as num?)?.toDouble() ?? 280.0,
    );
  }

  double calculateCurrentRange() {
    return (batteryCapacityKwh * 1000.0 * (currentBatteryPercent / 100.0)) /
        (consumptionWhPerKm > 0 ? consumptionWhPerKm : 160.0);
  }
}

class Charger {
  final int id;
  final int? hostId;
  final String title;
  final String? description;
  final String address;
  final String city;
  final String? state;
  final String? postalCode;
  final double latitude;
  final double longitude;
  final String chargerType; // "public", "business", "home"
  final String currentType; // "AC", "DC"
  final double powerKw;
  final List<String> connectorTypes;
  final double pricePerKwh;
  final double pricePerHour;
  final String pricingModel;
  final String status; // "available", "in_use", "faulty", "offline"
  final String dataSource; // "live_operator", "host_confirmed", "manually_reported", "unverified"
  final String? accessInstructions;
  final bool isAccessMasked;
  final DateTime freshnessTimestamp;
  final bool isVerified;
  final double reliabilityScore;
  final double? distanceKm;
  final double averageRating;
  final int totalReviews;

  Charger({
    required this.id,
    this.hostId,
    required this.title,
    this.description,
    required this.address,
    required this.city,
    this.state,
    this.postalCode,
    required this.latitude,
    required this.longitude,
    required this.chargerType,
    required this.currentType,
    required this.powerKw,
    required this.connectorTypes,
    required this.pricePerKwh,
    required this.pricePerHour,
    required this.pricingModel,
    required this.status,
    required this.dataSource,
    this.accessInstructions,
    required this.isAccessMasked,
    required this.freshnessTimestamp,
    required this.isVerified,
    required this.reliabilityScore,
    this.distanceKm,
    required this.averageRating,
    required this.totalReviews,
  });

  factory Charger.fromJson(Map<String, dynamic> json) {
    var rawConnectors = json['connector_types'];
    List<String> connectors = [];
    if (rawConnectors is List) {
      connectors = rawConnectors.map((e) => e.toString()).toList();
    } else if (rawConnectors is String) {
      try {
        connectors = (jsonDecode(rawConnectors) as List).map((e) => e.toString()).toList();
      } catch (_) {
        connectors = [rawConnectors];
      }
    }

    return Charger(
      id: json['id'] as int,
      hostId: json['host_id'] as int?,
      title: json['title'] as String,
      description: json['description'] as String?,
      address: json['address'] as String? ?? 'San Francisco, CA',
      city: json['city'] as String? ?? 'San Francisco',
      state: json['state'] as String?,
      postalCode: json['postal_code'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      chargerType: json['charger_type'] as String? ?? 'public',
      currentType: json['current_type'] as String? ?? 'DC',
      powerKw: (json['power_kw'] as num).toDouble(),
      connectorTypes: connectors,
      pricePerKwh: (json['price_per_kwh'] as num?)?.toDouble() ?? 0.0,
      pricePerHour: (json['price_per_hour'] as num?)?.toDouble() ?? 0.0,
      pricingModel: json['pricing_model'] as String? ?? 'per_kwh',
      status: json['status'] as String? ?? 'available',
      dataSource: json['data_source'] as String? ?? 'live_operator',
      accessInstructions: json['access_instructions'] as String?,
      isAccessMasked: json['is_access_masked'] as bool? ?? false,
      freshnessTimestamp: json['freshness_timestamp'] != null
          ? DateTime.tryParse(json['freshness_timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isVerified: json['is_verified'] as bool? ?? true,
      reliabilityScore: (json['reliability_score'] as num?)?.toDouble() ?? 95.0,
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      averageRating: (json['average_rating'] as num?)?.toDouble() ?? 4.8,
      totalReviews: json['total_reviews'] as int? ?? 5,
    );
  }
}

class Booking {
  final int id;
  final String bookingCode;
  final int driverId;
  final int? hostId;
  final int chargerId;
  final int? vehicleId;
  final DateTime startTime;
  final DateTime endTime;
  String status; // "pending", "confirmed", "rejected", "cancelled", "in_progress", "completed"
  final double totalPriceSnapshot;
  final String? cancellationReason;
  final bool isBackupBooking;
  final String? backupTriggerReason;
  final Charger? charger;
  final Vehicle? vehicle;
  final String? driverName;

  Booking({
    required this.id,
    required this.bookingCode,
    required this.driverId,
    this.hostId,
    required this.chargerId,
    this.vehicleId,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.totalPriceSnapshot,
    this.cancellationReason,
    required this.isBackupBooking,
    this.backupTriggerReason,
    this.charger,
    this.vehicle,
    this.driverName,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] as int,
      bookingCode: json['booking_code'] as String? ?? 'CS-DEMO',
      driverId: json['driver_id'] as int,
      hostId: json['host_id'] as int?,
      chargerId: json['charger_id'] as int,
      vehicleId: json['vehicle_id'] as int?,
      startTime: DateTime.tryParse(json['start_time'].toString()) ?? DateTime.now(),
      endTime: DateTime.tryParse(json['end_time'].toString()) ?? DateTime.now().add(const Duration(hours: 1)),
      status: json['status'] as String? ?? 'pending',
      totalPriceSnapshot: (json['total_price_snapshot'] as num?)?.toDouble() ?? 15.0,
      cancellationReason: json['cancellation_reason'] as String?,
      isBackupBooking: json['is_backup_booking'] as bool? ?? false,
      backupTriggerReason: json['backup_trigger_reason'] as String?,
      charger: json['charger'] != null ? Charger.fromJson(json['charger']) : null,
      vehicle: json['vehicle'] != null ? Vehicle.fromJson(json['vehicle']) : null,
      driverName: json['driver_name'] as String?,
    );
  }
}

class ChargingSession {
  final int id;
  final int? bookingId;
  final int driverId;
  final int chargerId;
  final int? vehicleId;
  final DateTime startTime;
  DateTime? endTime;
  int? durationMinutes;
  final double initialBatteryPercent;
  double? finalBatteryPercent;
  double energyDeliveredKwh;
  double totalCost;
  String status; // "active", "completed", "interrupted"
  final String telemetrySource;
  final String? notes;

  ChargingSession({
    required this.id,
    this.bookingId,
    required this.driverId,
    required this.chargerId,
    this.vehicleId,
    required this.startTime,
    this.endTime,
    this.durationMinutes,
    required this.initialBatteryPercent,
    this.finalBatteryPercent,
    required this.energyDeliveredKwh,
    required this.totalCost,
    required this.status,
    required this.telemetrySource,
    this.notes,
  });

  factory ChargingSession.fromJson(Map<String, dynamic> json) {
    return ChargingSession(
      id: json['id'] as int,
      bookingId: json['booking_id'] as int?,
      driverId: json['driver_id'] as int,
      chargerId: json['charger_id'] as int,
      vehicleId: json['vehicle_id'] as int?,
      startTime: DateTime.tryParse(json['start_time'].toString()) ?? DateTime.now(),
      endTime: json['end_time'] != null ? DateTime.tryParse(json['end_time'].toString()) : null,
      durationMinutes: json['duration_minutes'] as int?,
      initialBatteryPercent: (json['initial_battery_percent'] as num).toDouble(),
      finalBatteryPercent: (json['final_battery_percent'] as num?)?.toDouble(),
      energyDeliveredKwh: (json['energy_delivered_kwh'] as num?)?.toDouble() ?? 0.0,
      totalCost: (json['total_cost'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'active',
      telemetrySource: json['telemetry_source'] as String? ?? 'simulated',
      notes: json['notes'] as String?,
    );
  }
}

class BackupCandidate {
  final Charger charger;
  final double distanceKm;
  final double detourKm;
  final int estimatedDrivingTimeMinutes;
  final double estimatedArrivalBatteryPercent;
  final bool isSafelyReachable;
  final bool connectorCompatible;
  final double availabilityConfidenceScore;
  final double overallRankScore;
  final String primaryRecommendationReason;

  BackupCandidate({
    required this.charger,
    required this.distanceKm,
    required this.detourKm,
    required this.estimatedDrivingTimeMinutes,
    required this.estimatedArrivalBatteryPercent,
    required this.isSafelyReachable,
    required this.connectorCompatible,
    required this.availabilityConfidenceScore,
    required this.overallRankScore,
    required this.primaryRecommendationReason,
  });

  factory BackupCandidate.fromJson(Map<String, dynamic> json) {
    return BackupCandidate(
      charger: Charger.fromJson(json['charger']),
      distanceKm: (json['distance_km'] as num).toDouble(),
      detourKm: (json['detour_km'] as num).toDouble(),
      estimatedDrivingTimeMinutes: json['estimated_driving_time_minutes'] as int,
      estimatedArrivalBatteryPercent: (json['estimated_arrival_battery_percent'] as num).toDouble(),
      isSafelyReachable: json['is_safely_reachable'] as bool,
      connectorCompatible: json['connector_compatible'] as bool,
      availabilityConfidenceScore: (json['availability_confidence_score'] as num).toDouble(),
      overallRankScore: (json['overall_rank_score'] as num).toDouble(),
      primaryRecommendationReason: json['primary_recommendation_reason'] as String,
    );
  }
}

class BackupResult {
  final String failureReason;
  final String? originalChargerTitle;
  final String vehicleSummary;
  final double minSafetyReservePercent;
  final int candidatesFound;
  final int safeCandidatesCount;
  final bool hasSafeAlternative;
  final String statusSummary;
  final BackupCandidate? bestCandidate;
  final List<BackupCandidate> additionalOptions;
  final List<Map<String, dynamic>> emergencyContacts;

  BackupResult({
    required this.failureReason,
    this.originalChargerTitle,
    required this.vehicleSummary,
    required this.minSafetyReservePercent,
    required this.candidatesFound,
    required this.safeCandidatesCount,
    required this.hasSafeAlternative,
    required this.statusSummary,
    this.bestCandidate,
    required this.additionalOptions,
    required this.emergencyContacts,
  });

  factory BackupResult.fromJson(Map<String, dynamic> json) {
    List<BackupCandidate> addOpts = [];
    if (json['additional_options'] is List) {
      addOpts = (json['additional_options'] as List)
          .map((e) => BackupCandidate.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    List<Map<String, dynamic>> emerg = [];
    if (json['emergency_contacts'] is List) {
      emerg = (json['emergency_contacts'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }

    return BackupResult(
      failureReason: json['failure_reason'] as String,
      originalChargerTitle: json['original_charger_title'] as String?,
      vehicleSummary: json['vehicle_summary'] as String? ?? 'Vehicle',
      minSafetyReservePercent: (json['min_safety_reserve_percent'] as num?)?.toDouble() ?? 15.0,
      candidatesFound: json['candidates_found'] as int? ?? 0,
      safeCandidatesCount: json['safe_candidates_count'] as int? ?? 0,
      hasSafeAlternative: json['has_safe_alternative'] as bool? ?? false,
      statusSummary: json['status_summary'] as String,
      bestCandidate: json['best_candidate'] != null
          ? BackupCandidate.fromJson(json['best_candidate'])
          : null,
      additionalOptions: addOpts,
      emergencyContacts: emerg,
    );
  }
}

class TripStop {
  final Charger charger;
  final double distanceFromOriginKm;
  final double arrivalBatteryPercent;
  final double targetChargeBatteryPercent;
  final int chargingTimeMinutes;
  final double energyNeededKwh;
  final double estimatedCost;

  TripStop({
    required this.charger,
    required this.distanceFromOriginKm,
    required this.arrivalBatteryPercent,
    required this.targetChargeBatteryPercent,
    required this.chargingTimeMinutes,
    required this.energyNeededKwh,
    required this.estimatedCost,
  });

  factory TripStop.fromJson(Map<String, dynamic> json) {
    return TripStop(
      charger: Charger.fromJson(json['charger']),
      distanceFromOriginKm: (json['distance_from_origin_km'] as num).toDouble(),
      arrivalBatteryPercent: (json['arrival_battery_percent'] as num).toDouble(),
      targetChargeBatteryPercent: (json['target_charge_battery_percent'] as num).toDouble(),
      chargingTimeMinutes: json['charging_time_minutes'] as int,
      energyNeededKwh: (json['energy_needed_kwh'] as num).toDouble(),
      estimatedCost: (json['estimated_cost'] as num).toDouble(),
    );
  }
}

class TripPlan {
  final double totalDistanceKm;
  final int totalDrivingTimeMinutes;
  final int totalTripTimeMinutes;
  final double initialBatteryPercent;
  final double estimatedConsumptionKwh;
  final double estimatedArrivalBatteryPercent;
  final bool isChargingRequired;
  final String explanation;
  final List<TripStop> suggestedStops;
  final List<Map<String, double>> routeWaypoints;

  TripPlan({
    required this.totalDistanceKm,
    required this.totalDrivingTimeMinutes,
    required this.totalTripTimeMinutes,
    required this.initialBatteryPercent,
    required this.estimatedConsumptionKwh,
    required this.estimatedArrivalBatteryPercent,
    required this.isChargingRequired,
    required this.explanation,
    required this.suggestedStops,
    required this.routeWaypoints,
  });

  factory TripPlan.fromJson(Map<String, dynamic> json) {
    List<TripStop> stops = [];
    if (json['suggested_stops'] is List) {
      stops = (json['suggested_stops'] as List)
          .map((e) => TripStop.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    List<Map<String, double>> waypoints = [];
    if (json['route_waypoints'] is List) {
      for (var wp in json['route_waypoints']) {
        if (wp is Map) {
          waypoints.add({
            'latitude': (wp['latitude'] as num).toDouble(),
            'longitude': (wp['longitude'] as num).toDouble(),
          });
        }
      }
    }

    return TripPlan(
      totalDistanceKm: (json['total_distance_km'] as num).toDouble(),
      totalDrivingTimeMinutes: json['total_driving_time_minutes'] as int,
      totalTripTimeMinutes: json['total_trip_time_minutes'] as int,
      initialBatteryPercent: (json['initial_battery_percent'] as num).toDouble(),
      estimatedConsumptionKwh: (json['estimated_consumption_kwh'] as num).toDouble(),
      estimatedArrivalBatteryPercent: (json['estimated_arrival_battery_percent'] as num).toDouble(),
      isChargingRequired: json['is_charging_required'] as bool,
      explanation: json['explanation'] as String,
      suggestedStops: stops,
      routeWaypoints: waypoints,
    );
  }
}
