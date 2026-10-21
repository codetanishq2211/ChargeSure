import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final bool isDataSource;

  const StatusBadge({
    super.key,
    required this.status,
    this.isDataSource = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;
    IconData? icon;

    final norm = status.toLowerCase();

    if (isDataSource) {
      if (norm.contains('live') || norm == 'live_operator') {
        bg = const Color(0xFFE6F5EE);
        fg = AppColors.success;
        label = 'Live Operator';
        icon = Icons.sensors;
      } else if (norm.contains('host') || norm == 'host_confirmed') {
        bg = AppColors.accentSkyBlue;
        fg = AppColors.primaryTeal;
        label = 'Host Confirmed';
        icon = Icons.verified_user_outlined;
      } else if (norm.contains('report') || norm == 'manually_reported') {
        bg = AppColors.warningLight;
        fg = AppColors.warning;
        label = 'Reported';
        icon = Icons.report_problem_outlined;
      } else {
        bg = AppColors.surfaceMuted;
        fg = AppColors.textSecondary;
        label = 'Unverified';
        icon = Icons.help_outline;
      }
    } else {
      if (norm == 'available' || norm == 'confirmed' || norm == 'completed' || norm == 'active') {
        bg = AppColors.successLight;
        fg = AppColors.success;
        label = norm[0].toUpperCase() + norm.substring(1);
        icon = Icons.check_circle_outline;
      } else if (norm == 'in_use' || norm == 'pending' || norm == 'in_progress') {
        bg = AppColors.warningLight;
        fg = AppColors.warning;
        label = norm.replaceAll('_', ' ').toUpperCase();
        icon = Icons.schedule;
      } else if (norm == 'faulty' || norm == 'rejected' || norm == 'cancelled' || norm == 'offline') {
        bg = AppColors.errorLight;
        fg = AppColors.error;
        label = norm[0].toUpperCase() + norm.substring(1);
        icon = Icons.error_outline;
      } else {
        bg = AppColors.surfaceMuted;
        fg = AppColors.textSecondary;
        label = norm.toUpperCase();
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withOpacity(0.2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
