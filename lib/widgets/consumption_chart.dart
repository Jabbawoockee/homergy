import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../database/database.dart';
import '../services/weather_service.dart';

// ---------------------------------------------------------------------------
// Generic reading data point — convert MeterReading / ElectricityReading here
// ---------------------------------------------------------------------------

class ReadingPoint {
  final double value;
  final DateTime timestamp;
  const ReadingPoint({required this.value, required this.timestamp});
}

// ---------------------------------------------------------------------------
// Shared palette constants
// ---------------------------------------------------------------------------

const _neuBase     = Color(0xFFEAEEE6);
const _neuTextSec  = Color(0xFF7A8E7B);
const _tempLineColor = Color(0xFF7BA3C0);

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

// ---------------------------------------------------------------------------
// Period enum
// ---------------------------------------------------------------------------

enum ChartPeriod { week, month, year }

// ---------------------------------------------------------------------------
// ConsumptionChart — 7T / Monat / Jahr switcher chart
// ---------------------------------------------------------------------------

class ConsumptionChart extends StatefulWidget {
  final List<ReadingPoint> readings;
  final String unit;
  final Color accentColor;
  final Color accentDark;
  final double chartHeight;
  final VoidCallback? onExpand;
  final bool showWeather;

  const ConsumptionChart({
    super.key,
    required this.readings,
    required this.unit,
    required this.accentColor,
    required this.accentDark,
    this.chartHeight = 160,
    this.onExpand,
    this.showWeather = true,
  });

  @override
  State<ConsumptionChart> createState() => _ConsumptionChartState();
}

class _ConsumptionChartState extends State<ConsumptionChart> {
  static const _weekdayLabels = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
  static const _monthLabels = [
    'Jan', 'Feb', 'Mär', 'Apr', 'Mai', 'Jun',
    'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez',
  ];

  ChartPeriod _period = ChartPeriod.week;
  int? _touchedSpotIndex;

  double? _lat, _lon;
  Map<DateTime, double> _temperatures = {};
  ChartPeriod? _lastWeatherPeriod;

