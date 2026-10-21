import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

class InteractiveChargerMap extends StatelessWidget {
  final List<Charger> chargers;
  final Charger? selectedCharger;
  final ValueChanged<Charger>? onChargerSelected;
  final LatLng initialCenter;
  final double initialZoom;

  const InteractiveChargerMap({
    super.key,
    required this.chargers,
    this.selectedCharger,
    this.onChargerSelected,
    this.initialCenter = const LatLng(37.7845, -122.4194),
    this.initialZoom = 13.0,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(
            initialCenter: initialCenter,
            initialZoom: initialZoom,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.chargesure.chargesure',
            ),
            MarkerLayer(
              markers: chargers.map((ch) {
                final isSelected = selectedCharger?.id == ch.id;
                Color markerColor;
                IconData markerIcon = Icons.ev_station;

                if (ch.status == 'faulty' || ch.status == 'offline') {
                  markerColor = AppColors.error;
                  markerIcon = Icons.error;
                } else if (ch.chargerType == 'home') {
                  markerColor = AppColors.secondaryNavy;
                  markerIcon = Icons.home;
                } else if (ch.powerKw >= 100.0) {
                  markerColor = AppColors.primaryTeal;
                  markerIcon = Icons.bolt;
                } else {
                  markerColor = AppColors.primaryTealLight;
                }

                return Marker(
                  point: LatLng(ch.latitude, ch.longitude),
                  width: isSelected ? 50 : 40,
                  height: isSelected ? 50 : 40,
                  child: GestureDetector(
                    onTap: () {
                      if (onChargerSelected != null) {
                        onChargerSelected!(ch);
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      decoration: BoxDecoration(
                        color: markerColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.white70,
                          width: isSelected ? 3.0 : 2.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: isSelected ? 8 : 4,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        markerIcon,
                        color: Colors.white,
                        size: isSelected ? 24 : 18,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        // Live OpenStreetMap attribution tag
        Positioned(
          top: 10,
          right: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              '© OpenStreetMap contributors',
              style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
            ),
          ),
        ),
      ],
    );
  }
}
