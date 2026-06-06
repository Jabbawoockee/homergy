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
enum _TrackingMode { gas, electricity, both }

// Fixed page indices in the PageView
const _pageEmail    = 0;
const _pageTracking = 1;
const _pageGas      = 2;
const _pageElec     = 3;
const _pageLocation = 4;

const _skipHint = 'Wenn "Überspringen" gewählt wird, kannst du die Einstellung auch jederzeit in der App unter "Einstellungen" nachholen oder anpassen.';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _settingsService = SettingsService();

  _OnbMode _mode = _OnbMode.welcome;

  // Login flow
  final _loginEmailController = TextEditingController();
  bool _isSendingLink = false;
  bool _linkSent = false;
  bool _isSyncing = false;
  StreamSubscription<AuthState>? _authSub;

  // New-user flow
  final _pageController       = PageController();
  final _emailController      = TextEditingController();
  final _plzController        = TextEditingController();
  int _selectedDigits         = 5;
  int _selectedElecIntDigits  = 6;
  int _selectedElecDecDigits  = 1;
  int _currentPage            = 0;
  bool _saving                = false;
  bool _emailSending          = false;
  _TrackingMode _trackingMode = _TrackingMode.both;

  @override
  void initState() {
    super.initState();
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
    _emailController.dispose();
    _plzController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Navigation helpers
  // ---------------------------------------------------------------------------

  int _nextPageIndex(int current) {
    switch (current) {
      case _pageEmail:    return _pageTracking;
      case _pageTracking:
        return (_trackingMode == _TrackingMode.electricity) ? _pageElec : _pageGas;
      case _pageGas:
        return (_trackingMode == _TrackingMode.both) ? _pageElec : _pageLocation;
      case _pageElec:     return _pageLocation;
      default:            return -1;
    }
  }

  int _prevPageIndex(int current) {
    switch (current) {
      case _pageTracking: return _pageEmail;
      case _pageGas:      return _pageTracking;
      case _pageElec:
        return (_trackingMode == _TrackingMode.both) ? _pageGas : _pageTracking;
      case _pageLocation:
        return (_trackingMode == _TrackingMode.gas) ? _pageGas : _pageElec;
      default:            return -1;
    }
  }

  // How many steps are relevant for progress dots
  int get _totalSteps => _trackingMode == _TrackingMode.both ? 5 : 4;

  // Current step index (0-based) among relevant pages
  int get _currentStepIndex {
    switch (_currentPage) {
      case _pageEmail:    return 0;
      case _pageTracking: return 1;
      case _pageGas:      return 2;
      case _pageElec:     return _trackingMode == _TrackingMode.both ? 3 : 2;
      case _pageLocation: return _trackingMode == _TrackingMode.both ? 4 : 3;
      default:            return 0;
    }
  }

  void _goToNext() {
    final next = _nextPageIndex(_currentPage);
    if (next >= 0) {
      _pageController.animateToPage(next,
          duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
    }
  }

  void _goToPrev() {
    final prev = _prevPageIndex(_currentPage);
    if (prev >= 0) {
      _pageController.animateToPage(prev,
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      setState(() => _mode = _OnbMode.welcome);
    }
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> _finishWithLogin() async {
    if (mounted) setState(() => _isSyncing = true);
    await SyncService().syncAll();
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

  // Check email existence, send link, return false if account already exists
  Future<bool> _sendOnboardingEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) return false;
    setState(() => _emailSending = true);
    try {
      final exists = await SupabaseService.emailExists(email);
      if (exists) {
        if (mounted) {
          setState(() => _emailSending = false);
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => AlertDialog(
              backgroundColor: AppColors.background,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text('Konto bereits vorhanden',
                  style: GoogleFonts.rajdhani(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              content: Text(
                'Die E-Mail-Adresse "$email" ist bereits mit einem Homergy-Konto verknüpft.\n\nMelde dich stattdessen mit dieser E-Mail an.',
                style: GoogleFonts.rajdhani(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    setState(() {
                      _mode = _OnbMode.welcome;
                      _emailController.clear();
                      _currentPage = 0;
                    });
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (_pageController.hasClients) {
                        _pageController.jumpToPage(0);
                      }
                    });
                  },
                  child: Text('ZUM ANMELDEN',
                      style: GoogleFonts.spaceMono(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.green, letterSpacing: 1)),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Andere E-Mail',
                      style: GoogleFonts.rajdhani(fontSize: 14, color: AppColors.textSecondary)),
                ),
              ],
            ),
          );
        }
        return false;
      }
      await SupabaseService.signInWithMagicLink(email);
    } catch (_) {}
    if (mounted) setState(() => _emailSending = false);
    return true;
  }

  Future<void> _finishNewUser({bool skipLocation = false}) async {
    setState(() => _saving = true);

    await _settingsService.setTrackingMode(_trackingMode.name);

    if (_trackingMode == _TrackingMode.gas || _trackingMode == _TrackingMode.both) {
      await _settingsService.setMeterIntDigits(_selectedDigits);
    }
    if (_trackingMode == _TrackingMode.electricity || _trackingMode == _TrackingMode.both) {
      await _settingsService.setElectricityIntDigits(_selectedElecIntDigits);
      await _settingsService.setElectricityDecDigits(_selectedElecDecDigits);
    }

    if (!skipLocation) {
      final plz = _plzController.text.trim();
      if (plz.isNotEmpty) {
        await AppDatabase.instance.saveLocation(plz: plz, city: '');
        _geocodeInBackground(plz);
      }
    }

    await _settingsService.setOnboardingDone();
    SyncService().syncAll();
    if (mounted) Navigator.of(context).pushReplacementNamed('/main');
  }

  void _geocodeInBackground(String plz) async {
    final coords = await WeatherService().geocodeByPlz(plz);
    if (coords != null) {
      final settings = await AppDatabase.instance.getSettings();
      if (settings != null) {
        await AppDatabase.instance.saveLocation(plz: plz, city: coords.city);
        await AppDatabase.instance.saveCoordinates(settings.id, coords.lat, coords.lon);
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: AppColors.error,
      content: Text(msg, style: GoogleFonts.rajdhani(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
    ));
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
  // Welcome
  // ---------------------------------------------------------------------------

  Widget _buildWelcome() {
    return Padding(
      key: const ValueKey('welcome'),
      padding: const EdgeInsets.fromLTRB(28, 48, 28, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(flex: 1),
          Center(
            child: Container(
              width: 80, height: 80,
              decoration: BoxDecoration(color: AppColors.background, shape: BoxShape.circle, boxShadow: AppColors.neu(10)),
              child: const Icon(Icons.local_fire_department_rounded, color: AppColors.amber, size: 38),
            ),
          ),
          const SizedBox(height: 28),
          Text('HOMERGY', textAlign: TextAlign.center,
              style: GoogleFonts.spaceMono(fontSize: 30, fontWeight: FontWeight.w700, color: AppColors.greenDark, letterSpacing: 6)),
          const SizedBox(height: 8),
          Text('Strom & Gas im Blick', textAlign: TextAlign.center,
              style: GoogleFonts.rajdhani(fontSize: 15, color: AppColors.textSecondary, letterSpacing: 0.5)),
          const Spacer(flex: 2),

          // Existing account
          GestureDetector(
            onTap: () => setState(() => _mode = _OnbMode.login),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(18), boxShadow: AppColors.neu(7)),
              child: Row(children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(color: AppColors.green.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.person_rounded, color: AppColors.green, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Ich habe bereits ein Konto', style: GoogleFonts.rajdhani(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: 0.3)),
                  const SizedBox(height: 3),
                  Text('Anmelden & Daten wiederherstellen', style: GoogleFonts.rajdhani(fontSize: 13, color: AppColors.textSecondary)),
                ])),
                const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textSecondary),
              ]),
            ),
          ),
          const SizedBox(height: 14),

          // New account
          GestureDetector(
            onTap: () => setState(() => _mode = _OnbMode.newUser),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.green,
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [BoxShadow(color: Color(0xFF3A5E3D), offset: Offset(0, 5), blurRadius: 12)],
              ),
              child: Row(children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Neu starten', style: GoogleFonts.rajdhani(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.3)),
                  const SizedBox(height: 3),
                  Text('Konto erstellen & einrichten', style: GoogleFonts.rajdhani(fontSize: 13, color: Colors.white.withValues(alpha: 0.8))),
                ])),
                Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white.withValues(alpha: 0.7)),
              ]),
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
          Row(children: [
            GestureDetector(
              onTap: () => setState(() { _mode = _OnbMode.welcome; _linkSent = false; _loginEmailController.clear(); }),
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: AppColors.background, shape: BoxShape.circle, boxShadow: AppColors.neu(5)),
                child: const Icon(Icons.arrow_back_ios_new, size: 16, color: AppColors.textPrimary),
              ),
            ),
            const SizedBox(width: 16),
            Text('ANMELDEN', style: GoogleFonts.spaceMono(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.greenDark, letterSpacing: 4)),
          ]),
          const SizedBox(height: 32),
          Container(height: 1, color: AppColors.border),
          const SizedBox(height: 28),

          if (!_linkSent) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.green.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(12)),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.green),
                const SizedBox(width: 10),
                Expanded(child: Text(
                  'Gib deine E-Mail-Adresse ein. Wir senden dir einen Anmeldelink — kein Passwort nötig. Alle deine Daten werden danach automatisch geladen.',
                  style: GoogleFonts.rajdhani(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
                )),
              ]),
            ),
            const SizedBox(height: 28),
            Text('E-MAIL-ADRESSE', style: GoogleFonts.rajdhani(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 2)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(color: const Color(0xFFDFE5DA), borderRadius: BorderRadius.circular(12)),
              child: TextField(
                controller: _loginEmailController,
                keyboardType: TextInputType.emailAddress,
                autofocus: true,
                style: GoogleFonts.rajdhani(fontSize: 17, color: AppColors.textPrimary),
                cursorColor: AppColors.green,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                  hintText: 'deine@email.de',
                  hintStyle: GoogleFonts.rajdhani(fontSize: 16, color: AppColors.textSecondary),
                ),
              ),
            ),
            const SizedBox(height: 24),
            _ActionButton(label: 'ANMELDELINK SENDEN', isBusy: _isSendingLink, onTap: _isSendingLink ? null : _sendMagicLink),
          ] else ...[
            const Spacer(),
            Center(
              child: Container(
                width: 80, height: 80,
                decoration: BoxDecoration(color: AppColors.background, shape: BoxShape.circle, boxShadow: AppColors.neu(10)),
                child: _isSyncing
                    ? const Padding(padding: EdgeInsets.all(22), child: CircularProgressIndicator(color: AppColors.green, strokeWidth: 2.5))
                    : const Icon(Icons.mark_email_read_outlined, color: AppColors.green, size: 36),
              ),
            ),
            const SizedBox(height: 28),
            Text(_isSyncing ? 'Daten werden geladen …' : 'E-Mail gesendet!',
                textAlign: TextAlign.center,
                style: GoogleFonts.spaceMono(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.greenDark, letterSpacing: 1)),
            const SizedBox(height: 12),
            Text(
              _isSyncing
                  ? 'Deine Daten werden aus der Cloud synchronisiert.\nEinen Moment …'
                  : 'Wir haben einen Anmeldelink an\n${_loginEmailController.text.trim()}\ngesendet.',
              textAlign: TextAlign.center,
              style: GoogleFonts.rajdhani(fontSize: 15, color: AppColors.textSecondary, height: 1.6),
            ),
            const SizedBox(height: 20),
            if (!_isSyncing)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(color: AppColors.amber.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(12)),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Icons.touch_app_outlined, size: 18, color: AppColors.amber),
                  const SizedBox(width: 10),
                  Expanded(child: Text(
                    'Öffne deine E-Mail-App, tippe den Link an — die App öffnet sich automatisch und lädt deine Daten.',
                    style: GoogleFonts.rajdhani(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
                  )),
                ]),
              ),
            const Spacer(),
            GestureDetector(
              onTap: () => setState(() => _linkSent = false),
              child: Text('Andere E-Mail-Adresse verwenden', textAlign: TextAlign.center,
                  style: GoogleFonts.rajdhani(fontSize: 13, color: AppColors.textSecondary,
                      decoration: TextDecoration.underline, decorationColor: AppColors.textSecondary)),
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // New-user flow
  // ---------------------------------------------------------------------------

  Widget _buildNewUserFlow() {
    final isLastPage = _currentPage == _pageLocation;

    return Column(
      key: const ValueKey('newUser'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header: back + progress dots
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          child: Row(
            children: [
              GestureDetector(
                onTap: _goToPrev,
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(color: AppColors.background, shape: BoxShape.circle, boxShadow: AppColors.neu(4)),
                  child: const Icon(Icons.arrow_back_ios_new, size: 14, color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(width: 12),
              ...List.generate(_totalSteps, (i) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: _ProgressDot(active: i <= _currentStepIndex),
              )),
            ],
          ),
        ),

        // PageView
        Expanded(
          child: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (i) => setState(() => _currentPage = i),
            children: [
              // Page 0: Email
              _EmailOnboardingPage(
                controller: _emailController,
                isSending: _emailSending,
              ),
              // Page 1: Tracking mode
              _TrackingModePage(
                selected: _trackingMode,
                onSelect: (m) => setState(() => _trackingMode = m),
              ),
              // Page 2: Gas meter
              _MeterTypePage(
                selectedDigits: _selectedDigits,
                onSelect: (d) => setState(() => _selectedDigits = d),
                trackingMode: _trackingMode,
              ),
              // Page 3: Electricity meter
              _ElecMeterPage(
                intDigits: _selectedElecIntDigits,
                decDigits: _selectedElecDecDigits,
                onIntSelect: (d) => setState(() => _selectedElecIntDigits = d),
                onDecSelect: (d) => setState(() => _selectedElecDecDigits = d),
                trackingMode: _trackingMode,
              ),
              // Page 4: Location
              _LocationPage(plzController: _plzController),
            ],
          ),
        ),

        // Bottom actions
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ActionButton(
                label: isLastPage ? 'LOSLEGEN' : 'WEITER',
                isBusy: isLastPage ? _saving : _emailSending,
                onTap: (isLastPage && _saving) || (!isLastPage && _emailSending)
                    ? null
                    : () async {
                        if (_currentPage == _pageEmail) {
                          final email = _emailController.text.trim();
                          if (email.isEmpty || !email.contains('@')) {
                            _showError('Bitte eine gültige E-Mail-Adresse eingeben.');
                            return;
                          }
                          final ok = await _sendOnboardingEmail();
                          if (!ok) return;
                        }
                        if (isLastPage) {
                          _finishNewUser();
                        } else {
                          _goToNext();
                        }
                      },
              ),
              if (isLastPage) ...[
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _saving ? null : () => _finishNewUser(skipLocation: true),
                  child: Text('Überspringen',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.rajdhani(fontSize: 13, color: AppColors.textSecondary,
                          decoration: TextDecoration.underline, decorationColor: AppColors.textSecondary)),
                ),
                const SizedBox(height: 6),
                Text(_skipHint,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.rajdhani(fontSize: 11, color: AppColors.textSecondary.withValues(alpha: 0.6), height: 1.4)),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Page 0 — Email
// ---------------------------------------------------------------------------

class _EmailOnboardingPage extends StatelessWidget {
  final TextEditingController controller;
  final bool isSending;
  const _EmailOnboardingPage({required this.controller, required this.isSending});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('HOMERGY', style: GoogleFonts.spaceMono(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.greenDark, letterSpacing: 6)),
          const SizedBox(height: 6),
          Text('EINRICHTUNG  ·  E-MAIL', style: GoogleFonts.rajdhani(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary, letterSpacing: 3)),
          const SizedBox(height: 28),
          Container(height: 1, color: AppColors.border),
          const SizedBox(height: 24),

          Text('DEIN KONTO', style: GoogleFonts.spaceMono(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: 0.5, height: 1.5)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.green.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(12)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.cloud_outlined, size: 18, color: AppColors.green),
              const SizedBox(width: 10),
              Expanded(child: Text(
                'Gib deine E-Mail-Adresse ein, um deine Daten in der Cloud zu sichern und geräteübergreifend zu nutzen. Wir senden dir einen Bestätigungslink — kein Passwort nötig.',
                style: GoogleFonts.rajdhani(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
              )),
            ]),
          ),
          const SizedBox(height: 24),
          Text('E-MAIL-ADRESSE', style: GoogleFonts.rajdhani(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 2)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(color: const Color(0xFFDFE5DA), borderRadius: BorderRadius.circular(12)),
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.emailAddress,
              style: GoogleFonts.rajdhani(fontSize: 17, color: AppColors.textPrimary),
              cursorColor: AppColors.green,
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                hintText: 'deine@email.de',
                hintStyle: GoogleFonts.rajdhani(fontSize: 16, color: AppColors.textSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Page 1 — Tracking mode
// ---------------------------------------------------------------------------

class _TrackingModePage extends StatelessWidget {
  final _TrackingMode selected;
  final ValueChanged<_TrackingMode> onSelect;
  const _TrackingModePage({required this.selected, required this.onSelect});

  static const _elecBlue = Color(0xFF5B8DB8);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('HOMERGY', style: GoogleFonts.spaceMono(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.greenDark, letterSpacing: 6)),
          const SizedBox(height: 6),
          Text('EINRICHTUNG  ·  TRACKING-MODUS', style: GoogleFonts.rajdhani(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary, letterSpacing: 3)),
          const SizedBox(height: 28),
          Container(height: 1, color: AppColors.border),
          const SizedBox(height: 24),

          Text('WAS MÖCHTEST DU TRACKEN?', style: GoogleFonts.spaceMono(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: 0.5, height: 1.5)),
          const SizedBox(height: 8),
          Text('Du kannst den Modus jederzeit in den Einstellungen ändern.', style: GoogleFonts.rajdhani(fontSize: 14, color: AppColors.textSecondary, height: 1.5)),
          const SizedBox(height: 24),

          _TrackingCard(
            icon: Icons.local_fire_department_rounded,
            iconColor: AppColors.green,
            title: 'Nur Gas',
            subtitle: 'Gaszähler ablesen & Verbrauch verfolgen',
            selected: selected == _TrackingMode.gas,
            onTap: () => onSelect(_TrackingMode.gas),
          ),
          const SizedBox(height: 12),
          _TrackingCard(
            icon: Icons.bolt_rounded,
            iconColor: _elecBlue,
            title: 'Nur Strom',
            subtitle: 'Stromzähler ablesen & Verbrauch verfolgen',
            selected: selected == _TrackingMode.electricity,
            onTap: () => onSelect(_TrackingMode.electricity),
          ),
          const SizedBox(height: 12),
          _TrackingCard(
            icon: Icons.home_rounded,
            iconColor: AppColors.amber,
            title: 'Gas & Strom',
            subtitle: 'Beide Zähler erfassen und vergleichen',
            selected: selected == _TrackingMode.both,
            onTap: () => onSelect(_TrackingMode.both),
            highlight: true,
          ),
        ],
      ),
    );
  }
}

