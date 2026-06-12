import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database.dart';
import '../utils/meter_interpolator.dart';
import 'supabase_service.dart';

// ---------------------------------------------------------------------------
// Models
// ---------------------------------------------------------------------------

class BenchmarkResult {
  final double minVal;
  final double maxVal;
  final double avgVal;
  final double medianVal;
  final int count;
  final double? userVal;
  final int? userPercentile; // % of comparable users who use MORE than you

  const BenchmarkResult({
    required this.minVal,
    required this.maxVal,
    required this.avgVal,
    required this.medianVal,
    required this.count,
    this.userVal,
    this.userPercentile,
  });
}

class GasBenchmarkFilters {
  final bool useHouseType;
  final bool useSqm;
  final int sqmRangePct;             // 10 | 20 | 30 | 50
  final bool useSolarThermal;
  final bool useConstructionYear;
  final String constructionYearMode; // 'era' | 'decade' | 'quarter'
  final bool useIsInsulated;
  final bool usePlzRegion;
  final int plzDigits;               // 1 | 2 | 3

  const GasBenchmarkFilters({
    this.useHouseType = true,
    this.useSqm = true,
    this.sqmRangePct = 30,
    this.useSolarThermal = true,
    this.useConstructionYear = true,
    this.constructionYearMode = 'era',
    this.useIsInsulated = true,
    this.usePlzRegion = true,
    this.plzDigits = 2,
  });

  GasBenchmarkFilters copyWith({
    bool? useHouseType,
    bool? useSqm,
    int? sqmRangePct,
    bool? useSolarThermal,
    bool? useConstructionYear,
    String? constructionYearMode,
    bool? useIsInsulated,
    bool? usePlzRegion,
    int? plzDigits,
  }) =>
      GasBenchmarkFilters(
        useHouseType: useHouseType ?? this.useHouseType,
        useSqm: useSqm ?? this.useSqm,
        sqmRangePct: sqmRangePct ?? this.sqmRangePct,
        useSolarThermal: useSolarThermal ?? this.useSolarThermal,
        useConstructionYear: useConstructionYear ?? this.useConstructionYear,
        constructionYearMode: constructionYearMode ?? this.constructionYearMode,
        useIsInsulated: useIsInsulated ?? this.useIsInsulated,
        usePlzRegion: usePlzRegion ?? this.usePlzRegion,
        plzDigits: plzDigits ?? this.plzDigits,
      );
}

class ElectricityBenchmarkFilters {
  final bool usePersons;
  final bool usePv;
  final bool useSqm;
  final int sqmRangePct; // 10 | 20 | 30 | 50
  final bool useHouseType;

  const ElectricityBenchmarkFilters({
    this.usePersons = true,
    this.usePv = true,
    this.useSqm = true,
    this.sqmRangePct = 30,
    this.useHouseType = true,
  });

  ElectricityBenchmarkFilters copyWith({
    bool? usePersons,
    bool? usePv,
    bool? useSqm,
    int? sqmRangePct,
    bool? useHouseType,
  }) =>
      ElectricityBenchmarkFilters(
        usePersons: usePersons ?? this.usePersons,
        usePv: usePv ?? this.usePv,
        useSqm: useSqm ?? this.useSqm,
        sqmRangePct: sqmRangePct ?? this.sqmRangePct,
        useHouseType: useHouseType ?? this.useHouseType,
      );
}

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

class BenchmarkService {
  static final BenchmarkService _instance = BenchmarkService._();
  factory BenchmarkService() => _instance;
  BenchmarkService._();

  static const _keySharesData = 'shares_benchmark_data';
  static const _table = 'consumption_benchmarks';

