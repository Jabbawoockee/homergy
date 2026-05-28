import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../database/database.dart';
import 'supabase_service.dart';

class SyncService {
  static final SyncService _instance = SyncService._();
  factory SyncService() => _instance;
  SyncService._();

  final _db = AppDatabase.instance;
  SupabaseClient get _client => SupabaseService.client;

  static const _readingsTable = 'meter_readings';
  static const _settingsTable = 'user_settings';
  static const _contractsTable = 'price_contracts';

  /// Push unsynced local records to Supabase, then pull missing remote records.
  Future<void> syncAll() async {
    final user = SupabaseService.currentUser;
    if (user == null) return;
    await _pushPendingReadings(user.id);
    await _pullMissingReadings(user.id);
    await _syncSettings(user.id);
    await _pushPendingContracts(user.id);
    await _pullMissingContracts(user.id);
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