class _TrackingCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title, subtitle;
  final bool selected, highlight;
  final VoidCallback onTap;
  const _TrackingCard({required this.icon, required this.iconColor, required this.title, required this.subtitle, required this.selected, required this.onTap, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected ? AppColors.green : AppColors.background,
          borderRadius: BorderRadius.circular(16),
          boxShadow: selected
              ? const [BoxShadow(color: Color(0xFF3A5E3D), offset: Offset(0, 4), blurRadius: 10)]
              : AppColors.neu(6),
        ),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: selected ? Colors.white.withValues(alpha: 0.2) : iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: selected ? Colors.white : iconColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: GoogleFonts.rajdhani(fontSize: 16, fontWeight: FontWeight.w700,
                color: selected ? Colors.white : AppColors.textPrimary, letterSpacing: 0.3)),
            const SizedBox(height: 3),
            Text(subtitle, style: GoogleFonts.rajdhani(fontSize: 13,
                color: selected ? Colors.white.withValues(alpha: 0.8) : AppColors.textSecondary)),
          ])),
          if (selected)
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20)
          else
            Icon(Icons.radio_button_unchecked_rounded, color: AppColors.textSecondary.withValues(alpha: 0.4), size: 20),
        ]),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Page 2 — Gas meter type
// ---------------------------------------------------------------------------

