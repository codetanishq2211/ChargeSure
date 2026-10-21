import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/app_state.dart';
import 'theme/app_theme.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/driver/driver_root_screen.dart';
import 'screens/host/host_dashboard_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ChargeSureApp());
}

class ChargeSureApp extends StatefulWidget {
  final AppState? appState;

  const ChargeSureApp({super.key, this.appState});

  @override
  State<ChargeSureApp> createState() => _ChargeSureAppState();
}

class _ChargeSureAppState extends State<ChargeSureApp> {
  late final AppState _state;

  @override
  void initState() {
    super.initState();
    _state = widget.appState ?? AppState();
    _state.init();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppState>.value(value: _state),
      ],
      child: MaterialApp(
        title: 'ChargeSure — Intelligent EV Charging Assurance',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: Consumer<AppState>(
          builder: (context, state, _) {
            if (!state.isAuthenticated) {
              return const OnboardingScreen();
            }

            if (state.activeRole == 'admin') {
              return const AdminDashboardScreen();
            } else if (state.activeRole == 'host') {
              return const HostDashboardScreen();
            } else {
              return const DriverRootScreen();
            }
          },
        ),
      ),
    );
  }
}
