import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../database/database.dart';
import '../services/cost_service.dart';
import '../services/ocr_service.dart';
import '../widgets/consumption_chart.dart';
import 'electricity_detail_screen.dart';
import 'gas_detail_screen.dart';
import 'scan_screen.dart';

const _neuBase    = Color(0xFFEAEEE6);
const _neuGreen   = Color(0xFF6B8F6B);
const _neuGreenDk = Color(0xFF446B47);
const _neuBlue    = Color(0xFF5B8DB8);
const _neuBlueDk  = Color(0xFF3D6A8A);
const _neuAmber   = Color(0xFFB08B5E);
const _neuText    = Color(0xFF2A3B2B);
const _neuTextSec = Color(0xFF7A8E7B);

List<BoxShadow> _neu([double d = 7]) => [
  BoxShadow(color: const Color(0xFFFFFFFF).withOpacity(0.90), offset: Offset(-d, -d), blurRadius: d * 2.0),
  BoxShadow(color: const Color(0xFFC2CFC0), offset: Offset(d, d), blurRadius: d * 2.0),
];

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _costService = CostService();
  double _gasPrice = 0.09;
  double _brennwert = 0.0;
  double _zustandszahl = 0.0;
  double _elecPrice = 0.30;

  @override
  void initState() {
    super.initState();
    _loadPrices();
  }

  Future<void> _loadPrices() async {
    final gasContract = await AppDatabase.instance.getLatestContract();
    final elecContract = await AppDatabase.instance.getLatestElectricityContract();
    if (mounted) {
      setState(() {
        if (gasContract != null) {
          _gasPrice = gasContract.pricePerKwh;
          _brennwert = gasContract.brennwert;
          _zustandszahl = gasContract.zustandszahl;
        }
        if (elecContract != null) _elecPrice = elecContract.pricePerKwh;
      });
    }
  }

  double _monthConsumption(List<({double value, DateTime timestamp})> readings) {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    final monthR = readings.where((r) => !r.timestamp.isBefore(monthStart) && !r.timestamp.isAfter(monthEnd)).toList();
    if (monthR.length >= 2) {
      final c = monthR.first.value - monthR.last.value;
      return c < 0 ? 0 : c;
    }
    if (monthR.length == 1 && readings.length >= 2) {
      final before = readings.where((r) => r.timestamp.isBefore(monthStart)).toList();
      if (before.isNotEmpty) {
        final c = monthR.first.value - before.first.value;
        return c < 0 ? 0 : c;
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _neuBase,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('HOMERGY', style: GoogleFonts.rajdhani(fontSize: 30, fontWeight: FontWeight.w700, color: _neuGreenDk, letterSpacing: 5, height: 1.0)),
                  const SizedBox(height: 2),
                  Text('VERBRAUCHSMONITOR', style: GoogleFonts.spaceMono(fontSize: 9, fontWeight: FontWeight.w400, color: _neuTextSec, letterSpacing: 2.5)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // GAS card
                    StreamBuilder<List<MeterReading>>(
                      stream: AppDatabase.instance.watchAllReadings(),
                      builder: (context, snap) {
                        final readings = snap.data ?? [];
                        final points = readings.map((r) => (value: r.value, timestamp: r.timestamp)).toList();
                        final last = readings.isNotEmpty ? readings.first : null;
                        final monthC = _monthConsumption(points);
                        final monthCost = _costService.calculateCost(monthC, pricePerKwh: _gasPrice, monthlyBasePrice: 0, brennwert: _brennwert, zustandszahl: _zustandszahl);
                        final sparkPoints = readings.map((r) => ReadingPoint(value: r.value, timestamp: r.timestamp)).toList();

                        return _MeterCard(
                          icon: Icons.local_fire_department,
                          label: 'GAS',
                          accentColor: _neuGreen,
                          accentDark: _neuGreenDk,
                          lastValue: last?.value != null ? '${last!.value.toStringAsFixed(3)} m³' : '— m³',
                          lastDate: last != null ? DateFormat('dd.MM.yyyy', 'de_DE').format(last.timestamp) : null,
                          monthConsumption: '${monthC.toStringAsFixed(2)} m³',
                          monthCost: NumberFormat.currency(locale: 'de_DE', symbol: '€').format(monthCost),
                          sparklineReadings: sparkPoints,
                          onTap: () async {
                            await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GasDetailScreen()));
                            _loadPrices();
                          },
                          onScan: () async {
                            await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ScanScreen(meterType: MeterType.gas)));
                            _loadPrices();
                          },
                        );
                      },
                    ),

                    const SizedBox(height: 20),

                    // STROM card
                    StreamBuilder<List<ElectricityReading>>(
                      stream: AppDatabase.instance.watchAllElectricityReadings(),
                      builder: (context, snap) {
                        final readings = snap.data ?? [];
                        final points = readings.map((r) => (value: r.value, timestamp: r.timestamp)).toList();
                        final last = readings.isNotEmpty ? readings.first : null;
                        final monthC = _monthConsumption(points);
                        final monthCost = monthC * _elecPrice;
                        final sparkPoints = readings.map((r) => ReadingPoint(value: r.value, timestamp: r.timestamp)).toList();

                        return _MeterCard(
                          icon: Icons.bolt,
                          label: 'STROM',
                          accentColor: _neuBlue,
                          accentDark: _neuBlueDk,
                          lastValue: last?.value != null ? '${last!.value.toStringAsFixed(1)} kWh' : '— kWh',
                          lastDate: last != null ? DateFormat('dd.MM.yyyy', 'de_DE').format(last.timestamp) : null,
                          monthConsumption: '${monthC.toStringAsFixed(1)} kWh',
                          monthCost: NumberFormat.currency(locale: 'de_DE', symbol: '€').format(monthCost),
                          sparklineReadings: sparkPoints,
                          onTap: () async {
                            await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ElectricityDetailScreen()));
                            _loadPrices();
                          },
                          onScan: () async {
                            await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ScanScreen(meterType: MeterType.electricity)));
                            _loadPrices();
                          },
                        );
                      },
                    ),
                  ],
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
// Meter card widget
// ---------------------------------------------------------------------------