class _MeterTypePage extends StatelessWidget {
  final int selectedDigits;
  final ValueChanged<int> onSelect;
  final _TrackingMode trackingMode;

  const _MeterTypePage({required this.selectedDigits, required this.onSelect, required this.trackingMode});

  @override
  Widget build(BuildContext context) {
    final stepLabel = trackingMode == _TrackingMode.both ? 'SCHRITT 3 VON 5' : 'SCHRITT 3 VON 4';
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('HOMERGY', style: GoogleFonts.spaceMono(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.greenDark, letterSpacing: 6)),
          const SizedBox(height: 6),
          Text('EINRICHTUNG  ·  $stepLabel', style: GoogleFonts.rajdhani(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary, letterSpacing: 3)),
          const SizedBox(height: 28),
          Container(height: 1, color: AppColors.border),
          const SizedBox(height: 24),
          Text('WIE VIELE STELLEN HAT DER\nVORKOMMA-BEREICH DEINES GASZÄHLERS?',
              style: GoogleFonts.spaceMono(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: 0.5, height: 1.5)),
          const SizedBox(height: 8),
          Text('Diese Einstellung hilft der OCR-Erkennung, den Zählerstand korrekt aufzuteilen. Du kannst sie später in den Einstellungen ändern.',
              style: GoogleFonts.rajdhani(fontSize: 14, color: AppColors.textSecondary, height: 1.5)),
          const SizedBox(height: 24),
          _MeterTypeCard(intDigits: 4, exampleInt: '1234', exampleDec: '567', isSelected: selectedDigits == 4, onTap: () => onSelect(4)),
          const SizedBox(height: 12),
          _MeterTypeCard(intDigits: 5, exampleInt: '15154', exampleDec: '888', isSelected: selectedDigits == 5, onTap: () => onSelect(5)),
          const SizedBox(height: 12),
          _MeterTypeCard(intDigits: 6, exampleInt: '123456', exampleDec: '789', isSelected: selectedDigits == 6, onTap: () => onSelect(6)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Page 3 — Electricity meter
// ---------------------------------------------------------------------------

class _ElecMeterPage extends StatelessWidget {
  final int intDigits, decDigits;
  final ValueChanged<int> onIntSelect, onDecSelect;
  final _TrackingMode trackingMode;

  const _ElecMeterPage({required this.intDigits, required this.decDigits, required this.onIntSelect, required this.onDecSelect, required this.trackingMode});

  static const _elecBlue   = Color(0xFF5B8DB8);
  static const _elecBlueDk = Color(0xFF3D6A8A);

  @override
  Widget build(BuildContext context) {
    final stepLabel = trackingMode == _TrackingMode.both ? 'SCHRITT 4 VON 5' : 'SCHRITT 3 VON 4';
    final total = intDigits + decDigits;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('HOMERGY', style: GoogleFonts.spaceMono(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.greenDark, letterSpacing: 6)),
          const SizedBox(height: 6),
          Text('EINRICHTUNG  ·  $stepLabel', style: GoogleFonts.rajdhani(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary, letterSpacing: 3)),
          const SizedBox(height: 28),
          Container(height: 1, color: AppColors.border),
          const SizedBox(height: 24),
          Row(children: [
            Container(width: 36, height: 36, decoration: BoxDecoration(color: _elecBlue.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.bolt_rounded, color: _elecBlue, size: 20)),
            const SizedBox(width: 12),
            Text('STROMZÄHLER EINRICHTEN', style: GoogleFonts.spaceMono(fontSize: 12, fontWeight: FontWeight.w700, color: _elecBlueDk, letterSpacing: 0.5)),
          ]),
          const SizedBox(height: 12),
          Text('Schau auf deinen Stromzähler und zähle die Stellen im Anzeigefeld — links vom Komma und rechts vom Komma.',
              style: GoogleFonts.rajdhani(fontSize: 14, color: AppColors.textSecondary, height: 1.5)),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(12)),
            child: Column(children: [
              Text('kWh', style: GoogleFonts.spaceMono(fontSize: 11, color: Colors.white60, letterSpacing: 2)),
              const SizedBox(height: 8),
              _ElecMiniDisplay(intDigits: intDigits, decDigits: decDigits),
              const SizedBox(height: 8),
              Text('Gesamt $total Ziffern — OCR prüft genau $total Stellen',
                  style: GoogleFonts.rajdhani(fontSize: 11, color: Colors.white38, letterSpacing: 0.5)),
            ]),
          ),
          const SizedBox(height: 24),
          Text('STELLEN VOR DEM KOMMA', style: GoogleFonts.rajdhani(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 2)),
          const SizedBox(height: 10),
          Row(children: [
            for (final d in [5, 6, 7]) ...[
              Expanded(child: _ElecDigitButton(value: d, selected: intDigits == d, color: _elecBlue, onTap: () => onIntSelect(d))),
              if (d < 7) const SizedBox(width: 10),
            ],
          ]),
          const SizedBox(height: 20),
          Text('STELLEN NACH DEM KOMMA', style: GoogleFonts.rajdhani(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 2)),
          const SizedBox(height: 10),
          Row(children: [
            for (final d in [1, 2, 3]) ...[
              Expanded(child: _ElecDigitButton(value: d, selected: decDigits == d, color: _elecBlue, onTap: () => onDecSelect(d))),
              if (d < 3) const SizedBox(width: 10),
            ],
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: _elecBlue.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.info_outline_rounded, size: 16, color: _elecBlue),
              const SizedBox(width: 10),
              Expanded(child: Text(
                'Die rot markierte Dezimaltrommel zeigt die Stellen nach dem Komma. Diese Einstellung kann jederzeit in den Einstellungen geändert werden.',
                style: GoogleFonts.rajdhani(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
              )),
            ]),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Page 4 — Location
// ---------------------------------------------------------------------------

class _LocationPage extends StatelessWidget {
  final TextEditingController plzController;
  const _LocationPage({required this.plzController});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('HOMERGY', style: GoogleFonts.spaceMono(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.greenDark, letterSpacing: 6)),
          const SizedBox(height: 6),
          Text('EINRICHTUNG  ·  STANDORT', style: GoogleFonts.rajdhani(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary, letterSpacing: 3)),
          const SizedBox(height: 28),
          Container(height: 1, color: AppColors.border),
          const SizedBox(height: 24),
          Text('STANDORT FÜR WETTERDATEN', style: GoogleFonts.spaceMono(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: 0.5, height: 1.5)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.amber.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(12)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.thermostat_rounded, size: 18, color: AppColors.amber),
              const SizedBox(width: 10),
              Expanded(child: Text(
                'Gib deine Postleitzahl ein — dann können wir dir Temperaturdaten zur Korrelation mit deinem Verbrauch anzeigen.',
                style: GoogleFonts.rajdhani(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
              )),
            ]),
          ),
          const SizedBox(height: 24),
          Text('Postleitzahl', style: GoogleFonts.rajdhani(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary, letterSpacing: 0.3)),
          const SizedBox(height: 8),
          _OnboardingTextField(controller: plzController, hint: 'z.B. 80331', keyboardType: TextInputType.number),
          const SizedBox(height: 8),
          Text('Optional — kann jederzeit in den Einstellungen geändert werden.',
              style: GoogleFonts.rajdhani(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared widgets
// ---------------------------------------------------------------------------

class _ActionButton extends StatelessWidget {
  final String label;
  final bool isBusy;
  final VoidCallback? onTap;
  const _ActionButton({required this.label, required this.isBusy, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          color: AppColors.green,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Color(0xFF3A5E3D), offset: Offset(0, 5), blurRadius: 10)],
        ),
        child: Center(child: isBusy
            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text(label, style: GoogleFonts.spaceMono(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 3))),
      ),
    );
  }
}

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

