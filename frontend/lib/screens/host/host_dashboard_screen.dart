import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/status_badge.dart';
import '../driver/driver_root_screen.dart';
import '../admin/admin_dashboard_screen.dart';
import 'add_charger_screen.dart';

class HostDashboardScreen extends StatefulWidget {
  const HostDashboardScreen({super.key});

  @override
  State<HostDashboardScreen> createState() => _HostDashboardScreenState();
}

class _HostDashboardScreenState extends State<HostDashboardScreen> {
  Map<String, dynamic>? _analytics;
  List<Charger> _chargers = [];
  List<Booking> _hostBookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHostData();
  }

  Future<void> _loadHostData() async {
    setState(() => _isLoading = true);
    final api = ApiService();
    try {
      final an = await api.getHostAnalytics();
      final ch = await api.getHostChargers();
      final bk = await api.getHostBookings();
      if (mounted) {
        setState(() {
          _analytics = an;
          _chargers = ch;
          _hostBookings = bk;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _acceptBooking(int id) async {
    try {
      await ApiService().acceptBooking(id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking accepted! Driver notified with gate access pass.'), backgroundColor: AppColors.success),
      );
      _loadHostData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _rejectBooking(int id) async {
    try {
      await ApiService().rejectBooking(id, reason: 'Host driveway currently occupied');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking rejected. ChargeSure Backup Engine automatically triggered for driver.'), backgroundColor: AppColors.warning),
      );
      _loadHostData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingRequests = _hostBookings.where((b) => b.status == 'pending').toList();

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.home_work, color: AppColors.primaryTeal, size: 22),
            SizedBox(width: 8),
            Text('Host Partner Portal'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadHostData,
          ),
          PopupMenuButton<String>(
            tooltip: 'Switch Mode',
            onSelected: (val) {
              if (val == 'driver') {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const DriverRootScreen()),
                );
              } else if (val == 'admin') {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
                );
              }
            },
            itemBuilder: (ctx) => const [
              PopupMenuItem(value: 'driver', child: Text('Switch to Driver Mode')),
              PopupMenuItem(value: 'admin', child: Text('Switch to Admin Mode')),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryTeal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Charger Listing'),
        onPressed: () async {
          final added = await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddChargerScreen()),
          );
          if (added == true) _loadHostData();
        },
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryTeal))
          : RefreshIndicator(
              onRefresh: _loadHostData,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Verification Banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.accentSkyBlueDark),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.verified, color: AppColors.primaryTeal, size: 32),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _analytics?['host_name'] ?? 'Host Partner',
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Verified ChargeSure Home & Business Host',
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // KPI Cards
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          title: 'Pending Requests',
                          value: '${_analytics?['pending_requests_count'] ?? 0}',
                          icon: Icons.notifications_active,
                          iconColor: AppColors.warning,
                          iconBgColor: AppColors.warningLight,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatCard(
                          title: 'Est. Earnings',
                          value: '\$${(_analytics?['estimated_earnings'] ?? 0).toString()}',
                          icon: Icons.payments_outlined,
                          iconColor: AppColors.success,
                          iconBgColor: AppColors.successLight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Pending Requests Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Pending Booking Requests',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.secondaryNavy),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.warningLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${pendingRequests.length} Needs Action',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.warning),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  if (pendingRequests.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: const Center(
                        child: Text('No pending booking requests at this time.', style: TextStyle(color: AppColors.textSecondary)),
                      ),
                    )
                  else
                    ...pendingRequests.map((b) => Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.warning),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Driver: ${b.driverName ?? "EV Driver"}',
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                                  ),
                                  Text(
                                    b.bookingCode,
                                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${DateFormat('EEE, MMM d • h:mm a').format(b.startTime)} - ${DateFormat('h:mm a').format(b.endTime)}',
                                style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Earnings: \$${b.totalPriceSnapshot.toStringAsFixed(2)}',
                                style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primaryTeal),
                              ),
                              const Divider(height: 20, color: AppColors.divider),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                                      onPressed: () => _acceptBooking(b.id),
                                      child: const Text('Accept Booking'),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: OutlinedButton(
                                      style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                                      onPressed: () => _rejectBooking(b.id),
                                      child: const Text('Decline'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )),

                  const SizedBox(height: 28),

                  // Host Charger Listings
                  const Text(
                    'Your Charger Listings',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.secondaryNavy),
                  ),
                  const SizedBox(height: 10),

                  ..._chargers.map((ch) => Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.borderSubtle),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    ch.title,
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                                  ),
                                ),
                                StatusBadge(status: ch.status),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(ch.address, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                            const SizedBox(height: 8),
                            Text(
                              '${ch.powerKw.toStringAsFixed(0)} kW • \$${ch.pricePerKwh.toStringAsFixed(2)}/kWh • Connectors: ${ch.connectorTypes.join(", ")}',
                              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                            ),
                            if (ch.accessInstructions != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Private Access Notes: ${ch.accessInstructions}',
                                style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontStyle: FontStyle.italic),
                              ),
                            ],
                          ],
                        ),
                      )),
                  const SizedBox(height: 60),
                ],
              ),
            ),
    );
  }
}
