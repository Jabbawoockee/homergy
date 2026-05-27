import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../database/database.dart';
import '../theme/colors.dart';

class CostDetailScreen extends StatefulWidget {
  const CostDetailScreen({super.key});

  @override
  State<CostDetailScreen> createState() => _CostDetailScreenState();
}

class _CostDetailScreenState extends State<CostDetailScreen> {
  late Future<_CostDetailData> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadData();
  }

  Future<_CostDetailData> _loadData() async {
    final allContracts = await AppDatabase.instance.getAllContracts();
    if (allContracts.isEmpty) {
      return const _CostDetailData(
          months: [], hasContracts: false, providerName: '', displayStart: null);
    }

    // Current provider = displayName of the contract with the latest validFrom
    final latestContract = allContracts.last;
    final providerName = latestContract.displayName;

    // All price entries for this provider (ascending by validFrom — already sorted)
    final providerContracts =
        allContracts.where((c) => c.displayName == providerName).toList();

    // Show months from the earliest entry of this provider
    final displayStart =
        DateTime.fromMillisecondsSinceEpoch(providerContracts.first.validFrom);

    // All readings sorted ascending
    final rawReadings = await AppDatabase.instance.watchAllReadings().first;
    final readings = List<MeterReading>.from(rawReadings)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Readings that fall within (or after) the display start
    final relevant =
        readings.where((r) => !r.timestamp.isBefore(displayStart)).toList();

    // Anchor: the last reading recorded strictly before displayStart
    final beforeStart =
        readings.where((r) => r.timestamp.isBefore(displayStart)).toList();
    double? rollingAnchor =
        beforeStart.isNotEmpty ? beforeStart.last.value : null;

    if (relevant.isEmpty) {
      return _CostDetailData(
        months: [],
        hasContracts: true,
        providerName: providerName,
        displayStart: displayStart,
      );
    }

    // Max and min reading value per (year, month) — for delta and fallback anchor
    final maxByYM = <String, double>{};
    final minByYM = <String, double>{};
    for (final r in relevant) {
      final k = '${r.timestamp.year}-${r.timestamp.month}';
      final exMax = maxByYM[k];
      if (exMax == null || r.value > exMax) maxByYM[k] = r.value;
      final exMin = minByYM[k];
      if (exMin == null || r.value < exMin) minByYM[k] = r.value;
    }

    final now = DateTime.now();
    final months = <_MonthData>[];

    // Iterate every month from displayStart to now (handles multi-year spans)
    int year = displayStart.year;
    int month = displayStart.month;

    while (year < now.year || (year == now.year && month <= now.month)) {
      final k = '$year-$month';
      final monthMax = maxByYM[k];

      if (monthMax != null) {
        double? prevMax = rollingAnchor;

        if (prevMax == null) {
          // No prior anchor: use the minimum reading within this month so we
          // can at least compute within-month consumption for the first entry.
          final monthMin = minByYM[k];
          if (monthMin != null && monthMin < monthMax) {
            prevMax = monthMin;
          }
        }

        if (prevMax != null) {
          // Find which contract was active at the end of this month
          final lastDay = month < 12
              ? DateTime(year, month + 1, 0)
              : DateTime(year, 12, 31);
          final contract =
              await AppDatabase.instance.getContractForDate(lastDay) ??
                  latestContract;

          final factor =
              (contract.brennwert > 0 && contract.zustandszahl > 0)
                  ? contract.brennwert * contract.zustandszahl
                  : 10.55;
          final consumptionM3 =
              (monthMax - prevMax).clamp(0.0, double.infinity);
          final consumptionKwh = consumptionM3 * factor;
          final gasCost = consumptionKwh * contract.pricePerKwh;

          months.add(_MonthData(
            year: year,
            month: month,
            consumptionM3: consumptionM3,
            consumptionKwh: consumptionKwh,
            gasCost: gasCost,
            basePrice: contract.monthlyBasePrice,
            pricePerKwh: contract.pricePerKwh,
            providerName: contract.displayName,
            factorIsEstimated:
                !(contract.brennwert > 0 && contract.zustandszahl > 0),
          ));
        }

        // This month's max becomes the anchor for the following month
        rollingAnchor = monthMax;
      }

      // Advance to next month
      month++;
      if (month > 12) {
        month = 1;
        year++;
      }
    }

    return _CostDetailData(
      months: months.reversed.toList(),
      hasContracts: true,
      providerName: providerName,
      displayStart: displayStart,
    );
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Static header (back + title)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: AppColors.textSecondary, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'KOSTENÜBERSICHT',
                    style: GoogleFonts.spaceMono(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.amber,
                      letterSpacing: 3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: FutureBuilder<_CostDetailData>(
                future: _future,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.amber, strokeWidth: 2));
                  }
                  final data = snapshot.data!;

                  if (!data.hasContracts) return _noSettingsView();
                  if (data.months.isEmpty) return _emptyView(data);
                  return _buildContent(data);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(_CostDetailData data) {
    final totalGas = data.months.fold(0.0, (s, m) => s + m.gasCost);
    final totalBase = data.months.fold(0.0, (s, m) => s + m.basePrice);
    final grandTotal = totalGas + totalBase;
    final eurFmt = NumberFormat.currency(locale: 'de_DE', symbol: '€');
    final monthNames = [
      '', 'Januar', 'Februar', 'März', 'April', 'Mai', 'Juni',
      'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember',
    ];
    final anyEstimated = data.months.any((m) => m.factorIsEstimated);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Provider + date-range info
          Row(
            children: [
              const Icon(Icons.business_rounded,
                  size: 14, color: AppColors.amber),
              const SizedBox(width: 6),
              Text(
                data.providerName,
                style: GoogleFonts.rajdhani(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.amber,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'seit ${_fmtDate(data.displayStart!)}',
                style: GoogleFonts.rajdhani(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Monthly cards
          for (final month in data.months) ...[
            _MonthCard(
              month: month,
              monthName: monthNames[month.month],
              eurFmt: eurFmt,
            ),
            const SizedBox(height: 12),
          ],

          const SizedBox(height: 4),

          // Grand total
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.amber.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: AppColors.amber.withOpacity(0.4), width: 1.5),
            ),
            child: Column(
              children: [
                _TotalRow(
                  label: 'Gaskosten gesamt',
                  value: eurFmt.format(totalGas),
                  bold: false,
                ),
                const SizedBox(height: 8),
                _TotalRow(
                  label: 'Grundpreis (${data.months.length} Mon.)',
                  value: eurFmt.format(totalBase),
                  bold: false,
                ),
                const SizedBox(height: 12),
                Container(
                    height: 1, color: AppColors.amber.withOpacity(0.4)),
                const SizedBox(height: 12),
                _TotalRow(
                  label: 'GESAMT',
                  value: eurFmt.format(grandTotal),
                  bold: true,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Center(
            child: Text(
              anyEstimated
                  ? 'Teile der Berechnung nutzen die Faustformel (1 m³ ≈ 10,55 kWh)'
                  : 'Berechnung basiert auf deinen Vertragsdaten',
              style: GoogleFonts.rajdhani(
                fontSize: 12,
                color: AppColors.textSecondary.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _noSettingsView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.settings_outlined,
                size: 48, color: AppColors.textSecondary.withOpacity(0.4)),
            const SizedBox(height: 16),
            Text(
              'Preise noch nicht konfiguriert',
              style: GoogleFonts.rajdhani(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Bitte trage in den Einstellungen unter "Gaspreis" den Lieferanten, den Preis pro kWh, den Grundpreis und das Startdatum ein.',
              style: GoogleFonts.rajdhani(
                fontSize: 14,
                color: AppColors.textSecondary.withOpacity(0.7),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyView(_CostDetailData data) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bar_chart_outlined,
                size: 48, color: AppColors.textSecondary.withOpacity(0.4)),
            const SizedBox(height: 16),
            Text(
              'Noch keine Verbrauchsdaten',
              style: GoogleFonts.rajdhani(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            if (data.displayStart != null) ...[
              const SizedBox(height: 8),
              Text(
                'Sobald Ablesungen seit dem ${_fmtDate(data.displayStart!)} vorliegen, erscheint hier die Monatsübersicht.',
                style: GoogleFonts.rajdhani(
                  fontSize: 14,
                  color: AppColors.textSecondary.withOpacity(0.7),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Data models
// ---------------------------------------------------------------------------

class _CostDetailData {
  final List<_MonthData> months;
  final bool hasContracts;
  final String providerName;
  final DateTime? displayStart;

  const _CostDetailData({
    required this.months,
    required this.hasContracts,
    required this.providerName,
    required this.displayStart,
  });
}

class _MonthData {
  final int year;
  final int month;
  final double consumptionM3;
  final double consumptionKwh;
  final double gasCost;
  final double basePrice;
  final double pricePerKwh;
  final String providerName;
  final bool factorIsEstimated;

  double get total => gasCost + basePrice;

  const _MonthData({
    required this.year,
    required this.month,
    required this.consumptionM3,
    required this.consumptionKwh,
    required this.gasCost,
    required this.basePrice,
    required this.pricePerKwh,
    required this.providerName,
    required this.factorIsEstimated,
  });
}

// ---------------------------------------------------------------------------
// Widgets
// ---------------------------------------------------------------------------

class _MonthCard extends StatefulWidget {
  final _MonthData month;
  final String monthName;
  final NumberFormat eurFmt;

  const _MonthCard({
    required this.month,
    required this.monthName,
    required this.eurFmt,
  });

  @override
  State<_MonthCard> createState() => _MonthCardState();
}

class _MonthCardState extends State<_MonthCard> {
  bool _showCalc = false;

  @override
  Widget build(BuildContext context) {
    final month = widget.month;
    final eurFmt = widget.eurFmt;
    final monthName = widget.monthName;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$monthName ${month.year}'.toUpperCase(),
                style: GoogleFonts.spaceMono(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.amber,
                  letterSpacing: 2,
                ),
              ),
              Text(
                month.providerName,
                style: GoogleFonts.rajdhani(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          _DetailRow(
            label: 'Verbrauch',
            value: '${month.consumptionM3.toStringAsFixed(3)} m³',
          ),
          const SizedBox(height: 8),
          _DetailRow(
            label: 'Energie',
            value: '${month.consumptionKwh.toStringAsFixed(2)} kWh',
            valueColor: AppColors.textSecondary,
          ),
          const SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _showCalc = !_showCalc),
                    child: Row(
                      children: [
                        Text(
                          'Gaskosten',
                          style: GoogleFonts.rajdhani(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Icon(
                          _showCalc
                              ? Icons.info
                              : Icons.info_outline,
                          size: 14,
                          color: _showCalc
                              ? AppColors.amber
                              : AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    eurFmt.format(month.gasCost),
                    style: GoogleFonts.spaceMono(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.amber,
                    ),
                  ),
                ],
              ),
              if (_showCalc) ...[
                const SizedBox(height: 4),
                Text(
                  '${month.consumptionKwh.toStringAsFixed(2)} kWh  ×  ${(month.pricePerKwh * 100).toStringAsFixed(4)} ct/kWh',
                  style: GoogleFonts.spaceMono(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          _DetailRow(
            label: 'Grundpreis',
            value: eurFmt.format(month.basePrice),
          ),

          const SizedBox(height: 12),
          Container(height: 1, color: AppColors.border),
          const SizedBox(height: 12),

          _DetailRow(
            label: 'Gesamt',
            value: eurFmt.format(month.total),
            bold: true,
            valueColor: AppColors.amber,
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;

  const _DetailRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.rajdhani(
            fontSize: bold ? 15 : 14,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
            color: AppColors.textPrimary,
            letterSpacing: 0.3,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.spaceMono(
            fontSize: bold ? 15 : 13,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;

  const _TotalRow({
    required this.label,
    required this.value,
    required this.bold,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.rajdhani(
            fontSize: bold ? 16 : 14,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            color: bold ? AppColors.amber : AppColors.textSecondary,
            letterSpacing: bold ? 1 : 0.3,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.spaceMono(
            fontSize: bold ? 18 : 14,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
            color: bold ? AppColors.amber : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
