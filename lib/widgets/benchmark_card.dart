import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../database/database.dart';
import '../services/benchmark_service.dart';
import '../theme/colors.dart';

enum BenchmarkType { gas, electricity }

const _allHouseTypes = [
  'Wohnung',
  'Reihenmittelhaus',
  'Reihenendhaus',
  'Doppelhaushälfte',
  'Einfamilienhaus',
];

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

  GasBenchmarkFilters         _gasFilters  = const GasBenchmarkFilters();
  ElectricityBenchmarkFilters _elecFilters = const ElectricityBenchmarkFilters();

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final shares   = await BenchmarkService().getSharesData();
    final settings = await AppDatabase.instance.getSettings();
    if (!mounted) return;

    // Pre-select user's own house type as default
    var gasF  = _gasFilters;
    var elecF = _elecFilters;
    if (settings?.houseType != null) {
      gasF  = gasF.copyWithHouseTypes([settings!.houseType!]);
      elecF = elecF.copyWithHouseTypes([settings.houseType!]);
    }

    setState(() {
      _sharesData  = shares;
      _settings    = settings;
      _gasFilters  = gasF;
      _elecFilters = elecF;
      _initLoading = false;
    });
    if (shares) {
      BenchmarkService().uploadBenchmark(); // PLZ-Daten aktualisieren (vollständige PLZ)
      _loadResult();
    }
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
  // Chip sublabel helpers
  // ---------------------------------------------------------------------------

  String _sqmSublabel(int pct) => pct == 0 ? 'Exakt' : '±$pct %';

  String _yearSublabel(String mode) {
    if (mode == 'exact') return 'Exakt';
    return '±$mode Jahre';
  }

  String _plzSublabel(int digits) {
    switch (digits) {
      case 1:  return 'Großregion';
      case 3:  return 'Lokal';
      case 5:  return 'Eigene PLZ';
      default: return 'Regional';
    }
  }

  String? _houseTypeSublabel(List<String>? types) {
    if (types == null || types.isEmpty) return null;
    if (types.length == 1) return types.first;
    return '${types.length} Typen';
  }

  // ---------------------------------------------------------------------------
  // Bottom sheets
  // ---------------------------------------------------------------------------

  void _showSqmSheet({required bool isGas}) {
    final current = isGas ? _gasFilters.sqmRangePct : _elecFilters.sqmRangePct;
    _showSheet(
      title: 'WOHNFLÄCHE',
      explanation: 'Wie groß darf die Abweichung zu deiner Wohnfläche sein?',
      options: [
        (label: 'Exakt',    description: 'Nur gleiche Wohnfläche',     selected: current == 0),
        (label: '±10 %',    description: 'Sehr präzise',               selected: current == 10),
        (label: '±20 %',    description: 'Präzise',                    selected: current == 20),
        (label: '±30 %',    description: 'Standard',                   selected: current == 30),
        (label: '±50 %',    description: 'Tolerant',                   selected: current == 50),
      ],
      onSelect: (i) {
        final pct = [0, 10, 20, 30, 50][i];
        setState(() {
          if (isGas) {
            _gasFilters = _gasFilters.copyWith(sqmRangePct: pct, useSqm: true);
          } else {
            _elecFilters = _elecFilters.copyWith(sqmRangePct: pct, useSqm: true);
          }
        });
        _loadResult();
      },
      onDisable: () {
        setState(() {
          if (isGas) {
            _gasFilters = _gasFilters.copyWith(useSqm: false);
          } else {
            _elecFilters = _elecFilters.copyWith(useSqm: false);
          }
        });
        _loadResult();
      },
    );
  }

  void _showYearSheet() {
    final current = _gasFilters.constructionYearMode;
    _showSheet(
      title: 'BAUJAHR',
      explanation: 'Wie nah soll das Baujahr der Vergleichshaushalte an deinem sein?',
      options: [
        (label: 'Exakt',      description: 'Nur gleiches Baujahr',   selected: current == 'exact'),
        (label: '±5 Jahre',   description: 'Sehr präzise',           selected: current == '5'),
        (label: '±10 Jahre',  description: 'Präzise (Standard)',     selected: current == '10'),
        (label: '±15 Jahre',  description: 'Mittel',                 selected: current == '15'),
        (label: '±20 Jahre',  description: 'Breit',                  selected: current == '20'),
        (label: '±25 Jahre',  description: 'Sehr breit',             selected: current == '25'),
      ],
      onSelect: (i) {
        const modes = ['exact', '5', '10', '15', '20', '25'];
        setState(() => _gasFilters = _gasFilters.copyWith(constructionYearMode: modes[i]));
        _loadResult();
      },
      onDisable: () {
        setState(() => _gasFilters = _gasFilters.copyWith(useConstructionYear: false));
        _loadResult();
      },
    );
  }

  void _showPlzSheet() {
    final current = _gasFilters.plzDigits;
    _showSheet(
      title: 'KLIMAZONE',
      explanation:
          'Deine PLZ dient als Näherung für deine Klimazone. Je mehr Stellen übereinstimmen, '
          'desto enger ist der geografische Vergleichsraum – und damit ähnlicher das regionale Klima.',
      options: [
        (label: 'Großregion',   description: '1. Stelle der PLZ identisch · ~200 km Radius',          selected: current == 1),
        (label: 'Regional',     description: '1.–2. Stelle identisch · ~50 km Radius (Standard)',      selected: current == 2),
        (label: 'Lokal',        description: '1.–3. Stelle identisch · ~15 km Radius',                 selected: current == 3),
        (label: 'Eigene PLZ',   description: 'Vollständige PLZ identisch · sehr lokal',                selected: current == 5),
      ],
      onSelect: (i) {
        final digits = [1, 2, 3, 5][i];
        setState(() => _gasFilters = _gasFilters.copyWith(plzDigits: digits));
        _loadResult();
      },
      onDisable: () {
        setState(() => _gasFilters = _gasFilters.copyWith(usePlzRegion: false));
        _loadResult();
      },
    );
  }

  void _showHaustypenSheet({required bool isGas}) {
    final current = isGas ? _gasFilters.selectedHouseTypes : _elecFilters.selectedHouseTypes;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _HaustypenSheet(
        selected: current ?? [],
        accent: widget.accent,
        onApply: (types) {
          setState(() {
            // Empty selection = deactivate filter (null)
            final result = types.isEmpty ? null : types;
            if (isGas) {
              _gasFilters = _gasFilters.copyWithHouseTypes(result);
            } else {
              _elecFilters = _elecFilters.copyWithHouseTypes(result);
            }
          });
          _loadResult();
        },
        onDisable: () {
          setState(() {
            if (isGas) {
              _gasFilters = _gasFilters.copyWithHouseTypes(null);
            } else {
              _elecFilters = _elecFilters.copyWithHouseTypes(null);
            }
          });
          _loadResult();
        },
      ),
    );
  }

  void _showSheet({
    required String title,
    required String explanation,
    required List<({String label, String description, bool selected})> options,
    required ValueChanged<int> onSelect,
    required VoidCallback onDisable,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _FilterSheet(
        title: title,
        explanation: explanation,
        options: options,
        onSelect: onSelect,
        onDisable: onDisable,
        accent: widget.accent,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Chip lists
  // ---------------------------------------------------------------------------

  List<_Chip> _gasChips() {
    final s = _settings;
    if (s == null) return [];
    final houseActive = (_gasFilters.selectedHouseTypes?.isNotEmpty ?? false);
    return [
      if (s.houseType != null)
        _Chip(
          'Haustyp', houseActive,
          sublabel: houseActive ? _houseTypeSublabel(_gasFilters.selectedHouseTypes) : null,
          onTap: () {
            if (!houseActive) {
              // Enable with default (user's own type)
              final def = s.houseType != null ? [s.houseType!] : <String>[];
              setState(() => _gasFilters = _gasFilters.copyWithHouseTypes(def.isEmpty ? null : def));
              _loadResult();
            } else {
              _showHaustypenSheet(isGas: true);
            }
          },
        ),
      if (s.squareMeters != null)
        _Chip(
          'Wohnfläche', _gasFilters.useSqm,
          sublabel: _gasFilters.useSqm ? _sqmSublabel(_gasFilters.sqmRangePct) : null,
          onTap: () {
            if (!_gasFilters.useSqm) {
              setState(() => _gasFilters = _gasFilters.copyWith(useSqm: true));
              _loadResult();
            } else {
              _showSqmSheet(isGas: true);
            }
          },
        ),
      if (s.hasSolarThermal != null)
        _Chip('Solarthermie', _gasFilters.useSolarThermal, onTap: () {
          setState(() => _gasFilters = _gasFilters.copyWith(useSolarThermal: !_gasFilters.useSolarThermal));
          _loadResult();
        }),
      if (s.constructionYear != null)
        _Chip(
          'Baujahr', _gasFilters.useConstructionYear,
          sublabel: _gasFilters.useConstructionYear ? _yearSublabel(_gasFilters.constructionYearMode) : null,
          onTap: () {
            if (!_gasFilters.useConstructionYear) {
              setState(() => _gasFilters = _gasFilters.copyWith(useConstructionYear: true));
              _loadResult();
            } else {
              _showYearSheet();
            }
          },
        ),
      if (s.isInsulated != null)
        _Chip('Dämmung', _gasFilters.useIsInsulated, onTap: () {
          setState(() => _gasFilters = _gasFilters.copyWith(useIsInsulated: !_gasFilters.useIsInsulated));
          _loadResult();
        }),
      if (s.locationPlz != null)
        _Chip(
          'Klimazone', _gasFilters.usePlzRegion,
          sublabel: _gasFilters.usePlzRegion ? _plzSublabel(_gasFilters.plzDigits) : null,
          onTap: () {
            if (!_gasFilters.usePlzRegion) {
              setState(() => _gasFilters = _gasFilters.copyWith(usePlzRegion: true));
              _loadResult();
            } else {
              _showPlzSheet();
            }
          },
        ),
    ];
  }

  List<_Chip> _elecChips() {
    final s = _settings;
    if (s == null) return [];
    final houseActive = (_elecFilters.selectedHouseTypes?.isNotEmpty ?? false);
    return [
      if (s.numberOfPersons != null)
        _Chip('Personenanzahl', _elecFilters.usePersons, onTap: () {
          setState(() => _elecFilters = _elecFilters.copyWith(usePersons: !_elecFilters.usePersons));
          _loadResult();
        }),
      if (s.hasPv != null)
        _Chip('PV-Anlage', _elecFilters.usePv, onTap: () {
          setState(() => _elecFilters = _elecFilters.copyWith(usePv: !_elecFilters.usePv));
          _loadResult();
        }),
      if (s.squareMeters != null)
        _Chip(
          'Wohnfläche', _elecFilters.useSqm,
          sublabel: _elecFilters.useSqm ? _sqmSublabel(_elecFilters.sqmRangePct) : null,
          onTap: () {
            if (!_elecFilters.useSqm) {
              setState(() => _elecFilters = _elecFilters.copyWith(useSqm: true));
              _loadResult();
            } else {
              _showSqmSheet(isGas: false);
            }
          },
        ),
      if (s.houseType != null)
        _Chip(
          'Haustyp', houseActive,
          sublabel: houseActive ? _houseTypeSublabel(_elecFilters.selectedHouseTypes) : null,
          onTap: () {
            if (!houseActive) {
              final def = s.houseType != null ? [s.houseType!] : <String>[];
              setState(() => _elecFilters = _elecFilters.copyWithHouseTypes(def.isEmpty ? null : def));
              _loadResult();
            } else {
              _showHaustypenSheet(isGas: false);
            }
          },
        ),
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
        onTap: c.onTap,
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
            if (c.active && c.sublabel != null) ...[
              Text(' · ${c.sublabel}', style: GoogleFonts.rajdhani(
                fontSize: 11, fontWeight: FontWeight.w600,
                color: widget.accent.withValues(alpha: 0.75),
              )),
              const SizedBox(width: 4),
              Icon(Icons.tune_rounded, size: 10, color: widget.accent),
            ] else if (c.active) ...[
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
          'Filter deaktivieren oder Reichweite vergrößern, um den Vergleichspool zu erweitern.',
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
          TextSpan(text: ' als $pct % der Vergleichshaushalte.'),
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
              Positioned(
                left: 0, right: 0, top: 16,
                child: Container(height: 6, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(3))),
              ),
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
              Positioned(
                left: (medianFrac * w).clamp(1, w - 2) - 1,
                top: 10,
                child: Container(width: 2, height: 18, color: AppColors.textSecondary.withValues(alpha: 0.35)),
              ),
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
// Chip model
// ---------------------------------------------------------------------------

class _Chip {
  final String label;
  final String? sublabel;
  final bool active;
  final VoidCallback onTap;
  const _Chip(this.label, this.active, {this.sublabel, required this.onTap});
}

// ---------------------------------------------------------------------------
// Haustyp multi-select sheet
// ---------------------------------------------------------------------------

class _HaustypenSheet extends StatefulWidget {
  final List<String> selected;
  final Color accent;
  final ValueChanged<List<String>> onApply;
  final VoidCallback onDisable;

  const _HaustypenSheet({
    required this.selected,
    required this.accent,
    required this.onApply,
    required this.onDisable,
  });

  @override
  State<_HaustypenSheet> createState() => _HaustypenSheetState();
}

class _HaustypenSheetState extends State<_HaustypenSheet> {
  late Set<String> _checked;

  @override
  void initState() {
    super.initState();
    _checked = Set.from(widget.selected);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final maxHeight = MediaQuery.of(context).size.height * 0.85;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'HAUSTYP',
              style: GoogleFonts.spaceMono(
                fontSize: 11, fontWeight: FontWeight.w700,
                letterSpacing: 2, color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Wähle die Haustypen, mit denen du verglichen werden möchtest. '
              'Standardmäßig ist nur dein eigener Haustyp ausgewählt.',
              style: GoogleFonts.rajdhani(
                fontSize: 13, color: AppColors.textSecondary, height: 1.45,
              ),
            ),
            const SizedBox(height: 16),
            ..._allHouseTypes.map((type) {
              final isChecked = _checked.contains(type);
              return GestureDetector(
                onTap: () => setState(() {
                  if (isChecked) { _checked.remove(type); } else { _checked.add(type); }
                }),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 140),
                      width: 20, height: 20,
                      decoration: BoxDecoration(
                        color: isChecked ? widget.accent : Colors.transparent,
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: isChecked ? widget.accent : AppColors.border,
                          width: 1.5,
                        ),
                      ),
                      child: isChecked
                          ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Text(
                      type,
                      style: GoogleFonts.rajdhani(
                        fontSize: 15, fontWeight: FontWeight.w700,
                        color: isChecked ? AppColors.textPrimary : AppColors.textSecondary,
                      ),
                    ),
                  ]),
                ),
              );
            }),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                widget.onApply(_checked.toList());
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  color: widget.accent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'ÜBERNEHMEN',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.spaceMono(
                    fontSize: 11, fontWeight: FontWeight.w700,
                    color: Colors.white, letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(height: 1, color: AppColors.border),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                widget.onDisable();
              },
              child: Text(
                'Filter deaktivieren',
                style: GoogleFonts.rajdhani(
                  fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.error,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Single-select filter bottom sheet
// ---------------------------------------------------------------------------

class _FilterSheet extends StatelessWidget {
  final String title;
  final String explanation;
  final List<({String label, String description, bool selected})> options;
  final ValueChanged<int> onSelect;
  final VoidCallback onDisable;
  final Color accent;

  const _FilterSheet({
    required this.title,
    required this.explanation,
    required this.options,
    required this.onSelect,
    required this.onDisable,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final maxHeight = MediaQuery.of(context).size.height * 0.85;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.spaceMono(
                fontSize: 11, fontWeight: FontWeight.w700,
                letterSpacing: 2, color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              explanation,
              style: GoogleFonts.rajdhani(
                fontSize: 13, color: AppColors.textSecondary, height: 1.45,
              ),
            ),
            const SizedBox(height: 20),
            ...options.asMap().entries.map((e) {
              final opt = e.value;
              return GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  onSelect(e.key);
                },
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(children: [
                    Container(
                      width: 20, height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: opt.selected ? accent : AppColors.border,
                          width: opt.selected ? 5 : 2,
                        ),
                        color: AppColors.background,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            opt.label,
                            style: GoogleFonts.rajdhani(
                              fontSize: 15, fontWeight: FontWeight.w700,
                              color: opt.selected ? AppColors.textPrimary : AppColors.textSecondary,
                            ),
                          ),
                          if (opt.description.isNotEmpty)
                            Text(
                              opt.description,
                              style: GoogleFonts.rajdhani(
                                fontSize: 12,
                                color: AppColors.textSecondary.withValues(alpha: 0.7),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ]),
                ),
              );
            }),
            const SizedBox(height: 16),
            Container(height: 1, color: AppColors.border),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                onDisable();
              },
              child: Text(
                'Filter deaktivieren',
                style: GoogleFonts.rajdhani(
                  fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.error,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
