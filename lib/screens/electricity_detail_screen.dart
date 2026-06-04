import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../database/database.dart';
import '../services/ocr_service.dart';
import '../widgets/consumption_chart.dart';
import 'scan_screen.dart';

const _neuBase    = Color(0xFFEAEEE6);
const _neuBlue    = Color(0xFF5B8DB8);
const _neuBlueDk  = Color(0xFF3D6A8A);
const _neuAmber   = Color(0xFFB08B5E);
const _neuText    = Color(0xFF2A3B2B);
const _neuTextSec = Color(0xFF7A8E7B);

List<BoxShadow> _neu([double d = 7]) => [
  BoxShadow(color: const Color(0xFFFFFFFF).withOpacity(0.90), offset: Offset(-d, -d), blurRadius: d * 2.0),
  BoxShadow(color: const Color(0xFFC2CFC0), offset: Offset(d, d), blurRadius: d * 2.0),
];

class ElectricityDetailScreen extends StatefulWidget {
  const ElectricityDetailScreen({super.key});

  @override
  State<ElectricityDetailScreen> createState() => _ElectricityDetailScreenState();
}

class _ElectricityDetailScreenState extends State<ElectricityDetailScreen> {
  double _pricePerKwh = 0.30;
  int _chartRefreshKey = 0;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadPrice();
  }

  Future<void> _loadPrice() async {
    final contract = await AppDatabase.instance.getLatestElectricityContract();
    if (mounted && contract != null) {
      setState(() {
        _pricePerKwh = contract.pricePerKwh;
      });
    }
  }

  Future<void> _refresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    await _loadPrice();
    if (mounted) setState(() { _chartRefreshKey++; _isRefreshing = false; });
  }

  Widget _buildMeterValue(double? value) {
    if (value == null) {
      return FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text('-------.--', style: GoogleFonts.spaceMono(fontSize: 48, fontWeight: FontWeight.w700, color: _neuTextSec.withOpacity(0.35), letterSpacing: 3)),
      );
    }
    final formatted = value.toStringAsFixed(2);
    final parts = formatted.split('.');
    final intPart = parts[0];
    final decPart = parts.length > 1 ? parts[1] : '00';
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(intPart, style: GoogleFonts.spaceMono(fontSize: 52, fontWeight: FontWeight.w700, color: _neuBlueDk, letterSpacing: 3)),
          Text('.', style: GoogleFonts.spaceMono(fontSize: 40, fontWeight: FontWeight.w700, color: _neuBlue)),
          Text(decPart, style: GoogleFonts.spaceMono(fontSize: 32, fontWeight: FontWeight.w400, color: _neuBlue.withOpacity(0.65), letterSpacing: 2)),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text('kWh', style: GoogleFonts.rajdhani(fontSize: 16, fontWeight: FontWeight.w600, color: _neuTextSec, letterSpacing: 1)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _neuBase,
      appBar: AppBar(
        backgroundColor: _neuBase,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _neuText),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('STROM', style: GoogleFonts.rajdhani(fontSize: 13, fontWeight: FontWeight.w700, color: _neuTextSec, letterSpacing: 4)),
        actions: [
          GestureDetector(
            onTap: _refresh,
            child: Container(
              width: 36, height: 36,
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(color: _neuBase, shape: BoxShape.circle, boxShadow: _neu(4)),
              child: _isRefreshing
                  ? const Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator(strokeWidth: 2, color: _neuBlue))
                  : const Icon(Icons.refresh_rounded, color: _neuBlue, size: 18),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<List<ElectricityReading>>(
          stream: AppDatabase.instance.watchAllElectricityReadings(),
          builder: (context, snapshot) {
            final readings = snapshot.data ?? [];
            final lastReading = readings.isNotEmpty ? readings.first : null;
            final now = DateTime.now();
            final monthStart = DateTime(now.year, now.month, 1);
            final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
            final monthReadings = readings.where((r) => !r.timestamp.isBefore(monthStart) && !r.timestamp.isAfter(monthEnd)).toList();

            double monthConsumption = 0;
            if (monthReadings.length >= 2) {
              monthConsumption = monthReadings.first.value - monthReadings.last.value;
              if (monthConsumption < 0) monthConsumption = 0;
            } else if (monthReadings.length == 1 && readings.length >= 2) {
              final before = readings.where((r) => r.timestamp.isBefore(monthStart)).toList();
              if (before.isNotEmpty) {
                monthConsumption = monthReadings.first.value - before.first.value;
                if (monthConsumption < 0) monthConsumption = 0;
              }
            }

            final monthCost = monthConsumption * _pricePerKwh;
            final readingPoints = readings.map((r) => ReadingPoint(value: r.value, timestamp: r.timestamp)).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 8),
                        // Meter card
                        Container(
                          padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
                          decoration: BoxDecoration(color: _neuBase, borderRadius: BorderRadius.circular(24), boxShadow: _neu(9)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('AKTUELLER ZÄHLERSTAND', style: GoogleFonts.rajdhani(fontSize: 11, fontWeight: FontWeight.w600, color: _neuTextSec, letterSpacing: 2)),
                              const SizedBox(height: 14),
                              _buildMeterValue(lastReading?.value),
                              if (lastReading != null) ...[
                                const SizedBox(height: 8),
                                Text('Abgelesen am ${DateFormat('dd. MMM yyyy, HH:mm', 'de_DE').format(lastReading.timestamp)}', style: GoogleFonts.rajdhani(fontSize: 13, color: _neuTextSec, letterSpacing: 0.3)),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                        // Month stats
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 12),
                          child: Text('DIESEN MONAT', style: GoogleFonts.rajdhani(fontSize: 11, fontWeight: FontWeight.w600, color: _neuTextSec, letterSpacing: 2)),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                label: 'Verbrauch',
                                value: monthConsumption.toStringAsFixed(1),
                                unit: 'kWh',
                                icon: Icons.bolt_outlined,
                                iconColor: _neuBlueDk,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: _StatCard(
                                label: 'Kosten',
                                value: NumberFormat.currency(locale: 'de_DE', symbol: '€').format(monthCost),
                                unit: 'nur Arbeitskosten',
                                icon: Icons.euro_outlined,
                                iconColor: _neuAmber,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        // Chart
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 12),
                          child: Text('VERBRAUCH', style: GoogleFonts.rajdhani(fontSize: 11, fontWeight: FontWeight.w600, color: _neuTextSec, letterSpacing: 2)),
                        ),
                        ConsumptionChart(
                          key: ValueKey(_chartRefreshKey),
                          readings: readingPoints,
                          unit: 'kWh',
                          accentColor: _neuBlue,
                          accentDark: _neuBlueDk,
                          onExpand: () => Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => ChartFullscreenScreen(readings: readingPoints, unit: 'kWh', accentColor: _neuBlue, accentDark: _neuBlueDk),
                          )),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
                // ABLESEN button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                  child: _ScanButton(
                    color: _neuBlue,
                    shadowColor: const Color(0xFF2A4E6A),
                    onPressed: () async {
                      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ScanScreen(meterType: MeterType.electricity)));
                      _loadPrice();
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

class _StatCard extends StatelessWidget {
  final String label, value, unit;
  final IconData icon;
  final Color iconColor;
  const _StatCard({required this.label, required this.value, required this.unit, required this.icon, required this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: _neuBase, borderRadius: BorderRadius.circular(20), boxShadow: _neu(6)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(width: 32, height: 32, decoration: BoxDecoration(color: _neuBase, shape: BoxShape.circle, boxShadow: _neu(3)), child: Icon(icon, color: iconColor, size: 15)),
              const SizedBox(width: 8),
              Expanded(child: Text(label, style: GoogleFonts.rajdhani(fontSize: 12, fontWeight: FontWeight.w600, color: _neuTextSec, letterSpacing: 1))),
              ]),
            const SizedBox(height: 12),
            Text(value, style: GoogleFonts.spaceMono(fontSize: 20, fontWeight: FontWeight.w700, color: _neuText)),
            if (unit.isNotEmpty) Text(unit, style: GoogleFonts.rajdhani(fontSize: 12, color: _neuTextSec)),
          ],
        ),
      );
  }
}

class _ScanButton extends StatelessWidget {
  final Color color, shadowColor;
  final VoidCallback onPressed;
  const _ScanButton({required this.color, required this.shadowColor, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(color: const Color(0xFFFFFFFF).withOpacity(0.45), offset: const Offset(-6, -6), blurRadius: 12),
            BoxShadow(color: shadowColor, offset: const Offset(6, 6), blurRadius: 12),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.document_scanner_outlined, color: Colors.white, size: 22),
            const SizedBox(width: 12),
            Text('ABLESEN', style: GoogleFonts.spaceMono(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 3)),
          ],
        ),
      ),
    );
  }
}
