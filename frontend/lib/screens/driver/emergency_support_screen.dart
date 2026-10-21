import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'backup_engine_screen.dart';

class EmergencySupportScreen extends StatelessWidget {
  const EmergencySupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> providers = [
      {
        'title': 'ChargeSure Rapid EV Mobile Dispatch',
        'phone': '+1-800-242-7437',
        'type': 'Level 2/3 Mobile Boost & High-Speed Power Van',
        'verified': true,
        'eta': '15-25 mins (Urban Area)',
        'coverage': 'Verified Coverage Active',
      },
      {
        'title': 'National EV Flatbed Towing Network',
        'phone': '+1-800-555-0199',
        'type': 'Zero-Ground-Clearance Flatbed EV Transport',
        'verified': true,
        'eta': '25-40 mins',
        'coverage': 'Verified Highway & Metro Support',
      },
      {
        'title': 'Local Emergency Host Responder',
        'phone': '+1-888-382-4274',
        'type': 'Residential Host Priority Gate Override',
        'verified': false,
        'eta': 'On-Demand Standby',
        'coverage': 'Unverified (Subject to Host Vicinity)',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency EV Assistance'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Banner
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.errorLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.error.withOpacity(0.4)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.shield_outlined, color: AppColors.error, size: 28),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ChargeSure 24/7 Mobility Assurance',
                        style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.textPrimary, fontSize: 15),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'If your EV has stopped or cannot safely reach any station within reserve limits, contact dispatch below for rapid mobile charging or flatbed transport.',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Return to Backup Engine CTA
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.accentSkyBlue,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.accentSkyBlueDark),
            ),
            child: Row(
              children: [
                const Icon(Icons.bolt, color: AppColors.primaryTeal, size: 28),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Still have remaining battery?',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.secondaryNavy),
                      ),
                      Text(
                        'Let Backup Engine recalculate with a lower reserve buffer.',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const BackupEngineScreen()),
                    );
                  },
                  child: const Text('Run Backup'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'Emergency Providers & Contacts',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),

          ...providers.map((p) => Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(18),
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
                            p['title'] as String,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: (p['verified'] as bool) ? AppColors.successLight : AppColors.surfaceMuted,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            (p['verified'] as bool) ? 'Verified' : 'Unverified',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: (p['verified'] as bool) ? AppColors.success : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      p['type'] as String,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Estimated ETA: ${p['eta']} • ${p['coverage']}',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.call, size: 18),
                        label: Text('Call ${p['phone']}'),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Dialing ${p['phone']}...')),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
