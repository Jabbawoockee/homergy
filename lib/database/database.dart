import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'database.g.dart';

// ---------------------------------------------------------------------------
// Table definitions
// ---------------------------------------------------------------------------

class MeterReadings extends Table {
  IntColumn get id => integer().autoIncrement()();
  RealColumn get value => real()();
  DateTimeColumn get timestamp => dateTime()();
  TextColumn get note => text().nullable()();
  TextColumn get imagePath => text().nullable()();
  BoolColumn get isSynced =>
      boolean().withDefault(const Constant(false))();
  TextColumn get remoteId => text().nullable()();
}

// ---------------------------------------------------------------------------
// App settings table (single row: user location for weather)
// ---------------------------------------------------------------------------

class AppSettings extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get locationPlz => text().nullable()();
  TextColumn get locationCity => text().nullable()();
  RealColumn get locationLat => real().nullable()();
  RealColumn get locationLon => real().nullable()();
  IntColumn get meterIntDigits => integer().nullable()();
}

// ---------------------------------------------------------------------------
// Weather cache table
// ---------------------------------------------------------------------------

class WeatherCaches extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get date => text()(); // "YYYY-MM-DD"
  RealColumn get lat => real()();
  RealColumn get lon => real()();
  RealColumn get tempMean => real()();
}

// ---------------------------------------------------------------------------
// Price contracts table
// ---------------------------------------------------------------------------

class PriceContracts extends Table {
  IntColumn get id => integer().autoIncrement()();
  /// Internal unique name, e.g. "Stadtwerke_1". Never shown to the user.
  TextColumn get internalName => text()();
  /// Display name shown to the user, e.g. "Stadtwerke".
  TextColumn get displayName => text()();
  RealColumn get pricePerKwh => real()();
  RealColumn get monthlyBasePrice => real()();
  /// Milliseconds since epoch.
  IntColumn get validFrom => integer()();
  RealColumn get brennwert => real().withDefault(const Constant(0.0))();
  RealColumn get zustandszahl => real().withDefault(const Constant(0.0))();
  BoolColumn get isSynced =>
      boolean().withDefault(const Constant(false))();
  TextColumn get remoteId => text().nullable()();
}

// ---------------------------------------------------------------------------
// DAO — Readings
// ---------------------------------------------------------------------------

@DriftAccessor(tables: [MeterReadings])
class ReadingsDao extends DatabaseAccessor<AppDatabase>
    with _$ReadingsDaoMixin {
  ReadingsDao(super.db);

  /// Watch all readings ordered by timestamp descending.
  Stream<List<MeterReading>> watchAllReadings() =>
      (select(meterReadings)..orderBy([(t) => OrderingTerm.desc(t.timestamp)]))
          .watch();

  /// Insert a new reading.
  Future<int> insertReading(MeterReadingsCompanion companion) =>
      into(meterReadings).insert(companion);

  /// Delete a reading by id.
  Future<void> deleteReading(int id) =>
      (delete(meterReadings)..where((t) => t.id.equals(id))).go();

  /// Get readings within a date range, ordered ascending for delta calculations.
  Future<List<MeterReading>> getReadingsInRange(
      DateTime from, DateTime to) async {
    return (select(meterReadings)
          ..where((t) => t.timestamp.isBiggerOrEqualValue(from) &
              t.timestamp.isSmallerOrEqualValue(to))
          ..orderBy([(t) => OrderingTerm.asc(t.timestamp)]))
        .get();
  }

  Future<MeterReading?> getLatestReading() async {
    final results = await (select(meterReadings)
          ..orderBy([(t) => OrderingTerm.desc(t.timestamp)])
          ..limit(1))
        .get();
    return results.isNotEmpty ? results.first : null;
  }

  Future<void> updateReadingValue(int id, double value) =>
      (update(meterReadings)..where((t) => t.id.equals(id))).write(
        MeterReadingsCompanion(
          value: Value(value),
          isSynced: const Value(false),
        ),
      );

  Future<List<MeterReading>> getUnsyncedReadings() =>
      (select(meterReadings)..where((t) => t.isSynced.equals(false))).get();

  Future<void> markSynced(int localId, String remoteId) =>
      (update(meterReadings)..where((t) => t.id.equals(localId))).write(
        MeterReadingsCompanion(
          isSynced: const Value(true),
          remoteId: Value(remoteId),
        ),
      );

  Future<Set<String>> getAllRemoteIds() async {
    final rows = await (select(meterReadings)
          ..where((t) => t.remoteId.isNotNull()))
        .get();
    return rows.map((r) => r.remoteId!).toSet();
  }

  Future<MeterReading?> getReadingById(int id) =>
      (select(meterReadings)..where((t) => t.id.equals(id)))
          .getSingleOrNull();
}

// ---------------------------------------------------------------------------
// DAO — Price Contracts
// ---------------------------------------------------------------------------

