import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../database/database.dart';
import '../services/benchmark_service.dart';
import '../theme/colors.dart';

enum BenchmarkType { gas, electricity }

class BenchmarkCard extends StatefulWidget {
  final BenchmarkType type;
  final Color accent;

  const BenchmarkCard({super.key, required this.type, required this.accent});

  @override
  State<BenchmarkCard> createState() => _BenchmarkCardState();
}

class _BenchmarkCardState extends State<BenchmarkCard> {
  bool _sharesData    = false;
  bool _initLoading   = true;
  bool _resultLoading = false;
  AppSetting? _settings;
  BenchmarkResult? _result;

  GasBenchmarkFilters          _gasFilters  = const GasBenchmarkFilters();
  ElectricityBenchmarkFilters  _elecFilters = const ElectricityBenchmarkFilters();

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final shares   = await BenchmarkService().getSharesData();
    final settings = await AppDatabase.instance.getSettings();
    if (!mounted) return;
    setState(() { _sharesData = shares; _settings = settings; _initLoading = false; });
    if (shares) _loadResult();
  }

  Future<void> _loadResult() async {
    if (!mounted) return;
    setState(() => _resultLoading = true);
    BenchmarkResult? result;
    if (widget.type == BenchmarkType.gas) {
      result = await BenchmarkService().getGasBenchmark(_gasFilters);
    } else {
      result = await BenchmarkService().getElectricityBenchmark(_elecFilters);
    }
    if (!mounted) return;
    setState(() { _result = result; _resultLoading = false; });
  }

  Future<void> _enableSharing() async {
    setState(() => _initLoading = true);
    await BenchmarkService().setSharesData(true);
    final settings = await AppDatabase.instance.getSettings();
    if (!mounted) return;
    setState(() { _sharesData = true; _settings = settings; _initLoading = false; });
    _loadResult();
  }

  // ---------------------------------------------------------------------------
  // Chip lists
  // ---------------------------------------------------------------------------

  List<_Chip> _gasChips() {
    final s = _settings;
    if (s == null) return [];
    return [
      if (s.houseType != null)      _Chip('Haustyp',       _gasFilters.useHouseType,       () { setState(() => _gasFilters = _gasFilters.copyWith(useHouseType:       !_gasFilters.useHouseType));       _loadResult(); }),
      if (s.squareMeters != null)   _Chip('Wohnfläche',    _gasFilters.useSqm,             () { setState(() => _gasFilters = _gasFilters.copyWith(useSqm:             !_gasFilters.useSqm));             _loadResult(); }),
      if (s.hasSolarThermal != null)_Chip('Solarthermie',  _gasFilters.useSolarThermal,    () { setState(() => _gasFilters = _gasFilters.copyWith(useSolarThermal:    !_gasFilters.useSolarThermal));    _loadResult(); }),
      if (s.constructionYear != null)_Chip('Baujahr',      _gasFilters.useConstructionYear,() { setState(() => _gasFilters = _gasFilters.copyWith(useConstructionYear: !_gasFilters.useConstructionYear)); _loadResult(); }),
      if (s.isInsulated != null)    _Chip('Dämmung',       _gasFilters.useIsInsulated,     () { setState(() => _gasFilters = _gasFilters.copyWith(useIsInsulated:     !_gasFilters.useIsInsulated));     _loadResult(); }),
      if (s.locationPlz != null)    _Chip('Region',        _gasFilters.usePlzRegion,       () { setState(() => _gasFilters = _gasFilters.copyWith(usePlzRegion:       !_gasFilters.usePlzRegion));       _loadResult(); }),
    ];
  }

  List<_Chip> _elecChips() {
    final s = _settings;
    if (s == null) return [];
    return [
      if (s.numberOfPersons != null)_Chip('Personenanzahl',_elecFilters.usePersons,        () { setState(() => _elecFilters = _elecFilters.copyWith(usePersons:   !_elecFilters.usePersons));   _loadResult(); }),
      if (s.hasPv != null)          _Chip('PV-Anlage',     _elecFilters.usePv,             () { setState(() => _elecFilters = _elecFilters.copyWith(usePv:        !_elecFilters.usePv));        _loadResult(); }),
      if (s.squareMeters != null)   _Chip('Wohnfläche',    _elecFilters.useSqm,            () { setState(() => _elecFilters = _elecFilters.copyWith(useSqm:       !_elecFilters.useSqm));       _loadResult(); }),
      if (s.houseType != null)      _Chip('Haustyp',       _elecFilters.useHouseType,      () { setState(() => _elecFilters = _elecFilters.copyWith(useHouseType: !_elecFilters.useHouseType)); _loadResult(); }),
    ];
  }

  List<String> _missingGas() {
    final s = _settings;
    if (s == null) return [];
    return [
      if (s.houseType == null)       'Haustyp',
      if (s.squareMeters == null)    'Wohnfläche',
      if (s.hasSolarThermal == null) 'Solarthermie',
      if (s.constructionYear == null)'Baujahr',
      if (s.isInsulated == null)     'Dämmung',
      if (s.locationPlz == null)     'Standort',
    ];
  }

  List<String> _missingElec() {
    final s = _settings;
    if (s == null) return [];
    return [
      if (s.numberOfPersons == null) 'Personenanzahl',
      if (s.hasPv == null)           'PV-Anlage',
      if (s.squareMeters == null)    'Wohnfläche',
      if (s.houseType == null)       'Haustyp',
    ];
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (_initLoading) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.neu(7),
      ),
      child: !_sharesData ? _buildLocked() : _buildUnlocked(),
    );
  }

  Widget _buildLocked() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel(),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.lock_outline_rounded, size: 26, color: AppColors.textSecondary.withValues(alpha: 0.35)),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'Teile deinen Verbrauch anonym und erfahre, wie du im Vergleich zu ähnlichen Haushalten abschneidest.',
                style: GoogleFonts.rajdhani(fontSize: 14, color: AppColors.textSecondary, height: 1.5, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: _enableSharing,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(color: widget.accent, borderRadius: BorderRadius.circular(10)),
            child: Text(
              'DATEN FREIGEBEN',
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceMono(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUnlocked() {
    final chips   = widget.type == BenchmarkType.gas ? _gasChips() : _elecChips();
    final missing = widget.type == BenchmarkType.gas ? _missingGas() : _missingElec();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel(),
        if (chips.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildChips(chips),
        ],
        const SizedBox(height: 16),
        if (_resultLoading)
          const Center(child: Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.green)),
          ))
        else if (_result == null)
          _buildNoResult()
        else
          _buildResult(_result!),
        if (missing.isNotEmpty) _buildFootnote(missing),
      ],
    );
  }

  Widget _sectionLabel() {
    return Row(children: [
      Icon(Icons.compare_arrows_rounded, size: 15, color: widget.accent),
      const SizedBox(width: 8),
      Text('VERGLEICH', style: GoogleFonts.spaceMono(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 2)),
    ]);
  }

  Widget _buildChips(List<_Chip> chips) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: chips.map((c) => GestureDetector(
        onTap: c.onToggle,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: c.active ? widget.accent.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: c.active ? widget.accent : AppColors.border, width: 1),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(c.label, style: GoogleFonts.rajdhani(
              fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.3,
              color: c.active ? widget.accent : AppColors.textSecondary,
            )),
            if (c.active) ...[
              const SizedBox(width: 4),
              Icon(Icons.check_rounded, size: 11, color: widget.accent),
            ],
          ]),
        ),
      )).toList(),
    );
  }

  Widget _buildNoResult() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(children: [
        Icon(Icons.group_outlined, size: 30, color: AppColors.textSecondary.withValues(alpha: 0.35)),
        const SizedBox(height: 10),
        Text(
          'Noch zu wenige Nutzer für einen Vergleich',
          style: GoogleFonts.rajdhani(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          'Filter deaktivieren, um den Vergleichspool zu vergrößern.',
          style: GoogleFonts.rajdhani(fontSize: 12, color: AppColors.textSecondary.withValues(alpha: 0.65), height: 1.4),
          textAlign: TextAlign.center,
        ),
      ]),
    );
  }

  Widget _buildResult(BenchmarkResult r) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRangeBar(r),
        const SizedBox(height: 14),
        if (r.userVal != null && r.userPercentile != null)
          _buildPercentileChip(r)
        else if (r.userVal == null)
          Text(
            'Noch nicht genügend Messwerte für eine persönliche Einordnung.',
            style: GoogleFonts.rajdhani(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
          ),
        const SizedBox(height: 8),
        Text(
          'Basierend auf ${r.count} ${r.count == 1 ? 'Haushalt' : 'Haushalten'}',
          style: GoogleFonts.rajdhani(fontSize: 11, color: AppColors.textSecondary.withValues(alpha: 0.6), fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildPercentileChip(BenchmarkResult r) {
    final p           = r.userPercentile!;
    final isEfficient = p >= 50;
    final pct         = isEfficient ? p : 100 - p;
    final chipColor   = isEfficient ? widget.accent : AppColors.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: chipColor.withValues(alpha: 0.2), width: 1),
      ),
      child: RichText(text: TextSpan(
        style: GoogleFonts.rajdhani(fontSize: 14, color: AppColors.textPrimary, height: 1.4, fontWeight: FontWeight.w500),
        children: [
          const TextSpan(text: 'Du verbrauchst '),
          TextSpan(text: isEfficient ? 'weniger' : 'mehr', style: TextStyle(fontWeight: FontWeight.w700, color: chipColor)),
          TextSpan(text: ' als $pct % der Vergleichshaushalte.'),
        ],
      )),
    );
  }

  Widget _buildRangeBar(BenchmarkResult r) {
    final range      = r.maxVal - r.minVal;
    final userFrac   = (r.userVal != null && range > 0)
        ? ((r.userVal! - r.minVal) / range).clamp(0.0, 1.0)
        : null;
    final medianFrac = range > 0
        ? ((r.medianVal - r.minVal) / range).clamp(0.0, 1.0)
        : 0.5;
    const markerD    = 20.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (r.userVal != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              'Du: ${r.userVal!.round()} kWh/Mon.',
              style: GoogleFonts.spaceMono(fontSize: 10, fontWeight: FontWeight.w700, color: widget.accent),
            ),
          ),
        SizedBox(
          height: 38,
          child: LayoutBuilder(builder: (ctx, box) {
            final w = box.maxWidth;
            return Stack(alignment: Alignment.center, children: [
              // Track
              Positioned(
                left: 0, right: 0, top: 16,
                child: Container(height: 6, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(3))),
              ),
              // Filled portion up to user
              if (userFrac != null)
                Positioned(
                  left: 0, top: 16,
                  child: Container(
                    width: (userFrac * w).clamp(0.0, w),
                    height: 6,
                    decoration: BoxDecoration(
                      color: widget.accent.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              // Median tick
              Positioned(
                left: (medianFrac * w).clamp(1, w - 2) - 1,
                top: 10,
                child: Container(width: 2, height: 18, color: AppColors.textSecondary.withValues(alpha: 0.35)),
              ),
              // User dot
              if (userFrac != null)
                Positioned(
                  left: (userFrac * w - markerD / 2).clamp(0, w - markerD),
                  child: Container(
                    width: markerD, height: markerD,
                    decoration: BoxDecoration(
                      color: widget.accent,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: widget.accent.withValues(alpha: 0.4), blurRadius: 8, spreadRadius: 1)],
                    ),
                  ),
                ),
            ]);
          }),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${r.minVal.round()}', style: GoogleFonts.spaceMono(fontSize: 9, color: AppColors.textSecondary)),
            Text('Ø ${r.medianVal.round()} kWh/Mon.', style: GoogleFonts.spaceMono(fontSize: 9, color: AppColors.textSecondary)),
            Text('${r.maxVal.round()}', style: GoogleFonts.spaceMono(fontSize: 9, color: AppColors.textSecondary)),
          ],
        ),
      ],
    );
  }

  Widget _buildFootnote(List<String> missing) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 12, color: AppColors.textSecondary.withValues(alpha: 0.55)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Nicht berücksichtigt: ${missing.join(', ')} – in den Hausdaten ergänzen für einen genaueren Vergleich.',
              style: GoogleFonts.rajdhani(fontSize: 11, color: AppColors.textSecondary.withValues(alpha: 0.6), height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Internal model
// ---------------------------------------------------------------------------

class _Chip {
  final String label;
  final bool active;
  final VoidCallback onToggle;
  const _Chip(this.label, this.active, this.onToggle);
}
