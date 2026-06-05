import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../database/database.dart';
import 'supabase_service.dart';
import 'weather_service.dart';

class SyncService {
  static final SyncService _instance = SyncService._();
  factory SyncService() => _instance;
  SyncService._();

  final _db = AppDatabase.instance;
  SupabaseClient get _client => SupabaseService.client;

  static const _readingsTable           = 'meter_readings';
  static const _settingsTable           = 'user_settings';
  static const _contractsTable          = 'price_contracts';
  static const _elecReadingsTable       = 'electricity_readings';
  static const _elecContractsTable      = 'electricity_contracts';

  /// Push unsynced local records to Supabase, then pull missing remote records.
  Future<void> syncAll() async {
    final user = SupabaseService.currentUser;
    if (user == null) return;
    await _pushPendingReadings(user.id);
    await _pullMissingReadings(user.id);
    await _pushPendingElectricityReadings(user.id);
    await _pullMissingElectricityReadings(user.id);
    await _syncSettings(user.id);
    await _pushPendingContracts(user.id);
    await _pullMissingContracts(user.id);
    await _pushPendingElectricityContracts(user.id);
    await _pullMissingElectricityContracts(user.id);
    await _prefetchWeather();
  }

  /// Pre-fetches weather for the last 30 days so the chart always has data,
  /// independent of when the user last opened the chart.
  Future<void> _prefetchWeather() async {
    try {
      final settings = await _db.getSettings();
      if (settings?.locationLat == null || settings?.locationLon == null) return;
      final now = DateTime.now();
      await WeatherService().getTemperatures(
        lat: settings!.locationLat!,
        lon: settings.locationLon!,
        start: DateTime(now.year, now.month, now.day - 30),
        end: now,
      );
      debugPrint('[Sync] Weather pre-fetched');
    } catch (e) {
      debugPrint('[Sync] Weather pre-fetch failed: $e');
    }
  }

  /// Sync only settings (call after saving location in settings screen).
  Future<void> syncSettings() async {
    final user = SupabaseService.currentUser;
    if (user == null) return;
    await _syncSettings(user.id);
  }

  // ---------------------------------------------------------------------------
  // Meter readings
  // ---------------------------------------------------------------------------

  Future<void> _pushPendingReadings(String userId) async {
    try {
      final unsynced = await _db.getUnsyncedReadings();
      for (final r in unsynced) {
        if (r.remoteId == null) {
          final response = await _client.from(_readingsTable).insert({
            'user_id': userId,
            'value': r.value,
            'timestamp': r.timestamp.toUtc().toIso8601String(),
            'note': r.note,
          }).select('id').single();
          await _db.markSynced(r.id, response['id'] as String);
          debugPrint('[Sync] Reading inserted: local=${r.id} remote=${response['id']}');
        } else {
          await _client.from(_readingsTable).update({
            'value': r.value,
            'note': r.note,
          }).eq('id', r.remoteId!);
          await _db.markSynced(r.id, r.remoteId!);
          debugPrint('[Sync] Reading updated: ${r.remoteId}');
        }
      }
    } catch (e) {
      debugPrint('[Sync] Readings push failed: $e');
    }
  }

  Future<void> _pullMissingReadings(String userId) async {
    try {
      final knownIds = await _db.getAllRemoteIds();
      final List<dynamic> remote = await _client
          .from(_readingsTable)
          .select('id, value, timestamp, note')
          .eq('user_id', userId)
          .order('timestamp', ascending: false);

      for (final row in remote) {
        final remoteId = row['id'] as String;
        if (!knownIds.contains(remoteId)) {
          await _db.insertReading(MeterReadingsCompanion(
            value: Value((row['value'] as num).toDouble()),
            timestamp:
                Value(DateTime.parse(row['timestamp'] as String).toLocal()),
            note: Value(row['note'] as String?),
            isSynced: const Value(true),
            remoteId: Value(remoteId),
          ));
          debugPrint('[Sync] Reading pulled: $remoteId');
        }
      }
    } catch (e) {
      debugPrint('[Sync] Readings pull failed: $e');
    }
  }

