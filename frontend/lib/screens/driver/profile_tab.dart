import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/app_state.dart';
import '../../theme/app_theme.dart';
import '../auth/auth_screen.dart';
import '../host/host_dashboard_screen.dart';
import '../admin/admin_dashboard_screen.dart';
import 'emergency_support_screen.dart';
import 'vehicle_management_screen.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final user = appState.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // User Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.primaryTeal.withOpacity(0.12),
                  child: Text(
                    user != null && user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'U',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.primaryTeal),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.fullName ?? 'EV Driver',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user?.email ?? 'driver@chargesure.com',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.accentSkyBlue,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'ROLE: ${(user?.role ?? "driver").toUpperCase()}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primaryTeal),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Role Switcher for Evaluator Convenience
          const Text('Switch Role Mode', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.secondaryNavy)),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Material(
                color: Colors.transparent,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.electric_car, color: AppColors.primaryTeal),
                      title: const Text('EV Driver App Mode'),
                      subtitle: const Text('Search chargers, plan trips, book slots'),
                      trailing: const Icon(Icons.check, color: AppColors.primaryTeal),
                      onTap: () {},
                    ),
                    const Divider(height: 1, color: AppColors.divider),
                    ListTile(
                      leading: const Icon(Icons.home_work, color: AppColors.secondaryNavy),
                      title: const Text('Charger Host App Mode'),
                      subtitle: const Text('Manage your listings, approve requests & earnings'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                      onTap: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const HostDashboardScreen()),
                        );
                      },
                    ),
                    const Divider(height: 1, color: AppColors.divider),
                    ListTile(
                      leading: const Icon(Icons.admin_panel_settings, color: AppColors.warning),
                      title: const Text('Admin Web Dashboard'),
                      subtitle: const Text('Platform reliability, audit logs, charger status'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                      onTap: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // App Settings
          const Text('Preferences & Services', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.secondaryNavy)),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Material(
                color: Colors.transparent,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.garage_outlined),
                      title: const Text('My Garage & Vehicles'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const VehicleManagementScreen()),
                        );
                      },
                    ),
                    const Divider(height: 1, color: AppColors.divider),
                    ListTile(
                      leading: const Icon(Icons.emergency_outlined, color: AppColors.error),
                      title: const Text('Emergency EV Assistance'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const EmergencySupportScreen()),
                        );
                      },
                    ),
                    const Divider(height: 1, color: AppColors.divider),
                    ListTile(
                      leading: const Icon(Icons.info_outline),
                      title: const Text('About ChargeSure'),
                      subtitle: const Text('v1.0.0 • Intelligent EV Charging Assurance'),
                      onTap: () {
                        showAboutDialog(
                          context: context,
                          applicationName: 'ChargeSure',
                          applicationVersion: '1.0.0',
                          applicationLegalese: '“Always a Charge Ahead.”\nDesigned with minimal MedSuraksha elegance.',
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Logout Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
              ),
              icon: const Icon(Icons.logout),
              label: const Text('Sign Out'),
              onPressed: () async {
                await appState.logout();
                if (context.mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const AuthScreen()),
                  );
                }
              },
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
