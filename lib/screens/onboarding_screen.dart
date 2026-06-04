import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../database/database.dart';
import '../services/settings_service.dart';
import '../services/supabase_service.dart';
import '../services/sync_service.dart';
import '../services/weather_service.dart';
import '../theme/colors.dart';

enum _OnbMode { welcome, login, newUser }

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _settingsService = SettingsService();

  // Mode
  _OnbMode _mode = _OnbMode.welcome;

  // Login flow
  final _loginEmailController = TextEditingController();
  bool _isSendingLink = false;
  bool _linkSent = false;
  bool _isSyncing = false;
  StreamSubscription<AuthState>? _authSub;

  // New-user flow
  final _pageController = PageController();
  final _plzController = TextEditingController();
  final _cityController = TextEditingController();
  int _selectedDigits = 5;         // gas intDigits
  int _selectedElecIntDigits = 6;  // electricity intDigits
  int _selectedElecDecDigits = 1;  // electricity decDigits
  int _currentPage = 0;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // Listen for magic-link confirmation during onboarding.
    // Ignore anonymous sign-ins (emitted immediately on subscription from main()).
    _authSub = SupabaseService.client.auth.onAuthStateChange.listen((data) {
      if (!mounted) return;
      if (data.event == AuthChangeEvent.signedIn ||
          data.event == AuthChangeEvent.userUpdated) {
        if (!SupabaseService.isAnonymous) {
          _finishWithLogin();
        }
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _loginEmailController.dispose();
    _pageController.dispose();
    _plzController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> _finishWithLogin() async {
    if (mounted) setState(() => _isSyncing = true);
    await SyncService().syncAll(); // await so data is ready before navigation
    await _settingsService.setOnboardingDone();
    if (mounted) Navigator.of(context).pushReplacementNamed('/main');
  }

  Future<void> _sendMagicLink() async {
    final email = _loginEmailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showError('Bitte eine gültige E-Mail-Adresse eingeben.');
      return;
    }
    setState(() => _isSendingLink = true);
    try {
      await SupabaseService.signInWithMagicLink(email);
      if (mounted) setState(() { _isSendingLink = false; _linkSent = true; });
    } catch (e) {
      if (mounted) {
        setState(() => _isSendingLink = false);
        _showError('Fehler: $e');
      }
    }
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _finishNewUser({bool skipLocation = false}) async {
    setState(() => _saving = true);
    await _settingsService.setMeterIntDigits(_selectedDigits);
    await _settingsService.setElectricityIntDigits(_selectedElecIntDigits);
    await _settingsService.setElectricityDecDigits(_selectedElecDecDigits);

    if (!skipLocation) {
      final plz = _plzController.text.trim();
      final city = _cityController.text.trim();
      if (plz.isNotEmpty || city.isNotEmpty) {
        await AppDatabase.instance.saveLocation(plz: plz, city: city);
        _geocodeInBackground(city, plz);
      }
    }

    await _settingsService.setOnboardingDone();
    if (mounted) Navigator.of(context).pushReplacementNamed('/main');
  }

  void _geocodeInBackground(String city, String plz) async {
    final coords = await WeatherService().geocode(city, plz);
    if (coords != null) {
      final settings = await AppDatabase.instance.getSettings();
      if (settings != null) {
        await AppDatabase.instance
            .saveCoordinates(settings.id, coords.lat, coords.lon);
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.error,
        content: Text(msg,
            style: GoogleFonts.rajdhani(
                fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _mode == _OnbMode.welcome
              ? _buildWelcome()
              : _mode == _OnbMode.login
                  ? _buildLoginFlow()
                  : _buildNewUserFlow(),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Welcome page
  // ---------------------------------------------------------------------------

  Widget _buildWelcome() {
    return Padding(
      key: const ValueKey('welcome'),
      padding: const EdgeInsets.fromLTRB(28, 48, 28, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(flex: 1),

          // Logo / title
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.background,
                shape: BoxShape.circle,
                boxShadow: AppColors.neu(10),
              ),
              child: const Icon(Icons.local_fire_department_rounded,
                  color: AppColors.amber, size: 38),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'HOMERGY',
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceMono(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: AppColors.greenDark,
              letterSpacing: 6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Dein Gasverbrauch im Blick',
            textAlign: TextAlign.center,
            style: GoogleFonts.rajdhani(
              fontSize: 15,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),

          const Spacer(flex: 2),

          // Existing account card
          GestureDetector(
            onTap: () => setState(() => _mode = _OnbMode.login),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(18),
                boxShadow: AppColors.neu(7),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.green.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.person_rounded,
                        color: AppColors.green, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ich habe bereits ein Konto',
                          style: GoogleFonts.rajdhani(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Anmelden & Daten wiederherstellen',
                          style: GoogleFonts.rajdhani(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios,
                      size: 14, color: AppColors.textSecondary),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          // New account card
          GestureDetector(
            onTap: () => setState(() => _mode = _OnbMode.newUser),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.green,
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0xFF3A5E3D),
                    offset: Offset(0, 5),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.add_rounded,
                        color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Neu starten',
                          style: GoogleFonts.rajdhani(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Konto erstellen & einrichten',
                          style: GoogleFonts.rajdhani(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios,
                      size: 14, color: Colors.white.withOpacity(0.7)),
                ],
              ),
            ),
          ),

          const Spacer(flex: 1),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Login flow (existing account)
  // ---------------------------------------------------------------------------

  Widget _buildLoginFlow() {
    return Padding(
      key: const ValueKey('login'),
      padding: const EdgeInsets.fromLTRB(28, 16, 28, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Back + title
          Row(
            children: [
              GestureDetector(
                onTap: () => setState(() {
                  _mode = _OnbMode.welcome;
                  _linkSent = false;
                  _loginEmailController.clear();
                }),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    shape: BoxShape.circle,
                    boxShadow: AppColors.neu(5),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new,
                      size: 16, color: AppColors.textPrimary),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'ANMELDEN',
                style: GoogleFonts.spaceMono(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.greenDark,
                  letterSpacing: 4,
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),
          Container(height: 1, color: AppColors.border),
          const SizedBox(height: 28),

          if (!_linkSent) ...[
            // Explanation
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.green.withOpacity(0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 18, color: AppColors.green),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Gib deine E-Mail-Adresse ein. Wir senden dir einen Anmeldelink — kein Passwort nötig. Alle deine Daten werden danach automatisch geladen.',
                      style: GoogleFonts.rajdhani(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            Text(
              'E-MAIL-ADRESSE',
              style: GoogleFonts.rajdhani(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFDFE5DA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _loginEmailController,
                keyboardType: TextInputType.emailAddress,
                autofocus: true,
                style: GoogleFonts.rajdhani(
                  fontSize: 17,
                  color: AppColors.textPrimary,
                ),
                cursorColor: AppColors.green,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 15),
                  hintText: 'deine@email.de',
                  hintStyle: GoogleFonts.rajdhani(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            _ActionButton(
              label: 'ANMELDELINK SENDEN',
              isBusy: _isSendingLink,
              onTap: _isSendingLink ? null : _sendMagicLink,
            ),
          ] else ...[
            // Link sent — waiting / syncing state
            const Spacer(),
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  shape: BoxShape.circle,
                  boxShadow: AppColors.neu(10),
                ),
                child: _isSyncing
                    ? const Padding(
                        padding: EdgeInsets.all(22),
                        child: CircularProgressIndicator(
                          color: AppColors.green,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Icon(Icons.mark_email_read_outlined,
                        color: AppColors.green, size: 36),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              _isSyncing ? 'Daten werden geladen …' : 'E-Mail gesendet!',
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceMono(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.greenDark,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _isSyncing
                  ? 'Deine Daten werden aus der Cloud synchronisiert.\nEinen Moment …'
                  : 'Wir haben einen Anmeldelink an\n${_loginEmailController.text.trim()}\ngesendet.',
              textAlign: TextAlign.center,
              style: GoogleFonts.rajdhani(
                fontSize: 15,
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 20),
            if (!_isSyncing)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.amber.withOpacity(0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.touch_app_outlined,
                      size: 18, color: AppColors.amber),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Öffne deine E-Mail-App, tippe den Link an — die App öffnet sich automatisch und lädt deine Daten.',
                      style: GoogleFonts.rajdhani(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => setState(() => _linkSent = false),
              child: Text(
                'Andere E-Mail-Adresse verwenden',
                textAlign: TextAlign.center,
                style: GoogleFonts.rajdhani(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  decoration: TextDecoration.underline,
                  decorationColor: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // New-user flow (existing 2-page setup)
  // ---------------------------------------------------------------------------

  Widget _buildNewUserFlow() {
    return Column(
      key: const ValueKey('newUser'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Progress dots
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          child: Row(
            children: [
              GestureDetector(
                onTap: _currentPage == 0
                    ? () => setState(() => _mode = _OnbMode.welcome)
                    : null,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    shape: BoxShape.circle,
                    boxShadow: AppColors.neu(4),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new,
                      size: 14, color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(width: 12),
              _ProgressDot(active: _currentPage >= 0),
              const SizedBox(width: 6),
              _ProgressDot(active: _currentPage >= 1),
              const SizedBox(width: 6),
              _ProgressDot(active: _currentPage >= 2),
            ],
          ),
        ),

        Expanded(
          child: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (i) => setState(() => _currentPage = i),
            children: [
              _MeterTypePage(
                selectedDigits: _selectedDigits,
                onSelect: (d) => setState(() => _selectedDigits = d),
              ),
              _ElecMeterPage(
                intDigits: _selectedElecIntDigits,
                decDigits: _selectedElecDecDigits,
                onIntSelect: (d) => setState(() => _selectedElecIntDigits = d),
                onDecSelect: (d) => setState(() => _selectedElecDecDigits = d),
              ),
              _LocationPage(
                plzController: _plzController,
                cityController: _cityController,
              ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: _currentPage < 2
              ? _ActionButton(
                  label: 'WEITER',
                  isBusy: false,
                  onTap: _nextPage,
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ActionButton(
                      label: 'LOSLEGEN',
                      isBusy: _saving,
                      onTap: _saving ? null : () => _finishNewUser(),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _saving
                          ? null
                          : () => _finishNewUser(skipLocation: true),
                      child: Text(
                        'Überspringen — Standort später in Einstellungen eingeben',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.rajdhani(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Page 1 — Meter type
// ---------------------------------------------------------------------------

class _MeterTypePage extends StatelessWidget {
  final int selectedDigits;
  final ValueChanged<int> onSelect;

  const _MeterTypePage({
    required this.selectedDigits,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'HOMERGY',
            style: GoogleFonts.spaceMono(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppColors.greenDark,
              letterSpacing: 6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'EINRICHTUNG  ·  SCHRITT 1 VON 3',
            style: GoogleFonts.rajdhani(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 28),
          Container(height: 1, color: AppColors.border),
          const SizedBox(height: 24),

          Text(
            'WIE VIELE STELLEN HAT DER\nVORKOMMA-BEREICH DEINES ZÄHLERS?',
            style: GoogleFonts.spaceMono(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: 0.5,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Diese Einstellung hilft der OCR-Erkennung, den Zählerstand korrekt aufzuteilen. Du kannst sie später in den Einstellungen ändern.',
            style: GoogleFonts.rajdhani(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),

          _MeterTypeCard(
            intDigits: 4,
            exampleInt: '1234',
            exampleDec: '567',
            isSelected: selectedDigits == 4,
            onTap: () => onSelect(4),
          ),
          const SizedBox(height: 12),
          _MeterTypeCard(
            intDigits: 5,
            exampleInt: '15154',
            exampleDec: '888',
            isSelected: selectedDigits == 5,
            onTap: () => onSelect(5),
          ),
          const SizedBox(height: 12),
          _MeterTypeCard(
            intDigits: 6,
            exampleInt: '123456',
            exampleDec: '789',
            isSelected: selectedDigits == 6,
            onTap: () => onSelect(6),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Page 2 — Electricity meter configuration
// ---------------------------------------------------------------------------

class _ElecMeterPage extends StatelessWidget {
  final int intDigits;
  final int decDigits;
  final ValueChanged<int> onIntSelect;
  final ValueChanged<int> onDecSelect;

  const _ElecMeterPage({
    required this.intDigits,
    required this.decDigits,
    required this.onIntSelect,
    required this.onDecSelect,
  });

  static const _elecBlue = Color(0xFF5B8DB8);
  static const _elecBlueDk = Color(0xFF3D6A8A);

  @override
  Widget build(BuildContext context) {
    final total = intDigits + decDigits;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('HOMERGY', style: GoogleFonts.spaceMono(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.greenDark, letterSpacing: 6)),
          const SizedBox(height: 6),
          Text('EINRICHTUNG  ·  SCHRITT 2 VON 3', style: GoogleFonts.rajdhani(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary, letterSpacing: 3)),
          const SizedBox(height: 28),
          Container(height: 1, color: AppColors.border),
          const SizedBox(height: 24),

          Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: _elecBlue.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.bolt_rounded, color: _elecBlue, size: 20),
            ),
            const SizedBox(width: 12),
            Text('STROMZÄHLER EINRICHTEN', style: GoogleFonts.spaceMono(fontSize: 12, fontWeight: FontWeight.w700, color: _elecBlueDk, letterSpacing: 0.5)),
          ]),
          const SizedBox(height: 12),
          Text(
            'Schau auf deinen Stromzähler und zähle die Stellen im Anzeigefeld — links vom Komma und rechts vom Komma.',
            style: GoogleFonts.rajdhani(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 24),

          // Live preview
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                Text('kWh', style: GoogleFonts.spaceMono(fontSize: 11, color: Colors.white60, letterSpacing: 2)),
                const SizedBox(height: 8),
                _ElecMiniDisplay(intDigits: intDigits, decDigits: decDigits),
                const SizedBox(height: 8),
                Text(
                  'Gesamt $total Ziffern — OCR prüft genau $total Stellen',
                  style: GoogleFonts.rajdhani(fontSize: 11, color: Colors.white38, letterSpacing: 0.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // intDigits selector
          Text('STELLEN VOR DEM KOMMA', style: GoogleFonts.rajdhani(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 2)),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final d in [5, 6, 7]) ...[
                Expanded(child: _ElecDigitButton(value: d, selected: intDigits == d, color: _elecBlue, onTap: () => onIntSelect(d))),
                if (d < 7) const SizedBox(width: 10),
              ],
            ],
          ),
          const SizedBox(height: 20),

          // decDigits selector
          Text('STELLEN NACH DEM KOMMA', style: GoogleFonts.rajdhani(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 2)),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final d in [1, 2, 3]) ...[
                Expanded(child: _ElecDigitButton(value: d, selected: decDigits == d, color: _elecBlue, onTap: () => onDecSelect(d))),
                if (d < 3) const SizedBox(width: 10),
              ],
            ],
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: _elecBlue.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded, size: 16, color: _elecBlue),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Die rot markierte Dezimaltrommel zeigt die Stellen nach dem Komma. Diese Einstellung kann jederzeit in den Einstellungen geändert werden.',
                    style: GoogleFonts.rajdhani(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ElecDigitButton extends StatelessWidget {
  final int value;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _ElecDigitButton({required this.value, required this.selected, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 52,
        decoration: BoxDecoration(
          color: selected ? color : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          boxShadow: selected
              ? [BoxShadow(color: color.withOpacity(0.4), offset: const Offset(0, 3), blurRadius: 8)]
              : AppColors.neu(4),
        ),
        child: Center(
          child: Text('$value', style: GoogleFonts.spaceMono(fontSize: 20, fontWeight: FontWeight.w700, color: selected ? Colors.white : AppColors.textSecondary)),
        ),
      ),
    );
  }
}

class _ElecMiniDisplay extends StatelessWidget {
  final int intDigits;
  final int decDigits;
  const _ElecMiniDisplay({required this.intDigits, required this.decDigits});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < intDigits; i++) ...[
          _ElecDigitBox(isDecimal: false),
          if (i < intDigits - 1) const SizedBox(width: 3),
        ],
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: Text(',', style: GoogleFonts.spaceMono(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white70)),
        ),
        for (int i = 0; i < decDigits; i++) ...[
          _ElecDigitBox(isDecimal: true),
          if (i < decDigits - 1) const SizedBox(width: 3),
        ],
      ],
    );
  }
}

class _ElecDigitBox extends StatelessWidget {
  final bool isDecimal;
  const _ElecDigitBox({required this.isDecimal});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24, height: 30,
      decoration: BoxDecoration(
        color: isDecimal ? const Color(0xFF6B2020) : const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: isDecimal ? Colors.red.withOpacity(0.5) : Colors.white24, width: 1),
      ),
      child: Center(
        child: Text('0', style: GoogleFonts.spaceMono(fontSize: 13, fontWeight: FontWeight.w700, color: isDecimal ? Colors.redAccent.shade100 : Colors.white70)),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Page 3 — Location
// ---------------------------------------------------------------------------

class _LocationPage extends StatelessWidget {
  final TextEditingController plzController;
  final TextEditingController cityController;

  const _LocationPage({
    required this.plzController,
    required this.cityController,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'HOMERGY',
            style: GoogleFonts.spaceMono(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppColors.greenDark,
              letterSpacing: 6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'EINRICHTUNG  ·  SCHRITT 3 VON 3',
            style: GoogleFonts.rajdhani(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 28),
          Container(height: 1, color: AppColors.border),
          const SizedBox(height: 24),

          Text(
            'STANDORT FÜR WETTERDATEN',
            style: GoogleFonts.spaceMono(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: 0.5,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.amber.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.thermostat_rounded,
                    size: 18, color: AppColors.amber),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Gib deine Postleitzahl und deinen Wohnort ein — dann können wir dir Temperaturdaten zur Korrelation mit deinem Gasverbrauch anzeigen.',
                    style: GoogleFonts.rajdhani(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Text(
            'Postleitzahl',
            style: GoogleFonts.rajdhani(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
          _OnboardingTextField(
            controller: plzController,
            hint: 'z.B. 80331',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),

          Text(
            'Wohnort',
            style: GoogleFonts.rajdhani(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
          _OnboardingTextField(
            controller: cityController,
            hint: 'z.B. München',
            keyboardType: TextInputType.text,
          ),
          const SizedBox(height: 8),
          Text(
            'Optional — kann jederzeit in den Einstellungen geändert werden.',
            style: GoogleFonts.rajdhani(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared action button
// ---------------------------------------------------------------------------

class _ActionButton extends StatelessWidget {
  final String label;
  final bool isBusy;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.label,
    required this.isBusy,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          color: AppColors.green,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0xFF3A5E3D),
              offset: Offset(0, 5),
              blurRadius: 10,
            ),
          ],
        ),
        child: Center(
          child: isBusy
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  label,
                  style: GoogleFonts.spaceMono(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 3,
                  ),
                ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Progress dot
// ---------------------------------------------------------------------------

class _ProgressDot extends StatelessWidget {
  final bool active;
  const _ProgressDot({required this.active});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: active ? 20 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: active ? AppColors.green : AppColors.border,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Onboarding text field
// ---------------------------------------------------------------------------

class _OnboardingTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;

  const _OnboardingTextField({
    required this.controller,
    required this.hint,
    required this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFDFE5DA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: GoogleFonts.rajdhani(
          fontSize: 16,
          color: AppColors.textPrimary,
        ),
        cursorColor: AppColors.green,
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          hintText: hint,
          hintStyle: GoogleFonts.rajdhani(
            fontSize: 15,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Meter type card
// ---------------------------------------------------------------------------

class _MeterTypeCard extends StatelessWidget {
  final int intDigits;
  final String exampleInt;
  final String exampleDec;
  final bool isSelected;
  final VoidCallback onTap;

  const _MeterTypeCard({
    required this.intDigits,
    required this.exampleInt,
    required this.exampleDec,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(14),
          boxShadow: isSelected
              ? [
                  const BoxShadow(
                    color: Color(0xFF3A5E3D),
                    offset: Offset(0, 3),
                    blurRadius: 8,
                  ),
                ]
              : AppColors.neu(5),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.green : Colors.transparent,
                border: Border.all(
                  color: isSelected ? AppColors.green : AppColors.textSecondary,
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$intDigits Vorkomma-Stellen',
                  style: GoogleFonts.rajdhani(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? AppColors.greenDark : AppColors.textPrimary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                _MiniDisplay(
                  intDigits: intDigits,
                  exampleInt: exampleInt,
                  exampleDec: exampleDec,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniDisplay extends StatelessWidget {
  final int intDigits;
  final String exampleInt;
  final String exampleDec;

  const _MiniDisplay({
    required this.intDigits,
    required this.exampleInt,
    required this.exampleDec,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 0; i < intDigits; i++) ...[
          _DigitBox(char: exampleInt[i], isDecimal: false),
          if (i < intDigits - 1) const SizedBox(width: 2),
        ],
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            ',',
            style: GoogleFonts.spaceMono(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        for (int i = 0; i < 3; i++) ...[
          _DigitBox(char: exampleDec[i], isDecimal: true),
          if (i < 2) const SizedBox(width: 2),
        ],
        Padding(
          padding: const EdgeInsets.only(left: 6),
          child: Text(
            'm³',
            style: GoogleFonts.rajdhani(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _DigitBox extends StatelessWidget {
  final String char;
  final bool isDecimal;

  const _DigitBox({required this.char, required this.isDecimal});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 24,
      decoration: BoxDecoration(
        color: isDecimal
            ? AppColors.amber.withOpacity(0.12)
            : AppColors.background,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isDecimal
              ? AppColors.amber.withOpacity(0.4)
              : AppColors.green.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Center(
        child: Text(
          char,
          style: GoogleFonts.spaceMono(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isDecimal ? AppColors.amber : AppColors.greenDark,
          ),
        ),
      ),
    );
  }
}