  @override
  void initState() {
    super.initState();
    if (widget.showWeather) _loadWeather();
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
      case ChartPeriod.week:
        start = DateTime(now.year, now.month, now.day - 6);
        end = now;
      case ChartPeriod.month:
        start = DateTime(now.year, now.month, 1);
        end = now;
      case ChartPeriod.year:
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

  void _switchPeriod(ChartPeriod p) {
    setState(() {
      _period = p;
      _touchedSpotIndex = null;
    });
    if (widget.showWeather && _lastWeatherPeriod != p) _fetchWeather();
  }

  String _dayKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

  List<_DayStat> _buildWeekStats() {
    final now = DateTime.now();
    final days =
        List.generate(7, (i) => DateTime(now.year, now.month, now.day - 6 + i));
    final maxByDay = <String, double>{};
    for (final r in widget.readings) {
      final k = _dayKey(DateTime(r.timestamp.year, r.timestamp.month, r.timestamp.day));
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
      stats.add(_DayStat(date: days[i], consumption: consumption, daysCovered: daysCovered));
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
        if (maxByDay[pd] != null) { prevMax = maxByDay[pd]; prevDay = pd; break; }
      }
      prevMax ??= anchorValue;
      if (prevMax == null) continue;
      final total = (dayMax - prevMax).clamp(0.0, double.infinity);
      final days = day - prevDay;
      result.add(_SpotData(FlSpot(day.toDouble(), total / days), periodsCovered: days, totalConsumption: total));
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
    final prevYear = widget.readings.where((r) => r.timestamp.year < now.year).toList();
    final anchorValue = prevYear.isNotEmpty ? prevYear.first.value : null;
    final result = <_SpotData>[];
    for (int m = 0; m < now.month; m++) {
      final monthMax = maxByMonth[m];
      if (monthMax == null) continue;
      int prevM = -1;
      double? prevMax;
      for (int pm = m - 1; pm >= 0; pm--) {
        if (maxByMonth[pm] != null) { prevMax = maxByMonth[pm]; prevM = pm; break; }
      }
      prevMax ??= anchorValue;
      if (prevMax == null) continue;
      final total = (monthMax - prevMax).clamp(0.0, double.infinity);
      final months = m - prevM;
      result.add(_SpotData(FlSpot(m.toDouble(), total / months), periodsCovered: months, totalConsumption: total));
    }
    return result;
  }

  List<FlSpot> _buildRawTempSpots(List<_DayStat> weekStats) {
    if (_temperatures.isEmpty) return [];
    final now = DateTime.now();
    switch (_period) {
      case ChartPeriod.week:
        final spots = <FlSpot>[];
        for (int i = 0; i < weekStats.length; i++) {
          final d = weekStats[i].date;
          final temp = _temperatures[DateTime(d.year, d.month, d.day)];
          if (temp != null) spots.add(FlSpot(i.toDouble(), temp));
        }
        return spots;
      case ChartPeriod.month:
        final spots = <FlSpot>[];
        for (int day = 1; day <= now.day; day++) {
          final temp = _temperatures[DateTime(now.year, now.month, day)];
          if (temp != null) spots.add(FlSpot(day.toDouble(), temp));
        }
        return spots;
      case ChartPeriod.year:
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
      case ChartPeriod.week:
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
      case ChartPeriod.month:
        final monthData = _buildMonthSpotData();
        spots = monthData.map((d) => d.spot).toList();
        coverageByX = {for (final d in monthData) d.spot.x: d.periodsCovered};
        totalByX = {for (final d in monthData) d.spot.x: d.totalConsumption};
        minX = 0.5;
        maxX = DateTime(now.year, now.month + 1, 0).day.toDouble() + 0.5;
      case ChartPeriod.year:
        final yearData = _buildYearSpotData();
        spots = yearData.map((d) => d.spot).toList();
        coverageByX = {for (final d in yearData) d.spot.x: d.periodsCovered};
        totalByX = {for (final d in yearData) d.spot.x: d.totalConsumption};
        minX = -0.4;
        maxX = 11.4;
    }

    final hasData = spots.isNotEmpty;
    final rawMax = hasData ? spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) : 0.0;
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
      color: widget.accentColor,
      barWidth: 2.5,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, bar, index) {
          final coverage = coverageByX[spot.x] ?? 1;
          return FlDotCirclePainter(
            radius: coverage > 1 ? 4.5 : 3.0,
            color: widget.accentColor,
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
          colors: [widget.accentColor.withOpacity(0.20), widget.accentColor.withOpacity(0.0)],
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
        case ChartPeriod.week:
          final i = value.round();
          if (i < 0 || i >= weekStats.length) break;
          final isToday = i == 6;
          label = Text(
            _weekdayLabels[weekStats[i].date.weekday - 1],
            style: GoogleFonts.rajdhani(
              fontSize: 11,
              fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
              color: isToday ? widget.accentDark : _neuTextSec,
            ),
          );
        case ChartPeriod.month:
          final day = value.round();
          final lastDay = maxX.round();
          if (day == 1 || day % 5 == 0 || day == lastDay) {
            label = Text('$day', style: GoogleFonts.rajdhani(fontSize: 10, color: _neuTextSec));
          }
        case ChartPeriod.year:
          final m = value.round();
          if (m >= 0 && m <= 11) {
            label = Text(_monthLabels[m], style: GoogleFonts.rajdhani(fontSize: 10, color: _neuTextSec));
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
          Row(
            children: [
              _PeriodTab(label: '7T', selected: _period == ChartPeriod.week, accentColor: widget.accentColor, onTap: () => _switchPeriod(ChartPeriod.week)),
              const SizedBox(width: 4),
              _PeriodTab(label: 'Monat', selected: _period == ChartPeriod.month, accentColor: widget.accentColor, onTap: () => _switchPeriod(ChartPeriod.month)),
              const SizedBox(width: 4),
              _PeriodTab(label: 'Jahr', selected: _period == ChartPeriod.year, accentColor: widget.accentColor, onTap: () => _switchPeriod(ChartPeriod.year)),
              const Spacer(),
              if (_temperatures.isNotEmpty) ...[
                _ChartLegendDot(color: widget.accentColor, label: widget.unit),
                const SizedBox(width: 10),
                _ChartLegendDot(color: _tempLineColor, label: '°C'),
                const SizedBox(width: 10),
              ],
              if (widget.onExpand != null)
                GestureDetector(
                  onTap: widget.onExpand,
                  child: Icon(Icons.fullscreen_rounded, size: 20, color: _neuTextSec.withOpacity(0.5)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: widget.chartHeight,
            child: hasData
                ? LineChart(LineChartData(
                    minX: minX, maxX: maxX, minY: 0, maxY: chartMaxY,
                    clipData: const FlClipData.all(),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: yInterval,
                      getDrawingHorizontalLine: (_) => FlLine(color: _neuTextSec.withOpacity(0.15), strokeWidth: 0.8, dashArray: [4, 4]),
                    ),
                    borderData: FlBorderData(show: false),
                    showingTooltipIndicators: _touchedSpotIndex != null && _touchedSpotIndex! < spots.length
                        ? [ShowingTooltipIndicators([LineBarSpot(barData, 0, spots[_touchedSpotIndex!])])]
                        : [],
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: hasTempData,
                          reservedSize: 34,
                          interval: yInterval,
                          getTitlesWidget: (value, meta) {
                            if (value <= 0 || value > chartMaxY) return const SizedBox.shrink();
                            final tC = tempMin + (value / chartMaxY) * tempRange;
                            return Padding(padding: const EdgeInsets.only(left: 4), child: Text('${tC.round()}°', style: GoogleFonts.spaceMono(fontSize: 9, color: _tempLineColor)));
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 46,
                          interval: yInterval,
                          getTitlesWidget: (value, meta) {
                            if (value <= 0 || value > chartMaxY) return const SizedBox.shrink();
                            final str = value < 0.1 ? value.toStringAsFixed(3) : value < 10 ? value.toStringAsFixed(2) : value.toStringAsFixed(1);
                            return Padding(padding: const EdgeInsets.only(right: 6), child: Text(str, style: GoogleFonts.spaceMono(fontSize: 9, color: _neuTextSec), textAlign: TextAlign.right));
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28, interval: 1, getTitlesWidget: bottomTitle)),
                    ),
                    lineBarsData: [barData, if (hasTempData) tempBarData],
                    lineTouchData: LineTouchData(
                      handleBuiltInTouches: false,
                      touchCallback: (event, response) {
                        if (response?.lineBarSpots != null && response!.lineBarSpots!.isNotEmpty) {
                          final idx = response.lineBarSpots!.first.spotIndex;
                          if (_touchedSpotIndex != idx) setState(() => _touchedSpotIndex = idx);
                        } else if (event is FlTapDownEvent) {
                          if (_touchedSpotIndex != null) setState(() => _touchedSpotIndex = null);
                        }
                      },
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipColor: (_) => _neuBase,
                        tooltipBorder: BorderSide(color: _neuTextSec.withOpacity(0.2), width: 1),
                        tooltipRoundedRadius: 10,
                        getTooltipItems: (touchedSpots) => touchedSpots.map((s) {
                          if (s.barIndex == 1) return null;
                          final coverage = coverageByX[s.x] ?? 1;
                          final total = totalByX[s.x] ?? s.y;
                          final avgStr = s.y < 0.1 ? s.y.toStringAsFixed(3) : s.y.toStringAsFixed(2);
                          final totalStr = total < 0.1 ? total.toStringAsFixed(3) : total.toStringAsFixed(2);
                          final xKey = tempByX.keys.where((k) => (k - s.x).abs() < 0.6).fold<double?>(null, (prev, k) => prev == null || (k - s.x).abs() < (prev - s.x).abs() ? k : prev);
                          final tempC = xKey != null ? tempByX[xKey]!.toStringAsFixed(1) : null;
                          final periodLabel = _period == ChartPeriod.year ? 'Monate' : 'Tage';
                          final avgUnit = _period == ChartPeriod.year ? 'Mon.' : 'Tag';
                          final mainLabel = coverage > 1 ? 'Ø $avgStr ${widget.unit}/$avgUnit' : '$avgStr ${widget.unit}';
                          return LineTooltipItem(
                            mainLabel,
                            GoogleFonts.spaceMono(fontSize: 12, fontWeight: FontWeight.w700, color: widget.accentDark),
                            children: [
                              if (coverage > 1)
                                TextSpan(text: '\n$coverage $periodLabel · $totalStr ${widget.unit} gesamt', style: GoogleFonts.rajdhani(fontSize: 10, fontWeight: FontWeight.w500, color: _neuTextSec)),
                              if (tempC != null)
                                TextSpan(text: '\n$tempC°C', style: GoogleFonts.spaceMono(fontSize: 11, fontWeight: FontWeight.w600, color: _tempLineColor)),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ))
                : Center(child: Text('Zu wenig Daten', style: GoogleFonts.rajdhani(fontSize: 13, color: _neuTextSec))),
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
  final List<ReadingPoint> readings;
  final String unit;
  final Color accentColor;
  final Color accentDark;

  const ChartFullscreenScreen({
    super.key,
    required this.readings,
    required this.unit,
    required this.accentColor,
    required this.accentDark,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _neuBase,
      appBar: AppBar(
        backgroundColor: _neuBase,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF2A3B2B)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'VERBRAUCH',
          style: GoogleFonts.rajdhani(fontSize: 13, fontWeight: FontWeight.w700, color: _neuTextSec, letterSpacing: 3),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final chartH = (constraints.maxHeight - 96).clamp(200.0, double.infinity);
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: ConsumptionChart(
              readings: readings,
              unit: unit,
              accentColor: accentColor,
              accentDark: accentDark,
              chartHeight: chartH,
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mini sparkline — non-interactive, shows last N consumption deltas
// ---------------------------------------------------------------------------

class MiniSparkline extends StatelessWidget {
  final List<ReadingPoint> readings;
  final Color accentColor;
  final double height;

  const MiniSparkline({
    super.key,
    required this.readings,
    required this.accentColor,
    this.height = 56,
  });

  @override
  Widget build(BuildContext context) {
    final spots = _buildSpots();
    if (spots.length < 2) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            'Noch keine Daten',
            style: GoogleFonts.rajdhani(fontSize: 11, color: _neuTextSec),
          ),
        ),
      );
    }

    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final chartMaxY = maxY < 0.001 ? 1.0 : maxY * 1.2;

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: spots.length - 1.0,
          minY: 0,
          maxY: chartMaxY,
          clipData: const FlClipData.all(),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: const FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.4,
              preventCurveOverShooting: true,
              color: accentColor,
              barWidth: 2.0,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [accentColor.withOpacity(0.25), accentColor.withOpacity(0.0)],
                ),
              ),
            ),
          ],
          lineTouchData: const LineTouchData(enabled: false),
        ),
      ),
    );
  }

  List<FlSpot> _buildSpots() {
    if (readings.length < 2) return [];
    final sorted = [...readings]..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final deltas = <double>[];
    for (int i = 1; i < sorted.length; i++) {
      final delta = sorted[i].value - sorted[i - 1].value;
      if (delta >= 0) deltas.add(delta);
    }
    // Show last 8 deltas
    final slice = deltas.length > 8 ? deltas.sublist(deltas.length - 8) : deltas;
    return List.generate(slice.length, (i) => FlSpot(i.toDouble(), slice[i]));
  }
}

// ---------------------------------------------------------------------------
// Private helpers
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
  const _SpotData(this.spot, {this.periodsCovered = 1, required this.totalConsumption});
}

class _PeriodTab extends StatelessWidget {
  final String label;
  final bool selected;
  final Color accentColor;
  final VoidCallback onTap;
  const _PeriodTab({required this.label, required this.selected, required this.accentColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? accentColor : _neuBase,
          borderRadius: BorderRadius.circular(8),
          boxShadow: selected ? _neu(3) : null,
        ),
        child: Text(label, style: GoogleFonts.rajdhani(fontSize: 12, fontWeight: selected ? FontWeight.w700 : FontWeight.w500, color: selected ? Colors.white : _neuTextSec, letterSpacing: 0.5)),
      ),
    );
  }
}

class _ChartLegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _ChartLegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.rajdhani(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
