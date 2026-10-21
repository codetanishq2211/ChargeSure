import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../services/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/status_badge.dart';
import 'charger_detail_screen.dart';
import 'emergency_support_screen.dart';

class BackupEngineScreen extends StatefulWidget {
  final int? failedChargerId;
  final String failureReason;
  final double? initialBatteryPercent;

  const BackupEngineScreen({
    super.key,
    this.failedChargerId,
    this.failureReason = 'Station connector latch reported jammed / Host unavailable',
    this.initialBatteryPercent,
  });

  @override
  State<BackupEngineScreen> createState() => _BackupEngineScreenState();
}

class _BackupEngineScreenState extends State<BackupEngineScreen> {
  BackupResult? _result;
  bool _isLoading = true;
  String? _error;
  double _safetyReserve = 15.0;

  @override
  void initState() {
    super.initState();
    _evaluateBackup();
  }

  Future<void> _evaluateBackup() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final res = await appState.triggerBackupEngine(
        failedChargerId: widget.failedChargerId,
        failureReason: widget.failureReason,
        customBatteryPercent: widget.initialBatteryPercent,
        minSafetyReserve: _safetyReserve,
      );
      if (mounted) {
        setState(() {
          _result = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.shield_rounded, color: AppColors.primaryTeal, size: 22),
            SizedBox(width: 8),
            Text('ChargeSure Backup Engine'),
          ],
        ),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: AppColors.primaryTeal),
                  const SizedBox(height: 20),
                  const Text(
                    'Evaluating Candidate Stations...',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Checking connector compatibility & safety reserve (${_safetyReserve.toStringAsFixed(0)}%)...',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                        const SizedBox(height: 12),
                        Text('Evaluation Error: $_error', textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(onPressed: _evaluateBackup, child: const Text('Retry Evaluation')),
                      ],
                    ),
                  ),
                )
              : _buildBackupContent(_result!),
    );
  }

  Widget _buildBackupContent(BackupResult result) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Failure Reason Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.warningLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.warning.withOpacity(0.4)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Primary Station Disruption Detected',
                        style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Reason: ${result.failureReason}',
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Vehicle: ${result.vehicleSummary}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Status & Safety Reserve Config
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                result.hasSafeAlternative ? 'Safe Alternatives Found' : 'Critical Range Warning',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: result.hasSafeAlternative ? AppColors.secondaryNavy : AppColors.error,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Reserve: ${_safetyReserve.toStringAsFixed(0)}%',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            result.statusSummary,
            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 24),

          // CRITICAL CASE: If no safe alternative
          if (!result.hasSafeAlternative) ...[
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.error),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.dangerous, color: AppColors.error, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'EMERGENCY ASSISTANCE REQUIRED',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.error),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your vehicle battery does not have sufficient range to safely reach alternative chargers without breaching safety reserves. Do not risk running depleted on the road.',
                    style: TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.4),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                      icon: const Icon(Icons.emergency, color: Colors.white),
                      label: const Text('Contact 24/7 Roadside Assistance'),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const EmergencySupportScreen()),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // BEST CANDIDATE (Rank #1)
          if (result.bestCandidate != null) ...[
            const Row(
              children: [
                Icon(Icons.star, color: AppColors.warning, size: 18),
                SizedBox(width: 6),
                Text(
                  'TOP RECOMMENDED BACKUP ALTERNATIVE',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primaryTeal, letterSpacing: 0.5),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildCandidateCard(result.bestCandidate!, isTopPick: true),
            const SizedBox(height: 24),
          ],

          // ADDITIONAL CANDIDATES
          if (result.additionalOptions.isNotEmpty) ...[
            const Text(
              'Additional Compatible Options',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            ...result.additionalOptions.map((c) => _buildCandidateCard(c, isTopPick: false)),
          ],

          const SizedBox(height: 20),
          // Emergency Contacts Section
          const Text(
            'Emergency Mobility Contacts',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 10),
          ...result.emergencyContacts.map((contact) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.phone_in_talk, color: AppColors.primaryTeal, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(contact['name'] as String, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                          Text('${contact['service']} • ${contact['phone']}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.call, color: AppColors.success),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Dialing ${contact['name']} at ${contact['phone']}...')),
                        );
                      },
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildCandidateCard(BackupCandidate candidate, {required bool isTopPick}) {
    final ch = candidate.charger;
    final isSafe = candidate.isSafelyReachable;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isTopPick ? AppColors.primaryTeal : AppColors.borderSubtle,
          width: isTopPick ? 2.0 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isTopPick ? 0.05 : 0.02),
            blurRadius: isTopPick ? 12 : 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        ch.title,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSafe ? AppColors.successLight : AppColors.errorLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Score: ${candidate.overallRankScore.toStringAsFixed(0)}/100',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isSafe ? AppColors.success : AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    StatusBadge(status: ch.dataSource, isDataSource: true),
                    const SizedBox(width: 8),
                    Text(
                      '${ch.powerKw.toStringAsFixed(0)} kW ${ch.currentType}',
                      style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontSize: 13),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '• ${candidate.distanceKm.toStringAsFixed(1)} km away',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Metrics row: Arrival Battery, ETA, Detour
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text('Arrival Battery', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          const SizedBox(height: 2),
                          Text(
                            '${candidate.estimatedArrivalBatteryPercent.toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: isSafe ? AppColors.success : AppColors.error,
                            ),
                          ),
                        ],
                      ),
                      Container(height: 24, width: 1, color: AppColors.divider),
                      Column(
                        children: [
                          const Text('Driving Time', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          const SizedBox(height: 2),
                          Text(
                            '${candidate.estimatedDrivingTimeMinutes} mins',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                      Container(height: 24, width: 1, color: AppColors.divider),
                      Column(
                        children: [
                          const Text('Detour', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          const SizedBox(height: 2),
                          Text(
                            '+${candidate.detourKm.toStringAsFixed(1)} km',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Recommendation reason
                Text(
                  candidate.primaryRecommendationReason,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.bookmark_add_outlined, size: 18),
                    label: const Text('Request Backup Booking'),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => ChargerDetailScreen(charger: ch)),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.outlined(
                  icon: const Icon(Icons.navigation, color: AppColors.primaryTeal),
                  tooltip: 'Open Directions',
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Navigating to backup station: ${ch.title}...')),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
