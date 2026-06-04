import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../database/database.dart';
import '../services/cost_service.dart';
import '../services/weather_service.dart';
import 'cost_detail_screen.dart';
import 'scan_screen.dart';

// ── Neumorphic Sage-Green palette (from color1.PNG + neum.png) ───────────────
const _neuBase    = Color(0xFFEAEEE6); // warm sage off-white — THE base surface
const _neuGreen   = Color(0xFF6B8F6B); // primary sage green (accent)
const _neuGreenDk = Color(0xFF446B47); // deep forest green (headings, meter)
const _neuAmber   = Color(0xFFB08B5E); // earthy amber/tan (secondary accent)
const _neuText    = Color(0xFF2A3B2B); // near-black deep green
const _neuTextSec = Color(0xFF7A8E7B); // muted sage secondary text
const _tempLineColor = Color(0xFF7BA3C0); // muted blue for temperature line

/// Returns neumorphic dual-shadow: white highlight + sage-grey depth.
List<BoxShadow> _neu([double d = 7]) => [
  BoxShadow(
    color: const Color(0xFFFFFFFF).withOpacity(0.90),
    offset: Offset(-d, -d),
    blurRadius: d * 2.0,
  ),
  BoxShadow(
    color: const Color(0xFFC2CFC0),
    offset: Offset(d, d),
    blurRadius: d * 2.0,
  ),
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _costService = CostService();
  double _kwhPrice = 0.09;
  double _brennwert = 0.0;
  double _zustandszahl = 0.0;
  int _chartRefreshKey = 0;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadPrice();
  }

  Future<void> _loadPrice() async {
    final contract = await AppDatabase.instance.getLatestContract();
    if (mounted && contract != null) {
      setState(() {
        _kwhPrice = contract.pricePerKwh;
        _brennwert = contract.brennwert;
        _zustandszahl = contract.zustandszahl;
      });
    }
  }

  Future<void> _refresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    await _loadPrice();
    if (mounted) {
      setState(() {
        _chartRefreshKey++;
        _isRefreshing = false;
      });
    }
  }

  /// Inline neumorphic meter value display (replaces dark-themed MeterDisplay widget).
  Widget _buildMeterValue(double? value) {
    if (value == null) {
      return FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          '-------.---',
          style: GoogleFonts.spaceMono(
            fontSize: 48,
            fontWeight: FontWeight.w700,
            color: _neuTextSec.withOpacity(0.35),
            letterSpacing: 3,
          ),
        ),
      );
    }
    final formatted = value.toStringAsFixed(3);
    final parts = formatted.split('.');
    final intPart = parts[0];
    final decPart = parts.length > 1 ? parts[1] : '000';
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            intPart,
            style: GoogleFonts.spaceMono(
              fontSize: 52,
              fontWeight: FontWeight.w700,
              color: _neuGreenDk,
              letterSpacing: 3,
            ),
          ),
          Text(
            '.',
            style: GoogleFonts.spaceMono(
              fontSize: 40,
              fontWeight: FontWeight.w700,
              color: _neuGreen,
            ),
          ),
          Text(
            decPart,
            style: GoogleFonts.spaceMono(
              fontSize: 32,
              fontWeight: FontWeight.w400,
              color: _neuGreen.withOpacity(0.65),
              letterSpacing: 2,
            ),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              'm³',
              style: GoogleFonts.rajdhani(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _neuTextSec,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _neuBase,
      body: SafeArea(
        child: StreamBuilder<List<MeterReading>>(
          stream: AppDatabase.instance.watchAllReadings(),
          builder: (context, snapshot) {
            final readings = snapshot.data ?? [];
            final lastReading = readings.isNotEmpty ? readings.first : null;

            // Current month stats
            final now = DateTime.now();
            final monthStart = DateTime(now.year, now.month, 1);
            final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

            final monthReadings = readings
                .where((r) =>
                    !r.timestamp.isBefore(monthStart) &&
                    !r.timestamp.isAfter(monthEnd))
                .toList();

            double monthConsumption = 0;
            if (monthReadings.length >= 2) {
              final values = monthReadings.map((r) => r.value).toList();
              monthConsumption = values.first - values.last;
              if (monthConsumption < 0) monthConsumption = 0;
            } else if (monthReadings.length == 1 && readings.length >= 2) {
              final beforeMonth = readings
                  .where((r) => r.timestamp.isBefore(monthStart))
                  .toList();
              if (beforeMonth.isNotEmpty) {
                monthConsumption =
                    monthReadings.first.value - beforeMonth.first.value;
                if (monthConsumption < 0) monthConsumption = 0;
              }
            }

            final monthCost = _costService.calculateCost(
              monthConsumption,
              pricePerKwh: _kwhPrice,
              monthlyBasePrice: 0,
              brennwert: _brennwert,
              zustandszahl: _zustandszahl,
            );
            final monthKwh = _costService.kwhFromM3(
              monthConsumption,
              brennwert: _brennwert,
              zustandszahl: _zustandszahl,
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // ── Header ─────────────────────────────────────────
                          _buildHeader(),
                          const SizedBox(height: 28),

                          // ── Meter card ──────────────────────────────────────
                          Container(
                            padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
                            decoration: BoxDecoration(
                              color: _neuBase,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: _neu(9),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'AKTUELLER ZÄHLERSTAND',
                                  style: GoogleFonts.rajdhani(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: _neuTextSec,
                                    letterSpacing: 2,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                _buildMeterValue(lastReading?.value),
                                if (lastReading != null) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Abgelesen am ${DateFormat('dd. MMM yyyy, HH:mm', 'de_DE').format(lastReading.timestamp)}',
                                    style: GoogleFonts.rajdhani(
                                      fontSize: 13,
                                      color: _neuTextSec,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          const SizedBox(height: 28),

                          // ── Month stats ─────────────────────────────────────
                          Padding(
                            padding: const EdgeInsets.only(left: 4, bottom: 12),
                            child: Text(
                              'DIESEN MONAT',
                              style: GoogleFonts.rajdhani(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _neuTextSec,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: _StatCard(
                                  label: 'Verbrauch',
                                  value: monthConsumption.toStringAsFixed(3),
                                  unit: 'm³',
                                  subValue: '≈ ${monthKwh.toStringAsFixed(1)} kWh',
                                  icon: Icons.local_fire_department_outlined,
                                  iconColor: _neuGreenDk,
                                  onInfoTap: () => showDialog(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      backgroundColor: _neuBase,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(20)),
                                      content: Text(
                                        'Für eine genauere Berechnung gib in den Einstellungen deinen Gas-Brennwert sowie deine Gas-Zustandszahl an. Diese Werte bekommst du von deinem Gas-Anbieter.',
                                        style: GoogleFonts.rajdhani(
                                          fontSize: 14,
                                          color: _neuTextSec,
                                          height: 1.5,
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(),
                                          child: Text(
                                            'OK',
                                            style: GoogleFonts.rajdhani(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: _neuGreen,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: _StatCard(
                                  label: 'Kosten',
                                  value: NumberFormat.currency(
                                          locale: 'de_DE', symbol: '€')
                                      .format(monthCost),
                                  unit: 'nur Arbeitskosten',
                                  icon: Icons.euro_outlined,
                                  iconColor: _neuAmber,
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const CostDetailScreen()),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 28),

                          // ── Chart ───────────────────────────────────────────
                          Padding(
                            padding: const EdgeInsets.only(left: 4, bottom: 12),
                            child: Row(
                              children: [
                                Text(
                                  'VERBRAUCH',
                                  style: GoogleFonts.rajdhani(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: _neuTextSec,
                                    letterSpacing: 2,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                GestureDetector(
                                  onTap: () => showDialog(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      backgroundColor: _neuBase,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(20)),
                                      title: Text(
                                        'Chart-Infos',
                                        style: GoogleFonts.rajdhani(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: _neuText,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _ChartInfoRow(
                                            color: _neuGreen,
                                            text:
                                                'Tippe auf einen Datenpunkt – angezeigt wird die Verbrauchsdifferenz (m³) gegenüber dem Vortag.',
                                          ),
                                          const SizedBox(height: 12),
                                          _ChartInfoRow(
                                            color: _tempLineColor,
                                            dashed: true,
                                            text:
                                                'Die gestrichelte Linie zeigt die Tagesdurchschnittstemperatur deines Wohnorts. Da der heutige Durchschnitt noch nicht vollständig vorliegt, endet die Anzeige stets mit dem gestrigen Tag.',
                                          ),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(),
                                          child: Text(
                                            'OK',
                                            style: GoogleFonts.rajdhani(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: _neuGreen,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.info_outline_rounded,
                                    size: 14,
                                    color: _neuTextSec.withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _ConsumptionChart(
                            key: ValueKey(_chartRefreshKey),
                            readings: readings,
                            onExpand: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ChartFullscreenScreen(
                                    readings: readings),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── ABLESEN button ──────────────────────────────────────────
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                  child: _ScanButton(onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ScanScreen()),
                    );
                    _loadPrice();
                  }),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'HOMERGY',
                style: GoogleFonts.rajdhani(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: _neuGreenDk,
                  letterSpacing: 5,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'VERBRAUCHSMONITOR',
                style: GoogleFonts.spaceMono(
                  fontSize: 9,
                  fontWeight: FontWeight.w400,
                  color: _neuTextSec,
                  letterSpacing: 2.5,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Refresh — neumorphic circle
          GestureDetector(
            onTap: _refresh,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _neuBase,
                shape: BoxShape.circle,
                boxShadow: _neu(5),
              ),
              child: _isRefreshing
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: _neuGreen),
                    )
                  : const Icon(Icons.refresh_rounded,
                      color: _neuGreen, size: 20),
            ),
          ),
          const SizedBox(width: 10),
          // Flame badge — neumorphic circle
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _neuBase,
              shape: BoxShape.circle,
              boxShadow: _neu(5),
            ),
            child: const Icon(Icons.local_fire_department,
                color: _neuAmber, size: 22),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 7-day consumption chart
// ---------------------------------------------------------------------------

class _DayStat {
  final DateTime date;
  final double? consumption;
  final int daysCovered;
  const _DayStat({required this.date, this.consumption, this.daysCovered = 1});
}

class _SpotData {
  final FlSpot spot;
  final int periodsCovered;
  final double totalConsumption;
  const _SpotData(this.spot,
      {this.periodsCovered = 1, required this.totalConsumption});
}

enum _ChartPeriod { week, month, year }

class _ConsumptionChart extends StatefulWidget {
  final List<MeterReading> readings;
  final double chartHeight;
  final VoidCallback? onExpand;
  const _ConsumptionChart({
    super.key,
    required this.readings,
    this.chartHeight = 160,
    this.onExpand,
  });

  @override
  State<_ConsumptionChart> createState() => _ConsumptionChartState();
}

class _ConsumptionChartState extends State<_ConsumptionChart> {
  static const _weekdayLabels = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
  static const _monthLabels = [
    'Jan', 'Feb', 'Mär', 'Apr', 'Mai', 'Jun',
    'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez',
  ];

  _ChartPeriod _period = _ChartPeriod.week;
  int? _touchedSpotIndex;

  double? _lat, _lon;
  Map<DateTime, double> _temperatures = {};
  _ChartPeriod? _lastWeatherPeriod;

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    final settings = await AppDatabase.instance.getSettings();
    if (settings?.locationLat == null || settings?.locationLon == null) return;
    _lat = settings!.locationLat;
    _lon = settings.locationLon;
    await _fetchWeather();
  }

  Future<void> _fetchWeather() async {
    if (_lat == null || _lon == null) return;
    final now = DateTime.now();
    late DateTime start, end;
    switch (_period) {
      case _ChartPeriod.week:
        start = DateTime(now.year, now.month, now.day - 6);
        end = now;
      case _ChartPeriod.month:
        start = DateTime(now.year, now.month, 1);
        end = now;
      case _ChartPeriod.year:
        start = DateTime(now.year, 1, 1);
        end = now;
    }
    final temps = await WeatherService().getTemperatures(
      lat: _lat!,
      lon: _lon!,
      start: start,
      end: end,
    );
    if (mounted) {
      setState(() {
        _temperatures = temps;
        _lastWeatherPeriod = _period;
      });
    }
  }

  void _switchPeriod(_ChartPeriod p) {
    setState(() {
      _period = p;
      _touchedSpotIndex = null;
    });
    if (_lastWeatherPeriod != p) _fetchWeather();
  }

  String _dayKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

  List<_DayStat> _buildWeekStats() {
    final now = DateTime.now();
    final days =
        List.generate(7, (i) => DateTime(now.year, now.month, now.day - 6 + i));
    final maxByDay = <String, double>{};
    for (final r in widget.readings) {
      final k = _dayKey(
          DateTime(r.timestamp.year, r.timestamp.month, r.timestamp.day));
      final ex = maxByDay[k];
      if (ex == null || r.value > ex) maxByDay[k] = r.value;
    }
    final stats = <_DayStat>[];
    for (int i = 0; i < days.length; i++) {
      final todayMax = maxByDay[_dayKey(days[i])];
      double? consumption;
      int daysCovered = 1;
      if (todayMax != null) {
        for (int j = i - 1; j >= 0; j--) {
          final prevMax = maxByDay[_dayKey(days[j])];
          if (prevMax != null) {
            consumption = (todayMax - prevMax).clamp(0.0, double.infinity);
            daysCovered = i - j;
            break;
          }
        }
      }
      stats.add(_DayStat(
          date: days[i], consumption: consumption, daysCovered: daysCovered));
    }
    return stats;
  }

  List<_SpotData> _buildMonthSpotData() {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);

    final maxByDay = <int, double>{};
    for (final r in widget.readings) {
      if (r.timestamp.year == now.year && r.timestamp.month == now.month) {
        final d = r.timestamp.day;
        final ex = maxByDay[d];
        if (ex == null || r.value > ex) maxByDay[d] = r.value;
      }
    }

    final beforeMonth =
        widget.readings.where((r) => r.timestamp.isBefore(monthStart)).toList();
    final anchorValue = beforeMonth.isNotEmpty ? beforeMonth.first.value : null;

    final result = <_SpotData>[];
    for (int day = 1; day <= now.day; day++) {
      final dayMax = maxByDay[day];
      if (dayMax == null) continue;
      int prevDay = 0;
      double? prevMax;
      for (int pd = day - 1; pd >= 1; pd--) {
        if (maxByDay[pd] != null) {
          prevMax = maxByDay[pd];
          prevDay = pd;
          break;
        }
      }
      prevMax ??= anchorValue;
      if (prevMax == null) continue;
      final total = (dayMax - prevMax).clamp(0.0, double.infinity);
      final days = day - prevDay;
      result.add(_SpotData(
        FlSpot(day.toDouble(), total / days),
        periodsCovered: days,
        totalConsumption: total,
      ));
    }
    return result;
  }

  List<_SpotData> _buildYearSpotData() {
    final now = DateTime.now();

    final maxByMonth = <int, double>{};
    for (final r in widget.readings) {
      if (r.timestamp.year == now.year) {
        final m = r.timestamp.month - 1;
        final ex = maxByMonth[m];
        if (ex == null || r.value > ex) maxByMonth[m] = r.value;
      }
    }

    final prevYear =
        widget.readings.where((r) => r.timestamp.year < now.year).toList();
    final anchorValue = prevYear.isNotEmpty ? prevYear.first.value : null;

    final result = <_SpotData>[];
    for (int m = 0; m < now.month; m++) {
      final monthMax = maxByMonth[m];
      if (monthMax == null) continue;
      int prevM = -1;
      double? prevMax;
      for (int pm = m - 1; pm >= 0; pm--) {
        if (maxByMonth[pm] != null) {
          prevMax = maxByMonth[pm];
          prevM = pm;
          break;
        }
      }
      prevMax ??= anchorValue;
      if (prevMax == null) continue;
      final total = (monthMax - prevMax).clamp(0.0, double.infinity);
      final months = m - prevM;
      result.add(_SpotData(
        FlSpot(m.toDouble(), total / months),
        periodsCovered: months,
        totalConsumption: total,
      ));
    }
    return result;
  }

  List<FlSpot> _buildRawTempSpots(List<_DayStat> weekStats) {
    if (_temperatures.isEmpty) return [];
    final now = DateTime.now();
    switch (_period) {
      case _ChartPeriod.week:
        final spots = <FlSpot>[];
        for (int i = 0; i < weekStats.length; i++) {
          final d = weekStats[i].date;
          final temp = _temperatures[DateTime(d.year, d.month, d.day)];
          if (temp != null) spots.add(FlSpot(i.toDouble(), temp));
        }
        return spots;
      case _ChartPeriod.month:
        final spots = <FlSpot>[];
        for (int day = 1; day <= now.day; day++) {
          final temp = _temperatures[DateTime(now.year, now.month, day)];
          if (temp != null) spots.add(FlSpot(day.toDouble(), temp));
        }
        return spots;
      case _ChartPeriod.year:
        final spots = <FlSpot>[];
        for (int m = 0; m < now.month; m++) {
          final monthTemps = <double>[];
          for (int d = 1; d <= 31; d++) {
            final key = DateTime(now.year, m + 1, d);
            if (key.month != m + 1) break;
            final temp = _temperatures[key];
            if (temp != null) monthTemps.add(temp);
          }
          if (monthTemps.isNotEmpty) {
            final avg = monthTemps.reduce((a, b) => a + b) / monthTemps.length;
            spots.add(FlSpot(m.toDouble(), avg));
          }
        }
        return spots;
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    List<_DayStat> weekStats = [];
    List<FlSpot> spots = [];
    Map<double, int> coverageByX = {};
    Map<double, double> totalByX = {};
    double minX = 0, maxX = 6;

    switch (_period) {
      case _ChartPeriod.week:
        weekStats = _buildWeekStats();
        for (int i = 0; i < weekStats.length; i++) {
          if (weekStats[i].consumption != null) {
            final total = weekStats[i].consumption!;
            final days = weekStats[i].daysCovered;
            spots.add(FlSpot(i.toDouble(), total / days));
            coverageByX[i.toDouble()] = days;
            totalByX[i.toDouble()] = total;
          }
        }
        minX = -0.4;
        maxX = 6.4;
      case _ChartPeriod.month:
        final monthData = _buildMonthSpotData();
        spots = monthData.map((d) => d.spot).toList();
        coverageByX = {for (final d in monthData) d.spot.x: d.periodsCovered};
        totalByX = {for (final d in monthData) d.spot.x: d.totalConsumption};
        minX = 0.5;
        maxX = DateTime(now.year, now.month + 1, 0).day.toDouble() + 0.5;
      case _ChartPeriod.year:
        final yearData = _buildYearSpotData();
        spots = yearData.map((d) => d.spot).toList();
        coverageByX = {for (final d in yearData) d.spot.x: d.periodsCovered};
        totalByX = {for (final d in yearData) d.spot.x: d.totalConsumption};
        minX = -0.4;
        maxX = 11.4;
    }

    final hasData = spots.isNotEmpty;
    final rawMax =
        hasData ? spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) : 0.0;
    final chartMaxY = rawMax < 0.001 ? 1.0 : rawMax * 1.35;
    final yInterval = chartMaxY / 3;

    final rawTempSpots = _buildRawTempSpots(weekStats);
    double tempMin = 0, tempMax = 20, tempRange = 20;
    List<FlSpot> tempSpots = [];
    if (rawTempSpots.isNotEmpty && chartMaxY > 0) {
      final vals = rawTempSpots.map((s) => s.y).toList();
      tempMin = vals.reduce((a, b) => a < b ? a : b) - 2;
      tempMax = vals.reduce((a, b) => a > b ? a : b) + 2;
      tempRange = (tempMax - tempMin).clamp(1.0, double.infinity);
      tempSpots = rawTempSpots.map((s) {
        final norm = (s.y - tempMin) / tempRange * chartMaxY;
        return FlSpot(s.x, norm.clamp(0.0, chartMaxY));
      }).toList();
    }
    final hasTempData = tempSpots.isNotEmpty;
    final tempByX = {for (final s in rawTempSpots) s.x: s.y};

    final barData = LineChartBarData(
      spots: spots,
      isCurved: true,
      curveSmoothness: 0.35,
      preventCurveOverShooting: true,
      color: _neuGreen,
      barWidth: 2.5,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, bar, index) {
          final coverage = coverageByX[spot.x] ?? 1;
          return FlDotCirclePainter(
            radius: coverage > 1 ? 4.5 : 3.0,
            color: _neuGreen,
            strokeWidth: coverage > 1 ? 2.0 : 1.5,
            strokeColor: _neuBase,
          );
        },
      ),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _neuGreen.withOpacity(0.20),
            _neuGreen.withOpacity(0.0),
          ],
        ),
      ),
    );

    final tempBarData = LineChartBarData(
      spots: tempSpots,
      isCurved: true,
      curveSmoothness: 0.35,
      preventCurveOverShooting: true,
      color: _tempLineColor,
      barWidth: 1.5,
      dashArray: [5, 4],
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(show: false),
    );

    Widget bottomTitle(double value, TitleMeta meta) {
      Widget? label;
      switch (_period) {
        case _ChartPeriod.week:
          final i = value.round();
          if (i < 0 || i >= weekStats.length) break;
          final isToday = i == 6;
          label = Text(
            _weekdayLabels[weekStats[i].date.weekday - 1],
            style: GoogleFonts.rajdhani(
              fontSize: 11,
              fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
              color: isToday ? _neuGreenDk : _neuTextSec,
            ),
          );
        case _ChartPeriod.month:
          final day = value.round();
          final lastDay = maxX.round();
          if (day == 1 || day % 5 == 0 || day == lastDay) {
            label = Text(
              '$day',
              style: GoogleFonts.rajdhani(fontSize: 10, color: _neuTextSec),
            );
          }
        case _ChartPeriod.year:
          final m = value.round();
          if (m >= 0 && m <= 11) {
            label = Text(
              _monthLabels[m],
              style: GoogleFonts.rajdhani(fontSize: 10, color: _neuTextSec),
            );
          }
      }
      if (label == null) return const SizedBox.shrink();
      return Padding(padding: const EdgeInsets.only(top: 6), child: label);
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 14, 14, 10),
      decoration: BoxDecoration(
        color: _neuBase,
        borderRadius: BorderRadius.circular(22),
        boxShadow: _neu(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tab-Switcher + legend
          Row(
            children: [
              _PeriodTab(
                label: '7T',
                selected: _period == _ChartPeriod.week,
                onTap: () => _switchPeriod(_ChartPeriod.week),
              ),
              const SizedBox(width: 4),
              _PeriodTab(
                label: 'Monat',
                selected: _period == _ChartPeriod.month,
                onTap: () => _switchPeriod(_ChartPeriod.month),
              ),
              const SizedBox(width: 4),
              _PeriodTab(
                label: 'Jahr',
                selected: _period == _ChartPeriod.year,
                onTap: () => _switchPeriod(_ChartPeriod.year),
              ),
              const Spacer(),
              if (_temperatures.isNotEmpty) ...[
                _ChartLegendDot(color: _neuGreen, label: 'm³'),
                const SizedBox(width: 10),
                _ChartLegendDot(color: _tempLineColor, label: '°C'),
                const SizedBox(width: 10),
              ],
              if (widget.onExpand != null)
                GestureDetector(
                  onTap: widget.onExpand,
                  child: Icon(Icons.fullscreen_rounded,
                      size: 20, color: _neuTextSec.withOpacity(0.5)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: widget.chartHeight,
            child: hasData
                ? LineChart(LineChartData(
                    minX: minX,
                    maxX: maxX,
                    minY: 0,
                    maxY: chartMaxY,
                    clipData: const FlClipData.all(),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: yInterval,
                      getDrawingHorizontalLine: (_) => FlLine(
                        color: _neuTextSec.withOpacity(0.15),
                        strokeWidth: 0.8,
                        dashArray: [4, 4],
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    showingTooltipIndicators:
                        _touchedSpotIndex != null &&
                                _touchedSpotIndex! < spots.length
                            ? [
                                ShowingTooltipIndicators([
                                  LineBarSpot(
                                      barData, 0, spots[_touchedSpotIndex!]),
                                ])
                              ]
                            : [],
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: hasTempData,
                          reservedSize: 34,
                          interval: yInterval,
                          getTitlesWidget: (value, meta) {
                            if (value <= 0 || value > chartMaxY) {
                              return const SizedBox.shrink();
                            }
                            final tC =
                                tempMin + (value / chartMaxY) * tempRange;
                            return Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Text(
                                '${tC.round()}°',
                                style: GoogleFonts.spaceMono(
                                    fontSize: 9, color: _tempLineColor),
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 46,
                          interval: yInterval,
                          getTitlesWidget: (value, meta) {
                            if (value <= 0 || value > chartMaxY) {
                              return const SizedBox.shrink();
                            }
                            final str = value < 0.1
                                ? value.toStringAsFixed(3)
                                : value < 10
                                    ? value.toStringAsFixed(2)
                                    : value.toStringAsFixed(1);
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Text(
                                str,
                                style: GoogleFonts.spaceMono(
                                    fontSize: 9, color: _neuTextSec),
                                textAlign: TextAlign.right,
                              ),
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 28,
                          interval: 1,
                          getTitlesWidget: bottomTitle,
                        ),
                      ),
                    ),
                    lineBarsData: [barData, if (hasTempData) tempBarData],
                    lineTouchData: LineTouchData(
                      handleBuiltInTouches: false,
                      touchCallback: (event, response) {
                        if (response != null &&
                            response.lineBarSpots != null &&
                            response.lineBarSpots!.isNotEmpty) {
                          final idx = response.lineBarSpots!.first.spotIndex;
                          if (_touchedSpotIndex != idx) {
                            setState(() => _touchedSpotIndex = idx);
                          }
                        } else if (event is FlTapDownEvent) {
                          if (_touchedSpotIndex != null) {
                            setState(() => _touchedSpotIndex = null);
                          }
                        }
                      },
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipColor: (_) => _neuBase,
                        tooltipBorder: BorderSide(
                            color: _neuTextSec.withOpacity(0.2), width: 1),
                        tooltipRoundedRadius: 10,
                        getTooltipItems: (touchedSpots) =>
                            touchedSpots.map((s) {
                          if (s.barIndex == 1) return null;
                          final coverage = coverageByX[s.x] ?? 1;
                          final total = totalByX[s.x] ?? s.y;
                          final avgStr = s.y < 0.1
                              ? s.y.toStringAsFixed(3)
                              : s.y.toStringAsFixed(2);
                          final totalStr = total < 0.1
                              ? total.toStringAsFixed(3)
                              : total.toStringAsFixed(2);
                          final xKey = tempByX.keys
                              .where((k) => (k - s.x).abs() < 0.6)
                              .fold<double?>(
                                  null,
                                  (prev, k) => prev == null ||
                                          (k - s.x).abs() <
                                              (prev - s.x).abs()
                                      ? k
                                      : prev);
                          final tempC = xKey != null
                              ? tempByX[xKey]!.toStringAsFixed(1)
                              : null;
                          final periodLabel =
                              _period == _ChartPeriod.year ? 'Monate' : 'Tage';
                          final avgUnit =
                              _period == _ChartPeriod.year ? 'Mon.' : 'Tag';
                          final mainLabel = coverage > 1
                              ? 'Ø $avgStr m³/$avgUnit'
                              : '$avgStr m³';
                          return LineTooltipItem(
                            mainLabel,
                            GoogleFonts.spaceMono(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _neuGreenDk,
                            ),
                            children: [
                              if (coverage > 1)
                                TextSpan(
                                  text:
                                      '\n$coverage $periodLabel · $totalStr m³ gesamt',
                                  style: GoogleFonts.rajdhani(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: _neuTextSec,
                                  ),
                                ),
                              if (tempC != null)
                                TextSpan(
                                  text: '\n$tempC°C',
                                  style: GoogleFonts.spaceMono(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: _tempLineColor,
                                  ),
                                ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ))
                : Center(
                    child: Text(
                      'Zu wenig Daten',
                      style: GoogleFonts.rajdhani(
                          fontSize: 13, color: _neuTextSec),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Fullscreen chart screen
// ---------------------------------------------------------------------------

class ChartFullscreenScreen extends StatelessWidget {
  final List<MeterReading> readings;
  const ChartFullscreenScreen({super.key, required this.readings});

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
        title: Text(
          'VERBRAUCH',
          style: GoogleFonts.rajdhani(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: _neuTextSec,
            letterSpacing: 3,
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final chartH =
              (constraints.maxHeight - 96).clamp(200.0, double.infinity);
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: _ConsumptionChart(
              readings: readings,
              chartHeight: chartH,
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Period tab button
// ---------------------------------------------------------------------------

class _PeriodTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _PeriodTab(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? _neuGreen : _neuBase,
          borderRadius: BorderRadius.circular(8),
          boxShadow: selected ? _neu(3) : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.rajdhani(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? Colors.white : _neuTextSec,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Chart legend dot
// ---------------------------------------------------------------------------

class _ChartLegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _ChartLegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.rajdhani(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Stat card widget
// ---------------------------------------------------------------------------

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final String? subValue;
  final IconData icon;
  final Color iconColor;
  final VoidCallback? onTap;
  final VoidCallback? onInfoTap;

  const _StatCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.iconColor,
    this.subValue,
    this.onTap,
    this.onInfoTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _neuBase,
          borderRadius: BorderRadius.circular(20),
          boxShadow: _neu(6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Icon in small neumorphic circle
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _neuBase,
                    shape: BoxShape.circle,
                    boxShadow: _neu(3),
                  ),
                  child: Icon(icon, color: iconColor, size: 15),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.rajdhani(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _neuTextSec,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                if (onInfoTap != null)
                  GestureDetector(
                    onTap: onInfoTap,
                    behavior: HitTestBehavior.opaque,
                    child: Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: _neuTextSec.withOpacity(0.5),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: GoogleFonts.spaceMono(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _neuText,
              ),
            ),
            if (unit.isNotEmpty)
              Text(
                unit,
                style: GoogleFonts.rajdhani(
                  fontSize: 12,
                  color: _neuTextSec,
                ),
              ),
            if (subValue != null) ...[
              const SizedBox(height: 4),
              Text(
                subValue!,
                style: GoogleFonts.spaceMono(
                  fontSize: 11,
                  color: iconColor.withOpacity(0.75),
                ),
              ),
            ],
            if (onTap != null) ...[
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.chevron_right_rounded,
                      size: 14, color: _neuTextSec.withOpacity(0.5)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Chart info dialog row
// ---------------------------------------------------------------------------

class _ChartInfoRow extends StatelessWidget {
  final Color color;
  final bool dashed;
  final String text;
  const _ChartInfoRow(
      {required this.color, required this.text, this.dashed = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 5),
          child: dashed
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 5, height: 2, color: color),
                    const SizedBox(width: 2),
                    Container(width: 5, height: 2, color: color),
                  ],
                )
              : Container(
                  width: 8,
                  height: 8,
                  decoration:
                      BoxDecoration(color: color, shape: BoxShape.circle),
                ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.rajdhani(
              fontSize: 13,
              color: _neuTextSec,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Scan button
// ---------------------------------------------------------------------------

class _ScanButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _ScanButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: _neuGreen,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFFFFF).withOpacity(0.45),
              offset: const Offset(-6, -6),
              blurRadius: 12,
            ),
            BoxShadow(
              color: const Color(0xFF3A5E3D),
              offset: const Offset(6, 6),
              blurRadius: 12,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.document_scanner_outlined,
                color: Colors.white, size: 22),
            const SizedBox(width: 12),
            Text(
              'ABLESEN',
              style: GoogleFonts.spaceMono(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