@DriftAccessor(tables: [PriceContracts])
class ContractsDao extends DatabaseAccessor<AppDatabase>
    with _$ContractsDaoMixin {
  ContractsDao(super.db);

  Future<List<PriceContract>> getAllContracts() =>
      (select(priceContracts)
            ..orderBy([(t) => OrderingTerm.asc(t.validFrom)]))
          .get();

  Future<PriceContract?> getLatestContract() async {
    final results = await (select(priceContracts)
          ..orderBy([(t) => OrderingTerm.desc(t.validFrom)])
          ..limit(1))
        .get();
    return results.isNotEmpty ? results.first : null;
  }

  /// Returns the contract that was active at [date]:
  /// the one with the latest validFrom that is <= date.
  Future<PriceContract?> getContractForDate(DateTime date) async {
    final ms = date.millisecondsSinceEpoch;
    final results = await (select(priceContracts)
          ..where((t) => t.validFrom.isSmallerOrEqualValue(ms))
          ..orderBy([(t) => OrderingTerm.desc(t.validFrom)])
          ..limit(1))
        .get();
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> insertContract(PriceContractsCompanion entry) =>
      into(priceContracts).insert(entry);

  Future<void> updateContract(PriceContractsCompanion entry) =>
      (update(priceContracts)..where((t) => t.id.equals(entry.id.value)))
          .write(entry);

  Future<void> deleteContract(int id) =>
      (delete(priceContracts)..where((t) => t.id.equals(id))).go();

  /// Count how many contracts share the same displayName (for numbering).
  Future<int> countByDisplayName(String displayName) async {
    final results = await (select(priceContracts)
          ..where((t) => t.displayName.equals(displayName)))
        .get();
    return results.length;
  }

  Future<List<PriceContract>> getUnsyncedContracts() =>
      (select(priceContracts)..where((t) => t.isSynced.equals(false))).get();

  Future<void> markContractSynced(int localId, String remoteId) =>
      (update(priceContracts)..where((t) => t.id.equals(localId))).write(
        PriceContractsCompanion(
          isSynced: const Value(true),
          remoteId: Value(remoteId),
        ),
      );

  Future<Set<String>> getAllRemoteContractIds() async {
    final rows = await (select(priceContracts)
          ..where((t) => t.remoteId.isNotNull()))
        .get();
    return rows.map((r) => r.remoteId!).toSet();
  }
}

// ---------------------------------------------------------------------------
// DAO — App Settings
// ---------------------------------------------------------------------------

@DriftAccessor(tables: [AppSettings])
class SettingsDao extends DatabaseAccessor<AppDatabase>
    with _$SettingsDaoMixin {
  SettingsDao(super.db);

  Future<AppSetting?> getSettings() async {
    final list = await select(appSettings).get();
    return list.isNotEmpty ? list.first : null;
  }

  Future<void> saveLocation({
    required String plz,
    required String city,
    double? lat,
    double? lon,
  }) async {
    final existing = await getSettings();
    if (existing == null) {
      await into(appSettings).insert(AppSettingsCompanion(
        locationPlz: Value(plz),
        locationCity: Value(city),
        locationLat: Value(lat),
        locationLon: Value(lon),
      ));
    } else {
      await (update(appSettings)..where((t) => t.id.equals(existing.id))).write(
        AppSettingsCompanion(
          locationPlz: Value(plz),
          locationCity: Value(city),
          locationLat: Value(lat),
          locationLon: Value(lon),
        ),
      );
    }
  }

  Future<void> saveCoordinates(int id, double lat, double lon) =>
      (update(appSettings)..where((t) => t.id.equals(id))).write(
        AppSettingsCompanion(
          locationLat: Value(lat),
          locationLon: Value(lon),
        ),
      );

  Future<void> saveMeterIntDigits(int digits) async {
    final existing = await getSettings();
    if (existing == null) {
      await into(appSettings).insert(AppSettingsCompanion(
        meterIntDigits: Value(digits),
      ));
    } else {
      await (update(appSettings)..where((t) => t.id.equals(existing.id)))
          .write(AppSettingsCompanion(meterIntDigits: Value(digits)));
    }
  }
}

// ---------------------------------------------------------------------------
// DAO — Weather Cache
// ---------------------------------------------------------------------------

@DriftAccessor(tables: [WeatherCaches])
class WeatherDao extends DatabaseAccessor<AppDatabase>
    with _$WeatherDaoMixin {
  WeatherDao(super.db);

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<List<WeatherCache>> getForDateRange(
      DateTime start, DateTime end) async {
    final s = _dateKey(start);
    final e = _dateKey(end);
    return (select(weatherCaches)
          ..where((t) =>
              t.date.isBiggerOrEqualValue(s) & t.date.isSmallerOrEqualValue(e)))
        .get();
  }

  Future<void> insertAll(List<WeatherCachesCompanion> entries) async {
    await batch((b) =>
        b.insertAll(weatherCaches, entries, mode: InsertMode.insertOrReplace));
  }
}

// ---------------------------------------------------------------------------
// Database
// ---------------------------------------------------------------------------

@DriftDatabase(
  tables: [MeterReadings, PriceContracts, AppSettings, WeatherCaches],
  daos: [ReadingsDao, ContractsDao, SettingsDao, WeatherDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase._() : super(_openConnection());

  static AppDatabase? _instance;

  /// Singleton accessor.
  static AppDatabase get instance => _instance ??= AppDatabase._();

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.addColumn(meterReadings, meterReadings.isSynced);
        await migrator.addColumn(meterReadings, meterReadings.remoteId);
      }
      if (from < 3) {
        await migrator.createTable(priceContracts);
      }
      if (from < 4) {
        await migrator.createTable(appSettings);
        await migrator.createTable(weatherCaches);
      }
      if (from < 5) {
        await migrator.addColumn(priceContracts, priceContracts.isSynced);
        await migrator.addColumn(priceContracts, priceContracts.remoteId);
      }
      if (from < 6) {
        await migrator.addColumn(appSettings, appSettings.meterIntDigits);
      }
    },
  );

  // Convenience pass-throughs so callers don't need the DAO directly.
  Stream<List<MeterReading>> watchAllReadings() =>
      readingsDao.watchAllReadings();

  Future<int> insertReading(MeterReadingsCompanion companion) =>
      readingsDao.insertReading(companion);

  Future<void> deleteReading(int id) => readingsDao.deleteReading(id);

  Future<List<MeterReading>> getReadingsInRange(
          DateTime from, DateTime to) =>
      readingsDao.getReadingsInRange(from, to);

  Future<MeterReading?> getLatestReading() =>
      readingsDao.getLatestReading();

  Future<void> updateReadingValue(int id, double value) =>
      readingsDao.updateReadingValue(id, value);

  Future<List<MeterReading>> getUnsyncedReadings() =>
      readingsDao.getUnsyncedReadings();

  Future<void> markSynced(int localId, String remoteId) =>
      readingsDao.markSynced(localId, remoteId);

  Future<Set<String>> getAllRemoteIds() => readingsDao.getAllRemoteIds();

  Future<MeterReading?> getReadingById(int id) =>
      readingsDao.getReadingById(id);

  // ── Settings pass-throughs ───────────────────────────────────────────────

  Future<AppSetting?> getSettings() => settingsDao.getSettings();

  Future<void> saveLocation({
    required String plz,
    required String city,
    double? lat,
    double? lon,
  }) =>
      settingsDao.saveLocation(plz: plz, city: city, lat: lat, lon: lon);

  Future<void> saveCoordinates(int id, double lat, double lon) =>
      settingsDao.saveCoordinates(id, lat, lon);

  Future<void> saveMeterIntDigits(int digits) =>
      settingsDao.saveMeterIntDigits(digits);

  // ── Weather cache pass-throughs ──────────────────────────────────────────

  Future<List<WeatherCache>> getWeatherForDateRange(
          DateTime start, DateTime end) =>
      weatherDao.getForDateRange(start, end);

  Future<void> insertWeatherCache(List<WeatherCachesCompanion> entries) =>
      weatherDao.insertAll(entries);

  // ── Contracts pass-throughs ──────────────────────────────────────────────

  Future<List<PriceContract>> getAllContracts() =>
      contractsDao.getAllContracts();

  Future<PriceContract?> getLatestContract() =>
      contractsDao.getLatestContract();

  Future<PriceContract?> getContractForDate(DateTime date) =>
      contractsDao.getContractForDate(date);

  Future<int> insertContract(PriceContractsCompanion entry) =>
      contractsDao.insertContract(entry);

  Future<void> updateContract(PriceContractsCompanion entry) =>
      contractsDao.updateContract(entry);

  Future<void> deleteContract(int id) =>
      contractsDao.deleteContract(id);

  Future<int> countContractsByDisplayName(String displayName) =>
      contractsDao.countByDisplayName(displayName);

  Future<List<PriceContract>> getUnsyncedContracts() =>
      contractsDao.getUnsyncedContracts();

  Future<void> markContractSynced(int localId, String remoteId) =>
      contractsDao.markContractSynced(localId, remoteId);

  Future<Set<String>> getAllRemoteContractIds() =>
      contractsDao.getAllRemoteContractIds();

  /// Wipes all user data from local DB (called on sign-out).
  Future<void> clearAllUserData() async {
    await delete(meterReadings).go();
    await delete(priceContracts).go();
    await delete(appSettings).go();
    await delete(weatherCaches).go();
  }
}

// ---------------------------------------------------------------------------
// Connection helper
// ---------------------------------------------------------------------------

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'gastrack.db'));
    return NativeDatabase.createInBackground(file);
  });
}
