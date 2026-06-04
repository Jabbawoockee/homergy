import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
  _SettingsPreview? _preview;

  @override
  void initState() {
    super.initState();
    _loadPreview();
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
      });
    }
  }

  String _buildHausdatenLabel(AppSetting? s) {
    if (s == null) return 'Noch nicht konfiguriert';
    final parts = <String>[];
    if (s.houseType != null) parts.add(s.houseType!);
    if (s.squareMeters != null) parts.add('${s.squareMeters} m²');
    if (s.locationCity?.isNotEmpty == true) {
      parts.add('${s.locationPlz ?? ''} ${s.locationCity ?? ''}'.trim());
    }
    return parts.isEmpty ? 'Noch nicht konfiguriert' : parts.join(' · ');
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
              Text('EINSTELLUNGEN',
                  style: GoogleFonts.spaceMono(
                      fontSize: 22, fontWeight: FontWeight.w700,
                      color: AppColors.greenDark, letterSpacing: 4)),
              const SizedBox(height: 4),
              Text('Nutzerdaten, Haus & Energieverträge',
                  style: GoogleFonts.rajdhani(
                      fontSize: 13, color: AppColors.textSecondary, letterSpacing: 0.5)),
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
                      Text('Homergy v1.0.0',
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
