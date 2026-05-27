import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../database/database.dart';
import '../services/settings_service.dart';
import '../services/supabase_service.dart';
import '../services/sync_service.dart';
import '../services/weather_service.dart';
import '../theme/colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _settingsService = SettingsService();
  final _priceController = TextEditingController();
  final _basePriceController = TextEditingController();
  final _brennwertController = TextEditingController();
  final _zustandszahlController = TextEditingController();
  final _providerController = TextEditingController();
  final _emailController = TextEditingController();
  final _plzController = TextEditingController();
  final _cityController = TextEditingController();
  PriceContract? _latestContract;
  AppSetting? _locationSettings;
  bool _isNewContract = false;
  DateTime? _priceValidFrom;
  bool _isSaving = false;
  bool _isSavingLocation = false;
  bool _isSendingLink = false;
  bool _linkSent = false;
  int _meterIntDigits = 5;
  StreamSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();
    _loadPrice();
    _loadMeterType();
    _loadLocation();
    // Refresh session so the UI reflects the latest auth state (e.g. after email confirmation).
    SupabaseService.client.auth.refreshSession().catchError((_) {});
    // Rebuild whenever auth state changes (sign-in, email link confirmed, sign-out).
    _authSub = SupabaseService.client.auth.onAuthStateChange.listen((data) {
      if (mounted) {
        setState(() {
          if (data.event == AuthChangeEvent.userUpdated) _linkSent = false;
        });
        // After email confirmed or magic link sign-in: sync everything
        if (data.event == AuthChangeEvent.userUpdated ||
            data.event == AuthChangeEvent.signedIn) {
          SyncService().syncAll();
        }
      }
    });
  }

  Future<void> _loadPrice() async {
    final contracts = await AppDatabase.instance.getAllContracts();
    final latest = contracts.isNotEmpty ? contracts.last : null;
    if (mounted) {
      setState(() {
        _latestContract = latest;
      });
      if (latest != null) {
        _priceController.text = latest.pricePerKwh.toStringAsFixed(4);
        _basePriceController.text = latest.monthlyBasePrice.toStringAsFixed(2);
        _brennwertController.text =
            latest.brennwert > 0 ? latest.brennwert.toStringAsFixed(4) : '';
        _zustandszahlController.text = latest.zustandszahl > 0
            ? latest.zustandszahl.toStringAsFixed(4)
            : '';
        _priceValidFrom =
            DateTime.fromMillisecondsSinceEpoch(latest.validFrom);
        _providerController.text = latest.displayName;
      }
    }
  }

  Future<void> _loadLocation() async {
    final s = await AppDatabase.instance.getSettings();
    if (mounted) {
      setState(() => _locationSettings = s);
      if (s != null) {
        _plzController.text = s.locationPlz ?? '';
        _cityController.text = s.locationCity ?? '';
      }
    }
  }

  Future<void> _saveLocation() async {
    final plz = _plzController.text.trim();
    final city = _cityController.text.trim();
    if (plz.isEmpty && city.isEmpty) {
      _showSnack('Bitte PLZ oder Ort eingeben.', isError: true);
      return;
    }
    setState(() => _isSavingLocation = true);
    await AppDatabase.instance.saveLocation(plz: plz, city: city);
    // Geocode in background
    final coords = await WeatherService().geocode(city, plz);
    if (coords != null) {
      final s = await AppDatabase.instance.getSettings();
      if (s != null) {
        await AppDatabase.instance.saveCoordinates(s.id, coords.lat, coords.lon);
      }
    }
    await _loadLocation();
    SyncService().syncSettings();
    if (mounted) {
      setState(() => _isSavingLocation = false);
      _showSnack(coords != null
          ? 'Standort gespeichert & gefunden.'
          : 'Standort gespeichert. Koordinaten konnten nicht ermittelt werden.');
    }
  }

  Future<void> _loadMeterType() async {
    final digits = await _settingsService.getMeterIntDigits();
    if (mounted) setState(() => _meterIntDigits = digits);
  }

  Future<void> _saveMeterType(int digits) async {
    setState(() => _meterIntDigits = digits);
    await _settingsService.setMeterIntDigits(digits);
    SyncService().syncSettings();
    _showSnack('Zählertyp gespeichert: $digits Vorkomma-Stellen');
  }

  Future<void> _saveContract() async {
    final kwhText = _priceController.text.trim().replaceAll(',', '.');
    final kwhParsed = double.tryParse(kwhText);
    if (kwhParsed == null || kwhParsed <= 0) {
      _showSnack('Pflichtfeld fehlt: Preis pro kWh', isError: true);
      return;
    }

    final baseText = _basePriceController.text.trim().replaceAll(',', '.');
    if (baseText.isEmpty) {
      _showSnack(
          'Pflichtfeld fehlt: Grundpreis (0,00 wenn kein Grundpreis)',
          isError: true);
      return;
    }
    final baseParsed = double.tryParse(baseText) ?? -1;
    if (baseParsed < 0) {
      _showSnack('Bitte einen gültigen Grundpreis eingeben.', isError: true);
      return;
    }

    if (_priceValidFrom == null) {
      _showSnack('Pflichtfeld fehlt: Datum "Diese Preise gelten seit:"',
          isError: true);
      return;
    }

    final bool creatingNew = _latestContract == null || _isNewContract;
    final providerName = creatingNew
        ? _providerController.text.trim()
        : _latestContract!.displayName;
    if (providerName.isEmpty) {
      _showSnack('Pflichtfeld fehlt: Lieferant', isError: true);
      return;
    }

    final bwText = _brennwertController.text.trim().replaceAll(',', '.');
    final zzText = _zustandszahlController.text.trim().replaceAll(',', '.');
    final bw = bwText.isEmpty ? 0.0 : (double.tryParse(bwText) ?? -1.0);
    final zz = zzText.isEmpty ? 0.0 : (double.tryParse(zzText) ?? -1.0);
    if (bw < 0 || zz < 0) {
      _showSnack('Bitte gültige Werte für Brennwert / Zustandszahl eingeben.',
          isError: true);
      return;
    }

    setState(() => _isSaving = true);

    if (creatingNew) {
      final count =
          await AppDatabase.instance.countContractsByDisplayName(providerName);
      final internalName = '${providerName}_${count + 1}';
      await AppDatabase.instance.insertContract(PriceContractsCompanion(
        internalName: Value(internalName),
        displayName: Value(providerName),
        pricePerKwh: Value(kwhParsed),
        monthlyBasePrice: Value(baseParsed),
        validFrom: Value(_priceValidFrom!.millisecondsSinceEpoch),
        brennwert: Value(bw),
        zustandszahl: Value(zz),
      ));
    } else {
      // Price update within same contract: INSERT a new row so old prices
      // are preserved for historical month-by-month calculations.
      final count =
          await AppDatabase.instance.countContractsByDisplayName(providerName);
      final internalName = '${providerName}_${count + 1}';
      await AppDatabase.instance.insertContract(PriceContractsCompanion(
        internalName: Value(internalName),
        displayName: Value(providerName),
        pricePerKwh: Value(kwhParsed),
        monthlyBasePrice: Value(baseParsed),
        validFrom: Value(_priceValidFrom!.millisecondsSinceEpoch),
        brennwert: Value(bw),
        zustandszahl: Value(zz),
      ));
    }

    await _loadPrice();
    SyncService().syncAll();
    if (mounted) {
      setState(() {
        _isSaving = false;
        _isNewContract = false;
      });
      _showSnack('Vertrag gespeichert.');
    }
  }

  Future<void> _pickValidFromDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _priceValidFrom ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.amber,
            onPrimary: Colors.black,
            surface: AppColors.surface,
            onSurface: AppColors.textPrimary,
          ),
          dialogTheme: const DialogThemeData(backgroundColor: AppColors.background),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _priceValidFrom = picked);
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isError ? AppColors.error : AppColors.green,
        content: Text(
          msg,
          style: GoogleFonts.rajdhani(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _sendAccountLink() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showSnack('Bitte eine gültige E-Mail-Adresse eingeben.', isError: true);
      return;
    }
    setState(() => _isSendingLink = true);
    try {
      final isAnon = SupabaseService.isAnonymous;
      if (isAnon) {
        // Upgrade anonymous → real account
        await SupabaseService.linkEmail(email);
      } else {
        // Sign in on new device
        await SupabaseService.signInWithMagicLink(email);
      }
      if (mounted) {
        setState(() {
          _isSendingLink = false;
          _linkSent = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSendingLink = false);
        _showSnack('Fehler: $e', isError: true);
      }
    }
  }

  Future<void> _signOut() async {
    await SupabaseService.signOut();
    await SupabaseService.ensureSignedIn();
    if (mounted) {
      setState(() => _linkSent = false);
      _showSnack('Abgemeldet. Neues anonymes Konto erstellt.');
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _priceController.dispose();
    _basePriceController.dispose();
    _brennwertController.dispose();
    _zustandszahlController.dispose();
    _providerController.dispose();
    _emailController.dispose();
    _plzController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const SizedBox(height: 4),
              Text(
                'EINSTELLUNGEN',
                style: GoogleFonts.spaceMono(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.amber,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Konfiguration & App-Info',
                style: GoogleFonts.rajdhani(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),

              const SizedBox(height: 32),

              // ── Section: Zählertyp ─────────────────────────────────────────
              _SectionHeader(label: 'ZÄHLERTYP'),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.speed_rounded,
                            size: 16, color: AppColors.amber),
                        const SizedBox(width: 8),
                        Text(
                          'Vorkomma-Stellen',
                          style: GoogleFonts.rajdhani(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Wie viele Stellen stehen vor dem Komma auf deinem Zähler?',
                      style: GoogleFonts.rajdhani(
                        fontSize: 13,
                        color: AppColors.textSecondary.withOpacity(0.8),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        for (final d in [4, 5, 6]) ...[
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _saveMeterType(d),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                height: 48,
                                decoration: BoxDecoration(
                                  color: _meterIntDigits == d
                                      ? AppColors.amber
                                      : AppColors.background,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: _meterIntDigits == d
                                        ? AppColors.amber
                                        : AppColors.border,
                                    width: 1,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    '$d',
                                    style: GoogleFonts.spaceMono(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: _meterIntDigits == d
                                          ? Colors.black
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (d < 6) const SizedBox(width: 10),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Aktuell: $_meterIntDigits Stellen — Format: ${'0' * _meterIntDigits},${'0' * 3} m³',
                      style: GoogleFonts.spaceMono(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ── Section: Standort ──────────────────────────────────────────
              _SectionHeader(label: 'STANDORT'),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.thermostat_rounded,
                            size: 16, color: AppColors.amber),
                        const SizedBox(width: 8),
                        Text(
                          'Wetterdaten-Standort',
                          style: GoogleFonts.rajdhani(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Wird für die Temperaturkorrelation im Verbrauchsgraph verwendet.',
                      style: GoogleFonts.rajdhani(
                        fontSize: 13,
                        color: AppColors.textSecondary.withOpacity(0.8),
                        height: 1.4,
                      ),
                    ),
                    if (_locationSettings?.locationLat != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.green.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: AppColors.green.withOpacity(0.25),
                              width: 1),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_outline,
                                size: 14, color: AppColors.green),
                            const SizedBox(width: 8),
                            Text(
                              'Koordinaten gefunden',
                              style: GoogleFonts.rajdhani(
                                fontSize: 13,
                                color: AppColors.green,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'PLZ',
                                style: GoogleFonts.rajdhani(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              _TextField(
                                controller: _plzController,
                                hint: '80331',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Wohnort',
                                style: GoogleFonts.rajdhani(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              _TextField(
                                controller: _cityController,
                                hint: 'München',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _SaveButton(
                      label: 'STANDORT SPEICHERN',
                      isBusy: _isSavingLocation,
                      onTap: _saveLocation,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ── Section: Konto ────────────────────────────────────────────
              _SectionHeader(label: 'KONTO'),
              const SizedBox(height: 12),
              _AccountSection(
                isSendingLink: _isSendingLink,
                linkSent: _linkSent,
                emailController: _emailController,
                onSendLink: _sendAccountLink,
                onSignOut: _signOut,
                onSyncNow: () async {
                  await SyncService().syncAll();
                  _showSnack('Synchronisierung abgeschlossen.');
                },
              ),

              const SizedBox(height: 32),

              // ── Section: Gaspreis ──────────────────────────────────────────
              _SectionHeader(label: 'GASPREIS'),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ── Aktueller Vertrag Info ─────────────────────────────
                    if (_latestContract != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.amber.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppColors.amber.withOpacity(0.25),
                              width: 1),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.business_rounded,
                                size: 15, color: AppColors.amber),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _latestContract!.displayName,
                                    style: GoogleFonts.rajdhani(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.amber,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  Text(
                                    'seit ${() {
                                      final d = DateTime.fromMillisecondsSinceEpoch(_latestContract!.validFrom);
                                      return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
                                    }()}  ·  ${_latestContract!.pricePerKwh.toStringAsFixed(4)} €/kWh',
                                    style: GoogleFonts.spaceMono(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Neuer Vertrag? Toggle ──────────────────────────
                      Text(
                        'Neuer Vertrag?',
                        style: GoogleFonts.rajdhani(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _ToggleChip(
                              label: 'Nein – Preis aktualisieren',
                              selected: !_isNewContract,
                              onTap: () =>
                                  setState(() => _isNewContract = false),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _ToggleChip(
                              label: 'Ja – Neuer Anbieter',
                              selected: _isNewContract,
                              onTap: () {
                                setState(() {
                                  _isNewContract = true;
                                  _providerController.clear();
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ── Lieferant ─────────────────────────────────────────
                    if (_latestContract == null || _isNewContract) ...[
                      Row(
                        children: [
                          const Icon(Icons.business_rounded,
                              size: 16, color: AppColors.amber),
                          const SizedBox(width: 8),
                          Text(
                            'Lieferant',
                            style: GoogleFonts.rajdhani(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text('*',
                              style: GoogleFonts.rajdhani(
                                  fontSize: 15,
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _TextField(
                        controller: _providerController,
                        hint: 'z.B. Stadtwerke Musterstadt',
                      ),
                      const SizedBox(height: 20),
                    ],

                    // ── Preis pro kWh ──────────────────────────────────────
                    Row(
                      children: [
                        const Icon(Icons.bolt_rounded,
                            size: 16, color: AppColors.amber),
                        const SizedBox(width: 8),
                        Text(
                          'Preis pro kWh',
                          style: GoogleFonts.rajdhani(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text('*',
                            style: GoogleFonts.rajdhani(
                                fontSize: 15,
                                color: AppColors.error,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _PriceField(
                      controller: _priceController,
                      suffix: '€/kWh',
                      hint: 'z.B. 0.0891',
                    ),

                    const SizedBox(height: 20),

                    // ── Monatlicher Grundpreis ─────────────────────────────
                    Row(
                      children: [
                        const Icon(Icons.calendar_month_outlined,
                            size: 16, color: AppColors.amber),
                        const SizedBox(width: 8),
                        Text(
                          'Monatlicher Grundpreis',
                          style: GoogleFonts.rajdhani(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text('*',
                            style: GoogleFonts.rajdhani(
                                fontSize: 15,
                                color: AppColors.error,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _PriceField(
                      controller: _basePriceController,
                      suffix: '€/Monat',
                      hint: 'z.B. 8.00',
                    ),

                    const SizedBox(height: 20),

                    // ── Gültig seit ────────────────────────────────────────
                    Row(
                      children: [
                        const Icon(Icons.event_rounded,
                            size: 16, color: AppColors.amber),
                        const SizedBox(width: 8),
                        Text(
                          'Diese Preise gelten seit:',
                          style: GoogleFonts.rajdhani(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text('*',
                            style: GoogleFonts.rajdhani(
                                fontSize: 15,
                                color: AppColors.error,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: _pickValidFromDate,
                      child: Container(
                        height: 50,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _priceValidFrom == null
                                ? AppColors.border
                                : AppColors.amber.withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 18,
                              color: _priceValidFrom == null
                                  ? AppColors.textSecondary
                                  : AppColors.amber,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _priceValidFrom == null
                                  ? 'Datum auswählen'
                                  : '${_priceValidFrom!.day.toString().padLeft(2, '0')}.${_priceValidFrom!.month.toString().padLeft(2, '0')}.${_priceValidFrom!.year}',
                              style: _priceValidFrom == null
                                  ? GoogleFonts.rajdhani(
                                      fontSize: 15,
                                      color: AppColors.textSecondary,
                                    )
                                  : GoogleFonts.spaceMono(
                                      fontSize: 15,
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                    Divider(color: AppColors.border, height: 1),
                    const SizedBox(height: 20),

                    // ── Abrechnungsfaktoren ────────────────────────────────
                    Row(
                      children: [
                        const Icon(Icons.calculate_outlined,
                            size: 16, color: AppColors.amber),
                        const SizedBox(width: 8),
                        Text(
                          'Abrechnungsfaktoren',
                          style: GoogleFonts.rajdhani(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              backgroundColor: AppColors.surface,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              title: Text(
                                'Abrechnungsfaktoren',
                                style: GoogleFonts.rajdhani(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.amber,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              content: Text(
                                'Die genauen Faktoren für deine individuelle Abrechnung findest du auf der jährlichen Gasrechnung oder kannst von deinem Versorger angefragt werden.\n\nWenn du hier keine Daten angibst, wird mit der Faustformel 1 m³ ≈ 10 bis 11 kWh gerechnet.',
                                style: GoogleFonts.rajdhani(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                  height: 1.5,
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: Text(
                                    'OK',
                                    style: GoogleFonts.rajdhani(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.amber,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          child: const Icon(
                            Icons.info_outline_rounded,
                            size: 18,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Leer lassen für Faustformel (1 m³ ≈ 10,55 kWh)',
                      style: GoogleFonts.rajdhani(
                        fontSize: 12,
                        color: AppColors.textSecondary.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Brennwert',
                                style: GoogleFonts.rajdhani(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              _PriceField(
                                controller: _brennwertController,
                                suffix: 'kWh/m³',
                                hint: 'z.B. 10.93',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Zustandszahl',
                                style: GoogleFonts.rajdhani(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              _PriceField(
                                controller: _zustandszahlController,
                                suffix: '',
                                hint: 'z.B. 0.9521',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    _SaveButton(
                      label: 'VERTRAG SPEICHERN',
                      isBusy: _isSaving,
                      onTap: _saveContract,
                    ),

                    const SizedBox(height: 12),
                    Text(
                      'Tipp: Den Preis pro kWh und den Grundpreis\nfindest du auf deiner Jahresabrechnung oder\nbeim Versorger unter "Arbeitspreis".',
                      style: GoogleFonts.rajdhani(
                        fontSize: 13,
                        color: AppColors.textSecondary.withOpacity(0.7),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ── Section: Info ──────────────────────────────────────────────
              _SectionHeader(label: 'APP-INFO'),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: Column(
                  children: [
                    _InfoRow(
                      label: 'App',
                      value: 'Homergy',
                    ),
                    const SizedBox(height: 12),
                    _InfoRow(
                      label: 'Version',
                      value: 'v1.0.0',
                    ),
                    const SizedBox(height: 12),
                    _InfoRow(
                      label: 'Datenbank',
                      value: 'SQLite (Drift)',
                    ),
                    const SizedBox(height: 12),
                    _InfoRow(
                      label: 'OCR',
                      value: 'Google ML Kit',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Decorative footer
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.local_fire_department,
                      color: AppColors.amber.withOpacity(0.3),
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Homergy v1.0.0',
                      style: GoogleFonts.spaceMono(
                        fontSize: 11,
                        color: AppColors.textSecondary.withOpacity(0.5),
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helper widgets
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.rajdhani(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
        letterSpacing: 3,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Account section
// ---------------------------------------------------------------------------

class _AccountSection extends StatelessWidget {
  final bool isSendingLink;
  final bool linkSent;
  final TextEditingController emailController;
  final VoidCallback onSendLink;
  final VoidCallback onSignOut;
  final VoidCallback onSyncNow;

  const _AccountSection({
    required this.isSendingLink,
    required this.linkSent,
    required this.emailController,
    required this.onSendLink,
    required this.onSignOut,
    required this.onSyncNow,
  });

  @override
  Widget build(BuildContext context) {
    final isAnon = SupabaseService.isAnonymous;
    final email = SupabaseService.userEmail;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status row
          Row(
            children: [
              Icon(
                isAnon ? Icons.person_outline : Icons.verified_user_outlined,
                size: 16,
                color: isAnon ? AppColors.textSecondary : AppColors.green,
              ),
              const SizedBox(width: 8),
              Text(
                isAnon ? 'Anonym' : email ?? 'Verknüpft',
                style: GoogleFonts.spaceMono(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isAnon ? AppColors.textSecondary : AppColors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            isAnon
                ? 'Deine Daten sind nur auf diesem Gerät. Verknüpfe eine E-Mail, um sie geräteübergreifend nutzen zu können.'
                : 'Deine Ablesungen werden mit der Cloud synchronisiert.',
            style: GoogleFonts.rajdhani(
              fontSize: 13,
              color: AppColors.textSecondary.withOpacity(0.8),
              height: 1.4,
            ),
          ),

          const SizedBox(height: 16),

          if (!isAnon) ...[
            // Already linked — nothing more to do here
          ] else if (linkSent) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.green.withOpacity(0.3), width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.mark_email_read_outlined,
                      size: 16, color: AppColors.green),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Bestätigungs-E-Mail gesendet. Bitte prüfe dein Postfach und klicke den Link.',
                      style: GoogleFonts.rajdhani(
                        fontSize: 13,
                        color: AppColors.green,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              style: GoogleFonts.rajdhani(
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
              cursorColor: AppColors.amber,
              decoration: InputDecoration(
                hintText: 'E-Mail für Kontoverknüpfung',
                hintStyle: GoogleFonts.rajdhani(
                    fontSize: 14, color: AppColors.textSecondary),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: AppColors.amber, width: 1.5),
                ),
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: isSendingLink ? null : onSendLink,
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.amber,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.amber.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: isSendingLink
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.black, strokeWidth: 2),
                        )
                      : Text(
                          'KONTO VERKNÜPFEN',
                          style: GoogleFonts.spaceMono(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                            letterSpacing: 1.5,
                          ),
                        ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Sync now + sign out row
          Row(
            children: [
              GestureDetector(
                onTap: onSyncNow,
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.sync_rounded,
                          size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        'Jetzt sync.',
                        style: GoogleFonts.rajdhani(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (!isAnon) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onSignOut,
                  child: Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppColors.error.withOpacity(0.25), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.logout_rounded,
                            size: 14, color: AppColors.error),
                        const SizedBox(width: 6),
                        Text(
                          'Abmelden',
                          style: GoogleFonts.rajdhani(
                            fontSize: 13,
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Reusable input field for numeric price/factor values
// ---------------------------------------------------------------------------

class _PriceField extends StatelessWidget {
  final TextEditingController controller;
  final String suffix;
  final String hint;

  const _PriceField({
    required this.controller,
    required this.suffix,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: AppColors.amber.withOpacity(0.4), width: 1),
      ),
      child: TextField(
        controller: controller,
        keyboardType:
            const TextInputType.numberWithOptions(decimal: true),
        style: GoogleFonts.spaceMono(
          fontSize: 16,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          hintText: hint,
          hintStyle: GoogleFonts.spaceMono(
              fontSize: 14, color: AppColors.textSecondary),
          suffixText: suffix.isNotEmpty ? suffix : null,
          suffixStyle: GoogleFonts.rajdhani(
            fontSize: 13,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Reusable save button
// ---------------------------------------------------------------------------

class _SaveButton extends StatelessWidget {
  final String label;
  final bool isBusy;
  final VoidCallback onTap;

  const _SaveButton({
    required this.label,
    required this.isBusy,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isBusy ? null : onTap,
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: AppColors.amber,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: AppColors.amber.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: isBusy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.black, strokeWidth: 2),
                )
              : Text(
                  label,
                  style: GoogleFonts.spaceMono(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                    letterSpacing: 1.5,
                  ),
                ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Toggle chip for binary selection (e.g., "Neuer Vertrag?")
// ---------------------------------------------------------------------------

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.amber : AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppColors.amber : AppColors.border,
            width: 1,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.rajdhani(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.black : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Plain text input field (for provider name)
// ---------------------------------------------------------------------------

class _TextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;

  const _TextField({required this.controller, required this.hint});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: AppColors.amber.withOpacity(0.4), width: 1),
      ),
      child: TextField(
        controller: controller,
        style: GoogleFonts.rajdhani(
          fontSize: 16,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          hintText: hint,
          hintStyle: GoogleFonts.rajdhani(
              fontSize: 14, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.rajdhani(
            fontSize: 14,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.spaceMono(
            fontSize: 13,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