  Future<bool> getSharesData() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keySharesData) ?? false;
  }

  Future<void> setSharesData(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySharesData, value);
    if (value) await uploadBenchmark();
  }

  // 12-month rolling average for gas in kWh/month
  Future<double?> _calcGasMonthlyAvgKwh() async {
    final rawReadings = await AppDatabase.instance.watchAllReadings().first;
    final readings = List<MeterReading>.from(rawReadings)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    if (readings.length < 2) return null;

    final pts = readings.map((r) => (value: r.value, timestamp: r.timestamp)).toList();
    final contract = await AppDatabase.instance.getLatestContract();
    final bw = (contract?.brennwert ?? 0) > 0 ? contract!.brennwert : 10.55;
    final zz = (contract?.zustandszahl ?? 0) > 0 ? contract!.zustandszahl : 1.0;

    final now = DateTime.now();
    final values = <double>[];
    for (int i = 1; i <= 12; i++) {
      var m = now.month - i;
      var y = now.year;
      if (m <= 0) { m += 12; y -= 1; }
      final m3 = MeterInterpolator.monthConsumption(pts, y, m);
      if (m3 != null && m3 > 0) values.add(m3 * bw * zz);
    }
    if (values.isEmpty) return null;
    return values.reduce((a, b) => a + b) / values.length;
  }

  // 12-month rolling average for electricity in kWh/month
  Future<double?> _calcElectricityMonthlyAvgKwh() async {
    final rawReadings = await AppDatabase.instance.watchAllElectricityReadings().first;
    final readings = List<ElectricityReading>.from(rawReadings)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    if (readings.length < 2) return null;

    final pts = readings.map((r) => (value: r.value, timestamp: r.timestamp)).toList();
    final now = DateTime.now();
    final values = <double>[];
    for (int i = 1; i <= 12; i++) {
      var m = now.month - i;
      var y = now.year;
      if (m <= 0) { m += 12; y -= 1; }
      final kwh = MeterInterpolator.monthConsumption(pts, y, m);
      if (kwh != null && kwh > 0) values.add(kwh);
    }
    if (values.isEmpty) return null;
    return values.reduce((a, b) => a + b) / values.length;
  }

  Future<void> uploadBenchmark() async {
    try {
      final user = SupabaseService.currentUser;
      if (user == null) return;

      final settings = await AppDatabase.instance.getSettings();
      final gasAvg  = await _calcGasMonthlyAvgKwh();
      final elecAvg = await _calcElectricityMonthlyAvgKwh();
      final plz     = settings?.locationPlz;
      final plzPrefix = (plz != null && plz.length >= 2) ? plz.substring(0, 2) : null;

      await SupabaseService.client.from(_table).upsert({
        'user_id':                     user.id,
        'house_type':                  settings?.houseType,
        'square_meters':               settings?.squareMeters,
        'number_of_persons':           settings?.numberOfPersons,
        'has_pv':                      settings?.hasPv,
        'has_solar_thermal':           settings?.hasSolarThermal,
        'construction_year':           settings?.constructionYear,
        'is_insulated':                settings?.isInsulated,
        'plz_prefix':                  plzPrefix,
        'gas_kwh_monthly_avg':         gasAvg,
        'electricity_kwh_monthly_avg': elecAvg,
        'updated_at':                  DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'user_id');

      debugPrint('[Benchmark] Uploaded: gas=$gasAvg, elec=$elecAvg');
    } catch (e) {
      debugPrint('[Benchmark] Upload failed: $e');
    }
  }

  Future<BenchmarkResult?> getGasBenchmark(GasBenchmarkFilters filters) async {
    try {
      final user = SupabaseService.currentUser;
      if (user == null) return null;

      final settings = await AppDatabase.instance.getSettings();
      final sqm  = settings?.squareMeters;
      final year = settings?.constructionYear;
      final plz  = settings?.locationPlz;

      // Construction year range
      int? yearMin, yearMax;
      if (filters.useConstructionYear && year != null) {
        switch (filters.constructionYearMode) {
          case 'decade':
            yearMin = year - 10;
            yearMax = year + 10;
          case 'quarter':
            yearMin = year - 25;
            yearMax = year + 25;
          default: // 'era' — German insulation regulation milestones
            if (year < 1978)      { yearMin = 1900; yearMax = 1977; }
            else if (year < 2002) { yearMin = 1978; yearMax = 2001; }
            else                  { yearMin = 2002; yearMax = 2100; }
        }
      }

      // Sqm range
      final sqmFactor = filters.sqmRangePct / 100.0;

      // PLZ prefix (climate zone proxy)
      String? plzPrefix;
      if (filters.usePlzRegion && plz != null && plz.length >= filters.plzDigits) {
        plzPrefix = plz.substring(0, filters.plzDigits);
      }

      final data = await SupabaseService.client.rpc('get_gas_benchmark', params: {
        'p_user_id':               user.id,
        'p_house_type':            filters.useHouseType ? settings?.houseType : null,
        'p_sqm_min':               (filters.useSqm && sqm != null) ? (sqm * (1 - sqmFactor)).round() : null,
        'p_sqm_max':               (filters.useSqm && sqm != null) ? (sqm * (1 + sqmFactor)).round() : null,
        'p_has_solar_thermal':     filters.useSolarThermal ? settings?.hasSolarThermal : null,
        'p_construction_year_min': yearMin,
        'p_construction_year_max': yearMax,
        'p_is_insulated':          filters.useIsInsulated ? settings?.isInsulated : null,
        'p_plz_prefix':            plzPrefix,
      }) as Map<String, dynamic>?;

      return _parse(data);
    } catch (e) {
      debugPrint('[Benchmark] Gas query failed: $e');
      return null;
    }
  }

  Future<BenchmarkResult?> getElectricityBenchmark(ElectricityBenchmarkFilters filters) async {
    try {
      final user = SupabaseService.currentUser;
      if (user == null) return null;

      final settings = await AppDatabase.instance.getSettings();
      final sqm = settings?.squareMeters;
      final sqmFactor = filters.sqmRangePct / 100.0;

      final data = await SupabaseService.client.rpc('get_electricity_benchmark', params: {
        'p_user_id':           user.id,
        'p_number_of_persons': filters.usePersons ? settings?.numberOfPersons : null,
        'p_has_pv':            filters.usePv ? settings?.hasPv : null,
        'p_sqm_min':           (filters.useSqm && sqm != null) ? (sqm * (1 - sqmFactor)).round() : null,
        'p_sqm_max':           (filters.useSqm && sqm != null) ? (sqm * (1 + sqmFactor)).round() : null,
        'p_house_type':        filters.useHouseType ? settings?.houseType : null,
      }) as Map<String, dynamic>?;

      return _parse(data);
    } catch (e) {
      debugPrint('[Benchmark] Electricity query failed: $e');
      return null;
    }
  }

  BenchmarkResult? _parse(Map<String, dynamic>? data) {
    if (data == null) return null;
    final count = data['count_val'];
    if (count == null || (count as num) == 0) return null;
    return BenchmarkResult(
      minVal:         (data['min_val']    as num).toDouble(),
      maxVal:         (data['max_val']    as num).toDouble(),
      avgVal:         (data['avg_val']    as num).toDouble(),
      medianVal:      (data['median_val'] as num).toDouble(),
      count:          count.toInt(),
      userVal:        data['user_val']        != null ? (data['user_val']        as num).toDouble() : null,
      userPercentile: data['user_percentile'] != null ? (data['user_percentile'] as num).toInt()    : null,
    );
  }
}
