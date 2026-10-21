import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../services/app_state.dart';
import '../../theme/app_theme.dart';

class ChargingSessionScreen extends StatefulWidget {
  final Charger? charger;
  final int? bookingId;

  const ChargingSessionScreen({super.key, this.charger, this.bookingId});

  @override
  State<ChargingSessionScreen> createState() => _ChargingSessionScreenState();
}

class _ChargingSessionScreenState extends State<ChargingSessionScreen> {
  bool _isActionInProgress = false;

  @override
  void initState() {
    super.initState();
    // Auto start session if not already running and charger is provided
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = Provider.of<AppState>(context, listen: false);
      if (appState.activeSession == null && widget.charger != null) {
        _startChargingSession();
      }
    });
  }

  Future<void> _startChargingSession() async {
    if (widget.charger == null) return;
    setState(() => _isActionInProgress = true);
    final appState = Provider.of<AppState>(context, listen: false);
    try {
      await appState.startSession(widget.charger!.id, bookingId: widget.bookingId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isActionInProgress = false);
    }
  }

  Future<void> _completeChargingSession() async {
    setState(() => _isActionInProgress = true);
    final appState = Provider.of<AppState>(context, listen: false);
    try {
      final completed = await appState.completeSession();
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.success),
              SizedBox(width: 8),
              Text('Charging Completed!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Energy Delivered: ${completed.energyDeliveredKwh.toStringAsFixed(1)} kWh'),
              const SizedBox(height: 6),
              Text('Final Battery: ${completed.finalBatteryPercent?.toStringAsFixed(0) ?? "80"}%'),
              const SizedBox(height: 6),
              Text('Total Cost: \$${completed.totalCost.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              const Text(
                'A detailed session receipt has been saved to your booking history. Vehicle battery level updated.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text('Done & Return'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isActionInProgress = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final session = appState.activeSession;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Charging Session'),
        actions: [
          IconButton(
            icon: const Icon(Icons.report_problem_outlined, color: AppColors.warning),
            tooltip: 'Report Issue',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Support alerted for this active charging session.')),
              );
            },
          ),
        ],
      ),
      body: session == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.power_off, size: 64, color: AppColors.textMuted),
                  const SizedBox(height: 16),
                  const Text('No Active Charging Session', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  const Text('Select a confirmed charger booking to initiate charging.', style: TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Find Available Charger'),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Animated Charging Dial Visual
                  Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surface,
                      border: Border.all(color: AppColors.primaryTeal, width: 8),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryTeal.withOpacity(0.15),
                          blurRadius: 24,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.bolt, color: AppColors.primaryTeal, size: 36),
                          Text(
                            '${session.finalBatteryPercent?.toStringAsFixed(0) ?? session.initialBatteryPercent.toStringAsFixed(0)}%',
                            style: const TextStyle(
                              fontSize: 38,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const Text(
                            'Battery Level',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Session Telemetry Metrics Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Charging Status', style: TextStyle(color: AppColors.textSecondary)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.successLight,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.flash_on, size: 14, color: AppColors.success),
                                  SizedBox(width: 4),
                                  Text(
                                    'CHARGING ACTIVE',
                                    style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w700, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24, color: AppColors.divider),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                const Text('Energy', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                const SizedBox(height: 4),
                                Text(
                                  '${session.energyDeliveredKwh.toStringAsFixed(1)} kWh',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                ),
                              ],
                            ),
                            Container(height: 30, width: 1, color: AppColors.divider),
                            Column(
                              children: [
                                const Text('Total Cost', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                const SizedBox(height: 4),
                                Text(
                                  '\$${session.totalCost.toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                ),
                              ],
                            ),
                            Container(height: 30, width: 1, color: AppColors.divider),
                            Column(
                              children: [
                                const Text('Start Time', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat('h:mm a').format(session.startTime),
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Explicit User-Reported / Simulated Disclaimer Banner
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: AppColors.textMuted),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Telemetry Mode: Simulated software delivery curve. Meter telemetry marked as user-reported/estimated.',
                            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Finish Session Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: _isActionInProgress ? null : _completeChargingSession,
                      child: _isActionInProgress
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Stop & Complete Charging Session', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
