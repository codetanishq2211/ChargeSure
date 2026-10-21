import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../services/app_state.dart';
import '../../theme/app_theme.dart';
import 'charger_detail_screen.dart';

class TripsTab extends StatefulWidget {
  const TripsTab({super.key});

  @override
  State<TripsTab> createState() => _TripsTabState();
}

class _TripsTabState extends State<TripsTab> {
  final _originController = TextEditingController(text: 'San Francisco Downtown (37.7749, -122.4194)');
  final _destController = TextEditingController(text: 'Oakland Tech Park (37.8044, -122.2712)');
  double _safetyReserve = 15.0;

  // Selected route option: 0 = Short City Trip, 1 = Long Cross-Bay / Highway Trip
  int _routePreset = 0;

  TripPlan? _tripPlan;
  bool _isCalculating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _calculateRoute();
  }

  void _applyPreset(int preset) {
    setState(() {
      _routePreset = preset;
      if (preset == 0) {
        _originController.text = 'San Francisco (37.7749, -122.4194)';
        _destController.text = 'Oakland (37.8044, -122.2712)';
      } else {
        _originController.text = 'San Francisco (37.7749, -122.4194)';
        _destController.text = 'Sacramento Metro (38.5816, -121.4944)';
      }
    });
    _calculateRoute();
  }

  Future<void> _calculateRoute() async {
    setState(() {
      _isCalculating = true;
      _error = null;
    });

    final appState = Provider.of<AppState>(context, listen: false);
    final vehicle = appState.activeVehicle;
    final currentBattery = vehicle?.currentBatteryPercent ?? 45.0;

    double oLat = 37.7749;
    double oLon = -122.4194;
    double dLat = _routePreset == 0 ? 37.8044 : 38.5816;
    double dLon = _routePreset == 0 ? -122.2712 : -121.4944;

    try {
      final plan = await ApiService().planTrip(
        originLatitude: oLat,
        originLongitude: oLon,
        destinationLatitude: dLat,
        destinationLongitude: dLon,
        vehicleId: vehicle?.id,
        currentBatteryPercent: currentBattery,
        minSafetyReservePercent: _safetyReserve,
      );
      if (mounted) {
        setState(() {
          _tripPlan = plan;
          _isCalculating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isCalculating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final vehicle = appState.activeVehicle;

    return Scaffold(
      appBar: AppBar(
        title: const Text('EV Route & Range Planner'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Route Setup Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Plan Route with Battery Assurance', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 12),
                  // Preset Buttons
                  Row(
                    children: [
                      ChoiceChip(
                        label: const Text('Short City Trip (15 km)'),
                        selected: _routePreset == 0,
                        onSelected: (_) => _applyPreset(0),
                        selectedColor: AppColors.accentSkyBlue,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          color: _routePreset == 0 ? AppColors.primaryTeal : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Highway Corridor (140 km)'),
                        selected: _routePreset == 1,
                        onSelected: (_) => _applyPreset(1),
                        selectedColor: AppColors.accentSkyBlue,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          color: _routePreset == 1 ? AppColors.primaryTeal : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _originController,
                    decoration: const InputDecoration(
                      labelText: 'Origin Point',
                      prefixIcon: Icon(Icons.my_location, color: AppColors.primaryTeal, size: 20),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _destController,
                    decoration: const InputDecoration(
                      labelText: 'Destination Point',
                      prefixIcon: Icon(Icons.location_on, color: AppColors.error, size: 20),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Minimum Safety Reserve: ${_safetyReserve.toStringAsFixed(0)}%',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      Text(
                        'Battery: ${vehicle?.currentBatteryPercent.toStringAsFixed(0) ?? "45"}%',
                        style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primaryTeal, fontSize: 13),
                      ),
                    ],
                  ),
                  Slider(
                    value: _safetyReserve,
                    min: 5,
                    max: 30,
                    divisions: 5,
                    activeColor: AppColors.primaryTeal,
                    inactiveColor: AppColors.borderSubtle,
                    onChanged: (val) {
                      setState(() => _safetyReserve = val);
                      _calculateRoute();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Plan Output
            if (_isCalculating)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(color: AppColors.primaryTeal),
                ),
              )
            else if (_error != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.errorLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('Calculation Error: $_error', style: const TextStyle(color: AppColors.error)),
              )
            else if (_tripPlan != null) ...[
              _buildTripSummaryCard(_tripPlan!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTripSummaryCard(TripPlan plan) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Explanation Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: plan.isChargingRequired ? AppColors.warningLight : AppColors.successLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: plan.isChargingRequired ? AppColors.warning : AppColors.success),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                plan.isChargingRequired ? Icons.battery_alert : Icons.check_circle_outline,
                color: plan.isChargingRequired ? AppColors.warning : AppColors.success,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.isChargingRequired ? 'Charging Stop Required' : 'Direct Reachable',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      plan.explanation,
                      style: const TextStyle(fontSize: 13, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Key Trip Stats Grid
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  const Text('Total Distance', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  Text('${plan.totalDistanceKm.toStringAsFixed(0)} km', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ],
              ),
              Container(height: 28, width: 1, color: AppColors.divider),
              Column(
                children: [
                  const Text('Travel Time', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  Text('${plan.totalTripTimeMinutes} mins', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ],
              ),
              Container(height: 28, width: 1, color: AppColors.divider),
              Column(
                children: [
                  const Text('Arrival Battery', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  Text(
                    '${plan.estimatedArrivalBatteryPercent.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: plan.estimatedArrivalBatteryPercent >= _safetyReserve ? AppColors.success : AppColors.error,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Suggested Charging Stops if required
        if (plan.suggestedStops.isNotEmpty) ...[
          const Text(
            'Recommended Corridor Charging Stop',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 10),
          ...plan.suggestedStops.map((stop) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primaryTeal),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(stop.charger.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                        Text('${stop.charger.powerKw.toStringAsFixed(0)} kW DC', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primaryTeal)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Stop at km ${stop.distanceFromOriginKm.toStringAsFixed(0)} • Arrival Battery: ${stop.arrivalBatteryPercent.toStringAsFixed(0)}%',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Charge for ${stop.chargingTimeMinutes} mins to reach ${stop.targetChargeBatteryPercent.toStringAsFixed(0)}% (Energy: ${stop.energyNeededKwh.toStringAsFixed(1)} kWh, Est. Cost: \$${stop.estimatedCost.toStringAsFixed(2)})',
                      style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => ChargerDetailScreen(charger: stop.charger)),
                        );
                      },
                      child: const Text('Reserve Stop Slot'),
                    ),
                  ],
                ),
              )),
        ],
      ],
    );
  }
}
