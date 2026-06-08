import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../database/database.dart';
import '../services/sync_service.dart';
import '../theme/colors.dart';
import '../widgets/advance_payment_dialog.dart';
import 'settings_widgets.dart';

class ElectricitySettingsScreen extends StatefulWidget {
  const ElectricitySettingsScreen({super.key});

  @override
  State<ElectricitySettingsScreen> createState() => _ElectricitySettingsScreenState();
}

class _ElectricitySettingsScreenState extends State<ElectricitySettingsScreen> {
  final _priceController     = TextEditingController();
  final _basePriceController = TextEditingController();
  final _advanceController   = TextEditingController();
  final _providerController  = TextEditingController();

  ElectricityContract? _latestContract;
  List<ElectricityContract> _allContracts = [];
  bool? _isNewContract;
  DateTime? _validFrom;
  DateTime? _contractEndDate;
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
    _advanceController.dispose();
    _providerController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final contracts = await AppDatabase.instance.getAllElectricityContracts();
    final latest    = contracts.isNotEmpty ? contracts.last : null;
    if (mounted) {
      setState(() { _latestContract = latest; _allContracts = contracts; });
    }
  }

  void _fillFromLatestContract() {
    final c = _latestContract;
    if (c == null) return;
    _priceController.text     = c.pricePerKwh.toStringAsFixed(4);
    _basePriceController.text = c.monthlyBasePrice.toStringAsFixed(2);
    _providerController.text  = c.displayName;
    _advanceController.text   = c.monthlyAdvancePayment != null ? c.monthlyAdvancePayment!.toStringAsFixed(2) : '';
    _validFrom       = DateTime.fromMillisecondsSinceEpoch(c.validFrom);
    _contractEndDate = c.contractEndDate != null ? DateTime.fromMillisecondsSinceEpoch(c.contractEndDate!) : null;
  }

  void _selectNein() {
    if (_isNewContract == false) return;
    final c = _latestContract;
    if (c == null) return;
    _priceController.text     = c.pricePerKwh.toStringAsFixed(4);
    _basePriceController.text = c.monthlyBasePrice.toStringAsFixed(2);
    _providerController.text  = c.displayName;
    _advanceController.text   = c.monthlyAdvancePayment != null ? c.monthlyAdvancePayment!.toStringAsFixed(2) : '';
    setState(() {
      _isNewContract   = false;
      _validFrom       = DateTime.fromMillisecondsSinceEpoch(c.validFrom);
      _contractEndDate = c.contractEndDate != null ? DateTime.fromMillisecondsSinceEpoch(c.contractEndDate!) : null;
    });
  }

  void _selectJa() {
    if (_isNewContract == true) return;
    _priceController.clear();
    _basePriceController.clear();
    _providerController.clear();
    _advanceController.clear();
    setState(() { _isNewContract = true; _validFrom = null; _contractEndDate = null; });
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
      await SyncService().deleteRemoteElectricityContract(contract.remoteId!);
    }
    await AppDatabase.instance.deleteElectricityContract(id);
    await _load();
    if (mounted) _showSnack('Vertrag gelöscht.');
  }

  Future<void> _saveContract() async {
    final kwhText   = _priceController.text.trim().replaceAll(',', '.');
    final kwhParsed = double.tryParse(kwhText);
    if (kwhParsed == null || kwhParsed <= 0) { _showSnack('Pflichtfeld: Preis pro kWh', isError: true); return; }
    final baseText   = _basePriceController.text.trim().replaceAll(',', '.');
    final baseParsed = double.tryParse(baseText) ?? -1;
    if (baseText.isEmpty || baseParsed < 0) { _showSnack('Pflichtfeld: Grundpreis (0,00 wenn keiner)', isError: true); return; }
    if (_validFrom == null) { _showSnack('Pflichtfeld: Datum', isError: true); return; }
    final bool creatingNew = _latestContract == null || (_isNewContract == true);
    final providerName     = creatingNew ? _providerController.text.trim() : _latestContract!.displayName;
    if (providerName.isEmpty) { _showSnack('Pflichtfeld: Lieferant', isError: true); return; }

    setState(() => _isSaving = true);
    final advText   = _advanceController.text.trim().replaceAll(',', '.');
    final advParsed = advText.isNotEmpty ? double.tryParse(advText) : null;

    if (creatingNew) {
      final count = await AppDatabase.instance.countElectricityContractsByDisplayName(providerName);
      await AppDatabase.instance.insertElectricityContract(ElectricityContractsCompanion(
        internalName: Value('${providerName}_${count + 1}'),
        displayName: Value(providerName),
        pricePerKwh: Value(kwhParsed),
        monthlyBasePrice: Value(baseParsed),
        validFrom: Value(_validFrom!.millisecondsSinceEpoch),
        contractEndDate: Value(_contractEndDate?.millisecondsSinceEpoch),
        monthlyAdvancePayment: Value(advParsed),
      ));
      // Auto-create advance payment history entry for new contract
      if (advParsed != null) {
        await AppDatabase.instance.insertAdvancePaymentChange(AdvancePaymentChangesCompanion(
          contractType: const Value('electricity'),
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
            accentColor: _blue,
          ),
        );
        if (result == null) {
          setState(() => _isSaving = false);
          return;
        }
        advValidFrom = result.validFrom;
        finalAdv = result.amount;
      }

      await AppDatabase.instance.updateElectricityContract(ElectricityContractsCompanion(
        id: Value(_latestContract!.id),
        internalName: Value(_latestContract!.internalName),
        displayName: Value(providerName),
        pricePerKwh: Value(kwhParsed),
        monthlyBasePrice: Value(baseParsed),
        validFrom: Value(_validFrom!.millisecondsSinceEpoch),
        contractEndDate: Value(_contractEndDate?.millisecondsSinceEpoch),
        monthlyAdvancePayment: Value(finalAdv),
        isSynced: const Value(false),
      ));

      if (advChanged && finalAdv != null && advValidFrom != null) {
        await AppDatabase.instance.insertAdvancePaymentChange(AdvancePaymentChangesCompanion(
          contractType: const Value('electricity'),
          amount: Value(finalAdv),
          validFrom: Value(advValidFrom.millisecondsSinceEpoch),
        ));
      }
    }
    await _load();
    SyncService().syncAll();
    if (mounted) {
      _fillFromLatestContract();
      setState(() { _isSaving = false; _isNewContract = false; });
      _showSnack('Stromvertrag gespeichert.');
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _contractEndDate ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime(2000), lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: _blue, onPrimary: Colors.white, surface: AppColors.background, onSurface: AppColors.textPrimary),
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
          colorScheme: const ColorScheme.light(primary: _blue, onPrimary: Colors.white, surface: AppColors.background, onSurface: AppColors.textPrimary),
          dialogTheme: const DialogThemeData(backgroundColor: AppColors.background),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _validFrom = picked);
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: isError ? AppColors.error : _blue,
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
        title: Text('STROM-EIGENSCHAFTEN', style: GoogleFonts.rajdhani(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 4)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SettingsSectionLabel('STROMPREIS'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(16), boxShadow: AppColors.neu(7)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (_latestContract != null) ...[
                    Row(children: [
                      Expanded(child: SettingsToggleChip(label: 'Vertrag anpassen', selected: _isNewContract == false, accentColor: _blue, onTap: _selectNein)),
                      const SizedBox(width: 8),
                      Expanded(child: SettingsToggleChip(label: 'Neuer Anbieter', selected: _isNewContract == true, accentColor: _blue, onTap: _selectJa)),
                    ]),
                  ],
                  AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    child: (_latestContract == null || _isNewContract != null)
                        ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            if (_latestContract != null) ...[
                              const SizedBox(height: 20),
                              Divider(color: AppColors.border, height: 1),
                              const SizedBox(height: 16),
                            ],
                            if (_isNewContract == false) ...[
                              SettingsContractPreview(icon: Icons.bolt_rounded, color: _blue,
                                  name: _latestContract!.displayName, since: DateTime.fromMillisecondsSinceEpoch(_latestContract!.validFrom), price: _latestContract!.pricePerKwh),
                              const SizedBox(height: 20),
                            ],
                            if (_latestContract == null || _isNewContract == true) ...[
                              const SettingsFieldLabel('Lieferant', required: true),
                              const SizedBox(height: 8),
                              SettingsTextField(controller: _providerController, hint: 'z.B. Stadtwerke Musterstadt', accentColor: _blue),
                              const SizedBox(height: 20),
                            ],
                            const SettingsFieldLabel('Preis pro kWh', required: true),
                            const SizedBox(height: 8),
                            SettingsPriceField(controller: _priceController, suffix: '€/kWh', hint: 'z.B. 0.2890', accentColor: _blue),
                            const SizedBox(height: 20),
                            const SettingsFieldLabel('Monatlicher Grundpreis', required: true),
                            const SizedBox(height: 8),
                            SettingsPriceField(controller: _basePriceController, suffix: '€/Monat', hint: 'z.B. 12.00', accentColor: _blue),
                            const SizedBox(height: 20),
                            const SettingsFieldLabel('Monatlicher Abschlag'),
                            const SizedBox(height: 6),
                            Text('Dein monatlicher Vorauszahlungsbetrag an den Anbieter',
                                style: GoogleFonts.rajdhani(fontSize: 13,
                                    color: AppColors.textSecondary.withValues(alpha: 0.7))),
                            const SizedBox(height: 8),
                            SettingsPriceField(controller: _advanceController, suffix: '€/Monat', hint: 'z.B. 80.00', accentColor: _blue),
                            const SizedBox(height: 20),
                            const SettingsFieldLabel('Diese Preise gelten seit:', required: true),
                            const SizedBox(height: 10),
                            SettingsDatePicker(date: _validFrom, onTap: _pickDate, accentColor: _blue),
                            const SizedBox(height: 20),
                            const SettingsFieldLabel('Vertragsende'),
                            const SizedBox(height: 6),
                            Text('Optional – für spätere Kündigungserinnerung',
                                style: GoogleFonts.rajdhani(fontSize: 13,
                                    color: AppColors.textSecondary.withValues(alpha: 0.7))),
                            const SizedBox(height: 10),
                            Row(children: [
                              Expanded(child: SettingsDatePicker(date: _contractEndDate, onTap: _pickEndDate, accentColor: _blue)),
                              if (_contractEndDate != null) ...[
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () => setState(() => _contractEndDate = null),
                                  child: const Icon(Icons.close_rounded, size: 20, color: AppColors.textSecondary),
                                ),
                              ],
                            ]),
                            const SizedBox(height: 20),
                            SettingsSaveButton(label: 'VERTRAG SPEICHERN', isBusy: _isSaving, onTap: _saveContract, accentColor: _blue),
                            const SizedBox(height: 12),
                            Text('Den Preis pro kWh findest du auf deiner Jahresabrechnung oder beim Versorger unter "Arbeitspreis".',
                                style: GoogleFonts.rajdhani(fontSize: 13, color: AppColors.textSecondary.withValues(alpha: 0.7), height: 1.5)),
                          ])
                        : const SizedBox.shrink(),
                  ),
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
                          accentColor: _blue,
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
  final ElectricityContract contract;
  final bool isLatest;
  final bool canDelete;
  final VoidCallback onDelete;
  final Color accentColor;

  const _ContractHistoryRow({
    required this.contract,
    required this.isLatest,
    required this.canDelete,
    required this.onDelete,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final since = DateTime.fromMillisecondsSinceEpoch(contract.validFrom);
    final dateStr = '${since.day.toString().padLeft(2, '0')}.${since.month.toString().padLeft(2, '0')}.${since.year}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(Icons.bolt_rounded, size: 16, color: isLatest ? accentColor : AppColors.textSecondary),
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
                        decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                        child: Text('aktiv', style: GoogleFonts.spaceMono(fontSize: 9, fontWeight: FontWeight.w700, color: accentColor)),
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
