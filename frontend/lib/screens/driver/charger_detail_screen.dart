import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../services/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/status_badge.dart';
import 'charging_session_screen.dart';

class ChargerDetailScreen extends StatefulWidget {
  final Charger charger;

  const ChargerDetailScreen({super.key, required this.charger});

  @override
  State<ChargerDetailScreen> createState() => _ChargerDetailScreenState();
}

class _ChargerDetailScreenState extends State<ChargerDetailScreen> {
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  int _durationHours = 1;
  bool _isBooking = false;

  void _showReportFaultDialog() {
    final issueController = TextEditingController(text: 'Connector latch issue');
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Report Station Problem'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: issueController,
              decoration: const InputDecoration(labelText: 'Issue Type'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Details / Description'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Fault report submitted. ChargeSure network alerted.'),
                  backgroundColor: AppColors.warning,
                ),
              );
            },
            child: const Text('Submit Report'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleRequestBooking() async {
    setState(() => _isBooking = true);
    final appState = Provider.of<AppState>(context, listen: false);

    final startDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _startTime.hour,
      _startTime.minute,
    );
    final endDateTime = startDateTime.add(Duration(hours: _durationHours));

    try {
      final booking = await appState.createBooking(
        chargerId: widget.charger.id,
        startTime: startDateTime,
        endTime: endDateTime,
      );

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Row(
            children: [
              Icon(
                booking.status == 'confirmed' ? Icons.check_circle : Icons.schedule,
                color: booking.status == 'confirmed' ? AppColors.success : AppColors.warning,
              ),
              const SizedBox(width: 8),
              Text(booking.status == 'confirmed' ? 'Booking Confirmed!' : 'Request Sent to Host'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Booking Code: ${booking.bookingCode}', style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text('Time: ${DateFormat('EEE, MMM d • h:mm a').format(booking.startTime)} - ${DateFormat('h:mm a').format(booking.endTime)}'),
              const SizedBox(height: 8),
              Text('Estimated Total: \$${booking.totalPriceSnapshot.toStringAsFixed(2)}'),
              const SizedBox(height: 12),
              if (booking.status == 'pending')
                const Text(
                  'The residential host has been notified. You will receive immediate status updates upon confirmation. Access instructions remain protected until confirmed.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                )
              else
                const Text(
                  'Your slot is secured. You can now navigate to this station or initiate charging upon arrival.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text('View All Bookings'),
            ),
            if (booking.status == 'confirmed')
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ChargingSessionScreen(
                        charger: widget.charger,
                        bookingId: booking.id,
                      ),
                    ),
                  );
                },
                child: const Text('Start Charging Session'),
              ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isBooking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ch = widget.charger;
    final isHomeHost = ch.chargerType == 'home';

    return Scaffold(
      appBar: AppBar(
        title: Text(ch.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.report_problem_outlined, color: AppColors.warning),
            tooltip: 'Report Problem',
            onPressed: _showReportFaultDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Badges & Power
            Row(
              children: [
                StatusBadge(status: ch.status),
                const SizedBox(width: 8),
                StatusBadge(status: ch.dataSource, isDataSource: true),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accentSkyBlue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${ch.currentType} • ${ch.powerKw.toStringAsFixed(0)} kW',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryTeal,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              ch.title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    ch.address,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Pricing & Connector Highlights
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text('Tariff Rate', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      const SizedBox(height: 4),
                      Text(
                        '\$${ch.pricePerKwh.toStringAsFixed(2)}/kWh',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  Container(height: 30, width: 1, color: AppColors.divider),
                  Column(
                    children: [
                      const Text('Connectors', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      const SizedBox(height: 4),
                      Text(
                        ch.connectorTypes.join(', '),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  Container(height: 30, width: 1, color: AppColors.divider),
                  Column(
                    children: [
                      const Text('Reliability', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      const SizedBox(height: 4),
                      Text(
                        '${ch.reliabilityScore.toStringAsFixed(0)}%',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.success),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Description
            if (ch.description != null) ...[
              const Text('Station Details', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(
                ch.description!,
                style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 20),
            ],

            // Host Protection Notice if residential
            if (isHomeHost) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.accentSkyBlue,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.accentSkyBlueDark),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.shield_outlined, color: AppColors.primaryTeal, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Verified Residential Host: Exact driveway access instructions and gate pass will be unmasked upon booking confirmation.',
                        style: TextStyle(fontSize: 12, color: AppColors.secondaryNavy),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Booking Time Selection
            const Text('Select Reservation Window', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Date:', style: TextStyle(fontWeight: FontWeight.w600)),
                      TextButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(DateFormat('EEE, MMM d, yyyy').format(_selectedDate)),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 14)),
                          );
                          if (picked != null) setState(() => _selectedDate = picked);
                        },
                      ),
                    ],
                  ),
                  const Divider(color: AppColors.divider),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Start Time:', style: TextStyle(fontWeight: FontWeight.w600)),
                      TextButton.icon(
                        icon: const Icon(Icons.access_time, size: 16),
                        label: Text(_startTime.format(context)),
                        onPressed: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: _startTime,
                          );
                          if (picked != null) setState(() => _startTime = picked);
                        },
                      ),
                    ],
                  ),
                  const Divider(color: AppColors.divider),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Duration:', style: TextStyle(fontWeight: FontWeight.w600)),
                      DropdownButton<int>(
                        value: _durationHours,
                        items: const [
                          DropdownMenuItem(value: 1, child: Text('1 Hour')),
                          DropdownMenuItem(value: 2, child: Text('2 Hours')),
                          DropdownMenuItem(value: 3, child: Text('3 Hours')),
                          DropdownMenuItem(value: 4, child: Text('4 Hours')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _durationHours = val);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Action Buttons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isBooking ? null : _handleRequestBooking,
                child: _isBooking
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(
                        isHomeHost ? 'Request Host Booking' : 'Reserve & Start Booking',
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.directions, size: 18),
                label: const Text('Open Navigation Directions'),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Opening GPS route navigation to ${ch.title}...'),
                      backgroundColor: AppColors.primaryTeal,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
