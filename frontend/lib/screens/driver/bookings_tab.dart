import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../services/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/status_badge.dart';
import 'backup_engine_screen.dart';
import 'charging_session_screen.dart';

class BookingsTab extends StatefulWidget {
  const BookingsTab({super.key});

  @override
  State<BookingsTab> createState() => _BookingsTabState();
}

class _BookingsTabState extends State<BookingsTab> {
  String _filter = 'all'; // 'all', 'confirmed', 'pending', 'completed'

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    var bookings = appState.bookings;

    if (_filter != 'all') {
      bookings = bookings.where((b) => b.status == _filter).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Booking Management'),
      ),
      body: RefreshIndicator(
        onRefresh: () => appState.refreshAllData(),
        child: Column(
          children: [
            // Filter Chips
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: AppColors.surface,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('All Bookings', 'all'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Confirmed', 'confirmed'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Pending Host', 'pending'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Completed', 'completed'),
                  ],
                ),
              ),
            ),

            Expanded(
              child: bookings.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.bookmark_border, size: 54, color: AppColors.textMuted),
                          const SizedBox(height: 12),
                          const Text('No bookings in this category', style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          const Text('Reserve a station from Map or Planner', style: TextStyle(color: AppColors.textSecondary)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: bookings.length,
                      itemBuilder: (ctx, i) => _buildBookingCard(bookings[i], appState),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _filter = value),
      selectedColor: AppColors.accentSkyBlue,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? AppColors.primaryTeal : AppColors.textSecondary,
      ),
    );
  }

  Widget _buildBookingCard(Booking booking, AppState appState) {
    final isConfirmed = booking.status == 'confirmed';
    final isPending = booking.status == 'pending';
    final isRejected = booking.status == 'rejected' || booking.status == 'cancelled';
    final ch = booking.charger;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
              Text(
                booking.bookingCode,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.secondaryNavy),
              ),
              StatusBadge(status: booking.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            ch?.title ?? 'Charging Station',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            '${DateFormat('EEE, MMM d, yyyy • h:mm a').format(booking.startTime)} - ${DateFormat('h:mm a').format(booking.endTime)}',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Text(
            'Agreed Price Snapshot: \$${booking.totalPriceSnapshot.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primaryTeal, fontSize: 13),
          ),
          if (ch?.accessInstructions != null && ch!.accessInstructions!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.vpn_key_outlined, size: 16, color: AppColors.primaryTeal),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Access Details: ${ch.accessInstructions}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const Divider(height: 20, color: AppColors.divider),

          // Action Buttons
          Row(
            children: [
              if (isConfirmed) ...[
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.bolt, size: 16),
                    label: const Text('Start Charging'),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ChargingSessionScreen(charger: ch, bookingId: booking.id),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.outlined(
                  icon: const Icon(Icons.navigation, color: AppColors.primaryTeal, size: 18),
                  tooltip: 'Navigate',
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Navigating to ${ch?.title ?? "Station"}...')),
                    );
                  },
                ),
              ],
              if (isPending) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => appState.cancelBooking(booking.id, reason: 'Driver cancelled request'),
                    child: const Text('Cancel Request'),
                  ),
                ),
              ],
              if (isRejected) ...[
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                    icon: const Icon(Icons.shield, size: 16),
                    label: const Text('Find Backup Alternative'),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => BackupEngineScreen(
                            failedChargerId: booking.chargerId,
                            failureReason: booking.cancellationReason ?? 'Primary booking was cancelled or rejected by host',
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