class _OnboardingTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;
  const _OnboardingTextField({required this.controller, required this.hint, required this.keyboardType});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFFDFE5DA), borderRadius: BorderRadius.circular(12)),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: GoogleFonts.rajdhani(fontSize: 16, color: AppColors.textPrimary),
        cursorColor: AppColors.green,
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          hintText: hint,
          hintStyle: GoogleFonts.rajdhani(fontSize: 15, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

class _MeterTypeCard extends StatelessWidget {
  final int intDigits;
  final String exampleInt, exampleDec;
  final bool isSelected;
  final VoidCallback onTap;
  const _MeterTypeCard({required this.intDigits, required this.exampleInt, required this.exampleDec, required this.isSelected, required this.onTap});

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
          boxShadow: isSelected ? [const BoxShadow(color: Color(0xFF3A5E3D), offset: Offset(0, 3), blurRadius: 8)] : AppColors.neu(5),
        ),
        child: Row(children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 20, height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? AppColors.green : Colors.transparent,
              border: Border.all(color: isSelected ? AppColors.green : AppColors.textSecondary, width: 1.5),
            ),
            child: isSelected ? const Icon(Icons.check, size: 12, color: Colors.white) : null,
          ),
          const SizedBox(width: 16),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('$intDigits Vorkomma-Stellen',
                style: GoogleFonts.rajdhani(fontSize: 15, fontWeight: FontWeight.w700,
                    color: isSelected ? AppColors.greenDark : AppColors.textPrimary, letterSpacing: 0.5)),
            const SizedBox(height: 6),
            _MiniDisplay(intDigits: intDigits, exampleInt: exampleInt, exampleDec: exampleDec),
          ]),
        ]),
      ),
    );
  }
}

