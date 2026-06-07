import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../database/database.dart';
import '../services/settings_service.dart';
import '../services/sync_service.dart';
import '../services/weather_service.dart';
import '../theme/colors.dart';
import 'settings_widgets.dart';

const _houseTypes = [
  'Wohnung',
  'Reihenmittelhaus',
  'Reihenendhaus',
  'Doppelhaushälfte',
  'Einfamilienhaus',
];

class HausdatenSettingsScreen extends StatefulWidget {
  const HausdatenSettingsScreen({super.key});

  @override
  State<HausdatenSettingsScreen> createState() => _HausdatenSettingsScreenState();
}

class _HausdatenSettingsScreenState extends State<HausdatenSettingsScreen> {
  final _plzController  = TextEditingController();
  final _sqmController  = TextEditingController();
  String? _resolvedCity;

  final _settingsService = SettingsService();

  bool _isSaving = false;
  bool _coordsFound = false;

  String? _houseType;
  int?    _numberOfPersons;
  bool?   _hasPv;
  bool?   _hasSolarThermal;
  int?    _constructionYear;
  bool?   _isInsulated;
  String  _trackingMode = 'both';

  int _gasMeterIntDigits = 5;
  int _elecIntDigits     = 6;
  int _elecDecDigits     = 1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _plzController.dispose();
    _sqmController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final s = await AppDatabase.instance.getSettings();
    if (!mounted) return;
    final mode        = await _settingsService.getTrackingMode();
    final gasMeterD   = await _settingsService.getMeterIntDigits();
    final elecIntD    = await _settingsService.getElectricityIntDigits();
    final elecDecD    = await _settingsService.getElectricityDecDigits();
    setState(() {
      _coordsFound       = s?.locationLat != null;
      _houseType         = s?.houseType;
      _numberOfPersons   = s?.numberOfPersons;
      _hasPv             = s?.hasPv;
      _hasSolarThermal   = s?.hasSolarThermal;
      _constructionYear  = s?.constructionYear;
      _isInsulated       = s?.isInsulated;
      _trackingMode      = mode;
      _gasMeterIntDigits = gasMeterD;
      _elecIntDigits     = elecIntD;
      _elecDecDigits     = elecDecD;
    });
    if (s != null) {
      _plzController.text = s.locationPlz ?? '';
      _resolvedCity       = s.locationCity;
      _sqmController.text = s.squareMeters != null ? '${s.squareMeters}' : '';
    }
  }

  Future<void> _save() async {
    final plz    = _plzController.text.trim();
    final sqmRaw = _sqmController.text.trim();
    final sqm = sqmRaw.isNotEmpty ? int.tryParse(sqmRaw) : null;

    setState(() => _isSaving = true);

    // Geocode by PLZ only (unique in Germany) and save location
    if (plz.isNotEmpty) {
      final coords = await WeatherService().geocodeByPlz(plz);
      final resolvedCity = coords?.city;
      await AppDatabase.instance.saveLocation(plz: plz, city: resolvedCity ?? '');
      if (coords != null) {
        final s = await AppDatabase.instance.getSettings();
        if (s != null) {
          await AppDatabase.instance.saveCoordinates(s.id, coords.lat, coords.lon);
        }
        if (mounted) setState(() { _resolvedCity = resolvedCity; _coordsFound = true; });
      }
    }

    // Save house data
    await AppDatabase.instance.saveHouseData(
      houseType: _houseType,
      squareMeters: sqm,
      numberOfPersons: _numberOfPersons,
      hasPv: _hasPv,
      hasSolarThermal: _hasSolarThermal,
      constructionYear: _constructionYear,
      isInsulated: _isInsulated,
    );

    await _settingsService.setTrackingMode(_trackingMode);

    await _load();
    SyncService().syncSettings();

    if (mounted) {
      setState(() => _isSaving = false);
      _showSnack('Hausdaten gespeichert.');
    }
  }

  Future<void> _saveGasMeterDigits(int digits) async {
    setState(() => _gasMeterIntDigits = digits);
    await _settingsService.setMeterIntDigits(digits);
    SyncService().syncSettings();
    _showSnack('Gaszähler: $digits Vorkomma-Stellen gespeichert');
  }

  Future<void> _saveElecIntDigits(int d) async {
    setState(() => _elecIntDigits = d);
    await _settingsService.setElectricityIntDigits(d);
    SyncService().syncSettings();
    _showSnack('Stromzähler: $d Vorkomma-Stellen gespeichert');
  }

  Future<void> _saveElecDecDigits(int d) async {
    setState(() => _elecDecDigits = d);
    await _settingsService.setElectricityDecDigits(d);
    SyncService().syncSettings();
    _showSnack('Stromzähler: $d Nachkomma-Stellen gespeichert');
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: isError ? AppColors.error : AppColors.green,
      content: Text(msg,
          style: GoogleFonts.rajdhani(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
      duration: const Duration(seconds: 3),
    ));
  }

  void _stepPersons(int delta) {
    setState(() {
      if (delta > 0) {
        _numberOfPersons = (_numberOfPersons ?? 0) + 1;
      } else {
        if (_numberOfPersons == null || _numberOfPersons! <= 1) {
          _numberOfPersons = null;
        } else {
          _numberOfPersons = _numberOfPersons! - 1;
        }
      }
    });
  }

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
        title: Text('HAUSDATEN',
            style: GoogleFonts.rajdhani(
                fontSize: 13, fontWeight: FontWeight.w700,
                color: AppColors.textSecondary, letterSpacing: 4)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Tracking-Modus ────────────────────────────────────────────
              const SettingsSectionLabel('TRACKING-MODUS'),
              const SizedBox(height: 12),
              _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Icon(Icons.track_changes_rounded, size: 16, color: AppColors.amber),
                  const SizedBox(width: 8),
                  Text('Was möchtest du tracken?',
                      style: GoogleFonts.rajdhani(fontSize: 15, fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary, letterSpacing: 0.5)),
                ]),
                const SizedBox(height: 4),
                Text('Bestimmt, welcher Startbildschirm angezeigt wird.',
                    style: GoogleFonts.rajdhani(fontSize: 13,
                        color: AppColors.textSecondary.withValues(alpha: 0.8))),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    SettingsToggleChip(
                      label: '🔥  Nur Gas',
                      selected: _trackingMode == 'gas',
                      onTap: () => setState(() => _trackingMode = 'gas'),
                    ),
                    SettingsToggleChip(
                      label: '⚡  Nur Strom',
                      selected: _trackingMode == 'electricity',
                      onTap: () => setState(() => _trackingMode = 'electricity'),
                    ),
                    SettingsToggleChip(
                      label: '🏠  Gas & Strom',
                      selected: _trackingMode == 'both',
                      onTap: () => setState(() => _trackingMode = 'both'),
                    ),
                  ],
                ),
              ])),

              const SizedBox(height: 24),

              // ── Gaszähler-Typ ─────────────────────────────────────────────
              const SettingsSectionLabel('GASZÄHLER'),
              const SizedBox(height: 12),
              SettingsDigitSelector(
                icon: Icons.local_fire_department_outlined,
                iconColor: AppColors.amber,
                description: 'Wie viele Stellen stehen vor dem Komma auf deinem Gaszähler?',
                selected: _gasMeterIntDigits,
                options: const [4, 5, 6],
                formatHint: (d) => '${'0' * d},${'0' * 3} m³',
                onSelect: _saveGasMeterDigits,
              ),

              const SizedBox(height: 24),

              // ── Stromzähler-Typ ───────────────────────────────────────────
              const SettingsSectionLabel('STROMZÄHLER'),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'OCR prüft genau ${_elecIntDigits + _elecDecDigits} Stellen auf dem Foto.',
                  style: GoogleFonts.spaceMono(fontSize: 11, color: const Color(0xFF5B8DB8)),
                ),
              ),
              SettingsDigitSelector(
                icon: Icons.bolt_outlined,
                iconColor: const Color(0xFF5B8DB8),
                accentColor: const Color(0xFF5B8DB8),
                description: 'Stellen VOR dem Komma',
                selected: _elecIntDigits,
                options: const [5, 6, 7],
                formatHint: (d) => '${'0' * d},${'0' * _elecDecDigits} kWh',
                onSelect: _saveElecIntDigits,
              ),
              const SizedBox(height: 16),
              SettingsDigitSelector(
                icon: Icons.looks_one_outlined,
                iconColor: const Color(0xFF5B8DB8),
                accentColor: const Color(0xFF5B8DB8),
                title: 'Nachkomma-Stellen',
                description: 'Stellen NACH dem Komma (rote Dezimaltrommel)',
                selected: _elecDecDigits,
                options: const [1, 2, 3],
                formatHint: (d) => '${'0' * _elecIntDigits},${'0' * d} kWh',
                onSelect: _saveElecDecDigits,
              ),

              const SizedBox(height: 24),

              // ── Standort ──────────────────────────────────────────────────
              const SettingsSectionLabel('STANDORT & WETTERDATEN'),
              const SizedBox(height: 12),
              _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Icon(Icons.thermostat_rounded, size: 16, color: AppColors.amber),
                  const SizedBox(width: 8),
                  Text('Wetterdaten-Standort',
                      style: GoogleFonts.rajdhani(fontSize: 15, fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary, letterSpacing: 0.5)),
                ]),
                const SizedBox(height: 6),
                Text('Wird für die Temperaturkorrelation im Verbrauchsgraph verwendet.',
                    style: GoogleFonts.rajdhani(
                        fontSize: 13, color: AppColors.textSecondary.withValues(alpha: 0.8), height: 1.4)),
                if (_coordsFound) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                        color: AppColors.green.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(8)),
                    child: Row(children: [
                      const Icon(Icons.check_circle_outline, size: 14, color: AppColors.green),
                      const SizedBox(width: 8),
                      Text('Koordinaten gefunden',
                          style: GoogleFonts.rajdhani(fontSize: 13, color: AppColors.green,
                              fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ],
                const SizedBox(height: 16),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Postleitzahl', style: GoogleFonts.rajdhani(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  _InputField(controller: _plzController, hint: '80331', keyboardType: TextInputType.number),
                  if (_resolvedCity != null) ...[
                    const SizedBox(height: 10),
                    Row(children: [
                      const Icon(Icons.location_on_rounded, size: 14, color: AppColors.green),
                      const SizedBox(width: 6),
                      Text(_resolvedCity!, style: GoogleFonts.rajdhani(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.green)),
                    ]),
                  ],
                ]),
              ])),

              const SizedBox(height: 24),

              // ── Gebäude ───────────────────────────────────────────────────
              const SettingsSectionLabel('GEBÄUDE'),
              const SizedBox(height: 12),
              _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                // Haustyp
                Row(children: [
                  const Icon(Icons.home_rounded, size: 16, color: AppColors.amber),
                  const SizedBox(width: 8),
                  Text('Haustyp',
                      style: GoogleFonts.rajdhani(fontSize: 15, fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary, letterSpacing: 0.5)),
                ]),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _houseTypes.map((type) => SettingsToggleChip(
                    label: type,
                    selected: _houseType == type,
                    onTap: () => setState(() => _houseType = type),
                  )).toList(),
                ),

                const SizedBox(height: 20),
                const Divider(color: Color(0xFFCFD8C4), height: 1),
                const SizedBox(height: 20),

                // Baujahr
                Row(children: [
                  const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.amber),
                  const SizedBox(width: 8),
                  Text('Baujahr',
                      style: GoogleFonts.rajdhani(fontSize: 15, fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary, letterSpacing: 0.5)),
                ]),
                const SizedBox(height: 10),
                _YearField(
                  value: _constructionYear,
                  onChanged: (v) => setState(() => _constructionYear = v),
                ),

                const SizedBox(height: 20),
                const Divider(color: Color(0xFFCFD8C4), height: 1),
                const SizedBox(height: 20),

                // Wohnfläche
                Row(children: [
                  const Icon(Icons.square_foot_rounded, size: 16, color: AppColors.amber),
                  const SizedBox(width: 8),
                  Text('Wohnfläche',
                      style: GoogleFonts.rajdhani(fontSize: 15, fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary, letterSpacing: 0.5)),
                ]),
                const SizedBox(height: 10),
                _SqmField(controller: _sqmController),

                const SizedBox(height: 20),
                const Divider(color: Color(0xFFCFD8C4), height: 1),
                const SizedBox(height: 20),

                // Haushaltsgröße
                Row(children: [
                  const Icon(Icons.people_alt_rounded, size: 16, color: AppColors.amber),
                  const SizedBox(width: 8),
                  Text('Haushaltsgröße',
                      style: GoogleFonts.rajdhani(fontSize: 15, fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary, letterSpacing: 0.5)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                        color: AppColors.textSecondary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4)),
                    child: Text('optional',
                        style: GoogleFonts.rajdhani(fontSize: 11, color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                  ),
                ]),
                const SizedBox(height: 10),
                _PersonsStepper(value: _numberOfPersons, onStep: _stepPersons),

                const SizedBox(height: 20),
                const Divider(color: Color(0xFFCFD8C4), height: 1),
                const SizedBox(height: 20),

                // PV-Anlage
                Row(children: [
                  const Icon(Icons.solar_power_rounded, size: 16, color: AppColors.amber),
                  const SizedBox(width: 8),
                  Text('Photovoltaik (PV)',
                      style: GoogleFonts.rajdhani(fontSize: 15, fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary, letterSpacing: 0.5)),
                ]),
                const SizedBox(height: 4),
                Text('Zur Stromerzeugung installiert',
                    style: GoogleFonts.rajdhani(fontSize: 13,
                        color: AppColors.textSecondary.withValues(alpha: 0.8))),
                const SizedBox(height: 10),
                Row(children: [
                  SettingsToggleChip(label: 'Ja', selected: _hasPv == true,
                      onTap: () => setState(() => _hasPv = true)),
                  const SizedBox(width: 8),
                  SettingsToggleChip(label: 'Nein', selected: _hasPv == false,
                      onTap: () => setState(() => _hasPv = false)),
                ]),

                const SizedBox(height: 20),
                const Divider(color: Color(0xFFCFD8C4), height: 1),
                const SizedBox(height: 20),

                // Haus gedämmt
                Row(children: [
                  const Icon(Icons.house_rounded, size: 16, color: AppColors.amber),
                  const SizedBox(width: 8),
                  Text('Haus gedämmt',
                      style: GoogleFonts.rajdhani(fontSize: 15, fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary, letterSpacing: 0.5)),
                ]),
                const SizedBox(height: 4),
                Text('Wärmedämmung vorhanden',
                    style: GoogleFonts.rajdhani(fontSize: 13,
                        color: AppColors.textSecondary.withValues(alpha: 0.8))),
                const SizedBox(height: 10),
                Row(children: [
                  SettingsToggleChip(label: 'Ja', selected: _isInsulated == true,
                      onTap: () => setState(() => _isInsulated = true)),
                  const SizedBox(width: 8),
                  SettingsToggleChip(label: 'Nein', selected: _isInsulated == false,
                      onTap: () => setState(() => _isInsulated = false)),
                ]),

                const SizedBox(height: 20),
                const Divider(color: Color(0xFFCFD8C4), height: 1),
                const SizedBox(height: 20),

                // Solaranlage Wärme
                Row(children: [
                  const Icon(Icons.wb_sunny_rounded, size: 16, color: AppColors.amber),
                  const SizedBox(width: 8),
                  Text('Solaranlage (Wärme)',
                      style: GoogleFonts.rajdhani(fontSize: 15, fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary, letterSpacing: 0.5)),
                ]),
                const SizedBox(height: 4),
                Text('Zur Wärmeerzeugung installiert',
                    style: GoogleFonts.rajdhani(fontSize: 13,
                        color: AppColors.textSecondary.withValues(alpha: 0.8))),
                const SizedBox(height: 10),
                Row(children: [
                  SettingsToggleChip(label: 'Ja', selected: _hasSolarThermal == true,
                      onTap: () => setState(() => _hasSolarThermal = true)),
                  const SizedBox(width: 8),
                  SettingsToggleChip(label: 'Nein', selected: _hasSolarThermal == false,
                      onTap: () => setState(() => _hasSolarThermal = false)),
                ]),
              ])),

              const SizedBox(height: 28),
              SettingsSaveButton(label: 'HAUSDATEN SPEICHERN', isBusy: _isSaving, onTap: _save),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.neu(7)),
    child: child,
  );
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;
  const _InputField({required this.controller, required this.hint,
    this.keyboardType = TextInputType.text});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(color: const Color(0xFFDFE5DA), borderRadius: BorderRadius.circular(10)),
    child: TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: GoogleFonts.rajdhani(fontSize: 16, color: AppColors.textPrimary),
      cursorColor: AppColors.green,
      decoration: InputDecoration(
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        hintText: hint,
        hintStyle: GoogleFonts.rajdhani(fontSize: 14, color: AppColors.textSecondary),
      ),
    ),
  );
}

