import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../database/database.dart';
import '../services/settings_service.dart';
import '../services/sync_service.dart';
import '../theme/colors.dart';
import 'settings_widgets.dart';

class ElectricitySettingsScreen extends StatefulWidget {
  const ElectricitySettingsScreen({super.key});

  @override
  State<ElectricitySettingsScreen> createState() => _ElectricitySettingsScreenState();
}

class _ElectricitySettingsScreenState extends State<ElectricitySettingsScreen> {
  final _settingsService     = SettingsService();
  final _priceController     = TextEditingController();
  final _basePriceController = TextEditingController();
  final _providerController  = TextEditingController();

  ElectricityContract? _latestContract;
  bool _isNewContract = false;
  DateTime? _validFrom;
  int _intDigits = 6;
  int _decDigits = 1;
  bool _isSaving = false;

  static const _blue = Color(0xFF5B8DB8);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _priceController.dispose();
    _basePriceController.dispose();
    _providerController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final contracts = await AppDatabase.instance.getAllElectricityContracts();
    final latest    = contracts.isNotEmpty ? contracts.last : null;
    final intD      = await _settingsService.getElectricityIntDigits();
    final decD      = await _settingsService.getElectricityDecDigits();
    if (mounted) {
      setState(() { _latestContract = latest; _intDigits = intD; _decDigits = decD; });
      if (latest != null) {
        _priceController.text     = latest.pricePerKwh.toStringAsFixed(4);
        _basePriceController.text = latest.monthlyBasePrice.toStringAsFixed(2);
        _providerController.text  = latest.displayName;
        _validFrom = DateTime.fromMillisecondsSinceEpoch(latest.validFrom);
      }
    }
  }

  Future<void> _saveIntDigits(int d) async {
    setState(() => _intDigits = d);
    await _settingsService.setElectricityIntDigits(d);
    SyncService().syncSettings();
    _showSnack('Stromzähler: $d Vorkomma-Stellen gespeichert');
  }

  Future<void> _saveDecDigits(int d) async {
    setState(() => _decDigits = d);
    await _settingsService.setElectricityDecDigits(d);
    SyncService().syncSettings();
    _showSnack('Stromzähler: $d Nachkomma-Stellen gespeichert');
  }

  Future<void> _saveContract() async {
    final kwhText   = _priceController.text.trim().replaceAll(',', '.');
    final kwhParsed = double.tryParse(kwhText);
    if (kwhParsed == null || kwhParsed <= 0) { _showSnack('Pflichtfeld: Preis pro kWh', isError: true); return; }
    final baseText   = _basePriceController.text.trim().replaceAll(',', '.');
    final baseParsed = double.tryParse(baseText) ?? -1;
    if (baseText.isEmpty || baseParsed < 0) { _showSnack('Pflichtfeld: Grundpreis (0,00 wenn keiner)', isError: true); return; }
    if (_validFrom == null) { _showSnack('Pflichtfeld: Datum', isError: true); return; }
    final bool creatingNew = _latestContract == null || _isNewContract;
    final providerName     = creatingNew ? _providerController.text.trim() : _latestContract!.displayName;
    if (providerName.isEmpty) { _showSnack('Pflichtfeld: Lieferant', isError: true); return; }

    setState(() => _isSaving = true);
    final count = await AppDatabase.instance.countElectricityContractsByDisplayName(providerName);
    await AppDatabase.instance.insertElectricityContract(ElectricityContractsCompanion(
      internalName: Value('${providerName}_${count + 1}'),
      displayName: Value(providerName),
      pricePerKwh: Value(kwhParsed),
      monthlyBasePrice: Value(baseParsed),
      validFrom: Value(_validFrom!.millisecondsSinceEpoch),
    ));
    await _load();
    SyncService().syncAll();
    if (mounted) {
      setState(() { _isSaving = false; _isNewContract = false; });
      _showSnack('Stromvertrag gespeichert.');
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _validFrom ?? DateTime.now(),
      firstDate: DateTime(2000), lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.green, onPrimary: Colors.white, surface: AppColors.background, onSurface: AppColors.textPrimary),
          dialogTheme: const DialogThemeData(backgroundColor: AppColors.background),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _validFrom = picked);
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: isError ? AppColors.error : AppColors.green,
      content: Text(msg, style: GoogleFonts.rajdhani(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
      duration: const Duration(seconds: 3),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background, elevation: 0, surfaceTintColor: Colors.transparent,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textSecondary, size: 20), onPressed: () => Navigator.of(context).pop()),
        title: Text('STROM', style: GoogleFonts.rajdhani(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 4)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SettingsSectionLabel('ZÄHLERTYP'),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text('OCR prüft genau ${_intDigits + _decDigits} Stellen auf dem Foto.',
                    style: GoogleFonts.spaceMono(fontSize: 11, color: _blue)),
              ),
              SettingsDigitSelector(
                icon: Icons.bolt_outlined, iconColor: _blue,
                description: 'Stellen VOR dem Komma',
                selected: _intDigits, options: const [5, 6, 7],
                formatHint: (d) => '${'0' * d},${'0' * _decDigits} kWh',
                onSelect: _saveIntDigits,
              ),
              const SizedBox(height: 16),
              SettingsDigitSelector(
                icon: Icons.looks_one_outlined, iconColor: _blue,
                description: 'Stellen NACH dem Komma (rote Dezimaltrommel)',
                selected: _decDigits, options: const [1, 2, 3],
                formatHint: (d) => '${'0' * _intDigits},${'0' * d} kWh',
                onSelect: _saveDecDigits,
              ),
              const SizedBox(height: 32),

              const SettingsSectionLabel('STROMPREIS'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(16), boxShadow: AppColors.neu(7)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (_latestContract != null) ...[
                    SettingsContractPreview(icon: Icons.bolt_rounded, color: _blue,
                        name: _latestContract!.displayName, since: DateTime.fromMillisecondsSinceEpoch(_latestContract!.validFrom), price: _latestContract!.pricePerKwh),
                    const SizedBox(height: 16),
                    Text('Neuer Vertrag?', style: GoogleFonts.rajdhani(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary, letterSpacing: 0.5)),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(child: SettingsToggleChip(label: 'Nein – aktualisieren', selected: !_isNewContract, onTap: () => setState(() => _isNewContract = false))),
                      const SizedBox(width: 8),
                      Expanded(child: SettingsToggleChip(label: 'Ja – neuer Anbieter', selected: _isNewContract, onTap: () { setState(() { _isNewContract = true; _providerController.clear(); }); })),
                    ]),
                    const SizedBox(height: 20),
                  ],
                  if (_latestContract == null || _isNewContract) ...[
                    const SettingsFieldLabel('Lieferant', required: true),
                    const SizedBox(height: 8),
                    SettingsTextField(controller: _providerController, hint: 'z.B. Stadtwerke Musterstadt'),
                    const SizedBox(height: 20),
                  ],
                  const SettingsFieldLabel('Preis pro kWh', required: true),
                  const SizedBox(height: 8),
                  SettingsPriceField(controller: _priceController, suffix: '€/kWh', hint: 'z.B. 0.2890'),
                  const SizedBox(height: 20),
                  const SettingsFieldLabel('Monatlicher Grundpreis', required: true),
                  const SizedBox(height: 8),
                  SettingsPriceField(controller: _basePriceController, suffix: '€/Monat', hint: 'z.B. 12.00'),
                  const SizedBox(height: 20),
                  const SettingsFieldLabel('Diese Preise gelten seit:', required: true),
                  const SizedBox(height: 10),
                  SettingsDatePicker(date: _validFrom, onTap: _pickDate),
                  const SizedBox(height: 20),
                  SettingsSaveButton(label: 'VERTRAG SPEICHERN', isBusy: _isSaving, onTap: _saveContract),
                  const SizedBox(height: 12),
                  Text('Den Preis pro kWh findest du auf deiner Jahresabrechnung oder beim Versorger unter "Arbeitspreis".',
                      style: GoogleFonts.rajdhani(fontSize: 13, color: AppColors.textSecondary.withValues(alpha: 0.7), height: 1.5)),
                ]),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
