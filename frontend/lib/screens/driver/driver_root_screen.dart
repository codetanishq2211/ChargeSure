import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'dashboard_tab.dart';
import 'map_tab.dart';
import 'trips_tab.dart';
import 'bookings_tab.dart';
import 'profile_tab.dart';
import 'backup_engine_screen.dart';

class DriverRootScreen extends StatefulWidget {
  const DriverRootScreen({super.key});

  @override
  State<DriverRootScreen> createState() => _DriverRootScreenState();
}

class _DriverRootScreenState extends State<DriverRootScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> tabs = [
      DashboardTab(onNavigateTab: (idx) => setState(() => _currentIndex = idx)),
      const MapTab(),
      const TripsTab(),
      const BookingsTab(),
      const ProfileTab(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: tabs,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.error,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.shield_rounded),
        label: const Text(
          'Backup Engine',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const BackupEngineScreen()),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (idx) => setState(() => _currentIndex = idx),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.alt_route_outlined),
            activeIcon: Icon(Icons.alt_route),
            label: 'Trips',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark_outline),
            activeIcon: Icon(Icons.bookmark),
            label: 'Bookings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
