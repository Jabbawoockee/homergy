import 'dart:convert';
import 'package:drift/drift.dart' show Value;
import 'package:http/http.dart' as http;
import '../database/database.dart';

class WeatherService {
  static const _geocodingBase =
      'https://geocoding-api.open-meteo.com/v1/search';
  static const _archiveBase =
      'https://archive-api.open-meteo.com/v1/archive';
  static const _forecastBase =
      'https://api.open-meteo.com/v1/forecast';

  /// Geocodes city + PLZ to lat/lon.
  /// Tries Open-Meteo with city name first, then Nominatim with PLZ as fallback.
  Future<({double lat, double lon})?> geocode(String city, String plz) async {
    // 1. Open-Meteo — city name only (API doesn't support PLZ or countryCode)
    if (city.isNotEmpty) {
      final result = await _geocodeOpenMeteo(city);
      if (result != null) return result;
    }

    // 2. Nominatim (OpenStreetMap) — PLZ fallback
    if (plz.isNotEmpty) {
      final result = await _geocodeNominatim(plz, city);
      if (result != null) return result;
    }

    // 3. Last resort: try PLZ alone on Open-Meteo
    if (plz.isNotEmpty && city.isEmpty) {
      return _geocodeOpenMeteo(plz);
    }

    return null;
  }

  Future<({double lat, double lon})?> _geocodeOpenMeteo(String name) async {
    try {
      final uri = Uri.parse(
        '$_geocodingBase?name=${Uri.encodeComponent(name)}'
        '&count=1&language=de&format=json',
      );
      final resp = await http.get(uri).timeout(const Duration(seconds: 10));
      if (resp.statusCode != 200) return null;
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final results = data['results'] as List?;
      if (results == null || results.isEmpty) return null;
      final first = results.first as Map<String, dynamic>;
      return (
        lat: (first['latitude'] as num).toDouble(),
        lon: (first['longitude'] as num).toDouble(),
      );
    } catch (_) {
      return null;
    }
  }

  Future<({double lat, double lon})?> _geocodeNominatim(
      String plz, String city) async {
    try {
      final cityParam =
          city.isNotEmpty ? '&city=${Uri.encodeComponent(city)}' : '';
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?format=json&postalcode=${Uri.encodeComponent(plz)}'
        '$cityParam&countrycodes=de&limit=1',
      );
      final resp = await http.get(uri, headers: {
        'User-Agent': 'Homergy-GasTrack/1.0',
      }).timeout(const Duration(seconds: 10));
      if (resp.statusCode != 200) return null;
      final data = jsonDecode(resp.body) as List;
      if (data.isEmpty) return null;
      final first = data.first as Map<String, dynamic>;
      return (
        lat: double.parse(first['lat'] as String),
        lon: double.parse(first['lon'] as String),
      );
    } catch (_) {
      return null;
    }
  }

  /// Returns daily mean temperatures (°C) keyed by date.
  /// Checks DB cache first, fetches only missing dates from Open-Meteo.
  Future<Map<DateTime, double>> getTemperatures({
    required double lat,
    required double lon,
    required DateTime start,
    required DateTime end,
  }) async {
    final result = <DateTime, double>{};

    // 1. Load cached data
    final cached =
        await AppDatabase.instance.getWeatherForDateRange(start, end);
    final cachedDates = <String>{};
    for (final c in cached) {
      final parsed = DateTime.parse(c.date);
      result[DateTime(parsed.year, parsed.month, parsed.day)] = c.tempMean;
      cachedDates.add(c.date);
    }

    // 2. Find missing dates (archive only goes up to yesterday)
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final fetchEnd =
        end.isBefore(yesterday) ? end : yesterday;
    final missing = <DateTime>[];
    var d = DateTime(start.year, start.month, start.day);
    while (!d.isAfter(fetchEnd)) {
      if (!cachedDates.contains(_dateKey(d))) missing.add(d);
      d = d.add(const Duration(days: 1));
    }
    if (missing.isEmpty) return result;

    // 3. Fetch from appropriate API
    final fetchStart = missing.first;
    final fetchLast = missing.last;
    try {
      final now = DateTime.now();
      // Archive API has ~5 day lag; use forecast API for recent data
      final archiveCutoff = now.subtract(const Duration(days: 6));
      Map<String, dynamic>? data;

      if (fetchLast.isBefore(archiveCutoff)) {
        final uri = Uri.parse(
          '$_archiveBase?latitude=$lat&longitude=$lon'
          '&start_date=${_dateKey(fetchStart)}&end_date=${_dateKey(fetchLast)}'
          '&daily=temperature_2m_mean&timezone=Europe%2FBerlin',
        );
        final resp = await http.get(uri).timeout(const Duration(seconds: 15));
        if (resp.statusCode == 200) {
          data = jsonDecode(resp.body) as Map<String, dynamic>;
        }
      } else {
        final pastDays = now.difference(fetchStart).inDays + 1;
        final uri = Uri.parse(
          '$_forecastBase?latitude=$lat&longitude=$lon'
          '&daily=temperature_2m_mean&timezone=Europe%2FBerlin'
          '&past_days=${pastDays.clamp(1, 92)}&forecast_days=1',
        );
        final resp = await http.get(uri).timeout(const Duration(seconds: 15));
        if (resp.statusCode == 200) {
          data = jsonDecode(resp.body) as Map<String, dynamic>;
        }
      }

      if (data != null) {
        final daily = data['daily'] as Map<String, dynamic>;
        final dates = (daily['time'] as List).cast<String>();
        final temps = daily['temperature_2m_mean'] as List;
        final toCache = <WeatherCachesCompanion>[];

        for (int i = 0; i < dates.length; i++) {
          if (temps[i] == null) continue;
          final parsed = DateTime.parse(dates[i]);
          final key = DateTime(parsed.year, parsed.month, parsed.day);
          if (key.isBefore(fetchStart) || key.isAfter(fetchLast)) continue;
          final temp = (temps[i] as num).toDouble();
          result[key] = temp;
          toCache.add(WeatherCachesCompanion(
            date: Value(dates[i]),
            lat: Value(lat),
            lon: Value(lon),
            tempMean: Value(temp),
          ));
        }
        if (toCache.isNotEmpty) {
          await AppDatabase.instance.insertWeatherCache(toCache);
        }
      }
    } catch (_) {
      // Network failure — return whatever is in cache
    }

    return result;
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
