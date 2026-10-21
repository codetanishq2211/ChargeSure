import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/battery_gauge.dart';

class VehicleManagementScreen extends StatefulWidget {
  const VehicleManagementScreen({super.key});

  @override
  State<VehicleManagementScreen> createState() => _VehicleManagementScreenState();
}

class _VehicleManagementScreenState extends State<VehicleManagementScreen> {
  void _openAddVehicleDialog() {
    final makeController = TextEditingController();
    final modelController = TextEditingController();
    final plateController = TextEditingController();
    final capacityController = TextEditingController(text: '75.0');
    final consumptionController = TextEditingController(text: '160.0');
    String connector = 'CCS2';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Add New Electric Vehicle',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: makeController,
                  decoration: const InputDecoration(labelText: 'Make (e.g. Tesla, Hyundai, Tata)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: modelController,
                  decoration: const InputDecoration(labelText: 'Model (e.g. Model 3, Ioniq 5, Nexon EV)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: plateController,
                  decoration: const InputDecoration(labelText: 'License Plate (Optional)'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: capacityController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Battery (kWh)'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: consumptionController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Wh/km'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: connector,
                  decoration: const InputDecoration(labelText: 'Connector Type'),
                  items: const [
                    DropdownMenuItem(value: 'CCS2', child: Text('CCS2 (Universal Fast)')),
                    DropdownMenuItem(value: 'Type 2', child: Text('Type 2 (Mennekes AC)')),
                    DropdownMenuItem(value: 'GB/T', child: Text('GB/T Fast')),
                    DropdownMenuItem(value: 'CHAdeMO', child: Text('CHAdeMO DC')),
                  ],
                  onChanged: (val) {
                    if (val != null) setModalState(() => connector = val);
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    if (makeController.text.trim().isEmpty || modelController.text.trim().isEmpty) return;
                    final appState = Provider.of<AppState>(context, listen: false);
                    await appState.addVehicle({
                      'make': makeController.text.trim(),
                      'model': modelController.text.trim(),
                      'year': 2024,
                      'license_plate': plateController.text.trim(),
                      'battery_capacity_kwh': double.tryParse(capacityController.text) ?? 60.0,
                      'consumption_wh_per_km': double.tryParse(consumptionController.text) ?? 160.0,
                      'connector_type': connector,
                      'current_battery_percent': 80.0,
                      'is_primary': appState.vehicles.isEmpty,
                    });
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Save Vehicle'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final vehicles = appState.vehicles;
    final activeVehicle = appState.activeVehicle;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehicle Garage & Range'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: AppColors.primaryTeal),
            onPressed: _openAddVehicleDialog,
            tooltip: 'Add Vehicle',
          ),
        ],
      ),
      body: vehicles.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.electric_car, size: 64, color: AppColors.textMuted),
                  const SizedBox(height: 16),
                  const Text('No vehicles saved in your garage', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _openAddVehicleDialog,
                    child: const Text('Add Vehicle'),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (activeVehicle != null) ...[
                  const Text(
                    'Active Primary Vehicle',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.secondaryNavy),
                  ),
                  const SizedBox(height: 8),
                  BatteryGauge(
                    vehicle: activeVehicle,
                    onBatteryChanged: (val) {
                      appState.updateActiveVehicleBattery(val);
                    },
                  ),
                  const SizedBox(height: 24),
                ],
                const Text(
                  'Saved Vehicles',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.secondaryNavy),
                ),
                const SizedBox(height: 10),
                ...vehicles.map((v) {
                  final isPrimary = v.id == activeVehicle?.id;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isPrimary ? AppColors.primaryTeal : AppColors.borderSubtle,
                        width: isPrimary ? 1.8 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isPrimary ? AppColors.accentSkyBlue : AppColors.surfaceMuted,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.electric_car,
                            color: isPrimary ? AppColors.primaryTeal : AppColors.textSecondary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${v.make} ${v.model}',
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${v.batteryCapacityKwh.toStringAsFixed(1)} kWh • ${v.connectorType} • ${v.currentBatteryPercent.toStringAsFixed(0)}% battery',
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        if (!isPrimary)
                          TextButton(
                            onPressed: () => appState.setActiveVehicle(v),
                            child: const Text('Set Active'),
                          )
                        else
                          const Icon(Icons.check_circle, color: AppColors.primaryTeal, size: 22),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.textMuted),
                          onPressed: () => appState.deleteVehicle(v.id),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
    );
  }
}
