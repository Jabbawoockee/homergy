import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../database/database.dart';
import '../services/cost_service.dart';
import '../services/sync_service.dart';
import '../theme/colors.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _costService = CostService();
  double _kwhPrice = 0.09;
  double _basePrice = 0.0;
  double _brennwert = 0.0;
  double _zustandszahl = 0.0;

  @override
  void initState() {
    super.initState();
    _loadPricing();
  }

  Future<void> _loadPricing() async {
    final contract = await AppDatabase.instance.getLatestContract();
    if (mounted && contract != null) {
      setState(() {
        _kwhPrice = contract.pricePerKwh;
        _basePrice = contract.monthlyBasePrice;
        _brennwert = contract.brennwert;
        _zustandszahl = contract.zustandszahl;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Text(
                'VERLAUF',
                style: GoogleFonts.spaceMono(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.amber,
                  letterSpacing: 5,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Letzte 6 Monate & alle Ablesungen',
                style: GoogleFonts.rajdhani(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
            ),

            Expanded(
              child: StreamBuilder<List<MeterReading>>(
                stream: AppDatabase.instance.watchAllReadings(),
                builder: (context, snapshot) {
                  final readings = snapshot.data ?? [];

                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.amber),
                    );
                  }

                  if (readings.isEmpty) {
                    return _buildEmptyState();
                  }

                  final monthlyData = _buildMonthlyData(readings);

                  return Column(
                    children: [
                      // Bar chart
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                        child: _MonthlyChart(monthlyData: monthlyData),
                      ),

                      const SizedBox(height: 20),

                      // Divider
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            Text(
                              'ALLE ABLESUNGEN',
                              style: GoogleFonts.rajdhani(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                height: 1,
                                color: AppColors.border,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${readings.length}',
                              style: GoogleFonts.spaceMono(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Readings list
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          itemCount: readings.length,
                          itemBuilder: (context, index) {
                            final reading = readings[index];
                            final prev = index < readings.length - 1
                                ? readings[index + 1]
                                : null;
                            final delta = prev != null
                                ? reading.value - prev.value
                                : null;
                            final cost = delta != null && delta > 0
                                ? _costService.calculateCost(
                                    delta,
                                    pricePerKwh: _kwhPrice,
                                    monthlyBasePrice: _basePrice,
                                    brennwert: _brennwert,
                                    zustandszahl: _zustandszahl,
                                  )
                                : null;

                            return Dismissible(
                              key: Key('reading_${reading.id}'),
                              direction: DismissDirection.endToStart,
                              confirmDismiss: (_) =>
                                  _confirmDelete(context),
                              onDismissed: (_) async {
                                final remoteId = reading.remoteId;
                                await AppDatabase.instance
                                    .deleteReading(reading.id);
                                if (remoteId != null) {
                                  SyncService().deleteRemote(remoteId);
                                }
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    SnackBar(
                                      backgroundColor:
                                          AppColors.surface,
                                      content: Text(
                                        'Ablesung gelöscht.',
                                        style: GoogleFonts.rajdhani(
                                          fontSize: 14,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                  );
                                }
                              },
                              background: Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  color: AppColors.error,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                alignment: Alignment.centerRight,
                                padding:
                                    const EdgeInsets.only(right: 20),
                                child: const Icon(Icons.delete_outline,
                                    color: Colors.white, size: 24),
                              ),
                              child: _ReadingCard(
                                reading: reading,
                                delta: delta,
                                cost: cost,
                                onDelete: () async {
                                  final confirm =
                                      await _confirmDelete(context);
                                  if (confirm) {
                                    final remoteId = reading.remoteId;
                                    await AppDatabase.instance
                                        .deleteReading(reading.id);
                                    if (remoteId != null) {
                                      SyncService().deleteRemote(remoteId);
                                    }
                                  }
                                },
                                onEdit: () =>
                                    _showEditDialog(context, reading),
                              ),
                            );
                          },
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.history_rounded,
            size: 64,
            color: AppColors.textSecondary.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Noch keine Ablesungen',
            style: GoogleFonts.rajdhani(
              fontSize: 18,
              color: AppColors.textSecondary,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tippe auf ABLESEN auf der Startseite,\num die erste Ablesung hinzuzufügen.',
            textAlign: TextAlign.center,
            style: GoogleFonts.rajdhani(
              fontSize: 14,
              color: AppColors.textSecondary.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Ablesung löschen?',
          style: GoogleFonts.rajdhani(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'Diese Ablesung wird dauerhaft entfernt.',
          style: GoogleFonts.rajdhani(
            fontSize: 15,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Abbrechen',
                style: GoogleFonts.rajdhani(
                    fontSize: 15, color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Löschen',
                style: GoogleFonts.rajdhani(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.error)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _showEditDialog(BuildContext context, MeterReading reading) async {
    final controller = TextEditingController(
        text: reading.value.toStringAsFixed(3));
    final focusNode = FocusNode();

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Zählerstand anpassen',
          style: GoogleFonts.rajdhani(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Aktueller Wert',
              style: GoogleFonts.rajdhani(
                fontSize: 13,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${reading.value.toStringAsFixed(3)} m³',
              style: GoogleFonts.spaceMono(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.amber,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              focusNode: focusNode,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: GoogleFonts.spaceMono(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              cursorColor: AppColors.amber,
              decoration: InputDecoration(
                labelText: 'Neuer Wert (m³)',
                labelStyle: GoogleFonts.rajdhani(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
                suffixText: 'm³',
                suffixStyle: GoogleFonts.rajdhani(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.amber, width: 1.5),
                ),
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Abbrechen',
              style: GoogleFonts.rajdhani(
                  fontSize: 15, color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              final newValue = double.tryParse(
                  controller.text.replaceAll(',', '.'));
              if (newValue == null) return;
              await AppDatabase.instance
                  .updateReadingValue(reading.id, newValue);
              if (ctx.mounted) Navigator.of(ctx).pop();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppColors.surface,
                    content: Text(
                      'Ablesung aktualisiert.',
                      style: GoogleFonts.rajdhani(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                );
              }
            },
            child: Text(
              'Speichern',
              style: GoogleFonts.rajdhani(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.amber,
              ),
            ),
          ),
        ],
      ),
    );

    controller.dispose();
    focusNode.dispose();
  }

  // Build list of (month label, consumption) for last 6 months.
  List<_MonthStat> _buildMonthlyData(List<MeterReading> readings) {
    final now = DateTime.now();
    final stats = <_MonthStat>[];

    for (int i = 5; i >= 0; i--) {
      final monthDate = DateTime(now.year, now.month - i, 1);
      final monthStart = DateTime(monthDate.year, monthDate.month, 1);
      final monthEnd =
          DateTime(monthDate.year, monthDate.month + 1, 0, 23, 59, 59);

      // Readings in this month + the last reading before/on month end as reference.
      final inMonth = readings
          .where((r) =>
              !r.timestamp.isBefore(monthStart) &&
              !r.timestamp.isAfter(monthEnd))
          .toList();

      double consumption = 0;
      if (inMonth.length >= 2) {
        // Sorted desc, so first is max, last is min within this month.
        consumption = inMonth.first.value - inMonth.last.value;
        if (consumption < 0) consumption = 0;
      } else if (inMonth.length == 1) {
        // Find last reading before this month.
        final before = readings
            .where((r) => r.timestamp.isBefore(monthStart))
            .toList();
        if (before.isNotEmpty) {
          consumption = inMonth.first.value - before.first.value;
          if (consumption < 0) consumption = 0;
        }
      }

      stats.add(_MonthStat(
        label: DateFormat('MMM', 'de_DE').format(monthDate),
        consumption: consumption,
      ));
    }
    return stats;
  }
}

// ---------------------------------------------------------------------------
// Monthly bar chart
// ---------------------------------------------------------------------------

class _MonthStat {
  final String label;
  final double consumption;
  const _MonthStat({required this.label, required this.consumption});
}

class _MonthlyChart extends StatelessWidget {
  final List<_MonthStat> monthlyData;

  const _MonthlyChart({required this.monthlyData});

  @override
  Widget build(BuildContext context) {
    final maxY =
        monthlyData.map((s) => s.consumption).fold(0.0, (a, b) => a > b ? a : b);
    final chartMax = maxY < 1 ? 10.0 : maxY * 1.3;

    return Container(
      height: 180,
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 8),
            child: Text(
              'MONATSVERBRAUCH m³',
              style: GoogleFonts.rajdhani(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                letterSpacing: 2,
              ),
            ),
          ),
          Expanded(
            child: BarChart(
              BarChartData(
                maxY: chartMax,
                minY: 0,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: chartMax / 4,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppColors.border,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= monthlyData.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            monthlyData[index].label,
                            style: GoogleFonts.rajdhani(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        );
                      },
                      reservedSize: 28,
                    ),
                  ),
                ),
                barGroups: List.generate(monthlyData.length, (i) {
                  final stat = monthlyData[i];
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: stat.consumption,
                        width: 20,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6)),
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            AppColors.amber.withOpacity(0.5),
                            AppColors.amber,
                          ],
                        ),
                      ),
                    ],
                  );
                }),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppColors.border,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${rod.toY.toStringAsFixed(1)} m³',
                        GoogleFonts.spaceMono(
                          fontSize: 11,
                          color: AppColors.amber,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Reading list card
// ---------------------------------------------------------------------------

class _ReadingCard extends StatelessWidget {
  final MeterReading reading;
  final double? delta;
  final double? cost;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _ReadingCard({
    required this.reading,
    required this.delta,
    required this.cost,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd. MMM yyyy, HH:mm', 'de_DE')
        .format(reading.timestamp);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date row
          Row(
            children: [
              Icon(Icons.access_time_rounded,
                  size: 12, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                dateStr,
                style: GoogleFonts.rajdhani(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onEdit,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppColors.amber.withOpacity(0.3), width: 1),
                  ),
                  child: const Icon(Icons.edit_outlined,
                      size: 15, color: AppColors.amber),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onDelete,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppColors.error.withOpacity(0.25), width: 1),
                  ),
                  child: const Icon(Icons.delete_outline,
                      size: 16, color: AppColors.error),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Value row
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                reading.value.toStringAsFixed(3),
                style: GoogleFonts.spaceMono(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'm³',
                style: GoogleFonts.rajdhani(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (cost != null)
                Text(
                  NumberFormat.currency(locale: 'de_DE', symbol: '€')
                      .format(cost),
                  style: GoogleFonts.spaceMono(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.amber,
                  ),
                ),
            ],
          ),

          // Delta row
          if (delta != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  delta! > 0 ? Icons.arrow_upward : Icons.remove,
                  size: 12,
                  color: AppColors.green,
                ),
                const SizedBox(width: 4),
                Text(
                  '${delta!.toStringAsFixed(3)} m³',
                  style: GoogleFonts.rajdhani(
                    fontSize: 13,
                    color: AppColors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'seit voriger Ablesung',
                  style: GoogleFonts.rajdhani(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],

          // Optional note
          if (reading.note != null && reading.note!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.notes,
                      size: 12, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      reading.note!,
                      style: GoogleFonts.rajdhani(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
