import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';

class BatteryGauge extends StatelessWidget {
  final Vehicle vehicle;
  final ValueChanged<double>? onBatteryChanged;

  const BatteryGauge({
    super.key,
    required this.vehicle,
    this.onBatteryChanged,
  });

  @override
  Widget build(BuildContext context) {
    final battery = vehicle.currentBatteryPercent;
    final rangeKm = vehicle.calculateCurrentRange();

    Color gaugeColor;
    if (battery >= 30.0) {
      gaugeColor = AppColors.success;
    } else if (battery >= 15.0) {
      gaugeColor = AppColors.warning;
    } else {
      gaugeColor = AppColors.error;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.accentSkyBlue,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.electric_car, color: AppColors.primaryTeal, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${vehicle.make} ${vehicle.model}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${vehicle.batteryCapacityKwh.toStringAsFixed(1)} kWh • ${vehicle.connectorType}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Primary',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '${battery.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: gaugeColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '≈ ${rangeKm.toStringAsFixed(0)} km',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Estimated Driving Range',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Icon(
                battery >= 20 ? Icons.battery_charging_full : Icons.battery_alert,
                color: gaugeColor,
                size: 36,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Battery Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: battery / 100.0,
              minHeight: 10,
              backgroundColor: AppColors.surfaceMuted,
              valueColor: AlwaysStoppedAnimation<Color>(gaugeColor),
            ),
          ),
          if (onBatteryChanged != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Text(
                  'Adjust Battery %:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                ),
                Expanded(
                  child: Slider(
                    value: battery,
                    min: 5,
                    max: 100,
                    divisions: 19,
                    activeColor: AppColors.primaryTeal,
                    inactiveColor: AppColors.borderSubtle,
                    onChanged: onBatteryChanged,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, size: 14, color: AppColors.textMuted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Estimated range based on configured ${160} Wh/km. Actual range varies with speed, weather, and terrain.',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