class _MeterCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accentColor, accentDark;
  final String lastValue;
  final String? lastDate;
  final String monthConsumption, monthCost;
  final List<ReadingPoint> sparklineReadings;
  final VoidCallback onTap, onScan;

  const _MeterCard({
    required this.icon,
    required this.label,
    required this.accentColor,
    required this.accentDark,
    required this.lastValue,
    this.lastDate,
    required this.monthConsumption,
    required this.monthCost,
    required this.sparklineReadings,
    required this.onTap,
    required this.onScan,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
        decoration: BoxDecoration(
          color: _neuBase,
          borderRadius: BorderRadius.circular(24),
          boxShadow: _neu(9),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: icon + label + chevron
            Row(
              children: [
                Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(color: accentColor.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, color: accentColor, size: 20),
                ),
                const SizedBox(width: 12),
                Text(label, style: GoogleFonts.spaceMono(fontSize: 13, fontWeight: FontWeight.w700, color: accentDark, letterSpacing: 2)),
                const Spacer(),
                Icon(Icons.arrow_forward_ios_rounded, size: 14, color: _neuTextSec.withOpacity(0.5)),
              ],
            ),
            const SizedBox(height: 14),

            // Last reading
            Text(lastValue, style: GoogleFonts.spaceMono(fontSize: 26, fontWeight: FontWeight.w700, color: _neuText, letterSpacing: 1)),
            if (lastDate != null)
              Text('Letzte Ablesung: $lastDate', style: GoogleFonts.rajdhani(fontSize: 12, color: _neuTextSec)),

            const SizedBox(height: 12),

            // Sparkline
            MiniSparkline(readings: sparklineReadings, accentColor: accentColor, height: 60),

            const SizedBox(height: 14),

            // Month stats row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('DIESEN MONAT', style: GoogleFonts.rajdhani(fontSize: 10, color: _neuTextSec, letterSpacing: 1.5, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(monthConsumption, style: GoogleFonts.spaceMono(fontSize: 14, fontWeight: FontWeight.w700, color: accentDark)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('KOSTEN (ARBEIT)', style: GoogleFonts.rajdhani(fontSize: 10, color: _neuTextSec, letterSpacing: 1.5, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(monthCost, style: GoogleFonts.spaceMono(fontSize: 14, fontWeight: FontWeight.w700, color: _neuAmber)),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Ablesen button
            GestureDetector(
              onTap: onScan,
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFFFFFFFF).withOpacity(0.4), offset: const Offset(-4, -4), blurRadius: 8),
                    BoxShadow(color: accentDark.withOpacity(0.6), offset: const Offset(4, 4), blurRadius: 8),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.document_scanner_outlined, color: Colors.white, size: 18),
                    const SizedBox(width: 10),
                    Text('ABLESEN', style: GoogleFonts.spaceMono(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 2.5)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
