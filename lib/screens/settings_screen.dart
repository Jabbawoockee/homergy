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
  // Electricity contract controllers
  final _elecPriceController = TextEditingController();
  final _elecBasePriceController = TextEditingController();
  final _elecProviderController = TextEditingController();
  PriceContract? _latestContract;
  ElectricityContract? _latestElecContract;
  AppSetting? _locationSettings;
  bool _isNewContract = false;
  bool _isNewElecContract = false;
  DateTime? _priceValidFrom;
  DateTime? _elecValidFrom;
  bool _isSaving = false;
  bool _isSavingElec = false;
  bool _isSavingLocation = false;
  bool _isSendingLink = false;
  bool _linkSent = false;
  int _meterIntDigits = 5;
  int _electricityIntDigits = 6;
  int _electricityDecDigits = 1;
  StreamSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();
    _loadPrice();
    _loadMeterType();
    _loadLocation();
    SupabaseService.client.auth.refreshSession().catchError((_) {});
    _authSub = SupabaseService.client.auth.onAuthStateChange.listen((data) {
      if (mounted) {
        setState(() {
          if (data.event == AuthChangeEvent.userUpdated) _linkSent = false;
        });
        // Only sync when a real (non-anonymous) account is active.
        // Reload UI data after sync so location + contracts appear immediately.
        if ((data.event == AuthChangeEvent.userUpdated ||
                data.event == AuthChangeEvent.signedIn) &&
            !SupabaseService.isAnonymous) {
          SyncService().syncAll().then((_) {
            if (mounted) {
              _loadPrice();
              _loadLocation();
              _loadMeterType();
            }
          });
        }
      }
    });
  }

  Future<void> _loadPrice() async {
    final contracts = await AppDatabase.instance.getAllContracts();
    final latest = contracts.isNotEmpty ? contracts.last : null;
    final elecContracts = await AppDatabase.instance.getAllElectricityContracts();
    final latestElec = elecContracts.isNotEmpty ? elecContracts.last : null;
    if (mounted) {
      setState(() {
        _latestContract = latest;
        _latestElecContract = latestElec;
      });
      if (latest != null) {
        _priceController.text = latest.pricePerKwh.toStringAsFixed(4);
        _basePriceController.text = latest.monthlyBasePrice.toStringAsFixed(2);
        _brennwertController.text = latest.brennwert > 0 ? latest.brennwert.toStringAsFixed(4) : '';
        _zustandszahlController.text = latest.zustandszahl > 0 ? latest.zustandszahl.toStringAsFixed(4) : '';
        _priceValidFrom = DateTime.fromMillisecondsSinceEpoch(latest.validFrom);
        _providerController.text = latest.displayName;
      }
      if (latestElec != null) {
        _elecPriceController.text = latestElec.pricePerKwh.toStringAsFixed(4);
        _elecBasePriceController.text = latestElec.monthlyBasePrice.toStringAsFixed(2);
        _elecValidFrom = DateTime.fromMillisecondsSinceEpoch(latestElec.validFrom);
        _elecProviderController.text = latestElec.displayName;
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
    final gas = await _settingsService.getMeterIntDigits();
    final elecInt = await _settingsService.getElectricityIntDigits();
    final elecDec = await _settingsService.getElectricityDecDigits();
    if (mounted) setState(() {
      _meterIntDigits = gas;
      _electricityIntDigits = elecInt;
      _electricityDecDigits = elecDec;
    });
  }

  Future<void> _saveMeterType(int digits) async {
    setState(() => _meterIntDigits = digits);
    await _settingsService.setMeterIntDigits(digits);
    SyncService().syncSettings();
    _showSnack('Gaszähler-Typ gespeichert: $digits Vorkomma-Stellen');
  }

  Future<void> _saveElectricityMeterType(int digits) async {
    setState(() => _electricityIntDigits = digits);
    await _settingsService.setElectricityIntDigits(digits);
    _showSnack('Stromzähler: $digits Vorkomma-Stellen gespeichert');
  }

  Future<void> _saveElectricityDecDigits(int digits) async {
    setState(() => _electricityDecDigits = digits);
    await _settingsService.setElectricityDecDigits(digits);
    _showSnack('Stromzähler: $digits Nachkomma-Stellen gespeichert');
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

  Future<void> _saveElecContract() async {
    final kwhText = _elecPriceController.text.trim().replaceAll(',', '.');
    final kwhParsed = double.tryParse(kwhText);
    if (kwhParsed == null || kwhParsed <= 0) { _showSnack('Pflichtfeld fehlt: Preis pro kWh', isError: true); return; }
    final baseText = _elecBasePriceController.text.trim().replaceAll(',', '.');
    if (baseText.isEmpty) { _showSnack('Pflichtfeld fehlt: Grundpreis (0,00 wenn kein Grundpreis)', isError: true); return; }
    final baseParsed = double.tryParse(baseText) ?? -1;
    if (baseParsed < 0) { _showSnack('Bitte einen gültigen Grundpreis eingeben.', isError: true); return; }
    if (_elecValidFrom == null) { _showSnack('Pflichtfeld fehlt: Datum', isError: true); return; }
    final bool creatingNew = _latestElecContract == null || _isNewElecContract;
    final providerName = creatingNew ? _elecProviderController.text.trim() : _latestElecContract!.displayName;
    if (providerName.isEmpty) { _showSnack('Pflichtfeld fehlt: Lieferant', isError: true); return; }

    setState(() => _isSavingElec = true);
    final count = await AppDatabase.instance.countElectricityContractsByDisplayName(providerName);
    final internalName = '${providerName}_${count + 1}';
    await AppDatabase.instance.insertElectricityContract(ElectricityContractsCompanion(
      internalName: Value(internalName),
      displayName: Value(providerName),
      pricePerKwh: Value(kwhParsed),
      monthlyBasePrice: Value(baseParsed),
      validFrom: Value(_elecValidFrom!.millisecondsSinceEpoch),
    ));
    await _loadPrice();
    if (mounted) {
      setState(() { _isSavingElec = false; _isNewElecContract = false; });
      _showSnack('Stromvertrag gespeichert.');
    }
  }

  Future<void> _pickValidFromDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _priceValidFrom ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.green,
            onPrimary: Colors.white,
            surface: AppColors.background,
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
      // Always use magic link — works for both new and existing accounts.
      // linkEmail (updateUser) fails when the email is already registered.
      await SupabaseService.signInWithMagicLink(email);
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
    await AppDatabase.instance.clearAllUserData();
    await _settingsService.resetOnboarding();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/onboarding', (_) => false);
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
    _elecPriceController.dispose();
    _elecBasePriceController.dispose();
    _elecProviderController.dispose();
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
              const SizedBox(height: 4),
              Text(
                'EINSTELLUNGEN',
                style: GoogleFonts.spaceMono(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.greenDark,
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

              // ── Section: Gaszählertyp ──────────────────────────────────────
              _SectionHeader(label: 'GASZÄHLER — STELLENANZAHL'),
              const SizedBox(height: 12),
              _DigitSelector(
                icon: Icons.local_fire_department_outlined,
                iconColor: AppColors.amber,
                description: 'Wie viele Stellen stehen vor dem Komma auf deinem Gaszähler?',
                selected: _meterIntDigits,
                options: const [4, 5, 6],
                formatHint: (d) => '${'0' * d},${'0' * 3} m³',
                onSelect: _saveMeterType,
              ),

              const SizedBox(height: 28),

              // ── Section: Stromzählertyp ────────────────────────────────────
              _SectionHeader(label: 'STROMZÄHLER — STELLENANZAHL'),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'OCR prüft genau ${_electricityIntDigits + _electricityDecDigits} Stellen auf dem Foto.',
                  style: GoogleFonts.spaceMono(fontSize: 11, color: const Color(0xFF5B8DB8)),
                ),
              ),
              _DigitSelector(
                icon: Icons.bolt_outlined,
                iconColor: const Color(0xFF5B8DB8),
                description: 'Stellen VOR dem Komma',
                selected: _electricityIntDigits,
                options: const [5, 6, 7],
                formatHint: (d) => '${'0' * d},${'0' * _electricityDecDigits} kWh',
                onSelect: _saveElectricityMeterType,
              ),
              const SizedBox(height: 16),
              _DigitSelector(
                icon: Icons.looks_one_outlined,
                iconColor: const Color(0xFF5B8DB8),
                description: 'Stellen NACH dem Komma (rote Dezimaltrommel)',
                selected: _electricityDecDigits,
                options: const [1, 2, 3],
                formatHint: (d) => '${'0' * _electricityIntDigits},${'0' * d} kWh',
                onSelect: _saveElectricityDecDigits,
              ),

              const SizedBox(height: 32),

              // ── Section: Standort ──────────────────────────────────────────
              _SectionHeader(label: 'STANDORT'),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppColors.neu(7),
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
                          color: AppColors.green.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(8),
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
              ),

              const SizedBox(height: 32),

              // ── Section: Gaspreis ──────────────────────────────────────────
              _SectionHeader(label: 'GASPREIS'),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppColors.neu(7),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    if (_latestContract != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.amber.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(10),
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
                          color: const Color(0xFFDFE5DA),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 18,
                              color: _priceValidFrom == null
                                  ? AppColors.textSecondary
                                  : AppColors.green,
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
                              backgroundColor: AppColors.background,
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
                                      color: AppColors.green,
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

              // ── Section: Strompreis ────────────────────────────────────────
              _SectionHeader(label: 'STROMPREIS'),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(16), boxShadow: AppColors.neu(7)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_latestElecContract != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(color: const Color(0xFF5B8DB8).withOpacity(0.10), borderRadius: BorderRadius.circular(10)),
                        child: Row(children: [
                          const Icon(Icons.bolt_rounded, size: 15, color: Color(0xFF5B8DB8)),
                          const SizedBox(width: 8),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(_latestElecContract!.displayName, style: GoogleFonts.rajdhani(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF5B8DB8), letterSpacing: 0.5)),
                            Text(() {
                              final d = DateTime.fromMillisecondsSinceEpoch(_latestElecContract!.validFrom);
                              return 'seit ${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}  ·  ${_latestElecContract!.pricePerKwh.toStringAsFixed(4)} €/kWh';
                            }(), style: GoogleFonts.spaceMono(fontSize: 11, color: AppColors.textSecondary)),
                          ])),
                        ]),
                      ),
                      const SizedBox(height: 16),
                      Text('Neuer Vertrag?', style: GoogleFonts.rajdhani(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary, letterSpacing: 0.5)),
                      const SizedBox(height: 8),
                      Row(children: [
                        Expanded(child: _ToggleChip(label: 'Nein – Preis aktualisieren', selected: !_isNewElecContract, onTap: () => setState(() => _isNewElecContract = false))),
                        const SizedBox(width: 8),
                        Expanded(child: _ToggleChip(label: 'Ja – Neuer Anbieter', selected: _isNewElecContract, onTap: () { setState(() { _isNewElecContract = true; _elecProviderController.clear(); }); })),
                      ]),
                      const SizedBox(height: 16),
                    ],

                    if (_latestElecContract == null || _isNewElecContract) ...[
                      Row(children: [
                        const Icon(Icons.business_rounded, size: 16, color: AppColors.amber),
                        const SizedBox(width: 8),
                        Text('Lieferant', style: GoogleFonts.rajdhani(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary, letterSpacing: 0.5)),
                        const SizedBox(width: 4),
                        Text('*', style: GoogleFonts.rajdhani(fontSize: 15, color: AppColors.error, fontWeight: FontWeight.w700)),
                      ]),
                      const SizedBox(height: 8),
                      _TextField(controller: _elecProviderController, hint: 'z.B. Stadtwerke Musterstadt'),
                      const SizedBox(height: 20),
                    ],

                    Row(children: [
                      const Icon(Icons.bolt_rounded, size: 16, color: AppColors.amber),
                      const SizedBox(width: 8),
                      Text('Preis pro kWh', style: GoogleFonts.rajdhani(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary, letterSpacing: 0.5)),
                      const SizedBox(width: 4),
                      Text('*', style: GoogleFonts.rajdhani(fontSize: 15, color: AppColors.error, fontWeight: FontWeight.w700)),
                    ]),
                    const SizedBox(height: 8),
                    _PriceField(controller: _elecPriceController, suffix: '€/kWh', hint: 'z.B. 0.2890'),
                    const SizedBox(height: 20),

                    Row(children: [
                      const Icon(Icons.calendar_month_outlined, size: 16, color: AppColors.amber),
                      const SizedBox(width: 8),
                      Text('Monatlicher Grundpreis', style: GoogleFonts.rajdhani(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary, letterSpacing: 0.5)),
                      const SizedBox(width: 4),
                      Text('*', style: GoogleFonts.rajdhani(fontSize: 15, color: AppColors.error, fontWeight: FontWeight.w700)),
                    ]),
                    const SizedBox(height: 8),
                    _PriceField(controller: _elecBasePriceController, suffix: '€/Monat', hint: 'z.B. 12.00'),
                    const SizedBox(height: 20),

                    Row(children: [
                      const Icon(Icons.event_rounded, size: 16, color: AppColors.amber),
                      const SizedBox(width: 8),
                      Text('Diese Preise gelten seit:', style: GoogleFonts.rajdhani(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary, letterSpacing: 0.5)),
                      const SizedBox(width: 4),
                      Text('*', style: GoogleFonts.rajdhani(fontSize: 15, color: AppColors.error, fontWeight: FontWeight.w700)),
                    ]),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _elecValidFrom ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                          builder: (context, child) => Theme(
                            data: ThemeData.light().copyWith(colorScheme: const ColorScheme.light(primary: AppColors.green, onPrimary: Colors.white, surface: AppColors.background, onSurface: AppColors.textPrimary), dialogTheme: const DialogThemeData(backgroundColor: AppColors.background)),
                            child: child!,
                          ),
                        );
                        if (picked != null) setState(() => _elecValidFrom = picked);
                      },
                      child: Container(
                        height: 50,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(color: const Color(0xFFDFE5DA), borderRadius: BorderRadius.circular(10)),
                        child: Row(children: [
                          Icon(Icons.calendar_today_rounded, size: 18, color: _elecValidFrom == null ? AppColors.textSecondary : AppColors.green),
                          const SizedBox(width: 12),
                          Text(
                            _elecValidFrom == null ? 'Datum auswählen' : '${_elecValidFrom!.day.toString().padLeft(2, '0')}.${_elecValidFrom!.month.toString().padLeft(2, '0')}.${_elecValidFrom!.year}',
                            style: _elecValidFrom == null ? GoogleFonts.rajdhani(fontSize: 15, color: AppColors.textSecondary) : GoogleFonts.spaceMono(fontSize: 15, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                          ),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _SaveButton(label: 'VERTRAG SPEICHERN', isBusy: _isSavingElec, onTap: _saveElecContract),
                    const SizedBox(height: 12),
                    Text('Den Preis pro kWh findest du auf deiner Jahresabrechnung oder beim Versorger unter "Arbeitspreis".', style: GoogleFonts.rajdhani(fontSize: 13, color: AppColors.textSecondary.withOpacity(0.7), height: 1.5)),
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
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppColors.neu(7),
                ),
                child: const Column(
                  children: [
                    _InfoRow(label: 'App', value: 'Homergy'),
                    SizedBox(height: 12),
                    _InfoRow(label: 'Version', value: 'v1.0.0'),
                    SizedBox(height: 12),
                    _InfoRow(label: 'Datenbank', value: 'SQLite (Drift)'),
                    SizedBox(height: 12),
                    _InfoRow(label: 'OCR', value: 'Google ML Kit'),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.local_fire_department,
                      color: AppColors.green.withOpacity(0.3),
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

class _DigitSelector extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String description;
  final int selected;
  final List<int> options;
  final String Function(int) formatHint;
  final void Function(int) onSelect;

  const _DigitSelector({
    required this.icon,
    required this.iconColor,
    required this.description,
    required this.selected,
    required this.options,
    required this.formatHint,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(16), boxShadow: AppColors.neu(7)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 8),
            Text('Vorkomma-Stellen', style: GoogleFonts.rajdhani(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary, letterSpacing: 0.5)),
          ]),
          const SizedBox(height: 6),
          Text(description, style: GoogleFonts.rajdhani(fontSize: 13, color: AppColors.textSecondary.withOpacity(0.8), height: 1.4)),
          const SizedBox(height: 16),
          Row(
            children: [
              for (int i = 0; i < options.length; i++) ...[
                Expanded(
                  child: GestureDetector(
                    onTap: () => onSelect(options[i]),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      height: 48,
                      decoration: BoxDecoration(
                        color: selected == options[i] ? AppColors.green : AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: selected == options[i] ? [const BoxShadow(color: Color(0xFF3A5E3D), offset: Offset(0, 3), blurRadius: 6)] : AppColors.neu(4),
                      ),
                      child: Center(child: Text('${options[i]}', style: GoogleFonts.spaceMono(fontSize: 18, fontWeight: FontWeight.w700, color: selected == options[i] ? Colors.white : AppColors.textSecondary))),
                    ),
                  ),
                ),
                if (i < options.length - 1) const SizedBox(width: 10),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Text('Aktuell: $selected Stellen — Format: ${formatHint(selected)}', style: GoogleFonts.spaceMono(fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

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

  const _AccountSection({
    required this.isSendingLink,
    required this.linkSent,
    required this.emailController,
    required this.onSendLink,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    final isAnon = SupabaseService.isAnonymous;
    final email = SupabaseService.userEmail;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.neu(7),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                ? 'Melde dich mit deinem Homergy-Konto an oder erstelle ein neues — deine Daten werden automatisch geladen.'
                : 'Deine Ablesungen werden mit der Cloud synchronisiert.',
            style: GoogleFonts.rajdhani(
              fontSize: 13,
              color: AppColors.textSecondary.withOpacity(0.8),
              height: 1.4,
            ),
          ),

          const SizedBox(height: 16),

          if (!isAnon) ...[
            // Already linked
          ] else if (linkSent) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.green.withOpacity(0.10),
                borderRadius: BorderRadius.circular(10),
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
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFDFE5DA),
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                style: GoogleFonts.rajdhani(
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
                cursorColor: AppColors.green,
                decoration: InputDecoration(
                  hintText: 'E-Mail-Adresse eingeben',
                  hintStyle: GoogleFonts.rajdhani(
                      fontSize: 14, color: AppColors.textSecondary),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: AppColors.green, width: 1.5),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFDFE5DA),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: isSendingLink ? null : onSendLink,
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.green,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0xFF3A5E3D),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: isSendingLink
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          'ANMELDELINK SENDEN',
                          style: GoogleFonts.spaceMono(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 1.5,
                          ),
                        ),
                ),
              ),
            ),
          ],

          if (!isAnon) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: onSignOut,
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.logout_rounded, size: 14, color: AppColors.error),
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
        color: const Color(0xFFDFE5DA),
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: GoogleFonts.spaceMono(
          fontSize: 16,
          color: AppColors.textPrimary,
        ),
        cursorColor: AppColors.green,
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
          color: AppColors.green,
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(
              color: Color(0xFF3A5E3D),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: isBusy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                )
              : Text(
                  label,
                  style: GoogleFonts.spaceMono(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Toggle chip for binary selection
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.green : AppColors.background,
          borderRadius: BorderRadius.circular(8),
          boxShadow: selected
              ? [
                  const BoxShadow(
                    color: Color(0xFF3A5E3D),
                    offset: Offset(0, 2),
                    blurRadius: 5,
                  ),
                ]
              : AppColors.neu(3),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.rajdhani(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Plain text input field
// ---------------------------------------------------------------------------

class _TextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;

  const _TextField({required this.controller, required this.hint});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFDFE5DA),
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: controller,
        style: GoogleFonts.rajdhani(
          fontSize: 16,
          color: AppColors.textPrimary,
        ),
        cursorColor: AppColors.green,
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