class _SqmField extends StatelessWidget {
  final TextEditingController controller;
  const _SqmField({required this.controller});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(color: const Color(0xFFDFE5DA), borderRadius: BorderRadius.circular(10)),
    child: TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: GoogleFonts.spaceMono(fontSize: 16, color: AppColors.textPrimary),
      cursorColor: AppColors.green,
      decoration: InputDecoration(
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        hintText: '85',
        hintStyle: GoogleFonts.spaceMono(fontSize: 14, color: AppColors.textSecondary),
        suffixText: 'm²',
        suffixStyle: GoogleFonts.rajdhani(fontSize: 13, color: AppColors.textSecondary,
            fontWeight: FontWeight.w600),
      ),
    ),
  );
}

class _YearField extends StatefulWidget {
  final int? value;
  final void Function(int?) onChanged;
  const _YearField({required this.value, required this.onChanged});

  @override
  State<_YearField> createState() => _YearFieldState();
}

class _YearFieldState extends State<_YearField> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value != null ? '${widget.value}' : '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(color: const Color(0xFFDFE5DA), borderRadius: BorderRadius.circular(10)),
    child: TextField(
      controller: _ctrl,
      keyboardType: TextInputType.number,
      style: GoogleFonts.spaceMono(fontSize: 16, color: AppColors.textPrimary),
      cursorColor: AppColors.green,
      onChanged: (v) => widget.onChanged(int.tryParse(v)),
      decoration: InputDecoration(
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        hintText: '1985',
        hintStyle: GoogleFonts.spaceMono(fontSize: 14, color: AppColors.textSecondary),
      ),
    ),
  );
}

class _PersonsStepper extends StatelessWidget {
  final int? value;
  final void Function(int delta) onStep;
  const _PersonsStepper({required this.value, required this.onStep});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(color: const Color(0xFFDFE5DA), borderRadius: BorderRadius.circular(10)),
      child: Row(children: [
        _StepBtn(icon: Icons.remove, onTap: value == null ? null : () => onStep(-1)),
        Expanded(child: Center(
          child: Text(
            value == null ? '–' : '$value',
            style: value == null
                ? GoogleFonts.rajdhani(fontSize: 18, color: AppColors.textSecondary)
                : GoogleFonts.spaceMono(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
        )),
        _StepBtn(icon: Icons.add, onTap: () => onStep(1)),
      ]),
    );
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _StepBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: SizedBox(
      width: 52,
      height: 50,
      child: Icon(icon, size: 20,
          color: onTap == null ? AppColors.textSecondary.withValues(alpha: 0.3) : AppColors.textSecondary),
    ),
  );
}
