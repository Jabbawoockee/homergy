import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../database/database.dart';
import '../services/settings_service.dart';
import '../services/sync_service.dart';
import '../theme/colors.dart';
import '../widgets/advance_payment_dialog.dart';
import 'settings_widgets.dart';

class GasSettingsScreen extends StatefulWidget {
  const GasSettingsScreen({super.key});

  @override
  State<GasSettingsScreen> createState() => _GasSettingsScreenState();
}

class _GasSettingsScreenState extends State<GasSettingsScreen> {
  final _settingsService        = SettingsService();
  final _priceController        = TextEditingController();
  final _basePriceController    = TextEditingController();
  final _advanceController      = TextEditingController();
  final _brennwertController    = TextEditingController();
  final _zustandszahlController = TextEditingController();
  final _providerController     = TextEditingController();

  PriceContract? _latestContract;
  List<PriceContract> _allContracts = [];
  bool _isNewContract = false;
  DateTime? _validFrom;
  DateTime? _contractEndDate;
  int _meterIntDigits = 5;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _priceController.dispose();
    _basePriceController.dispose();
    _advanceController.dispose();
    _brennwertController.dispose();
    _zustandszahlController.dispose();
    _providerController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final contracts = await AppDatabase.instance.getAllContracts();
    final latest    = contracts.isNotEmpty ? contracts.last : null;
    final digits    = await _settingsService.getMeterIntDigits();
    if (mounted) {
      setState(() { _latestContract = latest; _allContracts = contracts; _meterIntDigits = digits; });
      if (latest != null) {
        _priceController.text        = latest.pricePerKwh.toStringAsFixed(4);
        _basePriceController.text    = latest.monthlyBasePrice.toStringAsFixed(2);
        _brennwertController.text    = latest.brennwert > 0 ? latest.brennwert.toStringAsFixed(4) : '';
        _zustandszahlController.text = latest.zustandszahl > 0 ? latest.zustandszahl.toStringAsFixed(4) : '';
        _providerController.text     = latest.displayName;
        _validFrom = DateTime.fromMillisecondsSinceEpoch(latest.validFrom);
        _contractEndDate = latest.contractEndDate != null
            ? DateTime.fromMillisecondsSinceEpoch(latest.contractEndDate!)
            : null;
        _advanceController.text = latest.monthlyAdvancePayment != null
            ? latest.monthlyAdvancePayment!.toStringAsFixed(2)
            : '';
      }
    }
  }

  Future<void> _deleteContract(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Vertrag löschen?', style: GoogleFonts.rajdhani(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        content: Text('Dieser Vertrag wird dauerhaft entfernt.', style: GoogleFonts.rajdhani(fontSize: 14, color: AppColors.textSecondary, height: 1.5)),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text('Abbrechen', style: GoogleFonts.rajdhani(fontSize: 14, color: AppColors.textSecondary))),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text('Löschen', style: GoogleFonts.rajdhani(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.error))),
        ],
      ),
    );
    if (confirm != true) return;
    final contract = _allContracts.firstWhere((c) => c.id == id);
    if (contract.remoteId != null) {
      await SyncService().deleteRemoteContract(contract.remoteId!);
    }
    await AppDatabase.instance.deleteContract(id);
    await _load();
    if (mounted) _showSnack('Vertrag gelöscht.');
  }

  Future<void> _saveMeterDigits(int digits) async {
    setState(() => _meterIntDigits = digits);
    await _settingsService.setMeterIntDigits(digits);
    SyncService().syncSettings();
    _showSnack('Gaszähler: $digits Vorkomma-Stellen gespeichert');
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
    final bwText = _brennwertController.text.trim().replaceAll(',', '.');
    final zzText = _zustandszahlController.text.trim().replaceAll(',', '.');
    final bw = bwText.isEmpty ? 0.0 : (double.tryParse(bwText) ?? -1.0);
    final zz = zzText.isEmpty ? 0.0 : (double.tryParse(zzText) ?? -1.0);
    if (bw < 0 || zz < 0) { _showSnack('Ungültige Brennwert/Zustandszahl', isError: true); return; }

    setState(() => _isSaving = true);
    final advText   = _advanceController.text.trim().replaceAll(',', '.');
    final advParsed = advText.isNotEmpty ? double.tryParse(advText) : null;

    if (creatingNew) {
      final count = await AppDatabase.instance.countContractsByDisplayName(providerName);
      await AppDatabase.instance.insertContract(PriceContractsCompanion(
        internalName: Value('${providerName}_${count + 1}'),
        displayName: Value(providerName),
        pricePerKwh: Value(kwhParsed),
        monthlyBasePrice: Value(baseParsed),
        validFrom: Value(_validFrom!.millisecondsSinceEpoch),
        contractEndDate: Value(_contractEndDate?.millisecondsSinceEpoch),
        monthlyAdvancePayment: Value(advParsed),
        brennwert: Value(bw),
        zustandszahl: Value(zz),
      ));
      // Auto-create advance payment history entry for new contract
      if (advParsed != null) {
        await AppDatabase.instance.insertAdvancePaymentChange(AdvancePaymentChangesCompanion(
          contractType: const Value('gas'),
          amount: Value(advParsed),
          validFrom: Value(_validFrom!.millisecondsSinceEpoch),
        ));
      }
    } else {
      final oldAdv = _latestContract!.monthlyAdvancePayment;
      final advChanged = advParsed != oldAdv;

      // If advance payment changed, ask from when it applies
      DateTime? advValidFrom;
      double? finalAdv = advParsed;
      if (advChanged && advParsed != null) {
        if (!mounted) return;
        final result = await showDialog<({double amount, DateTime validFrom})>(
          context: context,
          builder: (_) => AdvancePaymentDialog(
            currentAmount: advParsed,
            accentColor: AppColors.green,
          ),
        );
        if (result == null) {
          setState(() => _isSaving = false);
          return;
        }
        advValidFrom = result.validFrom;
        finalAdv = result.amount;
      }

      await AppDatabase.instance.updateContract(PriceContractsCompanion(
        id: Value(_latestContract!.id),
        internalName: Value(_latestContract!.internalName),
        displayName: Value(providerName),
        pricePerKwh: Value(kwhParsed),
        monthlyBasePrice: Value(baseParsed),
        validFrom: Value(_validFrom!.millisecondsSinceEpoch),
        contractEndDate: Value(_contractEndDate?.millisecondsSinceEpoch),
        monthlyAdvancePayment: Value(finalAdv),
        brennwert: Value(bw),
        zustandszahl: Value(zz),
        isSynced: const Value(false),
      ));

      if (advChanged && finalAdv != null && advValidFrom != null) {
        await AppDatabase.instance.insertAdvancePaymentChange(AdvancePaymentChangesCompanion(
          contractType: const Value('gas'),
          amount: Value(finalAdv),
          validFrom: Value(advValidFrom.millisecondsSinceEpoch),
        ));
      }
    }
    await _load();
    SyncService().syncAll();
    if (mounted) {
      setState(() { _isSaving = false; _isNewContract = false; });
      _showSnack('Gasvertrag gespeichert.');
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _contractEndDate ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime(2000), lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.green, onPrimary: Colors.white, surface: AppColors.background, onSurface: AppColors.textPrimary),
          dialogTheme: const DialogThemeData(backgroundColor: AppColors.background),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _contractEndDate = picked);
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
        title: Text('GAS-EIGENSCHAFTEN', style: GoogleFonts.rajdhani(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 4)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SettingsSectionLabel('ZÄHLERTYP'),
              const SizedBox(height: 12),
              SettingsDigitSelector(
                icon: Icons.local_fire_department_outlined, iconColor: AppColors.amber,
                description: 'Wie viele Stellen stehen vor dem Komma auf deinem Gaszähler?',
                selected: _meterIntDigits, options: const [4, 5, 6],
                formatHint: (d) => '${'0' * d},${'0' * 3} m³',
                onSelect: _saveMeterDigits,
              ),
              const SizedBox(height: 32),

              const SettingsSectionLabel('GASPREIS'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(16), boxShadow: AppColors.neu(7)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (_latestContract != null) ...[
                    SettingsContractPreview(icon: Icons.local_fire_department_outlined, color: AppColors.amber,
                        name: _latestContract!.displayName, since: DateTime.fromMillisecondsSinceEpoch(_latestContract!.validFrom), price: _latestContract!.pricePerKwh),
                    const SizedBox(height: 16),
                    Text('Neuer Vertrag?', style: GoogleFonts.rajdhani(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary, letterSpacing: 0.5)),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(child: SettingsToggleChip(label: 'Nein – nur Vertragsdaten anpassen', selected: !_isNewContract, onTap: () => setState(() => _isNewContract = false))),
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
                  SettingsPriceField(controller: _priceController, suffix: '€/kWh', hint: 'z.B. 0.0891'),
                  const SizedBox(height: 20),
                  const SettingsFieldLabel('Monatlicher Grundpreis', required: true),
                  const SizedBox(height: 8),
                  SettingsPriceField(controller: _basePriceController, suffix: '€/Monat', hint: 'z.B. 8.00'),
                  const SizedBox(height: 20),
                  const SettingsFieldLabel('Monatlicher Abschlag'),
                  const SizedBox(height: 6),
                  Text('Dein monatlicher Vorauszahlungsbetrag an den Anbieter',
                      style: GoogleFonts.rajdhani(fontSize: 13,
                          color: AppColors.textSecondary.withValues(alpha: 0.7))),
                  const SizedBox(height: 8),
                  SettingsPriceField(controller: _advanceController, suffix: '€/Monat', hint: 'z.B. 60.00'),
                  const SizedBox(height: 20),
                  const SettingsFieldLabel('Diese Preise gelten seit:', required: true),
                  const SizedBox(height: 10),
                  SettingsDatePicker(date: _validFrom, onTap: _pickDate),
                  const SizedBox(height: 20),
                  const SettingsFieldLabel('Vertragsende'),
                  const SizedBox(height: 6),
                  Text('Optional – für spätere Kündigungserinnerung',
                      style: GoogleFonts.rajdhani(fontSize: 13,
                          color: AppColors.textSecondary.withValues(alpha: 0.7))),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: SettingsDatePicker(
                        date: _contractEndDate, onTap: _pickEndDate)),
                    if (_contractEndDate != null) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => setState(() => _contractEndDate = null),
                        child: const Icon(Icons.close_rounded, size: 20, color: AppColors.textSecondary),
                      ),
                    ],
                  ]),
                  const SizedBox(height: 24),
                  Divider(color: AppColors.border, height: 1),
                  const SizedBox(height: 20),
                  Row(children: [
                    const Icon(Icons.calculate_outlined, size: 16, color: AppColors.amber),
                    const SizedBox(width: 8),
                    Text('Abrechnungsfaktoren', style: GoogleFonts.rajdhani(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary, letterSpacing: 0.5)),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => showDialog(context: context, builder: (_) => AlertDialog(
                        backgroundColor: AppColors.background,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        title: Text('Abrechnungsfaktoren', style: GoogleFonts.rajdhani(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.amber)),
                        content: Text('Die genauen Faktoren findest du auf der jährlichen Gasrechnung oder beim Versorger.\n\nOhne Angabe wird mit der Faustformel 1 m³ ≈ 10,55 kWh gerechnet.',
                            style: GoogleFonts.rajdhani(fontSize: 14, color: AppColors.textSecondary, height: 1.5)),
                        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('OK', style: GoogleFonts.rajdhani(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.green)))],
                      )),
                      child: const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.textSecondary),
                    ),
                  ]),
                  const SizedBox(height: 6),
                  Text('Leer lassen für Faustformel (1 m³ ≈ 10,55 kWh)', style: GoogleFonts.rajdhani(fontSize: 12, color: AppColors.textSecondary.withValues(alpha: 0.7))),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Brennwert', style: GoogleFonts.rajdhani(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      SettingsPriceField(controller: _brennwertController, suffix: 'kWh/m³', hint: 'z.B. 10.93'),
                    ])),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Zustandszahl', style: GoogleFonts.rajdhani(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      SettingsPriceField(controller: _zustandszahlController, suffix: '', hint: 'z.B. 0.9521'),
                    ])),
                  ]),
                  const SizedBox(height: 20),
                  SettingsSaveButton(label: 'VERTRAG SPEICHERN', isBusy: _isSaving, onTap: _saveContract),
                  const SizedBox(height: 12),
                  Text('Preis pro kWh und Grundpreis findest du auf deiner Jahresabrechnung oder beim Versorger unter "Arbeitspreis".',
                      style: GoogleFonts.rajdhani(fontSize: 13, color: AppColors.textSecondary.withValues(alpha: 0.7), height: 1.5)),
                ]),
              ),
              const SizedBox(height: 24),

              if (_allContracts.length > 1) ...[
                const SettingsSectionLabel('VERTRAGSVERLAUF'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(16), boxShadow: AppColors.neu(7)),
                  child: Column(
                    children: [
                      for (int i = _allContracts.length - 1; i >= 0; i--) ...[
                        _ContractHistoryRow(
                          contract: _allContracts[i],
                          isLatest: i == _allContracts.length - 1,
                          canDelete: _allContracts.length > 1,
                          onDelete: () => _deleteContract(_allContracts[i].id),
                        ),
                        if (i > 0) Divider(color: AppColors.border, height: 1, indent: 16, endIndent: 16),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ContractHistoryRow extends StatelessWidget {
  final PriceContract contract;
  final bool isLatest;
  final bool canDelete;
  final VoidCallback onDelete;

  const _ContractHistoryRow({
    required this.contract,
    required this.isLatest,
    required this.canDelete,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final since = DateTime.fromMillisecondsSinceEpoch(contract.validFrom);
    final dateStr = '${since.day.toString().padLeft(2, '0')}.${since.month.toString().padLeft(2, '0')}.${since.year}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(Icons.local_fire_department_outlined, size: 16, color: isLatest ? AppColors.amber : AppColors.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      contract.displayName,
                      style: GoogleFonts.rajdhani(fontSize: 14, fontWeight: FontWeight.w700, color: isLatest ? AppColors.textPrimary : AppColors.textSecondary),
                    ),
                    if (isLatest) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.amber.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                        child: Text('aktiv', style: GoogleFonts.spaceMono(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.amber)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'seit $dateStr  ·  ${(contract.pricePerKwh * 100).toStringAsFixed(3)} ct/kWh',
                  style: GoogleFonts.rajdhani(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          if (canDelete && !isLatest)
            GestureDetector(
              onTap: onDelete,
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.error.withValues(alpha: 0.7)),
              ),
            ),
        ],
      ),
    );
  }
}
