import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../services/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/battery_gauge.dart';
import '../../widgets/status_badge.dart';
import 'backup_engine_screen.dart';
import 'charger_detail_screen.dart';
import 'charging_session_screen.dart';
import 'vehicle_management_screen.dart';

class DashboardTab extends StatelessWidget {
  final ValueChanged<int> onNavigateTab;

  const DashboardTab({super.key, required this.onNavigateTab});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final user = appState.currentUser;
    final vehicle = appState.activeVehicle;
    final chargers = appState.chargers;
    final bookings = appState.bookings;
    final activeSession = appState.activeSession;

    // Upcoming booking if any
    final upcomingBooking = bookings.cast<Booking?>().firstWhere(
          (b) => b?.status == 'confirmed' || b?.status == 'pending',
          orElse: () => null,
        );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, ${user?.fullName.split(' ').first ?? 'Driver'}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
            const Text(
              'Always a Charge Ahead',
              style: TextStyle(fontSize: 12, color: AppColors.primaryTeal, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Network Status',
            onPressed: () => appState.refreshAllData(),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none_outlined),
            tooltip: 'Notifications',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('ChargeSure notifications: All stations operational.')),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => appState.refreshAllData(),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // Active Session Alert Card if currently charging
            if (activeSession != null) ...[
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ChargingSessionScreen()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryTeal,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryTeal.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.bolt, color: Colors.white, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Charging In Progress...',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
                            ),
                            Text(
                              '${activeSession.energyDeliveredKwh.toStringAsFixed(1)} kWh delivered • \$${activeSession.totalCost.toStringAsFixed(2)}',
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 14),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Active Vehicle & Battery Range Card
            if (vehicle != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Vehicle Energy Status',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.secondaryNavy),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const VehicleManagementScreen()),
                      );
                    },
                    child: const Text('Manage Garage'),
                  ),
                ],
              ),
              BatteryGauge(
                vehicle: vehicle,
                onBatteryChanged: (val) {
                  appState.updateActiveVehicleBattery(val);
                },
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.directions_car_filled_outlined, size: 40, color: AppColors.textMuted),
                    const SizedBox(height: 10),
                    const Text('No vehicle connected yet', style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const VehicleManagementScreen()),
                        );
                      },
                      child: const Text('Add Your EV'),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),

            // Quick Actions Row
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionButton(
                    icon: Icons.search,
                    label: 'Find Charger',
                    color: AppColors.primaryTeal,
                    onTap: () => onNavigateTab(1),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildQuickActionButton(
                    icon: Icons.alt_route,
                    label: 'Plan Trip',
                    color: AppColors.secondaryNavy,
                    onTap: () => onNavigateTab(2),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildQuickActionButton(
                    icon: Icons.shield,
                    label: 'Backup Engine',
                    color: AppColors.error,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const BackupEngineScreen()),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Upcoming Booking Card if any
            if (upcomingBooking != null) ...[
              const Text(
                'Upcoming Reservation',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.secondaryNavy),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.accentSkyBlueDark),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          upcomingBooking.charger?.title ?? 'Charging Station',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                        StatusBadge(status: upcomingBooking.status),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${DateFormat('EEE, MMM d • h:mm a').format(upcomingBooking.startTime)} - ${DateFormat('h:mm a').format(upcomingBooking.endTime)}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.navigation, size: 16),
                            label: const Text('Directions'),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Opening navigation directions...')),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        if (upcomingBooking.status == 'confirmed')
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.bolt, size: 16),
                              label: const Text('Start Session'),
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ChargingSessionScreen(
                                      charger: upcomingBooking.charger,
                                      bookingId: upcomingBooking.id,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Nearby Chargers Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Nearby Charging Stations',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.secondaryNavy),
                ),
                TextButton(
                  onPressed: () => onNavigateTab(1),
                  child: const Text('View All Map'),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ...chargers.take(3).map((ch) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => ChargerDetailScreen(charger: ch)),
                      );
                    },
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: ch.powerKw >= 100.0 ? AppColors.accentSkyBlue : AppColors.surfaceMuted,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            ch.chargerType == 'home' ? Icons.home : Icons.ev_station,
                            color: AppColors.primaryTeal,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ch.title,
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${ch.currentType} • ${ch.powerKw.toStringAsFixed(0)} kW • \$${ch.pricePerKwh.toStringAsFixed(2)}/kWh',
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  StatusBadge(status: ch.status),
                                  const SizedBox(width: 6),
                                  StatusBadge(status: ch.dataSource, isDataSource: true),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textMuted),
                      ],
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
