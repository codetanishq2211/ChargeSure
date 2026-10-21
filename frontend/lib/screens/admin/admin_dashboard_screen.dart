import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/status_badge.dart';
import '../driver/driver_root_screen.dart';
import '../host/host_dashboard_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedNavIndex = 0; // 0=Overview, 1=Users, 2=Chargers, 3=Faults, 4=Audit Logs
  Map<String, dynamic>? _analytics;
  List<User> _users = [];
  List<Charger> _chargers = [];
  List<Map<String, dynamic>> _faults = [];
  List<Map<String, dynamic>> _auditLogs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    setState(() => _isLoading = true);
    final api = ApiService();
    try {
      final an = await api.getAdminAnalytics();
      final us = await api.getAdminUsers();
      final ch = await api.getAdminChargers();
      final ft = await api.getAdminFaultReports();
      final al = await api.getAdminAuditLogs();

      if (mounted) {
        setState(() {
          _analytics = an;
          _users = us;
          _chargers = ch;
          _faults = ft;
          _auditLogs = al;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleChargerStatus(Charger ch) async {
    final newStatus = ch.status == 'available' ? 'offline' : 'available';
    try {
      await ApiService().setAdminChargerStatus(ch.id, newStatus);
      _loadAdminData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _verifyUser(User u) async {
    try {
      await ApiService().verifyUser(u.id);
      _loadAdminData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _resolveFault(int id) async {
    try {
      await ApiService().resolveFaultReport(id);
      _loadAdminData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.secondaryNavy,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Text('ChargeSure Admin Console'),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.accentSkyBlue,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'DEMO DATA MODE ACTIVE',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primaryTeal),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Analytics',
            onPressed: _loadAdminData,
          ),
          PopupMenuButton<String>(
            tooltip: 'Switch Mode',
            onSelected: (val) {
              if (val == 'driver') {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const DriverRootScreen()),
                );
              } else if (val == 'host') {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const HostDashboardScreen()),
                );
              }
            },
            itemBuilder: (ctx) => const [
              PopupMenuItem(value: 'driver', child: Text('Switch to Driver App')),
              PopupMenuItem(value: 'host', child: Text('Switch to Host Portal')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryTeal))
          : Row(
              children: [
                // Responsive Sidebar
                if (isDesktop)
                  NavigationRail(
                    selectedIndex: _selectedNavIndex,
                    onDestinationSelected: (idx) => setState(() => _selectedNavIndex = idx),
                    labelType: NavigationRailLabelType.all,
                    backgroundColor: AppColors.surface,
                    selectedIconTheme: const IconThemeData(color: AppColors.primaryTeal),
                    selectedLabelTextStyle: const TextStyle(color: AppColors.primaryTeal, fontWeight: FontWeight.w700),
                    destinations: const [
                      NavigationRailDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: Text('Overview')),
                      NavigationRailDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: Text('Users & Hosts')),
                      NavigationRailDestination(icon: Icon(Icons.ev_station_outlined), selectedIcon: Icon(Icons.ev_station), label: Text('Chargers')),
                      NavigationRailDestination(icon: Icon(Icons.report_outlined), selectedIcon: Icon(Icons.report), label: Text('Fault Reports')),
                      NavigationRailDestination(icon: Icon(Icons.history_edu), selectedIcon: Icon(Icons.history_edu), label: Text('Audit Logs')),
                    ],
                  ),
                const VerticalDivider(width: 1, thickness: 1, color: AppColors.borderSubtle),

                // Main Content Body
                Expanded(
                  child: IndexedStack(
                    index: _selectedNavIndex,
                    children: [
                      _buildOverviewTab(),
                      _buildUsersTab(),
                      _buildChargersTab(),
                      _buildFaultsTab(),
                      _buildAuditTab(),
                    ],
                  ),
                ),
              ],
            ),
      bottomNavigationBar: isDesktop
          ? null
          : BottomNavigationBar(
              currentIndex: _selectedNavIndex,
              onTap: (idx) => setState(() => _selectedNavIndex = idx),
              type: BottomNavigationBarType.fixed,
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Overview'),
                BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Users'),
                BottomNavigationBarItem(icon: Icon(Icons.ev_station), label: 'Chargers'),
                BottomNavigationBarItem(icon: Icon(Icons.report), label: 'Faults'),
                BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Audits'),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    final an = _analytics;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Platform Operational Analytics',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.secondaryNavy),
        ),
        const SizedBox(height: 6),
        const Text(
          'Live database metrics for network throughput, station reliability, and backup engine invocations.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 20),

        // KPI Grid
        LayoutBuilder(
          builder: (ctx, constraints) {
            final isWide = constraints.maxWidth > 600;
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                SizedBox(
                  width: isWide ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth,
                  child: StatCard(
                    title: 'Total Users & Drivers',
                    value: '${an?['total_users'] ?? 0}',
                    subtitle: '${an?['total_drivers'] ?? 0} Drivers • ${an?['total_hosts'] ?? 0} Hosts',
                    icon: Icons.group,
                  ),
                ),
                SizedBox(
                  width: isWide ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth,
                  child: StatCard(
                    title: 'Network Stations',
                    value: '${an?['total_chargers'] ?? 0}',
                    subtitle: '${an?['verified_chargers'] ?? 0} Verified Active',
                    icon: Icons.ev_station,
                    iconColor: AppColors.success,
                    iconBgColor: AppColors.successLight,
                  ),
                ),
                SizedBox(
                  width: isWide ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth,
                  child: StatCard(
                    title: 'Energy Delivered',
                    value: '${an?['total_energy_delivered_kwh'] ?? 0} kWh',
                    subtitle: 'Clean EV Miles Powered',
                    icon: Icons.electric_bolt,
                    iconColor: AppColors.primaryTeal,
                  ),
                ),
                SizedBox(
                  width: isWide ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth,
                  child: StatCard(
                    title: 'Backup Engine Triggers',
                    value: '${an?['backup_triggers_count'] ?? 0}',
                    subtitle: 'Disruptions Recovered Successfully',
                    icon: Icons.shield,
                    iconColor: AppColors.warning,
                    iconBgColor: AppColors.warningLight,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 28),

        // Quick Overview Tables
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Recent System Fault Reports', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            TextButton(
              onPressed: () => setState(() => _selectedNavIndex = 3),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._faults.take(3).map((f) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber, color: AppColors.warning, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Station #${f['charger_id']}: ${f['issue_type']}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                        if (f['description'] != null)
                          Text('${f['description']}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                  StatusBadge(status: f['status'] as String? ?? 'pending'),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildUsersTab() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text('User & Host Verification Management', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        ..._users.map((u) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.accentSkyBlue,
                    child: Text(u.fullName.isNotEmpty ? u.fullName[0].toUpperCase() : 'U'),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(u.fullName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                        Text('${u.email} • Role: ${u.role.toUpperCase()}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      ],
                    ),
                  ),
                  if (!u.isVerified)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                      onPressed: () => _verifyUser(u),
                      child: const Text('Verify Host/Driver'),
                    )
                  else
                    const Row(
                      children: [
                        Icon(Icons.verified, color: AppColors.success, size: 18),
                        SizedBox(width: 4),
                        Text('Verified', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w700, fontSize: 12)),
                      ],
                    ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildChargersTab() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text('Network Charger Fleet & Approvals', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        ..._chargers.map((ch) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Row(
                children: [
                  Icon(ch.chargerType == 'home' ? Icons.home : Icons.ev_station, color: AppColors.primaryTeal, size: 28),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(ch.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                        Text('${ch.address} • ${ch.powerKw.toStringAsFixed(0)} kW • \$${ch.pricePerKwh.toStringAsFixed(2)}/kWh', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            StatusBadge(status: ch.status),
                            const SizedBox(width: 8),
                            StatusBadge(status: ch.dataSource, isDataSource: true),
                          ],
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () => _toggleChargerStatus(ch),
                    child: Text(ch.status == 'available' ? 'Suspend Station' : 'Activate Station'),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildFaultsTab() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text('Station Fault Reports & Complaints', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        ..._faults.map((f) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.report, color: AppColors.error, size: 24),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Station #${f['charger_id']}: ${f['issue_type']}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                        const SizedBox(height: 4),
                        Text(f['description'] ?? 'No extra notes provided', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        const SizedBox(height: 6),
                        StatusBadge(status: f['status'] as String? ?? 'pending'),
                      ],
                    ),
                  ),
                  if (f['status'] != 'resolved')
                    ElevatedButton(
                      onPressed: () => _resolveFault(f['id'] as int),
                      child: const Text('Mark Resolved'),
                    ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildAuditTab() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text('System Security & Admin Audit Log', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        ..._auditLogs.map((log) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Row(
                children: [
                  const Icon(Icons.security, color: AppColors.secondaryNavy, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${log['action']} • Entity: ${log['entity_type']}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                        Text('Actor: ${log['actor_email']} • ${log['timestamp']}', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}
