import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../database/database.dart';
import '../services/cost_service.dart';
import '../services/sync_service.dart';
import '../theme/colors.dart';

enum HistoryFilter { gas, electricity, both }

class HistoryScreen extends StatefulWidget {
  final HistoryFilter initialFilter;
  const HistoryScreen({super.key, this.initialFilter = HistoryFilter.gas});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _costService = CostService();
  double _kwhPrice = 0.09;
  double _basePrice = 0.0;
  double _brennwert = 0.0;
  double _zustandszahl = 0.0;
  double _elecPrice = 0.30;
  late HistoryFilter _filter;

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter;
    _loadPricing();
  }

  Future<void> _loadPricing() async {
    final contract = await AppDatabase.instance.getLatestContract();
    final elecContract = await AppDatabase.instance.getLatestElectricityContract();
    if (mounted) {
      setState(() {
        if (contract != null) {
          _kwhPrice = contract.pricePerKwh;
          _basePrice = contract.monthlyBasePrice;
          _brennwert = contract.brennwert;
          _zustandszahl = contract.zustandszahl;
        }
        if (elecContract != null) _elecPrice = elecContract.pricePerKwh;
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
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Text(
                'VERLAUF',
                style: GoogleFonts.spaceMono(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.greenDark,
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
            const SizedBox(height: 16),

            // Filter bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(child: _FilterChip(label: '🔥  Gas', selected: _filter == HistoryFilter.gas, onTap: () => setState(() => _filter = HistoryFilter.gas))),
                  const SizedBox(width: 8),
                  Expanded(child: _FilterChip(label: '⚡  Strom', selected: _filter == HistoryFilter.electricity, onTap: () => setState(() => _filter = HistoryFilter.electricity))),
                  const SizedBox(width: 8),
                  Expanded(child: _FilterChip(label: 'Beides', selected: _filter == HistoryFilter.both, onTap: () => setState(() => _filter = HistoryFilter.both))),
                ],
              ),
            ),
            const SizedBox(height: 4),

            Expanded(
              child: _filter == HistoryFilter.gas
                  ? _buildGasHistory()
                  : _filter == HistoryFilter.electricity
                      ? _buildElectricityHistory()
                      : _buildCombinedHistory(),
            ),
          ],
        ),
      ),
    );
  }

  // ── Gas history ────────────────────────────────────────────────────────────

  Widget _buildGasHistory() {
    return StreamBuilder<List<MeterReading>>(
      stream: AppDatabase.instance.watchAllReadings(),
      builder: (context, snapshot) {
        final readings = snapshot.data ?? [];
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.green));
        if (readings.isEmpty) return _buildEmptyState('Gas');
        final monthlyData = _buildGasMonthlyData(readings);
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: _MonthlyChart(monthlyData: monthlyData, barColor: AppColors.green, unit: 'm³'),
            ),
            const SizedBox(height: 20),
            _readingCountRow(readings.length),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                itemCount: readings.length,
                itemBuilder: (context, index) {
                  final reading = readings[index];
                  final prev = index < readings.length - 1 ? readings[index + 1] : null;
                  final delta = prev != null ? reading.value - prev.value : null;
                  final cost = delta != null && delta > 0
                      ? _costService.calculateCost(delta, pricePerKwh: _kwhPrice, monthlyBasePrice: _basePrice, brennwert: _brennwert, zustandszahl: _zustandszahl)
                      : null;
                  return Dismissible(
                    key: Key('gas_${reading.id}'),
                    direction: DismissDirection.endToStart,
                    confirmDismiss: (_) => _confirmDelete(context),
                    onDismissed: (_) async {
                      final remoteId = reading.remoteId;
                      await AppDatabase.instance.deleteReading(reading.id);
                      if (remoteId != null) SyncService().deleteRemote(remoteId);
                      if (context.mounted) _showDeleteSnack(context);
                    },
                    background: _dismissBackground(),
                    child: _ReadingCard(
                      value: reading.value,
                      timestamp: reading.timestamp,
                      note: reading.note,
                      delta: delta,
                      cost: cost,
                      unit: 'm³',
                      accentColor: AppColors.green,
                      onDelete: () async {
                        if (await _confirmDelete(context)) {
                          final remoteId = reading.remoteId;
                          await AppDatabase.instance.deleteReading(reading.id);
                          if (remoteId != null) SyncService().deleteRemote(remoteId);
                        }
                      },
                      onEdit: () => _showGasEditDialog(context, reading),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // ── Electricity history ────────────────────────────────────────────────────

  Widget _buildElectricityHistory() {
    return StreamBuilder<List<ElectricityReading>>(
      stream: AppDatabase.instance.watchAllElectricityReadings(),
      builder: (context, snapshot) {
        final readings = snapshot.data ?? [];
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.green));
        if (readings.isEmpty) return _buildEmptyState('Strom');
        final monthlyData = _buildElecMonthlyData(readings);
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: _MonthlyChart(monthlyData: monthlyData, barColor: const Color(0xFF5B8DB8), unit: 'kWh'),
            ),
            const SizedBox(height: 20),
            _readingCountRow(readings.length),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                itemCount: readings.length,
                itemBuilder: (context, index) {
                  final reading = readings[index];
                  final prev = index < readings.length - 1 ? readings[index + 1] : null;
                  final delta = prev != null ? reading.value - prev.value : null;
                  final cost = delta != null && delta > 0 ? delta * _elecPrice : null;
                  return Dismissible(
                    key: Key('elec_${reading.id}'),
                    direction: DismissDirection.endToStart,
                    confirmDismiss: (_) => _confirmDelete(context),
                    onDismissed: (_) async {
                      await AppDatabase.instance.deleteElectricityReading(reading.id);
                      if (context.mounted) _showDeleteSnack(context);
                    },
                    background: _dismissBackground(),
                    child: _ReadingCard(
                      value: reading.value,
                      timestamp: reading.timestamp,
                      note: reading.note,
                      delta: delta,
                      cost: cost,
                      unit: 'kWh',
                      accentColor: const Color(0xFF5B8DB8),
                      onDelete: () async {
                        if (await _confirmDelete(context)) {
                          await AppDatabase.instance.deleteElectricityReading(reading.id);
                        }
                      },
                      onEdit: () => _showElecEditDialog(context, reading),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // ── Combined history ───────────────────────────────────────────────────────

  Widget _buildCombinedHistory() {
    return StreamBuilder<List<MeterReading>>(
      stream: AppDatabase.instance.watchAllReadings(),
      builder: (context, gasSnap) {
        return StreamBuilder<List<ElectricityReading>>(
          stream: AppDatabase.instance.watchAllElectricityReadings(),
          builder: (context, elecSnap) {
            final gasReadings = gasSnap.data ?? [];
            final elecReadings = elecSnap.data ?? [];

            // Merge into unified list sorted by timestamp desc
            final combined = [
              ...gasReadings.map((r) => _CombinedEntry(timestamp: r.timestamp, value: r.value, unit: 'm³', isGas: true, id: r.id, note: r.note)),
              ...elecReadings.map((r) => _CombinedEntry(timestamp: r.timestamp, value: r.value, unit: 'kWh', isGas: false, id: r.id, note: r.note)),
            ]..sort((a, b) => b.timestamp.compareTo(a.timestamp));

            if (combined.isEmpty) return _buildEmptyState('Gas oder Strom');

            return Column(
              children: [
                _readingCountRow(combined.length),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    itemCount: combined.length,
                    itemBuilder: (context, index) {
                      final e = combined[index];
                      return _CombinedCard(entry: e);
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(String type) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history_rounded, size: 64, color: AppColors.textSecondary.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text('Noch keine Ablesungen', style: GoogleFonts.rajdhani(fontSize: 18, color: AppColors.textSecondary, letterSpacing: 1)),
          const SizedBox(height: 8),
          Text('Tippe auf ABLESEN auf der Startseite,\num den ersten $type-Zählerstand hinzuzufügen.', textAlign: TextAlign.center, style: GoogleFonts.rajdhani(fontSize: 14, color: AppColors.textSecondary.withOpacity(0.6))),
        ],
      ),
    );
  }

  Widget _readingCountRow(int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Text('ALLE ABLESUNGEN', style: GoogleFonts.rajdhani(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 2)),
          const SizedBox(width: 12),
          Expanded(child: Container(height: 1, color: AppColors.border)),
          const SizedBox(width: 8),
          Text('$count', style: GoogleFonts.spaceMono(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _dismissBackground() {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(14)),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      child: const Icon(Icons.delete_outline, color: Colors.white, size: 24),
    );
  }

  void _showDeleteSnack(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: AppColors.textPrimary,
      content: Text('Ablesung gelöscht.', style: GoogleFonts.rajdhani(fontSize: 14, color: AppColors.background)),
    ));
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Ablesung löschen?', style: GoogleFonts.rajdhani(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        content: Text('Diese Ablesung wird dauerhaft entfernt.', style: GoogleFonts.rajdhani(fontSize: 15, color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text('Abbrechen', style: GoogleFonts.rajdhani(fontSize: 15, color: AppColors.textSecondary))),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text('Löschen', style: GoogleFonts.rajdhani(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.error))),
        ],
      ),
    );
    return result ?? false;
  }

  List<_MonthStat> _buildGasMonthlyData(List<MeterReading> readings) {
    return _buildMonthlyStats(readings.map((r) => (value: r.value, timestamp: r.timestamp)).toList());
  }

  List<_MonthStat> _buildElecMonthlyData(List<ElectricityReading> readings) {
    return _buildMonthlyStats(readings.map((r) => (value: r.value, timestamp: r.timestamp)).toList());
  }

  List<_MonthStat> _buildMonthlyStats(List<({double value, DateTime timestamp})> readings) {
    final now = DateTime.now();
    final stats = <_MonthStat>[];
    for (int i = 5; i >= 0; i--) {
      final monthDate = DateTime(now.year, now.month - i, 1);
      final monthStart = DateTime(monthDate.year, monthDate.month, 1);
      final monthEnd = DateTime(monthDate.year, monthDate.month + 1, 0, 23, 59, 59);
      final inMonth = readings.where((r) => !r.timestamp.isBefore(monthStart) && !r.timestamp.isAfter(monthEnd)).toList();
      double consumption = 0;
      if (inMonth.length >= 2) {
        consumption = inMonth.first.value - inMonth.last.value;
        if (consumption < 0) consumption = 0;
      } else if (inMonth.length == 1) {
        final before = readings.where((r) => r.timestamp.isBefore(monthStart)).toList();
        if (before.isNotEmpty) {
          consumption = inMonth.first.value - before.first.value;
          if (consumption < 0) consumption = 0;
        }
      }
      stats.add(_MonthStat(label: DateFormat('MMM', 'de_DE').format(monthDate), consumption: consumption));
    }
    return stats;
  }

  Future<void> _showGasEditDialog(BuildContext context, MeterReading reading) async {
    await _showEditDialog(context, reading.value, reading.id, unit: 'm³', onSave: (v) => AppDatabase.instance.updateReadingValue(reading.id, v));
  }

  Future<void> _showElecEditDialog(BuildContext context, ElectricityReading reading) async {
    await _showEditDialog(context, reading.value, reading.id, unit: 'kWh', onSave: (v) => AppDatabase.instance.updateElectricityReadingValue(reading.id, v));
  }

  Future<void> _showEditDialog(BuildContext context, double currentValue, int id, {required String unit, required Future<void> Function(double) onSave}) async {
    final controller = TextEditingController(text: currentValue.toStringAsFixed(unit == 'm³' ? 3 : 2));
    final focusNode = FocusNode();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Zählerstand anpassen', style: GoogleFonts.rajdhani(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Aktueller Wert', style: GoogleFonts.rajdhani(fontSize: 13, color: AppColors.textSecondary, letterSpacing: 0.5)),
            const SizedBox(height: 4),
            Text('${currentValue.toStringAsFixed(unit == 'm³' ? 3 : 2)} $unit', style: GoogleFonts.spaceMono(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.amber)),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(color: const Color(0xFFDFE5DA), borderRadius: BorderRadius.circular(10)),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: GoogleFonts.spaceMono(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                cursorColor: AppColors.green,
                decoration: InputDecoration(
                  labelText: 'Neuer Wert ($unit)',
                  labelStyle: GoogleFonts.rajdhani(fontSize: 14, color: AppColors.textSecondary),
                  suffixText: unit,
                  suffixStyle: GoogleFonts.rajdhani(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.green, width: 1.5)),
                  filled: true,
                  fillColor: const Color(0xFFDFE5DA),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text('Abbrechen', style: GoogleFonts.rajdhani(fontSize: 15, color: AppColors.textSecondary))),
          TextButton(
            onPressed: () async {
              final newValue = double.tryParse(controller.text.replaceAll(',', '.'));
              if (newValue == null) return;
              await onSave(newValue);
              if (ctx.mounted) Navigator.of(ctx).pop();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  backgroundColor: AppColors.textPrimary,
                  content: Text('Ablesung aktualisiert.', style: GoogleFonts.rajdhani(fontSize: 14, color: AppColors.background)),
                ));
              }
            },
            child: Text('Speichern', style: GoogleFonts.rajdhani(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.green)),
          ),
        ],
      ),
    );
    controller.dispose();
    focusNode.dispose();
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
  final Color barColor;
  final String unit;

  const _MonthlyChart({required this.monthlyData, required this.barColor, required this.unit});

  @override
  Widget build(BuildContext context) {
    final maxY = monthlyData.map((s) => s.consumption).fold(0.0, (a, b) => a > b ? a : b);
    final chartMax = maxY < 1 ? 10.0 : maxY * 1.3;

    return Container(
      height: 180,
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(16), boxShadow: AppColors.neu(7)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 8),
            child: Text('MONATSVERBRAUCH $unit', style: GoogleFonts.rajdhani(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 2)),
          ),
          Expanded(
            child: BarChart(BarChartData(
              maxY: chartMax,
              minY: 0,
              gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: chartMax / 4, getDrawingHorizontalLine: (_) => FlLine(color: AppColors.border, strokeWidth: 1)),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index < 0 || index >= monthlyData.length) return const SizedBox.shrink();
                    return Padding(padding: const EdgeInsets.only(top: 6), child: Text(monthlyData[index].label, style: GoogleFonts.rajdhani(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary)));
                  },
                  reservedSize: 28,
                )),
              ),
              barGroups: List.generate(monthlyData.length, (i) => BarChartGroupData(x: i, barRods: [
                BarChartRodData(
                  toY: monthlyData[i].consumption,
                  width: 20,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                  gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [barColor.withOpacity(0.5), barColor]),
                ),
              ])),
              barTouchData: BarTouchData(touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => AppColors.background,
                getTooltipItem: (group, groupIndex, rod, rodIndex) => BarTooltipItem('${rod.toY.toStringAsFixed(1)} $unit', GoogleFonts.spaceMono(fontSize: 11, color: AppColors.greenDark)),
              )),
            )),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Filter chip