  /// Delete a meter reading from Supabase.
  Future<void> deleteRemote(String remoteId) async {
    try {
      await _client.from(_readingsTable).delete().eq('id', remoteId);
      debugPrint('[Sync] Reading deleted remote: $remoteId');
    } catch (e) {
      debugPrint('[Sync] Reading remote delete failed: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Electricity readings
  // ---------------------------------------------------------------------------

  Future<void> _pushPendingElectricityReadings(String userId) async {
    try {
      final unsynced = await _db.getUnsyncedElectricityReadings();
      for (final r in unsynced) {
        if (r.remoteId == null) {
          final response = await _client.from(_elecReadingsTable).insert({
            'user_id': userId,
            'value': r.value,
            'timestamp': r.timestamp.toUtc().toIso8601String(),
            'note': r.note,
          }).select('id').single();
          await _db.markElectricityReadingSynced(r.id, response['id'] as String);
          debugPrint('[Sync] Elec reading inserted: local=${r.id} remote=${response['id']}');
        } else {
          await _client.from(_elecReadingsTable).update({
            'value': r.value,
            'note': r.note,
          }).eq('id', r.remoteId!);
          await _db.markElectricityReadingSynced(r.id, r.remoteId!);
          debugPrint('[Sync] Elec reading updated: ${r.remoteId}');
        }
      }
    } catch (e) {
      debugPrint('[Sync] Elec readings push failed: $e');
    }
  }

  Future<void> _pullMissingElectricityReadings(String userId) async {
    try {
      final knownIds = await _db.getAllRemoteElectricityIds();
      final List<dynamic> remote = await _client
          .from(_elecReadingsTable)
          .select('id, value, timestamp, note')
          .eq('user_id', userId)
          .order('timestamp', ascending: false);

      for (final row in remote) {
        final remoteId = row['id'] as String;
        if (!knownIds.contains(remoteId)) {
          await _db.insertElectricityReading(ElectricityReadingsCompanion(
            value: Value((row['value'] as num).toDouble()),
            timestamp:
                Value(DateTime.parse(row['timestamp'] as String).toLocal()),
            note: Value(row['note'] as String?),
            isSynced: const Value(true),
            remoteId: Value(remoteId),
          ));
          debugPrint('[Sync] Elec reading pulled: $remoteId');
        }
      }
    } catch (e) {
      debugPrint('[Sync] Elec readings pull failed: $e');
    }
  }

  /// Delete an electricity reading from Supabase.
  Future<void> deleteRemoteElectricityReading(String remoteId) async {
    try {
      await _client.from(_elecReadingsTable).delete().eq('id', remoteId);
      debugPrint('[Sync] Elec reading deleted remote: $remoteId');
    } catch (e) {
      debugPrint('[Sync] Elec reading remote delete failed: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Electricity contracts
  // ---------------------------------------------------------------------------

  Future<void> _pushPendingElectricityContracts(String userId) async {
    try {
      final unsynced = await _db.getUnsyncedElectricityContracts();
      for (final c in unsynced) {
        if (c.remoteId == null) {
          final response = await _client.from(_elecContractsTable).insert({
            'user_id': userId,
            'internal_name': c.internalName,
            'display_name': c.displayName,
            'price_per_kwh': c.pricePerKwh,
            'monthly_base_price': c.monthlyBasePrice,
            'valid_from': c.validFrom,
            'contract_end_date': c.contractEndDate,
            'monthly_advance_payment': c.monthlyAdvancePayment,
          }).select('id').single();
          await _db.markElectricityContractSynced(c.id, response['id'] as String);
          debugPrint('[Sync] Elec contract inserted: local=${c.id} remote=${response['id']}');
        } else {
          await _client.from(_elecContractsTable).update({
            'internal_name': c.internalName,
            'display_name': c.displayName,
            'price_per_kwh': c.pricePerKwh,
            'monthly_base_price': c.monthlyBasePrice,
            'valid_from': c.validFrom,
            'contract_end_date': c.contractEndDate,
            'monthly_advance_payment': c.monthlyAdvancePayment,
          }).eq('id', c.remoteId!);
          await _db.markElectricityContractSynced(c.id, c.remoteId!);
          debugPrint('[Sync] Elec contract updated: ${c.remoteId}');
        }
      }
    } catch (e) {
      debugPrint('[Sync] Elec contracts push failed: $e');
    }
  }

  Future<void> _pullMissingElectricityContracts(String userId) async {
    try {
      final knownIds = await _db.getAllRemoteElectricityContractIds();
      final List<dynamic> remote = await _client
          .from(_elecContractsTable)
          .select()
          .eq('user_id', userId);

      for (final row in remote) {
        final remoteId = row['id'] as String;
        if (!knownIds.contains(remoteId)) {
          await _db.insertElectricityContract(ElectricityContractsCompanion(
            internalName: Value(row['internal_name'] as String),
            displayName: Value(row['display_name'] as String),
            pricePerKwh: Value((row['price_per_kwh'] as num).toDouble()),
            monthlyBasePrice:
                Value((row['monthly_base_price'] as num).toDouble()),
            validFrom: Value(row['valid_from'] as int),
            contractEndDate: Value(row['contract_end_date'] as int?),
            monthlyAdvancePayment: Value((row['monthly_advance_payment'] as num?)?.toDouble()),
            isSynced: const Value(true),
            remoteId: Value(remoteId),
          ));
          debugPrint('[Sync] Elec contract pulled: $remoteId');
        }
      }
    } catch (e) {
      debugPrint('[Sync] Elec contracts pull failed: $e');
    }
  }

  /// Delete an electricity contract from Supabase.
  Future<void> deleteRemoteElectricityContract(String remoteId) async {
    try {
      await _client.from(_elecContractsTable).delete().eq('id', remoteId);
      debugPrint('[Sync] Elec contract deleted remote: $remoteId');
    } catch (e) {
      debugPrint('[Sync] Elec contract remote delete failed: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Settings
  // ---------------------------------------------------------------------------

  Future<void> _syncSettings(String userId) async {
    try {
      final local = await _db.getSettings();

      // Always fetch remote first — needed for new-device login.
      final remote = await _client
          .from(_settingsTable)
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      // Pull location from remote if local has none.
      final localHasLocation = local?.locationPlz?.isNotEmpty == true;
      if (!localHasLocation && remote != null) {
        final remotePlz = remote['location_plz'] as String? ?? '';
        if (remotePlz.isNotEmpty) {
          await _db.saveLocation(
            plz: remotePlz,
            city: remote['location_city'] as String? ?? '',
            lat: (remote['location_lat'] as num?)?.toDouble(),
            lon: (remote['location_lon'] as num?)?.toDouble(),
          );
          debugPrint('[Sync] Settings location pulled from remote');
        }
      }

      // Pull meterIntDigits from remote if not set locally.
      if (local?.meterIntDigits == null && remote?['meter_int_digits'] != null) {
        await _db.saveMeterIntDigits(remote!['meter_int_digits'] as int);
        debugPrint('[Sync] Settings meterIntDigits pulled from remote');
      }

      // Pull electricity digit settings from remote if not set locally.
      if (local?.electricityIntDigits == null &&
          remote?['electricity_int_digits'] != null) {
        await _db.saveElectricityIntDigits(
            remote!['electricity_int_digits'] as int);
        debugPrint('[Sync] Settings electricityIntDigits pulled from remote');
      }
      if (local?.electricityDecDigits == null &&
          remote?['electricity_dec_digits'] != null) {
        await _db.saveElectricityDecDigits(
            remote!['electricity_dec_digits'] as int);
        debugPrint('[Sync] Settings electricityDecDigits pulled from remote');
      }

      // Pull Hausdaten from remote if not set locally.
      if (local?.houseType == null && remote?['house_type'] != null) {
        await _db.saveHouseData(
          houseType: remote!['house_type'] as String?,
          squareMeters: remote['square_meters'] as int?,
          numberOfPersons: remote['number_of_persons'] as int?,
          hasPv: remote['has_pv'] as bool?,
          hasSolarThermal: remote['has_solar_thermal'] as bool?,
        );
        debugPrint('[Sync] Settings Hausdaten pulled from remote');
      }

      // Pull tracking mode from remote if not set locally.
      if (local?.trackingMode == null && remote?['tracking_mode'] != null) {
        await _db.saveTrackingMode(remote!['tracking_mode'] as String);
        debugPrint('[Sync] Settings trackingMode pulled from remote');
      }

      // Push merged local state to remote.
      final merged = await _db.getSettings();
      if (merged != null) {
        await _client.from(_settingsTable).upsert({
          'user_id': userId,
          'location_plz': merged.locationPlz,
          'location_city': merged.locationCity,
          'location_lat': merged.locationLat,
          'location_lon': merged.locationLon,
          'meter_int_digits': merged.meterIntDigits,
          'electricity_int_digits': merged.electricityIntDigits,
          'electricity_dec_digits': merged.electricityDecDigits,
          'house_type': merged.houseType,
          'square_meters': merged.squareMeters,
          'number_of_persons': merged.numberOfPersons,
          'has_pv': merged.hasPv,
          'has_solar_thermal': merged.hasSolarThermal,
          'tracking_mode': merged.trackingMode,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        }, onConflict: 'user_id');
        debugPrint('[Sync] Settings pushed');
      }
    } catch (e) {
      debugPrint('[Sync] Settings sync failed: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Price contracts
  // ---------------------------------------------------------------------------

  Future<void> _pushPendingContracts(String userId) async {
    try {
      final unsynced = await _db.getUnsyncedContracts();
      for (final c in unsynced) {
        if (c.remoteId == null) {
          final response = await _client.from(_contractsTable).insert({
            'user_id': userId,
            'internal_name': c.internalName,
            'display_name': c.displayName,
            'price_per_kwh': c.pricePerKwh,
            'monthly_base_price': c.monthlyBasePrice,
            'valid_from': c.validFrom,
            'contract_end_date': c.contractEndDate,
            'monthly_advance_payment': c.monthlyAdvancePayment,
            'brennwert': c.brennwert,
            'zustandszahl': c.zustandszahl,
          }).select('id').single();
          await _db.markContractSynced(c.id, response['id'] as String);
          debugPrint(
              '[Sync] Contract inserted: local=${c.id} remote=${response['id']}');
        } else {
          await _client.from(_contractsTable).update({
            'internal_name': c.internalName,
            'display_name': c.displayName,
            'price_per_kwh': c.pricePerKwh,
            'monthly_base_price': c.monthlyBasePrice,
            'valid_from': c.validFrom,
            'contract_end_date': c.contractEndDate,
            'monthly_advance_payment': c.monthlyAdvancePayment,
            'brennwert': c.brennwert,
            'zustandszahl': c.zustandszahl,
          }).eq('id', c.remoteId!);
          await _db.markContractSynced(c.id, c.remoteId!);
          debugPrint('[Sync] Contract updated: ${c.remoteId}');
        }
      }
    } catch (e) {
      debugPrint('[Sync] Contracts push failed: $e');
    }
  }

  Future<void> _pullMissingContracts(String userId) async {
    try {
      final knownIds = await _db.getAllRemoteContractIds();
      final List<dynamic> remote = await _client
          .from(_contractsTable)
          .select()
          .eq('user_id', userId);

      for (final row in remote) {
        final remoteId = row['id'] as String;
        if (!knownIds.contains(remoteId)) {
          await _db.insertContract(PriceContractsCompanion(
            internalName: Value(row['internal_name'] as String),
            displayName: Value(row['display_name'] as String),
            pricePerKwh: Value((row['price_per_kwh'] as num).toDouble()),
            monthlyBasePrice:
                Value((row['monthly_base_price'] as num).toDouble()),
            validFrom: Value(row['valid_from'] as int),
            contractEndDate: Value(row['contract_end_date'] as int?),
            monthlyAdvancePayment: Value((row['monthly_advance_payment'] as num?)?.toDouble()),
            brennwert: Value((row['brennwert'] as num? ?? 0).toDouble()),
            zustandszahl:
                Value((row['zustandszahl'] as num? ?? 0).toDouble()),
            isSynced: const Value(true),
            remoteId: Value(remoteId),
          ));
          debugPrint('[Sync] Contract pulled: $remoteId');
        }
      }
    } catch (e) {
      debugPrint('[Sync] Contracts pull failed: $e');
    }
  }

  /// Delete a price contract from Supabase.
  Future<void> deleteRemoteContract(String remoteId) async {
    try {
      await _client.from(_contractsTable).delete().eq('id', remoteId);
      debugPrint('[Sync] Contract deleted remote: $remoteId');
    } catch (e) {
      debugPrint('[Sync] Contract remote delete failed: $e');
    }
  }
}
