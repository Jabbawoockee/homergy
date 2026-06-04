import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../database/database.dart';
import '../services/supabase_service.dart';
import '../theme/colors.dart';
import 'settings_account_screen.dart';
import 'settings_gas_screen.dart';
import 'settings_electricity_screen.dart';
import 'settings_location_screen.dart';

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
    final location = await AppDatabase.instance.getSettings();
    if (mounted) {
      setState(() {
        _preview = _SettingsPreview(
          gasLabel:  gas != null
              ? '${gas.displayName} · ${gas.pricePerKwh.toStringAsFixed(4)} €/kWh'
              : 'Noch nicht konfiguriert',
          elecLabel: elec != null
              ? '${elec.displayName} · ${elec.pricePerKwh.toStringAsFixed(4)} €/kWh'
              : 'Noch nicht konfiguriert',
          locationLabel: (location?.locationCity?.isNotEmpty == true)
              ? '${location!.locationPlz ?? ''} ${location.locationCity ?? ''}'.trim()
              : 'Noch nicht gesetzt',
          accountLabel: SupabaseService.isAnonymous
              ? 'Anonym'
              : (SupabaseService.userEmail ?? 'Verknüpft'),
        );
      });
    }
  }

  Future<void> _navigateTo(Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    _loadPreview();
  }

  @override
  Widget build(BuildContext context) {
    final p = _preview;
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
                  style: GoogleFonts.spaceMono(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.greenDark, letterSpacing: 4)),
              const SizedBox(height: 4),
              Text('Konfiguration & App-Info',
                  style: GoogleFonts.rajdhani(fontSize: 13, color: AppColors.textSecondary, letterSpacing: 0.5)),
              const SizedBox(height: 32),

              _NavRow(
                icon: Icons.person_outline_rounded,
                iconColor: AppColors.green,
                title: 'Konto',
                subtitle: p?.accountLabel ?? '…',
                onTap: () => _navigateTo(const AccountSettingsScreen()),
              ),
              const SizedBox(height: 12),
              _NavRow(
                icon: Icons.local_fire_department_outlined,
                iconColor: AppColors.amber,
                title: 'Gas',
                subtitle: p?.gasLabel ?? '…',
                onTap: () => _navigateTo(const GasSettingsScreen()),
              ),
              const SizedBox(height: 12),
              _NavRow(
                icon: Icons.bolt_outlined,
                iconColor: const Color(0xFF5B8DB8),
                title: 'Strom',
                subtitle: p?.elecLabel ?? '…',
                onTap: () => _navigateTo(const ElectricitySettingsScreen()),
              ),
              const SizedBox(height: 12),
              _NavRow(
                icon: Icons.location_on_outlined,
                iconColor: AppColors.green,
                title: 'Standort',
                subtitle: p?.locationLabel ?? '…',
                onTap: () => _navigateTo(const LocationSettingsScreen()),
              ),
              const SizedBox(height: 12),
              _NavRow(
                icon: Icons.info_outline_rounded,
                iconColor: AppColors.textSecondary,
                title: 'App-Info',
                subtitle: 'Homergy v1.0.0',
                onTap: () => _navigateTo(const _AppInfoScreen()),
              ),

              const SizedBox(height: 48),
              Center(
                child: Column(
                  children: [
                    Icon(Icons.local_fire_department, color: AppColors.green.withValues(alpha: 0.3), size: 32),
                    const SizedBox(height: 8),
                    Text('Homergy v1.0.0',
                        style: GoogleFonts.spaceMono(fontSize: 11, color: AppColors.textSecondary.withValues(alpha: 0.5), letterSpacing: 2)),
                  ],
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

class _SettingsPreview {
  final String gasLabel, elecLabel, locationLabel, accountLabel;
  const _SettingsPreview({required this.gasLabel, required this.elecLabel, required this.locationLabel, required this.accountLabel});
}

class _NavRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title, subtitle;
  final VoidCallback onTap;

  const _NavRow({required this.icon, required this.iconColor, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppColors.neu(6),
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: AppColors.background, shape: BoxShape.circle, boxShadow: AppColors.neu(4)),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.rajdhani(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: 0.3)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: GoogleFonts.rajdhani(fontSize: 13, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary.withValues(alpha: 0.5), size: 20),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// App-Info screen (simple, no state needed)
// ---------------------------------------------------------------------------

class _AppInfoScreen extends StatelessWidget {
  const _AppInfoScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textSecondary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('APP-INFO', style: GoogleFonts.rajdhani(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 4)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(16), boxShadow: AppColors.neu(7)),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _InfoRow(label: 'App',        value: 'Homergy'),
                SizedBox(height: 12),
                _InfoRow(label: 'Version',    value: 'v1.0.0'),
                SizedBox(height: 12),
                _InfoRow(label: 'Datenbank',  value: 'SQLite (Drift)'),
                SizedBox(height: 12),
                _InfoRow(label: 'OCR',        value: 'Google ML Kit'),
                SizedBox(height: 12),
                _InfoRow(label: 'Cloud',      value: 'Supabase'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.rajdhani(fontSize: 14, color: AppColors.textSecondary, letterSpacing: 0.5)),
        Text(value,  style: GoogleFonts.spaceMono(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
