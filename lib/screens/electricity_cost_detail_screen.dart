import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../database/database.dart';
import '../theme/colors.dart';

class ElectricityCostDetailScreen extends StatefulWidget {
  const ElectricityCostDetailScreen({super.key});

  @override
  State<ElectricityCostDetailScreen> createState() =>
      _ElectricityCostDetailScreenState();
}

class _ElectricityCostDetailScreenState
    extends State<ElectricityCostDetailScreen> {
  late Future<_CostData> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadData();
  }

  Future<_CostData> _loadData() async {
    final allContracts = await AppDatabase.instance.getAllElectricityContracts();
    if (allContracts.isEmpty) {
      return const _CostData(months: [], hasContracts: false, providerName: '', displayStart: null);
    }

    final latestContract = allContracts.last;
    final providerName = latestContract.displayName;
    final providerContracts =
        allContracts.where((c) => c.displayName == providerName).toList();
    final displayStart =
        DateTime.fromMillisecondsSinceEpoch(providerContracts.first.validFrom);

    final rawReadings =
        await AppDatabase.instance.watchAllElectricityReadings().first;
    final readings = List<ElectricityReading>.from(rawReadings)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final relevant =
        readings.where((r) => !r.timestamp.isBefore(displayStart)).toList();
    final beforeStart =
        readings.where((r) => r.timestamp.isBefore(displayStart)).toList();
    double? rollingAnchor =
        beforeStart.isNotEmpty ? beforeStart.last.value : null;

    if (relevant.isEmpty) {
      return _CostData(months: [], hasContracts: true, providerName: providerName, displayStart: displayStart);
    }

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
    int year = displayStart.year;
    int month = displayStart.month;

    while (year < now.year || (year == now.year && month <= now.month)) {
      final k = '$year-$month';
      final monthMax = maxByYM[k];

      if (monthMax != null) {
        double? prevMax = rollingAnchor;
        if (prevMax == null) {
          final monthMin = minByYM[k];
          if (monthMin != null && monthMin < monthMax) prevMax = monthMin;
        }

        if (prevMax != null) {
          final lastDay = month < 12
              ? DateTime(year, month + 1, 0)
              : DateTime(year, 12, 31);
          final contract = allContracts.lastWhere(
            (c) => DateTime.fromMillisecondsSinceEpoch(c.validFrom)
                .isBefore(lastDay),
            orElse: () => latestContract,
          );

          final consumptionKwh = (monthMax - prevMax).clamp(0.0, double.infinity);
          final elecCost = consumptionKwh * contract.pricePerKwh;

          months.add(_MonthData(
            year: year,
            month: month,
            consumptionKwh: consumptionKwh,
            elecCost: elecCost,
            basePrice: contract.monthlyBasePrice,
            pricePerKwh: contract.pricePerKwh,
            providerName: contract.displayName,
          ));
        }
        rollingAnchor = monthMax;
      }

      month++;
      if (month > 12) { month = 1; year++; }
    }

    return _CostData(
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
                    'STROMKOSTEN',
                    style: GoogleFonts.spaceMono(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.greenDark,
                      letterSpacing: 3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: FutureBuilder<_CostData>(
                future: _future,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.green, strokeWidth: 2));
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

  Widget _buildContent(_CostData data) {
    final totalElec = data.months.fold(0.0, (s, m) => s + m.elecCost);
    final totalBase = data.months.fold(0.0, (s, m) => s + m.basePrice);
    final grandTotal = totalElec + totalBase;
    final eurFmt = NumberFormat.currency(locale: 'de_DE', symbol: '€');
    const monthNames = [
      '', 'Januar', 'Februar', 'März', 'April', 'Mai', 'Juni',
      'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember',
    ];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.business_rounded, size: 14, color: AppColors.amber),
              const SizedBox(width: 6),
              Text(data.providerName,
                  style: GoogleFonts.rajdhani(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.amber, letterSpacing: 0.5)),
              const SizedBox(width: 8),
              Text('seit ${_fmtDate(data.displayStart!)}',
                  style: GoogleFonts.rajdhani(fontSize: 13, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 16),

          for (final month in data.months) ...[
            _MonthCard(month: month, monthName: monthNames[month.month], eurFmt: eurFmt),
            const SizedBox(height: 12),
          ],

          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppColors.neu(7),
            ),
            child: Column(
              children: [
                _TotalRow(label: 'Stromkosten gesamt', value: eurFmt.format(totalElec), bold: false),
                const SizedBox(height: 8),
                _TotalRow(label: 'Grundpreis (${data.months.length} Mon.)', value: eurFmt.format(totalBase), bold: false),
                const SizedBox(height: 12),
                Container(height: 1, color: AppColors.border),
                const SizedBox(height: 12),
                _TotalRow(label: 'GESAMT', value: eurFmt.format(grandTotal), bold: true),
              ],
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
            Icon(Icons.settings_outlined, size: 48, color: AppColors.textSecondary.withOpacity(0.4)),
            const SizedBox(height: 16),
            Text('Preise noch nicht konfiguriert',
                style: GoogleFonts.rajdhani(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text('Bitte trage in den Einstellungen unter "Strompreis" den Anbieter, den Preis pro kWh und den Grundpreis ein.',
                style: GoogleFonts.rajdhani(fontSize: 14, color: AppColors.textSecondary.withOpacity(0.7), height: 1.5),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _emptyView(_CostData data) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bar_chart_outlined, size: 48, color: AppColors.textSecondary.withOpacity(0.4)),
            const SizedBox(height: 16),
            Text('Noch keine Verbrauchsdaten',
                style: GoogleFonts.rajdhani(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            if (data.displayStart != null) ...[
              const SizedBox(height: 8),
              Text('Sobald Ablesungen seit dem ${_fmtDate(data.displayStart!)} vorliegen, erscheint hier die Monatsübersicht.',
                  style: GoogleFonts.rajdhani(fontSize: 14, color: AppColors.textSecondary.withOpacity(0.7), height: 1.5),
                  textAlign: TextAlign.center),
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

class _CostData {
  final List<_MonthData> months;
  final bool hasContracts;
  final String providerName;
  final DateTime? displayStart;
  const _CostData({required this.months, required this.hasContracts, required this.providerName, required this.displayStart});
}

class _MonthData {
  final int year, month;
  final double consumptionKwh, elecCost, basePrice, pricePerKwh;
  final String providerName;
  double get total => elecCost + basePrice;
  const _MonthData({required this.year, required this.month, required this.consumptionKwh, required this.elecCost, required this.basePrice, required this.pricePerKwh, required this.providerName});
}

// ---------------------------------------------------------------------------
// Widgets
// ---------------------------------------------------------------------------

class _MonthCard extends StatefulWidget {
  final _MonthData month;
  final String monthName;
  final NumberFormat eurFmt;
  const _MonthCard({required this.month, required this.monthName, required this.eurFmt});

  @override
  State<_MonthCard> createState() => _MonthCardState();
}

class _MonthCardState extends State<_MonthCard> {
  bool _showCalc = false;

  @override
  Widget build(BuildContext context) {
    final m = widget.month;
    final eurFmt = widget.eurFmt;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(16), boxShadow: AppColors.neu(6)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${widget.monthName} ${m.year}'.toUpperCase(),
                  style: GoogleFonts.spaceMono(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.amber, letterSpacing: 2)),
              Text(m.providerName,
                  style: GoogleFonts.rajdhani(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 14),
          _DetailRow(label: 'Verbrauch', value: '${m.consumptionKwh.toStringAsFixed(2)} kWh'),
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
                        Text('Stromkosten',
                            style: GoogleFonts.rajdhani(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: 0.3)),
                        const SizedBox(width: 5),
                        Icon(_showCalc ? Icons.info : Icons.info_outline, size: 14,
                            color: _showCalc ? AppColors.amber : AppColors.textSecondary),
                      ],
                    ),
                  ),
                  Text(eurFmt.format(m.elecCost),
                      style: GoogleFonts.spaceMono(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.amber)),
                ],
              ),
              if (_showCalc) ...[
                const SizedBox(height: 4),
                Text('${m.consumptionKwh.toStringAsFixed(2)} kWh  ×  ${(m.pricePerKwh * 100).toStringAsFixed(4)} ct/kWh',
                    style: GoogleFonts.spaceMono(fontSize: 10, color: AppColors.textSecondary)),
              ],
            ],
          ),
          const SizedBox(height: 8),
          _DetailRow(label: 'Grundpreis', value: eurFmt.format(m.basePrice)),
          const SizedBox(height: 12),
          Container(height: 1, color: AppColors.border),
          const SizedBox(height: 12),
          _DetailRow(label: 'Gesamt', value: eurFmt.format(m.total), bold: true, valueColor: AppColors.greenDark),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label, value;
  final bool bold;
  final Color? valueColor;
  const _DetailRow({required this.label, required this.value, this.bold = false, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.rajdhani(fontSize: bold ? 15 : 14, fontWeight: bold ? FontWeight.w700 : FontWeight.w600, color: AppColors.textPrimary, letterSpacing: 0.3)),
        Text(value, style: GoogleFonts.spaceMono(fontSize: bold ? 15 : 13, fontWeight: bold ? FontWeight.w700 : FontWeight.w400, color: valueColor ?? AppColors.textPrimary)),
      ],
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label, value;
  final bool bold;
  const _TotalRow({required this.label, required this.value, required this.bold});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.rajdhani(fontSize: bold ? 16 : 14, fontWeight: bold ? FontWeight.w700 : FontWeight.w500, color: bold ? AppColors.greenDark : AppColors.textSecondary, letterSpacing: bold ? 1 : 0.3)),
        Text(value, style: GoogleFonts.spaceMono(fontSize: bold ? 18 : 14, fontWeight: bold ? FontWeight.w700 : FontWeight.w400, color: bold ? AppColors.greenDark : AppColors.textPrimary)),
      ],
    );
  }
}