// ---------------------------------------------------------------------------

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 38,
        decoration: BoxDecoration(
          color: selected ? AppColors.green : AppColors.background,
          borderRadius: BorderRadius.circular(10),
          boxShadow: selected ? [const BoxShadow(color: Color(0xFF3A5E3D), offset: Offset(0, 2), blurRadius: 5)] : AppColors.neu(3),
        ),
        child: Center(child: Text(label, style: GoogleFonts.rajdhani(fontSize: 13, fontWeight: FontWeight.w600, color: selected ? Colors.white : AppColors.textSecondary))),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Combined entry model
// ---------------------------------------------------------------------------

class _CombinedEntry {
  final DateTime timestamp;
  final double value;
  final String unit;
  final bool isGas;
  final int id;
  final String? note;
  const _CombinedEntry({required this.timestamp, required this.value, required this.unit, required this.isGas, required this.id, this.note});
}

class _CombinedCard extends StatelessWidget {
  final _CombinedEntry entry;
  const _CombinedCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final color = entry.isGas ? AppColors.green : const Color(0xFF5B8DB8);
    final dateStr = DateFormat('dd. MMM yyyy, HH:mm', 'de_DE').format(entry.timestamp);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(14), boxShadow: AppColors.neu(5)),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(entry.isGas ? Icons.local_fire_department : Icons.bolt, color: color, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dateStr, style: GoogleFonts.rajdhani(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text('${entry.value.toStringAsFixed(entry.unit == 'm³' ? 3 : 2)} ${entry.unit}', style: GoogleFonts.spaceMono(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              ],
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
  final double value;
  final DateTime timestamp;
  final String? note;
  final double? delta;
  final double? cost;
  final String unit;
  final Color accentColor;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _ReadingCard({
    required this.value,
    required this.timestamp,
    required this.note,
    required this.delta,
    required this.cost,
    required this.unit,
    required this.accentColor,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd. MMM yyyy, HH:mm', 'de_DE').format(timestamp);
    final decimals = unit == 'm³' ? 3 : 2;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(14), boxShadow: AppColors.neu(5)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.access_time_rounded, size: 12, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(dateStr, style: GoogleFonts.rajdhani(fontSize: 13, color: AppColors.textSecondary, letterSpacing: 0.5)),
              const Spacer(),
              GestureDetector(
                onTap: onEdit,
                child: Container(width: 30, height: 30, decoration: BoxDecoration(color: AppColors.amber.withOpacity(0.10), borderRadius: BorderRadius.circular(8)), child: Icon(Icons.edit_outlined, size: 15, color: AppColors.amber)),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onDelete,
                child: Container(width: 30, height: 30, decoration: BoxDecoration(color: AppColors.error.withOpacity(0.10), borderRadius: BorderRadius.circular(8)), child: Icon(Icons.delete_outline, size: 16, color: AppColors.error)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value.toStringAsFixed(decimals), style: GoogleFonts.spaceMono(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(width: 6),
              Text(unit, style: GoogleFonts.rajdhani(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
              const Spacer(),
              if (cost != null) Text(NumberFormat.currency(locale: 'de_DE', symbol: '€').format(cost), style: GoogleFonts.spaceMono(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.amber)),
            ],
          ),
          if (delta != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(delta! > 0 ? Icons.arrow_upward : Icons.remove, size: 12, color: accentColor),
                const SizedBox(width: 4),
                Text('${delta!.toStringAsFixed(decimals)} $unit', style: GoogleFonts.rajdhani(fontSize: 13, color: accentColor, fontWeight: FontWeight.w600)),
                const SizedBox(width: 6),
                Text('seit voriger Ablesung', style: GoogleFonts.rajdhani(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ],
          if (note != null && note!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: AppColors.border.withOpacity(0.5), borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  Icon(Icons.notes, size: 12, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(child: Text(note!, style: GoogleFonts.rajdhani(fontSize: 13, color: AppColors.textSecondary, fontStyle: FontStyle.italic))),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