class _MiniDisplay extends StatelessWidget {
  final int intDigits;
  final String exampleInt, exampleDec;
  const _MiniDisplay({required this.intDigits, required this.exampleInt, required this.exampleDec});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      for (int i = 0; i < intDigits; i++) ...[
        _DigitBox(char: exampleInt[i], isDecimal: false),
        if (i < intDigits - 1) const SizedBox(width: 2),
      ],
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(',', style: GoogleFonts.spaceMono(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
      ),
      for (int i = 0; i < 3; i++) ...[
        _DigitBox(char: exampleDec[i], isDecimal: true),
        if (i < 2) const SizedBox(width: 2),
      ],
      Padding(
        padding: const EdgeInsets.only(left: 6),
        child: Text('m³', style: GoogleFonts.rajdhani(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
      ),
    ]);
  }
}

class _DigitBox extends StatelessWidget {
  final String char;
  final bool isDecimal;
  const _DigitBox({required this.char, required this.isDecimal});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20, height: 24,
      decoration: BoxDecoration(
        color: isDecimal ? AppColors.amber.withValues(alpha: 0.12) : AppColors.background,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isDecimal ? AppColors.amber.withValues(alpha: 0.4) : AppColors.green.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Center(child: Text(char,
          style: GoogleFonts.spaceMono(fontSize: 11, fontWeight: FontWeight.w700,
              color: isDecimal ? AppColors.amber : AppColors.greenDark))),
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
              ? [BoxShadow(color: color.withValues(alpha: 0.4), offset: const Offset(0, 3), blurRadius: 8)]
              : AppColors.neu(4),
        ),
        child: Center(child: Text('$value',
            style: GoogleFonts.spaceMono(fontSize: 20, fontWeight: FontWeight.w700,
                color: selected ? Colors.white : AppColors.textSecondary))),
      ),
    );
  }
}

class _ElecMiniDisplay extends StatelessWidget {
  final int intDigits, decDigits;
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
        border: Border.all(color: isDecimal ? Colors.red.withValues(alpha: 0.5) : Colors.white24, width: 1),
      ),
      child: Center(child: Text('0',
          style: GoogleFonts.spaceMono(fontSize: 13, fontWeight: FontWeight.w700,
              color: isDecimal ? Colors.redAccent.shade100 : Colors.white70))),
    );
  }
}
