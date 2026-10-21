import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/app_state.dart';
import '../../theme/app_theme.dart';
import '../driver/driver_root_screen.dart';
import '../host/host_dashboard_screen.dart';
import '../admin/admin_dashboard_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _loginFormKey = GlobalKey<FormState>();
  final _regFormKey = GlobalKey<FormState>();

  // Login controllers
  final _loginEmailController = TextEditingController(text: 'driver@chargesure.com');
  final _loginPassController = TextEditingController(text: 'Driver@123');
  bool _obscureLoginPass = true;

  // Register controllers
  final _regNameController = TextEditingController();
  final _regEmailController = TextEditingController();
  final _regPassController = TextEditingController();
  final _regPhoneController = TextEditingController();
  String _selectedRole = 'driver'; // 'driver' or 'host'
  bool _obscureRegPass = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailController.dispose();
    _loginPassController.dispose();
    _regNameController.dispose();
    _regEmailController.dispose();
    _regPassController.dispose();
    _regPhoneController.dispose();
    super.dispose();
  }

  void _routeToRoleDashboard(String role) {
    Widget destination;
    if (role == 'admin') {
      destination = const AdminDashboardScreen();
    } else if (role == 'host') {
      destination = const HostDashboardScreen();
    } else {
      destination = const DriverRootScreen();
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  Future<void> _handleLogin() async {
    if (!_loginFormKey.currentState!.validate()) return;
    final appState = Provider.of<AppState>(context, listen: false);
    final success = await appState.login(
      _loginEmailController.text.trim(),
      _loginPassController.text,
    );
    if (!mounted) return;
    if (success) {
      _routeToRoleDashboard(appState.activeRole);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(appState.errorMessage ?? 'Invalid login credentials'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _handleRegister() async {
    if (!_regFormKey.currentState!.validate()) return;
    final appState = Provider.of<AppState>(context, listen: false);
    final success = await appState.register(
      _regEmailController.text.trim(),
      _regPassController.text,
      _regNameController.text.trim(),
      _regPhoneController.text.trim().isEmpty ? null : _regPhoneController.text.trim(),
      _selectedRole,
    );
    if (!mounted) return;
    if (success) {
      _routeToRoleDashboard(appState.activeRole);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(appState.errorMessage ?? 'Registration failed'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _handleQuickDemo(String role) async {
    final appState = Provider.of<AppState>(context, listen: false);
    await appState.quickDemoLogin(role);
    if (!mounted) return;
    _routeToRoleDashboard(role);
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo & Brand Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryTeal.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.bolt_rounded,
                      color: AppColors.primaryTeal,
                      size: 44,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'ChargeSure',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.secondaryNavy,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Always a Charge Ahead.',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primaryTeal,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Quick Demo Switcher Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.accentSkyBlueDark),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.flash_on, size: 16, color: AppColors.primaryTeal),
                            SizedBox(width: 6),
                            Text(
                              'Instant Demo Sign-In (Preloaded Roles):',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.secondaryNavy,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  textStyle: const TextStyle(fontSize: 12),
                                ),
                                onPressed: () => _handleQuickDemo('driver'),
                                child: const Text('Driver'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  textStyle: const TextStyle(fontSize: 12),
                                ),
                                onPressed: () => _handleQuickDemo('host'),
                                child: const Text('Host'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  textStyle: const TextStyle(fontSize: 12),
                                ),
                                onPressed: () => _handleQuickDemo('admin'),
                                child: const Text('Admin'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Main Card with Tabs
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.borderSubtle),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          decoration: const BoxDecoration(
                            border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
                          ),
                          child: TabBar(
                            controller: _tabController,
                            labelColor: AppColors.primaryTeal,
                            unselectedLabelColor: AppColors.textSecondary,
                            indicatorColor: AppColors.primaryTeal,
                            indicatorWeight: 3,
                            tabs: const [
                              Tab(text: 'Sign In'),
                              Tab(text: 'Register'),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: AnimatedBuilder(
                            animation: _tabController,
                            builder: (ctx, _) {
                              return _tabController.index == 0
                                  ? _buildLoginForm(appState.isLoading)
                                  : _buildRegisterForm(appState.isLoading);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm(bool isLoading) {
    return Form(
      key: _loginFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _loginEmailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email Address',
              prefixIcon: Icon(Icons.email_outlined, color: AppColors.textSecondary, size: 20),
            ),
            validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email address' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _loginPassController,
            obscureText: _obscureLoginPass,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textSecondary, size: 20),
              suffixIcon: IconButton(
                icon: Icon(_obscureLoginPass ? Icons.visibility_off : Icons.visibility, size: 20),
                onPressed: () => setState(() => _obscureLoginPass = !_obscureLoginPass),
              ),
            ),
            validator: (v) => (v == null || v.length < 6) ? 'Password must be at least 6 characters' : null,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: isLoading ? null : _handleLogin,
            child: isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Sign In'),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterForm(bool isLoading) {
    return Form(
      key: _regFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _regNameController,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              prefixIcon: Icon(Icons.person_outline, color: AppColors.textSecondary, size: 20),
            ),
            validator: (v) => (v == null || v.trim().length < 2) ? 'Please enter your name' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _regEmailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email Address',
              prefixIcon: Icon(Icons.email_outlined, color: AppColors.textSecondary, size: 20),
            ),
            validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _regPhoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Phone Number (Optional)',
              prefixIcon: Icon(Icons.phone_outlined, color: AppColors.textSecondary, size: 20),
            ),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _regPassController,
            obscureText: _obscureRegPass,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textSecondary, size: 20),
              suffixIcon: IconButton(
                icon: Icon(_obscureRegPass ? Icons.visibility_off : Icons.visibility, size: 20),
                onPressed: () => setState(() => _obscureRegPass = !_obscureRegPass),
              ),
            ),
            validator: (v) => (v == null || v.length < 6) ? 'At least 6 characters required' : null,
          ),
          const SizedBox(height: 14),
          // Role Selection (Driver vs Host)
          const Text(
            'Account Role',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Text('EV Driver'),
                  selected: _selectedRole == 'driver',
                  onSelected: (val) => setState(() => _selectedRole = 'driver'),
                  selectedColor: AppColors.accentSkyBlue,
                  labelStyle: TextStyle(
                    color: _selectedRole == 'driver' ? AppColors.primaryTeal : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ChoiceChip(
                  label: const Text('Charger Host'),
                  selected: _selectedRole == 'host',
                  onSelected: (val) => setState(() => _selectedRole = 'host'),
                  selectedColor: AppColors.accentSkyBlue,
                  labelStyle: TextStyle(
                    color: _selectedRole == 'host' ? AppColors.primaryTeal : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: isLoading ? null : _handleRegister,
            child: isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Create Account'),
          ),
        ],
      ),
    );
  }
}
