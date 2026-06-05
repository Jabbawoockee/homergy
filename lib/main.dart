import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'database/database.dart';
import 'screens/dashboard_screen.dart';
import 'screens/electricity_detail_screen.dart';
import 'screens/gas_detail_screen.dart';
import 'screens/history_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/settings_screen.dart';
import 'services/settings_service.dart';
import 'services/supabase_service.dart';
import 'services/sync_service.dart';
import 'theme/colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize German locale for date formatting.
  await initializeDateFormatting('de_DE', null);

  // Initialize Supabase.
  await SupabaseService.initialize();

  // Initialize the database singleton eagerly.
  AppDatabase.instance;

  // Force dark status bar icons.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.background,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Ensure user is signed in (anonymously if no session).
  // Wrapped in try/catch so the app starts even if offline or auth not configured.
  try {
    await SupabaseService.ensureSignedIn();
    SyncService().syncAll();
  } catch (e) {
    debugPrint('[Auth] Sign-in failed (offline or not configured): $e');
  }

  final onboardingDone = await SettingsService().isOnboardingDone();
  runApp(GasTrackApp(showOnboarding: !onboardingDone));
}

class GasTrackApp extends StatelessWidget {
  final bool showOnboarding;
  const GasTrackApp({super.key, required this.showOnboarding});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Homergy',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      initialRoute: showOnboarding ? '/onboarding' : '/main',
      routes: {
        '/onboarding': (_) => const OnboardingScreen(),
        '/main': (_) => const MainShell(),
      },
    );
  }

  ThemeData _buildTheme() {
    final base = ThemeData.light();
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.light(
        primary: AppColors.green,
        secondary: AppColors.amber,
        surface: AppColors.surface,
        error: AppColors.error,
      ),
      textTheme: GoogleFonts.rajdhaniTextTheme(base.textTheme).apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: GoogleFonts.rajdhani(
          fontSize: 15,
          color: AppColors.background,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.background,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Main shell with bottom navigation
// ---------------------------------------------------------------------------

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  String _trackingMode = 'both';

  @override
  void initState() {
    super.initState();
    _loadTrackingMode();
  }

  Future<void> _loadTrackingMode() async {
    final mode = await SettingsService().getTrackingMode();
    if (mounted && mode != _trackingMode) {
      setState(() => _trackingMode = mode);
    }
  }

  List<Widget> get _screens {
    switch (_trackingMode) {
      case 'gas':
        return [
          const GasDetailScreen(),
          HistoryScreen(key: ValueKey('hist_$_trackingMode'), initialFilter: HistoryFilter.gas),
          const SettingsScreen(),
        ];
      case 'electricity':
        return [
          const ElectricityDetailScreen(),
          HistoryScreen(key: ValueKey('hist_$_trackingMode'), initialFilter: HistoryFilter.electricity),
          const SettingsScreen(),
        ];
      default:
        return [
          const DashboardScreen(),
          HistoryScreen(key: ValueKey('hist_$_trackingMode')),
          const SettingsScreen(),
        ];
    }
  }

  void _onNavTap(int index) async {
    // Reload tracking mode when navigating to Start so changes from
    // settings take effect immediately without restarting the app.
    if (index == 0) await _loadTrackingMode();
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildNavBar(),
    );
  }

  Widget _buildNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFFFFF).withOpacity(0.90),
            offset: const Offset(-4, -4),
            blurRadius: 8,
          ),
          const BoxShadow(
            color: Color(0xFFC2CFC0),
            offset: Offset(0, -2),
            blurRadius: 6,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            _NavItem(
              icon: _trackingMode == 'gas'
                  ? Icons.local_fire_department_rounded
                  : _trackingMode == 'electricity'
                      ? Icons.bolt_rounded
                      : Icons.speed_rounded,
              label: 'Start',
              isActive: _currentIndex == 0,
              onTap: () => _onNavTap(0),
            ),
            _NavItem(
              icon: Icons.bar_chart_rounded,
              label: 'Verlauf',
              isActive: _currentIndex == 1,
              onTap: () => _onNavTap(1),
            ),
            _NavItem(
              icon: Icons.settings_outlined,
              label: 'Einstellungen',
              isActive: _currentIndex == 2,
              onTap: () => _onNavTap(2),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Custom nav item
// ---------------------------------------------------------------------------

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.green : AppColors.textSecondary;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 60,
          color: Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.rajdhani(
                  fontSize: 11,
                  fontWeight:
                      isActive ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isActive ? 20 : 0,
                height: 2,
                decoration: BoxDecoration(
                  color: AppColors.green,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Colors extension (alias kept here for convenience in tests)
// ---------------------------------------------------------------------------
class AppColors2 extends AppColors {}
