import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../database/database.dart';
import '../services/sync_service.dart';
import '../services/weather_service.dart';
import '../theme/colors.dart';
import 'settings_widgets.dart';

class LocationSettingsScreen extends StatefulWidget {
  const LocationSettingsScreen({super.key});

  @override
  State<LocationSettingsScreen> createState() => _LocationSettingsScreenState();
}

class _LocationSettingsScreenState extends State<LocationSettingsScreen> {
  final _plzController  = TextEditingController();
  final _cityController = TextEditingController();
  AppSetting? _settings;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _plzController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final s = await AppDatabase.instance.getSettings();
    if (mounted) {
      setState(() => _settings = s);
      if (s != null) {
        _plzController.text  = s.locationPlz  ?? '';
        _cityController.text = s.locationCity ?? '';
      }
    }
  }

  Future<void> _save() async {
    final plz  = _plzController.text.trim();
    final city = _cityController.text.trim();
    if (plz.isEmpty && city.isEmpty) { _showSnack('Bitte PLZ oder Ort eingeben.', isError: true); return; }
    setState(() => _isSaving = true);
    await AppDatabase.instance.saveLocation(plz: plz, city: city);
    final coords = await WeatherService().geocode(city, plz);
    if (coords != null) {
      final s = await AppDatabase.instance.getSettings();
      if (s != null) await AppDatabase.instance.saveCoordinates(s.id, coords.lat, coords.lon);
    }
    await _load();
    SyncService().syncSettings();
    if (mounted) {
      setState(() => _isSaving = false);
      _showSnack(coords != null ? 'Standort gespeichert & gefunden.' : 'Standort gespeichert. Koordinaten konnten nicht ermittelt werden.');
    }
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
        title: Text('STANDORT', style: GoogleFonts.rajdhani(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 4)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SettingsSectionLabel('WETTERDATEN-STANDORT'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(16), boxShadow: AppColors.neu(7)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const Icon(Icons.thermostat_rounded, size: 16, color: AppColors.amber),
                    const SizedBox(width: 8),
                    Text('Wetterdaten-Standort', style: GoogleFonts.rajdhani(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary, letterSpacing: 0.5)),
                  ]),
                  const SizedBox(height: 6),
                  Text('Wird für die Temperaturkorrelation im Verbrauchsgraph verwendet.',
                      style: GoogleFonts.rajdhani(fontSize: 13, color: AppColors.textSecondary.withValues(alpha: 0.8), height: 1.4)),
                  if (_settings?.locationLat != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(color: AppColors.green.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(8)),
                      child: Row(children: [
                        const Icon(Icons.check_circle_outline, size: 14, color: AppColors.green),
                        const SizedBox(width: 8),
                        Text('Koordinaten gefunden', style: GoogleFonts.rajdhani(fontSize: 13, color: AppColors.green, fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(flex: 2, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('PLZ', style: GoogleFonts.rajdhani(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      _InputField(controller: _plzController, hint: '80331'),
                    ])),
                    const SizedBox(width: 12),
                    Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Wohnort', style: GoogleFonts.rajdhani(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      _InputField(controller: _cityController, hint: 'München'),
                    ])),
                  ]),
                  const SizedBox(height: 16),
                  SettingsSaveButton(label: 'STANDORT SPEICHERN', isBusy: _isSaving, onTap: _save),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  const _InputField({required this.controller, required this.hint});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFFDFE5DA), borderRadius: BorderRadius.circular(10)),
      child: TextField(
        controller: controller,
        style: GoogleFonts.rajdhani(fontSize: 16, color: AppColors.textPrimary),
        cursorColor: AppColors.green,
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          hintText: hint, hintStyle: GoogleFonts.rajdhani(fontSize: 14, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
