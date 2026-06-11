import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../database/database.dart';
import '../theme/colors.dart';
import '../utils/meter_interpolator.dart';
import '../widgets/benchmark_card.dart';

class CostDetailScreen extends StatefulWidget {
  const CostDetailScreen({super.key});

  @override
  State<CostDetailScreen> createState() => _CostDetailScreenState();
}

class _CostDetailScreenState extends State<CostDetailScreen> {
  late Future<_CostDetailData> _future;
  final _pageController = PageController();
  int _currentPage = 0;
  bool _hasAdvance = false;

  @override
  void initState() {
    super.initState();
    _future = _loadData();
    _future.then((data) {
      if (mounted) {
        setState(() {
          _hasAdvance = data.months.any((m) => (m.advancePayment ?? 0) > 0);
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<_CostDetailData> _loadData() async {
    final allContracts = await AppDatabase.instance.getAllContracts();
    if (allContracts.isEmpty) {
      return const _CostDetailData(
          months: [], hasContracts: false, providerName: '', displayStart: null);
    }

    final latestContract = allContracts.last;
    final providerName = latestContract.displayName;

    final providerContracts =
        allContracts.where((c) => c.displayName == providerName).toList();

    final displayStart =
        DateTime.fromMillisecondsSinceEpoch(providerContracts.first.validFrom);

    final rawReadings = await AppDatabase.instance.watchAllReadings().first;
    final readings = List<MeterReading>.from(rawReadings)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    if (readings.isEmpty) {
      return _CostDetailData(
        months: [],
        hasContracts: true,
        providerName: providerName,
        displayStart: displayStart,
      );
    }

    // Use all readings (including before contract start) so interpolation
    // can compute values at month boundaries that straddle the contract start.
    final pts = readings
        .map((r) => (value: r.value, timestamp: r.timestamp))
        .toList();

    // Load full advance payment history once (sorted by validFrom asc)
    final advanceChanges =
        await AppDatabase.instance.getAllAdvancePaymentChanges('gas');

    final now = DateTime.now();
    final months = <_MonthData>[];

    int year = displayStart.year;
    int month = displayStart.month;

    while (year < now.year || (year == now.year && month <= now.month)) {
      final consumptionM3 =
          MeterInterpolator.monthConsumption(pts, year, month);

      if (consumptionM3 != null && consumptionM3 > 0) {
        final lastDay = month < 12
            ? DateTime(year, month + 1, 0)
            : DateTime(year, 12, 31);
        final contract =
            await AppDatabase.instance.getContractForDate(lastDay) ??
                latestContract;

        final factor = (contract.brennwert > 0 && contract.zustandszahl > 0)
            ? contract.brennwert * contract.zustandszahl
            : 10.55;
        final consumptionKwh = consumptionM3 * factor;
        final gasCost = consumptionKwh * contract.pricePerKwh;

        final dayTwo = DateTime(year, month, 2);
        final isIncomplete = !pts.any((r) => r.timestamp.isBefore(dayTwo));

        // Find which advance payment was active at end of this month
        final endMs = lastDay.millisecondsSinceEpoch;
        AdvancePaymentChange? bestChange;
        for (final c in advanceChanges) {
          if (c.validFrom <= endMs) {
            bestChange = c;
          } else {
            break;
          }
        }
        final advancePayment =
            bestChange?.amount ?? contract.monthlyAdvancePayment;

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
          isIncomplete: isIncomplete,
          advancePayment: advancePayment,
        ));
      }

      month++;
      if (month > 12) {
        month = 1;
        year++;
      }
    }

    // Projection for the current (incomplete) month
    _Projection? projection;
    if (months.isNotEmpty) {
      final newest = months.last;
      final nowP = DateTime.now();
      if (newest.year == nowP.year && newest.month == nowP.month) {
        final monthStart = DateTime(nowP.year, nowP.month, 1);
        final daysInMonth = DateTime(nowP.year, nowP.month + 1, 0).day;

        double? startVal = MeterInterpolator.interpolateAt(pts, monthStart);
        DateTime startTime = monthStart;
        if (startVal == null) {
          final monthEnd = DateTime(nowP.year, nowP.month + 1, 1);
          final sorted = [...pts]..sort((a, b) => a.timestamp.compareTo(b.timestamp));
          final firstInMonth = sorted.where((r) =>
              !r.timestamp.isBefore(monthStart) &&
              r.timestamp.isBefore(monthEnd)).firstOrNull;
          if (firstInMonth != null) {
            startVal = firstInMonth.value;
            startTime = firstInMonth.timestamp;
          }
        }

        if (startVal != null) {
          final candidates = pts.where((r) => !r.timestamp.isAfter(nowP)).toList();
          if (candidates.isNotEmpty) {
            final lastPt = candidates.reduce(
                (a, b) => a.timestamp.isAfter(b.timestamp) ? a : b);
            final elapsed = lastPt.timestamp.difference(startTime);
            final daysElapsedFrac = elapsed.inMinutes / (24.0 * 60);
            if (daysElapsedFrac > 0 && lastPt.value > startVal) {
              final consumptionSoFarM3 = lastPt.value - startVal;
              final contract =
                  await AppDatabase.instance.getContractForDate(nowP) ??
                      latestContract;
              final factor =
                  (contract.brennwert > 0 && contract.zustandszahl > 0)
                      ? contract.brennwert * contract.zustandszahl
                      : 10.55;
              final consumptionSoFarKwh = consumptionSoFarM3 * factor;
              final projectedM3 =
                  consumptionSoFarM3 * daysInMonth / daysElapsedFrac;
              final projectedKwh = projectedM3 * factor;
              final projectedCost =
                  projectedKwh * contract.pricePerKwh + contract.monthlyBasePrice;
              projection = _Projection(
                projectedTotal: projectedCost,
                projectedM3: projectedM3,
                projectedKwh: projectedKwh,
                consumptionSoFarM3: consumptionSoFarM3,
                consumptionSoFarKwh: consumptionSoFarKwh,
                daysElapsedFrac: daysElapsedFrac,
                daysElapsedDisplay: elapsed.inDays.clamp(1, 31),
                daysInMonth: daysInMonth,
                pricePerKwh: contract.pricePerKwh,
                basePrice: contract.monthlyBasePrice,
                conversionFactor: factor,
              );
            }
          }
        }
      }
    }

    return _CostDetailData(
      months: months.reversed.toList(),
      hasContracts: true,
      providerName: providerName,
      displayStart: displayStart,
      projection: projection,
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
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, anim) =>
                        FadeTransition(opacity: anim, child: child),
                    child: Text(
                      _currentPage == 0
                          ? 'KOSTENÜBERSICHT'
                          : (_hasAdvance && _currentPage == 1)
                              ? 'ABSCHLAGSVERGLEICH'
                              : 'VERBRAUCHSVERGLEICH',
                      key: ValueKey(_currentPage),
                      style: GoogleFonts.spaceMono(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.greenDark,
                        letterSpacing: 3,
                      ),
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
                            color: AppColors.green, strokeWidth: 2));
                  }
                  final data = snapshot.data!;

                  if (!data.hasContracts) return _noSettingsView();
                  if (data.months.isEmpty) return _emptyView(data);

                  final hasAdvance =
                      data.months.any((m) => (m.advancePayment ?? 0) > 0);
                  final pageCount = hasAdvance ? 3 : 2;

                  return Column(
                    children: [
                      _buildDots(pageCount),
                      Expanded(
                        child: PageView(
                          controller: _pageController,
                          onPageChanged: (i) =>
                              setState(() => _currentPage = i),
                          children: [
                            _buildContent(data),
                            if (hasAdvance) _buildAbschlagPage(data),
                            _buildVergleichPage(),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDots([int count = 2]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(count, (i) {
          final active = _currentPage == i;
          return GestureDetector(
            onTap: () => _pageController.animateToPage(
              i,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: active ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: active ? AppColors.greenDark : AppColors.border,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildAbschlagPage(_CostDetailData data) {
    final eurFmt = NumberFormat.currency(locale: 'de_DE', symbol: '€');
    const monthNames = [
      '', 'Januar', 'Februar', 'März', 'April', 'Mai', 'Juni',
      'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember',
    ];

    // Per-month delta: advance - actualCost (0 if incomplete or no advance)
    final deltas = data.months.map((m) {
      final adv = m.advancePayment ?? 0.0;
      if (m.isIncomplete || adv <= 0) return 0.0;
      return adv - m.total;
    }).toList();

    final cumulativeBalance = deltas.fold(0.0, (s, d) => s + d);

    // Only count complete months that had an advance payment
    final completeWithAdv = data.months
        .where((m) => !m.isIncomplete && (m.advancePayment ?? 0) > 0)
        .toList();
    final totalPaid =
        completeWithAdv.fold(0.0, (s, m) => s + (m.advancePayment ?? 0));
    final totalCost = completeWithAdv.fold(0.0, (s, m) => s + m.total);

    final monthsInSurplus = [
      for (int i = 0; i < data.months.length; i++)
        if (!data.months[i].isIncomplete &&
            (data.months[i].advancePayment ?? 0) > 0 &&
            deltas[i] >= 0)
          true,
    ].length;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SaldoCard(
            balance: cumulativeBalance,
            totalPaid: totalPaid,
            totalCost: totalCost,
            eurFmt: eurFmt,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: Container(height: 1, color: AppColors.border)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'MONATSÜBERSICHT',
                  style: GoogleFonts.spaceMono(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                    letterSpacing: 2,
                  ),
                ),
              ),
              Expanded(child: Container(height: 1, color: AppColors.border)),
            ],
          ),
          const SizedBox(height: 16),
          for (int i = 0; i < data.months.length; i++) ...[
            _AbschlagMonthCard(
              month: data.months[i],
              monthName: monthNames[data.months[i].month],
              advance: data.months[i].advancePayment,
              delta: deltas[i],
              eurFmt: eurFmt,
              projection: i == 0 ? data.projection : null,
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 8),
          _SurplusBar(
            monthsInSurplus: monthsInSurplus,
            totalMonths: completeWithAdv.length,
          ),
          const SizedBox(height: 24),
        ],
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
          Row(
            children: [
              Icon(Icons.business_rounded,
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

          for (final month in data.months) ...[
            _MonthCard(
              month: month,
              monthName: monthNames[month.month],
              eurFmt: eurFmt,
            ),
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
                Container(height: 1, color: AppColors.border),
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

  Widget _buildVergleichPage() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 8),
          const BenchmarkCard(type: BenchmarkType.gas, accent: AppColors.green),
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
  final _Projection? projection;

  const _CostDetailData({
    required this.months,
    required this.hasContracts,
    required this.providerName,
    required this.displayStart,
    this.projection,
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
  final bool isIncomplete;
  final double? advancePayment;

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
    this.isIncomplete = false,
    this.advancePayment,
  });
}

// ---------------------------------------------------------------------------
// Widgets – Kostenübersicht
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
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.neu(6),
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
                          _showCalc ? Icons.info : Icons.info_outline,
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
            valueColor: AppColors.greenDark,
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
            color: bold ? AppColors.greenDark : AppColors.textSecondary,
            letterSpacing: bold ? 1 : 0.3,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.spaceMono(
            fontSize: bold ? 18 : 14,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
            color: bold ? AppColors.greenDark : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Widgets – Abschlagsvergleich
// ---------------------------------------------------------------------------

class _SaldoCard extends StatelessWidget {
  final double balance, totalPaid, totalCost;
  final NumberFormat eurFmt;

  const _SaldoCard({
    required this.balance,
    required this.totalPaid,
    required this.totalCost,
    required this.eurFmt,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = balance >= 0;
    final accentColor = isPositive ? AppColors.greenDark : AppColors.error;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentColor.withOpacity(0.25), width: 1.5),
        boxShadow: AppColors.neu(7),
      ),
      child: Column(
        children: [
          Text(
            isPositive ? 'GUTHABEN' : 'NACHZAHLUNG',
            style: GoogleFonts.spaceMono(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: accentColor,
              letterSpacing: 2.5,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${isPositive ? '+' : ''}${eurFmt.format(balance)}',
            style: GoogleFonts.spaceMono(
              fontSize: 34,
              fontWeight: FontWeight.w700,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 20),
          Container(height: 1, color: AppColors.border),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Abschläge',
                      style: GoogleFonts.rajdhani(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      eurFmt.format(totalPaid),
                      style: GoogleFonts.spaceMono(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 36, color: AppColors.border),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Istkosten',
                      style: GoogleFonts.rajdhani(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      eurFmt.format(totalCost),
                      style: GoogleFonts.spaceMono(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AbschlagMonthCard extends StatelessWidget {
  final _MonthData month;
  final String monthName;
  final double? advance;
  final double delta;
  final NumberFormat eurFmt;
  final _Projection? projection;

  const _AbschlagMonthCard({
    required this.month,
    required this.monthName,
    required this.advance,
    required this.delta,
    required this.eurFmt,
    this.projection,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = delta >= 0;
    final deltaColor = isPositive ? AppColors.greenDark : AppColors.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppColors.neu(5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '$monthName ${month.year}'.toUpperCase(),
                          style: GoogleFonts.spaceMono(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.amber,
                            letterSpacing: 1.5,
                          ),
                        ),
                        if (month.isIncomplete) ...[
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () => showDialog(
                              context: context,
                              builder: (_) => const _IncompleteMonthDialog(),
                            ),
                            child: const Icon(
                              Icons.warning_amber_rounded,
                              size: 13,
                              color: AppColors.amber,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'Abschlag',
                          style: GoogleFonts.rajdhani(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          (advance != null && advance! > 0)
                              ? eurFmt.format(advance)
                              : '–',
                          style: GoogleFonts.spaceMono(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          'Istkosten',
                          style: GoogleFonts.rajdhani(
                            fontSize: 13,
                            color: month.isIncomplete
                                ? AppColors.textSecondary
                                : AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          eurFmt.format(month.total),
                          style: GoogleFonts.spaceMono(
                            fontSize: 12,
                            color: month.isIncomplete
                                ? AppColors.textSecondary
                                : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(width: 1, height: 52, color: AppColors.border),
              const SizedBox(width: 16),
              if (month.isIncomplete)
                Text(
                  '±0',
                  style: GoogleFonts.spaceMono(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Icon(
                      isPositive
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      color: deltaColor,
                      size: 16,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${isPositive ? '+' : ''}${eurFmt.format(delta)}',
                      style: GoogleFonts.spaceMono(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: deltaColor,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          if (projection != null && (advance ?? 0) > 0) ...[
            const SizedBox(height: 10),
            Container(height: 1, color: AppColors.border),
            const SizedBox(height: 10),
            _ProjectionRow(
              projection: projection!,
              advance: advance!,
              eurFmt: eurFmt,
              monthName: monthName,
              month: month,
            ),
          ],
        ],
      ),
    );
  }
}

class _SurplusBar extends StatelessWidget {
  final int monthsInSurplus, totalMonths;

  const _SurplusBar({
    required this.monthsInSurplus,
    required this.totalMonths,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = totalMonths > 0 ? monthsInSurplus / totalMonths : 0.0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppColors.neu(5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Monate im Guthaben',
                style: GoogleFonts.rajdhani(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '$monthsInSurplus / $totalMonths',
                style: GoogleFonts.spaceMono(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(
              children: [
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: ratio.clamp(0.0, 1.0),
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.greenDark,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Erster Monat – Warnung
// ---------------------------------------------------------------------------

class _IncompleteMonthDialog extends StatelessWidget {
  const _IncompleteMonthDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: AppColors.amber, size: 18),
          const SizedBox(width: 8),
          Text(
            'ERSTER MONAT',
            style: GoogleFonts.spaceMono(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.amber,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
      content: Text(
        'Dieser Monat ist nicht repräsentativ und wird mit ±0 gewertet.\n\n'
        'Da keine Messung vom 1. des Monats vorliegt, kann der Verbrauch '
        'für den gesamten Monat nicht zuverlässig berechnet werden.\n\n'
        'Erst wenn ein Monat vollständig – von Anfang bis Ende – mit '
        'Messwerten abgedeckt ist, fließt er in den Abschlagsvergleich ein.',
        style: GoogleFonts.rajdhani(
          fontSize: 14,
          color: AppColors.textPrimary,
          height: 1.5,
          fontWeight: FontWeight.w500,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'OK',
            style: GoogleFonts.rajdhani(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.greenDark,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Hochrechnung
// ---------------------------------------------------------------------------

class _Projection {
  final double projectedTotal;
  final double projectedM3;
  final double projectedKwh;
  final double consumptionSoFarM3;
  final double consumptionSoFarKwh;
  final double daysElapsedFrac;
  final int daysElapsedDisplay;
  final int daysInMonth;
  final double pricePerKwh;
  final double basePrice;
  final double conversionFactor;

  const _Projection({
    required this.projectedTotal,
    required this.projectedM3,
    required this.projectedKwh,
    required this.consumptionSoFarM3,
    required this.consumptionSoFarKwh,
    required this.daysElapsedFrac,
    required this.daysElapsedDisplay,
    required this.daysInMonth,
    required this.pricePerKwh,
    required this.basePrice,
    required this.conversionFactor,
  });
}

class _ProjectionRow extends StatelessWidget {
  final _Projection projection;
  final double advance;
  final NumberFormat eurFmt;
  final String monthName;
  final _MonthData month;

  const _ProjectionRow({
    super.key,
    required this.projection,
    required this.advance,
    required this.eurFmt,
    required this.monthName,
    required this.month,
  });

  @override
  Widget build(BuildContext context) {
    final isOver = projection.projectedTotal > advance;
    final color = isOver ? AppColors.error : AppColors.greenDark;

    return Row(
      children: [
        GestureDetector(
          onTap: () => showDialog(
            context: context,
            builder: (_) => _ProjectionInfoDialog(
              projection: projection,
              monthName: monthName,
              month: month,
              eurFmt: eurFmt,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Hochrechnung',
                style: GoogleFonts.rajdhani(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.info_outline_rounded,
                  size: 13, color: AppColors.textSecondary),
            ],
          ),
        ),
        const Spacer(),
        Text(
          eurFmt.format(projection.projectedTotal),
          style: GoogleFonts.spaceMono(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _ProjectionInfoDialog extends StatelessWidget {
  final _Projection projection;
  final String monthName;
  final _MonthData month;
  final NumberFormat eurFmt;

  const _ProjectionInfoDialog({
    super.key,
    required this.projection,
    required this.monthName,
    required this.month,
    required this.eurFmt,
  });

  @override
  Widget build(BuildContext context) {
    final gasCostOnly =
        projection.projectedKwh * projection.pricePerKwh;
    final dailyAvgKwh =
        projection.consumptionSoFarKwh / projection.daysElapsedFrac;
    final dailyAvgM3 =
        projection.consumptionSoFarM3 / projection.daysElapsedFrac;

    return AlertDialog(
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'HOCHRECHNUNG ${monthName.toUpperCase()} ${month.year}',
        style: GoogleFonts.spaceMono(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.amber,
          letterSpacing: 1.2,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoSection(
            'Bisheriger Zeitraum',
            '${projection.daysElapsedDisplay} Tage',
          ),
          _InfoSection(
            'Verbrauch bisher',
            '${projection.consumptionSoFarM3.toStringAsFixed(3)} m³'
            ' = ${projection.consumptionSoFarKwh.toStringAsFixed(2)} kWh',
          ),
          _InfoSection(
            'Tagesdurchschnitt',
            '${dailyAvgKwh.toStringAsFixed(3)} kWh/Tag'
            ' (${dailyAvgM3.toStringAsFixed(4)} m³/Tag)',
          ),
          _InfoSection(
            'Hochrechnung auf ${projection.daysInMonth} Tage',
            '${projection.projectedKwh.toStringAsFixed(2)} kWh'
            ' × ${(projection.pricePerKwh * 100).toStringAsFixed(4)} ct/kWh'
            '\n= ${eurFmt.format(gasCostOnly)}'
            '\n+ Grundpreis ${eurFmt.format(projection.basePrice)}'
            '\n= ${eurFmt.format(projection.projectedTotal)}',
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'OK',
            style: GoogleFonts.rajdhani(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.greenDark,
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String label, value;
  const _InfoSection(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.rajdhani(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.spaceMono(
              fontSize: 11,
              color: AppColors.textPrimary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
