import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../database/database.dart';
import '../services/supabase_service.dart';
import '../theme/colors.dart';
import 'settings_account_screen.dart';
import 'settings_gas_screen.dart';
import 'settings_electricity_screen.dart';
import 'settings_hausdaten_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  _SettingsPreview?    _preview;
  _Completeness?       _completeness;
  String               _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadPreview();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _appVersion = info.version);
    });
  }

  Future<void> _loadPreview() async {
    final gas      = await AppDatabase.instance.getLatestContract();
    final elec     = await AppDatabase.instance.getLatestElectricityContract();
    final settings = await AppDatabase.instance.getSettings();
    if (mounted) {
      setState(() {
        _preview = _SettingsPreview(
          gasLabel:  gas != null
              ? '${gas.displayName} · ${gas.pricePerKwh.toStringAsFixed(4)} €/kWh'
              : 'Noch nicht konfiguriert',
          elecLabel: elec != null
              ? '${elec.displayName} · ${elec.pricePerKwh.toStringAsFixed(4)} €/kWh'
              : 'Noch nicht konfiguriert',
          hausdatenLabel: _buildHausdatenLabel(settings),
          accountLabel: SupabaseService.isAnonymous
              ? 'Anonym'
              : (SupabaseService.userEmail ?? 'Verknüpft'),
        );
        _completeness = _buildCompleteness(settings, gas, elec);
      });
    }
  }

  String _buildHausdatenLabel(AppSetting? s) {
    if (s == null) return 'Noch nicht konfiguriert';
    final parts = <String>[];
    if (s.trackingMode != null) {
      parts.add(switch (s.trackingMode) {
        'gas'         => 'Nur Gas',
        'electricity' => 'Nur Strom',
        _             => 'Gas & Strom',
      });
    }
    if (s.houseType != null) parts.add(s.houseType!);
    if (s.squareMeters != null) parts.add('${s.squareMeters} m²');
    return parts.isEmpty ? 'Noch nicht konfiguriert' : parts.join(' · ');
  }

  _Completeness _buildCompleteness(
      AppSetting? s, PriceContract? gas, ElectricityContract? elec) {
    final mode = s?.trackingMode ?? 'both';
    final missingHausdaten = <String>[];

    if (s == null || (s.locationPlz == null || s.locationPlz!.isEmpty)) {
      missingHausdaten.add('Standort (Postleitzahl)');
    }
    if (s?.houseType == null)        missingHausdaten.add('Haustyp');
    if (s?.squareMeters == null)     missingHausdaten.add('Wohnfläche');
    if (s?.constructionYear == null) missingHausdaten.add('Baujahr');
    if (s?.hasPv == null)            missingHausdaten.add('PV-Anlage (Ja/Nein)');
    if (s?.isInsulated == null)      missingHausdaten.add('Haus gedämmt (Ja/Nein)');
    if (s?.hasSolarThermal == null)  missingHausdaten.add('Solaranlage Wärme (Ja/Nein)');

    final gasActive  = mode == 'gas'         || mode == 'both';
    final elecActive = mode == 'electricity' || mode == 'both';

    final gasMissingFields = <String>[];
    if (gasActive && gas != null) {
      if (gas.monthlyAdvancePayment == null) gasMissingFields.add('Monatlicher Abschlag');
      if (gas.contractEndDate == null)       gasMissingFields.add('Vertragsende');
    }

    final elecMissingFields = <String>[];
    if (elecActive && elec != null) {
      if (elec.monthlyAdvancePayment == null) elecMissingFields.add('Monatlicher Abschlag');
      if (elec.contractEndDate == null)       elecMissingFields.add('Vertragsende');
    }

    return _Completeness(
      missingHausdaten:  missingHausdaten,
      gasMissing:        gasActive  && gas  == null,
      elecMissing:       elecActive && elec == null,
      gasMissingFields:  gasMissingFields,
      elecMissingFields: elecMissingFields,
    );
  }

  void _showCompletenessDialog() {
    final c = _completeness;
    if (c == null || !c.hasIssues) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        contentPadding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
        title: Row(children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: AppColors.amber.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.warning_amber_rounded, color: AppColors.amber, size: 18),
          ),
          const SizedBox(width: 12),
          Text('Angaben unvollständig',
              style: GoogleFonts.rajdhani(
                  fontSize: 17, fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Je vollständiger deine Angaben, desto genauer sind die Auswertungen und Vergleiche mit ähnlichen Haushalten.',
              style: GoogleFonts.rajdhani(
                  fontSize: 13, color: AppColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 16),
            if (c.missingHausdaten.isNotEmpty) ...[
              _DialogSection(
                label: 'Hausdaten',
                icon: Icons.home_rounded,
                items: c.missingHausdaten,
              ),
              const SizedBox(height: 12),
            ],
            if (c.gasMissing) ...[
              _DialogSection(
                label: 'Gas-Eigenschaften',
                icon: Icons.local_fire_department_rounded,
                items: const ['Kein Gasvertrag eingetragen'],
              ),
              const SizedBox(height: 12),
            ],
            if (c.gasMissingFields.isNotEmpty) ...[
              _DialogSection(
                label: 'Gas-Vertrag (Details)',
                icon: Icons.local_fire_department_rounded,
                items: c.gasMissingFields,
              ),
              const SizedBox(height: 12),
            ],
            if (c.elecMissing) ...[
              _DialogSection(
                label: 'Strom-Eigenschaften',
                icon: Icons.bolt_rounded,
                items: const ['Kein Stromvertrag eingetragen'],
                iconColor: const Color(0xFF5B8DB8),
              ),
              const SizedBox(height: 12),
            ],
            if (c.elecMissingFields.isNotEmpty) ...[
              _DialogSection(
                label: 'Strom-Vertrag (Details)',
                icon: Icons.bolt_rounded,
                items: c.elecMissingFields,
                iconColor: const Color(0xFF5B8DB8),
              ),
              const SizedBox(height: 4),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK',
                style: GoogleFonts.rajdhani(
                    fontSize: 14, fontWeight: FontWeight.w700,
                    color: AppColors.green)),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateTo(Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    _loadPreview();
  }

  @override
  Widget build(BuildContext context) {
    final p = _preview;
    const blue = Color(0xFF5B8DB8);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('EINSTELLUNGEN',
                            style: GoogleFonts.spaceMono(
                                fontSize: 22, fontWeight: FontWeight.w700,
                                color: AppColors.greenDark, letterSpacing: 4)),
                        const SizedBox(height: 4),
                        Text('Nutzerdaten, Haus & Energieverträge',
                            style: GoogleFonts.rajdhani(
                                fontSize: 13, color: AppColors.textSecondary,
                                letterSpacing: 0.5)),
                      ],
                    ),
                  ),
                  if (_completeness?.hasIssues == true)
                    GestureDetector(
                      onTap: _showCompletenessDialog,
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.amber.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                          boxShadow: AppColors.neu(4),
                        ),
                        child: const Icon(Icons.warning_amber_rounded,
                            color: AppColors.amber, size: 22),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 32),

              _NavRow(
                icon: Icons.person_outline_rounded,
                iconColor: AppColors.green,
                title: 'Userdaten',
                subtitle: p?.accountLabel ?? '…',
                onTap: () => _navigateTo(const AccountSettingsScreen()),
              ),
              const SizedBox(height: 12),
              _NavRow(
                icon: Icons.home_rounded,
                iconColor: AppColors.amber,
                title: 'Hausdaten',
                subtitle: p?.hausdatenLabel ?? '…',
                onTap: () => _navigateTo(const HausdatenSettingsScreen()),
              ),
              const SizedBox(height: 12),
              _NavRow(
                icon: Icons.bolt_rounded,
                iconColor: blue,
                title: 'Strom-Eigenschaften',
                subtitle: p?.elecLabel ?? '…',
                accentColor: blue,
                onTap: () => _navigateTo(const ElectricitySettingsScreen()),
              ),
              const SizedBox(height: 12),
              _NavRow(
                icon: Icons.local_fire_department_rounded,
                iconColor: AppColors.green,
                title: 'Gas-Eigenschaften',
                subtitle: p?.gasLabel ?? '…',
                accentColor: AppColors.green,
                onTap: () => _navigateTo(const GasSettingsScreen()),
              ),

              const SizedBox(height: 40),

              // App-Info Zeile (kein eigener Screen)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: [
                      Icon(Icons.info_outline_rounded,
                          size: 14, color: AppColors.textSecondary.withValues(alpha: 0.5)),
                      const SizedBox(width: 6),
                      Text('Homergy v$_appVersion',
                          style: GoogleFonts.spaceMono(
                              fontSize: 11,
                              color: AppColors.textSecondary.withValues(alpha: 0.5),
                              letterSpacing: 1.5)),
                    ]),
                    Text('SQLite · Supabase · ML Kit',
                        style: GoogleFonts.spaceMono(
                            fontSize: 10,
                            color: AppColors.textSecondary.withValues(alpha: 0.35),
                            letterSpacing: 0.5)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _SettingsPreview {
  final String gasLabel, elecLabel, hausdatenLabel, accountLabel;
  const _SettingsPreview({
    required this.gasLabel,
    required this.elecLabel,
    required this.hausdatenLabel,
    required this.accountLabel,
  });
}

class _Completeness {
  final List<String> missingHausdaten;
  final bool gasMissing;
  final bool elecMissing;
  final List<String> gasMissingFields;
  final List<String> elecMissingFields;
  const _Completeness({
    required this.missingHausdaten,
    required this.gasMissing,
    required this.elecMissing,
    required this.gasMissingFields,
    required this.elecMissingFields,
  });
  bool get hasIssues =>
      missingHausdaten.isNotEmpty ||
      gasMissing ||
      elecMissing ||
      gasMissingFields.isNotEmpty ||
      elecMissingFields.isNotEmpty;
}

class _DialogSection extends StatelessWidget {
  final String label;
  final IconData icon;
  final List<String> items;
  final Color iconColor;
  const _DialogSection({
    required this.label,
    required this.icon,
    required this.items,
    this.iconColor = AppColors.amber,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.amber.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.amber.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 14, color: iconColor),
            const SizedBox(width: 6),
            Text(label,
                style: GoogleFonts.rajdhani(
                    fontSize: 13, fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary, letterSpacing: 0.3)),
          ]),
          const SizedBox(height: 6),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(width: 2),
              Text('·  ',
                  style: GoogleFonts.rajdhani(
                      fontSize: 13, color: AppColors.amber,
                      fontWeight: FontWeight.w700)),
              Expanded(
                child: Text(item,
                    style: GoogleFonts.rajdhani(
                        fontSize: 13, color: AppColors.textSecondary)),
              ),
            ]),
          )),
        ],
      ),
    );
  }
}

class _NavRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title, subtitle;
  final Color? accentColor;
  final VoidCallback onTap;

  const _NavRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final accent = accentColor;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppColors.neu(6),
          border: accent != null
              ? Border(left: BorderSide(color: accent.withValues(alpha: 0.5), width: 3))
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                  color: AppColors.background, shape: BoxShape.circle, boxShadow: AppColors.neu(4)),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.rajdhani(
                          fontSize: 16, fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary, letterSpacing: 0.3)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: GoogleFonts.rajdhani(
                          fontSize: 13, color: AppColors.textSecondary),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: AppColors.textSecondary.withValues(alpha: 0.5), size: 20),
          ],
        ),
      ),
    );
  }
}
