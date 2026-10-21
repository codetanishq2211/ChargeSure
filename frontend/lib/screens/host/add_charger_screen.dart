import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class AddChargerScreen extends StatefulWidget {
  const AddChargerScreen({super.key});

  @override
  State<AddChargerScreen> createState() => _AddChargerScreenState();
}

class _AddChargerScreenState extends State<AddChargerScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController(text: 'San Francisco');
  final _powerController = TextEditingController(text: '11.0');
  final _priceController = TextEditingController(text: '0.25');
  final _accessController = TextEditingController();

  String _chargerType = 'home'; // 'home' or 'business'
  String _currentType = 'AC';
  String _connector = 'Type 2';
  bool _isSubmitting = false;

  Future<void> _submitListing() async {
    if (_titleController.text.trim().isEmpty || _addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill title and address'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    // Simulate listing submission
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      setState(() => _isSubmitting = false);
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Charger Listing'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Listing Title (e.g. Hayes Valley Home Wallbox)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'Street Address'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _cityController,
              decoration: const InputDecoration(labelText: 'City'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _chargerType,
                    decoration: const InputDecoration(labelText: 'Listing Type'),
                    items: const [
                      DropdownMenuItem(value: 'home', child: Text('Residential Home')),
                      DropdownMenuItem(value: 'business', child: Text('Commercial Business')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _chargerType = val);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _currentType,
                    decoration: const InputDecoration(labelText: 'Current'),
                    items: const [
                      DropdownMenuItem(value: 'AC', child: Text('AC')),
                      DropdownMenuItem(value: 'DC', child: Text('DC Fast')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _currentType = val);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _powerController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Power (kW)'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Tariff (\$/kWh)'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _connector,
              decoration: const InputDecoration(labelText: 'Connector Type'),
              items: const [
                DropdownMenuItem(value: 'Type 2', child: Text('Type 2 (AC Wallbox)')),
                DropdownMenuItem(value: 'CCS2', child: Text('CCS2 (Fast Combo)')),
                DropdownMenuItem(value: 'CHAdeMO', child: Text('CHAdeMO')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _connector = val);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _accessController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Private Access Notes (Unmasked only after confirmed booking)',
                hintText: 'e.g. Driveway on left, garage keypad code 4821#',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Public Station Description & Amenities'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitListing,
              child: _isSubmitting
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Publish Charger Listing'),
            ),
          ],
        ),
      ),
    );
  }
}
