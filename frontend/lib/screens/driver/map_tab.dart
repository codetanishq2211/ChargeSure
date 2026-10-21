import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../services/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/map_view.dart';
import '../../widgets/status_badge.dart';
import 'charger_detail_screen.dart';

class MapTab extends StatefulWidget {
  const MapTab({super.key});

  @override
  State<MapTab> createState() => _MapTabState();
}

class _MapTabState extends State<MapTab> {
  bool _isMapView = true;
  String _selectedTypeFilter = 'all'; // 'all', 'public', 'business', 'home'
  String _selectedSpeedFilter = 'all'; // 'all', 'DC', 'AC'
  String _searchQuery = '';
  Charger? _selectedCharger;

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    var chargers = appState.chargers;

    // Apply Filters
    if (_selectedTypeFilter != 'all') {
      chargers = chargers.where((c) => c.chargerType == _selectedTypeFilter).toList();
    }
    if (_selectedSpeedFilter != 'all') {
      chargers = chargers.where((c) => c.currentType == _selectedSpeedFilter).toList();
    }
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      chargers = chargers.where((c) => c.title.toLowerCase().contains(q) || c.address.toLowerCase().contains(q)).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Charger Map & Finder'),
        actions: [
          IconButton(
            icon: Icon(_isMapView ? Icons.list_alt : Icons.map_outlined),
            tooltip: _isMapView ? 'Switch to List View' : 'Switch to Map View',
            onPressed: () => setState(() => _isMapView = !_isMapView),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppColors.surface,
            child: Column(
              children: [
                TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Search stations by name, city, or address...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () => setState(() => _searchQuery = ''),
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  ),
                ),
                const SizedBox(height: 8),
                // Horizontal filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All Types', 'all', _selectedTypeFilter, (v) => setState(() => _selectedTypeFilter = v)),
                      const SizedBox(width: 6),
                      _buildFilterChip('Public Hubs', 'public', _selectedTypeFilter, (v) => setState(() => _selectedTypeFilter = v)),
                      const SizedBox(width: 6),
                      _buildFilterChip('Business Parks', 'business', _selectedTypeFilter, (v) => setState(() => _selectedTypeFilter = v)),
                      const SizedBox(width: 6),
                      _buildFilterChip('Home Hosts', 'home', _selectedTypeFilter, (v) => setState(() => _selectedTypeFilter = v)),
                      const SizedBox(width: 12),
                      Container(height: 20, width: 1, color: AppColors.divider),
                      const SizedBox(width: 12),
                      _buildFilterChip('DC Fast', 'DC', _selectedSpeedFilter, (v) => setState(() => _selectedSpeedFilter = v)),
                      const SizedBox(width: 6),
                      _buildFilterChip('AC Wallbox', 'AC', _selectedSpeedFilter, (v) => setState(() => _selectedSpeedFilter = v)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Main View Body (Map or List)
          Expanded(
            child: _isMapView
                ? Stack(
                    children: [
                      InteractiveChargerMap(
                        chargers: chargers,
                        selectedCharger: _selectedCharger,
                        onChargerSelected: (ch) => setState(() => _selectedCharger = ch),
                      ),
                      // Floating Card for Selected Charger
                      if (_selectedCharger != null)
                        Positioned(
                          left: 16,
                          right: 16,
                          bottom: 20,
                          child: _buildChargerCard(_selectedCharger!),
                        ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: chargers.length,
                    itemBuilder: (ctx, i) => _buildChargerCard(chargers[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, String currentSelected, ValueChanged<String> onSelected) {
    final isSelected = currentSelected == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(value),
      selectedColor: AppColors.accentSkyBlue,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? AppColors.primaryTeal : AppColors.textSecondary,
      ),
    );
  }

  Widget _buildChargerCard(Charger ch) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
              ),
              StatusBadge(status: ch.status),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            ch.address,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              StatusBadge(status: ch.dataSource, isDataSource: true),
              const SizedBox(width: 8),
              Text(
                '${ch.currentType} • ${ch.powerKw.toStringAsFixed(0)} kW',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary),
              ),
              const Spacer(),
              Text(
                '\$${ch.pricePerKwh.toStringAsFixed(2)}/kWh',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.primaryTeal),
              ),
            ],
          ),
          const Divider(height: 20, color: AppColors.divider),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Connectors: ${ch.connectorTypes.join(", ")}',
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  textStyle: const TextStyle(fontSize: 13),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => ChargerDetailScreen(charger: ch)),
                  );
                },
                child: const Text('View Details'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
