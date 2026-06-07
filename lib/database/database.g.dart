// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
mixin _$ReadingsDaoMixin on DatabaseAccessor<AppDatabase> {
  $MeterReadingsTable get meterReadings => attachedDatabase.meterReadings;
  ReadingsDaoManager get managers => ReadingsDaoManager(this);
}

class ReadingsDaoManager {
  final _$ReadingsDaoMixin _db;
  ReadingsDaoManager(this._db);
  $$MeterReadingsTableTableManager get meterReadings =>
      $$MeterReadingsTableTableManager(_db.attachedDatabase, _db.meterReadings);
}

mixin _$ContractsDaoMixin on DatabaseAccessor<AppDatabase> {
  $PriceContractsTable get priceContracts => attachedDatabase.priceContracts;
  ContractsDaoManager get managers => ContractsDaoManager(this);
}

class ContractsDaoManager {
  final _$ContractsDaoMixin _db;
  ContractsDaoManager(this._db);
  $$PriceContractsTableTableManager get priceContracts =>
      $$PriceContractsTableTableManager(
        _db.attachedDatabase,
        _db.priceContracts,
      );
}

mixin _$ElectricityReadingsDaoMixin on DatabaseAccessor<AppDatabase> {
  $ElectricityReadingsTable get electricityReadings =>
      attachedDatabase.electricityReadings;
  ElectricityReadingsDaoManager get managers =>
      ElectricityReadingsDaoManager(this);
}

class ElectricityReadingsDaoManager {
  final _$ElectricityReadingsDaoMixin _db;
  ElectricityReadingsDaoManager(this._db);
  $$ElectricityReadingsTableTableManager get electricityReadings =>
      $$ElectricityReadingsTableTableManager(
        _db.attachedDatabase,
        _db.electricityReadings,
      );
}

mixin _$ElectricityContractsDaoMixin on DatabaseAccessor<AppDatabase> {
  $ElectricityContractsTable get electricityContracts =>
      attachedDatabase.electricityContracts;
  ElectricityContractsDaoManager get managers =>
      ElectricityContractsDaoManager(this);
}

class ElectricityContractsDaoManager {
  final _$ElectricityContractsDaoMixin _db;
  ElectricityContractsDaoManager(this._db);
  $$ElectricityContractsTableTableManager get electricityContracts =>
      $$ElectricityContractsTableTableManager(
        _db.attachedDatabase,
        _db.electricityContracts,
      );
}

mixin _$SettingsDaoMixin on DatabaseAccessor<AppDatabase> {
  $AppSettingsTable get appSettings => attachedDatabase.appSettings;
  SettingsDaoManager get managers => SettingsDaoManager(this);
}

class SettingsDaoManager {
  final _$SettingsDaoMixin _db;
  SettingsDaoManager(this._db);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db.attachedDatabase, _db.appSettings);
}

mixin _$AdvancePaymentChangesDaoMixin on DatabaseAccessor<AppDatabase> {
  $AdvancePaymentChangesTable get advancePaymentChanges =>
      attachedDatabase.advancePaymentChanges;
  AdvancePaymentChangesDaoManager get managers =>
      AdvancePaymentChangesDaoManager(this);
}

class AdvancePaymentChangesDaoManager {
  final _$AdvancePaymentChangesDaoMixin _db;
  AdvancePaymentChangesDaoManager(this._db);
  $$AdvancePaymentChangesTableTableManager get advancePaymentChanges =>
      $$AdvancePaymentChangesTableTableManager(
        _db.attachedDatabase,
        _db.advancePaymentChanges,
      );
}

mixin _$WeatherDaoMixin on DatabaseAccessor<AppDatabase> {
  $WeatherCachesTable get weatherCaches => attachedDatabase.weatherCaches;
  WeatherDaoManager get managers => WeatherDaoManager(this);
}

class WeatherDaoManager {
  final _$WeatherDaoMixin _db;
  WeatherDaoManager(this._db);
  $$WeatherCachesTableTableManager get weatherCaches =>
      $$WeatherCachesTableTableManager(_db.attachedDatabase, _db.weatherCaches);
}

class $MeterReadingsTable extends MeterReadings
    with TableInfo<$MeterReadingsTable, MeterReading> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MeterReadingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<double> value = GeneratedColumn<double>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _imagePathMeta = const VerificationMeta(
    'imagePath',
  );
  @override
  late final GeneratedColumn<String> imagePath = GeneratedColumn<String>(
    'image_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isSyncedMeta = const VerificationMeta(
    'isSynced',
  );
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
    'is_synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _remoteIdMeta = const VerificationMeta(
    'remoteId',
  );
  @override
  late final GeneratedColumn<String> remoteId = GeneratedColumn<String>(
    'remote_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    value,
    timestamp,
    note,
    imagePath,
    isSynced,
    remoteId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'meter_readings';
  @override
  VerificationContext validateIntegrity(
    Insertable<MeterReading> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('image_path')) {
      context.handle(
        _imagePathMeta,
        imagePath.isAcceptableOrUnknown(data['image_path']!, _imagePathMeta),
      );
    }
    if (data.containsKey('is_synced')) {
      context.handle(
        _isSyncedMeta,
        isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta),
      );
    }
    if (data.containsKey('remote_id')) {
      context.handle(
        _remoteIdMeta,
        remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MeterReading map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MeterReading(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}value'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      imagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_path'],
      ),
      isSynced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_synced'],
      )!,
      remoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_id'],
      ),
    );
  }

  @override
  $MeterReadingsTable createAlias(String alias) {
    return $MeterReadingsTable(attachedDatabase, alias);
  }
}

class MeterReading extends DataClass implements Insertable<MeterReading> {
  final int id;
  final double value;
  final DateTime timestamp;
  final String? note;
  final String? imagePath;
  final bool isSynced;
  final String? remoteId;
  const MeterReading({
    required this.id,
    required this.value,
    required this.timestamp,
    this.note,
    this.imagePath,
    required this.isSynced,
    this.remoteId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['value'] = Variable<double>(value);
    map['timestamp'] = Variable<DateTime>(timestamp);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || imagePath != null) {
      map['image_path'] = Variable<String>(imagePath);
    }
    map['is_synced'] = Variable<bool>(isSynced);
    if (!nullToAbsent || remoteId != null) {
      map['remote_id'] = Variable<String>(remoteId);
    }
    return map;
  }

  MeterReadingsCompanion toCompanion(bool nullToAbsent) {
    return MeterReadingsCompanion(
      id: Value(id),
      value: Value(value),
      timestamp: Value(timestamp),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      imagePath: imagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(imagePath),
      isSynced: Value(isSynced),
      remoteId: remoteId == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteId),
    );
  }

  factory MeterReading.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MeterReading(
      id: serializer.fromJson<int>(json['id']),
      value: serializer.fromJson<double>(json['value']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      note: serializer.fromJson<String?>(json['note']),
      imagePath: serializer.fromJson<String?>(json['imagePath']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      remoteId: serializer.fromJson<String?>(json['remoteId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'value': serializer.toJson<double>(value),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'note': serializer.toJson<String?>(note),
      'imagePath': serializer.toJson<String?>(imagePath),
      'isSynced': serializer.toJson<bool>(isSynced),
      'remoteId': serializer.toJson<String?>(remoteId),
    };
  }

  MeterReading copyWith({
    int? id,
    double? value,
    DateTime? timestamp,
    Value<String?> note = const Value.absent(),
    Value<String?> imagePath = const Value.absent(),
    bool? isSynced,
    Value<String?> remoteId = const Value.absent(),
  }) => MeterReading(
    id: id ?? this.id,
    value: value ?? this.value,
    timestamp: timestamp ?? this.timestamp,
    note: note.present ? note.value : this.note,
    imagePath: imagePath.present ? imagePath.value : this.imagePath,
    isSynced: isSynced ?? this.isSynced,
    remoteId: remoteId.present ? remoteId.value : this.remoteId,
  );
  MeterReading copyWithCompanion(MeterReadingsCompanion data) {
    return MeterReading(
      id: data.id.present ? data.id.value : this.id,
      value: data.value.present ? data.value.value : this.value,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      note: data.note.present ? data.note.value : this.note,
      imagePath: data.imagePath.present ? data.imagePath.value : this.imagePath,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MeterReading(')
          ..write('id: $id, ')
          ..write('value: $value, ')
          ..write('timestamp: $timestamp, ')
          ..write('note: $note, ')
          ..write('imagePath: $imagePath, ')
          ..write('isSynced: $isSynced, ')
          ..write('remoteId: $remoteId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, value, timestamp, note, imagePath, isSynced, remoteId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MeterReading &&
          other.id == this.id &&
          other.value == this.value &&
          other.timestamp == this.timestamp &&
          other.note == this.note &&
          other.imagePath == this.imagePath &&
          other.isSynced == this.isSynced &&
          other.remoteId == this.remoteId);
}

class MeterReadingsCompanion extends UpdateCompanion<MeterReading> {
  final Value<int> id;
  final Value<double> value;
  final Value<DateTime> timestamp;
  final Value<String?> note;
  final Value<String?> imagePath;
  final Value<bool> isSynced;
  final Value<String?> remoteId;
  const MeterReadingsCompanion({
    this.id = const Value.absent(),
    this.value = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.note = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.remoteId = const Value.absent(),
  });
  MeterReadingsCompanion.insert({
    this.id = const Value.absent(),
    required double value,
    required DateTime timestamp,
    this.note = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.remoteId = const Value.absent(),
  }) : value = Value(value),
       timestamp = Value(timestamp);
  static Insertable<MeterReading> custom({
    Expression<int>? id,
    Expression<double>? value,
    Expression<DateTime>? timestamp,
    Expression<String>? note,
    Expression<String>? imagePath,
    Expression<bool>? isSynced,
    Expression<String>? remoteId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (value != null) 'value': value,
      if (timestamp != null) 'timestamp': timestamp,
      if (note != null) 'note': note,
      if (imagePath != null) 'image_path': imagePath,
      if (isSynced != null) 'is_synced': isSynced,
      if (remoteId != null) 'remote_id': remoteId,
    });
  }

  MeterReadingsCompanion copyWith({
    Value<int>? id,
    Value<double>? value,
    Value<DateTime>? timestamp,
    Value<String?>? note,
    Value<String?>? imagePath,
    Value<bool>? isSynced,
    Value<String?>? remoteId,
  }) {
    return MeterReadingsCompanion(
      id: id ?? this.id,
      value: value ?? this.value,
      timestamp: timestamp ?? this.timestamp,
      note: note ?? this.note,
      imagePath: imagePath ?? this.imagePath,
      isSynced: isSynced ?? this.isSynced,
      remoteId: remoteId ?? this.remoteId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (value.present) {
      map['value'] = Variable<double>(value.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (imagePath.present) {
      map['image_path'] = Variable<String>(imagePath.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<String>(remoteId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MeterReadingsCompanion(')
          ..write('id: $id, ')
          ..write('value: $value, ')
          ..write('timestamp: $timestamp, ')
          ..write('note: $note, ')
          ..write('imagePath: $imagePath, ')
          ..write('isSynced: $isSynced, ')
          ..write('remoteId: $remoteId')
          ..write(')'))
        .toString();
  }
}

class $ElectricityReadingsTable extends ElectricityReadings
    with TableInfo<$ElectricityReadingsTable, ElectricityReading> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ElectricityReadingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<double> value = GeneratedColumn<double>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _imagePathMeta = const VerificationMeta(
    'imagePath',
  );
  @override
  late final GeneratedColumn<String> imagePath = GeneratedColumn<String>(
    'image_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isSyncedMeta = const VerificationMeta(
    'isSynced',
  );
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
    'is_synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _remoteIdMeta = const VerificationMeta(
    'remoteId',
  );
  @override
  late final GeneratedColumn<String> remoteId = GeneratedColumn<String>(
    'remote_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    value,
    timestamp,
    note,
    imagePath,
    isSynced,
    remoteId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'electricity_readings';
  @override
  VerificationContext validateIntegrity(
    Insertable<ElectricityReading> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('image_path')) {
      context.handle(
        _imagePathMeta,
        imagePath.isAcceptableOrUnknown(data['image_path']!, _imagePathMeta),
      );
    }
    if (data.containsKey('is_synced')) {
      context.handle(
        _isSyncedMeta,
        isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta),
      );
    }
    if (data.containsKey('remote_id')) {
      context.handle(
        _remoteIdMeta,
        remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ElectricityReading map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ElectricityReading(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}value'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      imagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_path'],
      ),
      isSynced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_synced'],
      )!,
      remoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_id'],
      ),
    );
  }

  @override
  $ElectricityReadingsTable createAlias(String alias) {
    return $ElectricityReadingsTable(attachedDatabase, alias);
  }
}

class ElectricityReading extends DataClass
    implements Insertable<ElectricityReading> {
  final int id;
  final double value;
  final DateTime timestamp;
  final String? note;
  final String? imagePath;
  final bool isSynced;
  final String? remoteId;
  const ElectricityReading({
    required this.id,
    required this.value,
    required this.timestamp,
    this.note,
    this.imagePath,
    required this.isSynced,
    this.remoteId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['value'] = Variable<double>(value);
    map['timestamp'] = Variable<DateTime>(timestamp);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || imagePath != null) {
      map['image_path'] = Variable<String>(imagePath);
    }
    map['is_synced'] = Variable<bool>(isSynced);
    if (!nullToAbsent || remoteId != null) {
      map['remote_id'] = Variable<String>(remoteId);
    }
    return map;
  }

  ElectricityReadingsCompanion toCompanion(bool nullToAbsent) {
    return ElectricityReadingsCompanion(
      id: Value(id),
      value: Value(value),
      timestamp: Value(timestamp),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      imagePath: imagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(imagePath),
      isSynced: Value(isSynced),
      remoteId: remoteId == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteId),
    );
  }

  factory ElectricityReading.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ElectricityReading(
      id: serializer.fromJson<int>(json['id']),
      value: serializer.fromJson<double>(json['value']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      note: serializer.fromJson<String?>(json['note']),
      imagePath: serializer.fromJson<String?>(json['imagePath']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      remoteId: serializer.fromJson<String?>(json['remoteId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'value': serializer.toJson<double>(value),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'note': serializer.toJson<String?>(note),
      'imagePath': serializer.toJson<String?>(imagePath),
      'isSynced': serializer.toJson<bool>(isSynced),
      'remoteId': serializer.toJson<String?>(remoteId),
    };
  }

  ElectricityReading copyWith({
    int? id,
    double? value,
    DateTime? timestamp,
    Value<String?> note = const Value.absent(),
    Value<String?> imagePath = const Value.absent(),
    bool? isSynced,
    Value<String?> remoteId = const Value.absent(),
  }) => ElectricityReading(
    id: id ?? this.id,
    value: value ?? this.value,
    timestamp: timestamp ?? this.timestamp,
    note: note.present ? note.value : this.note,
    imagePath: imagePath.present ? imagePath.value : this.imagePath,
    isSynced: isSynced ?? this.isSynced,
    remoteId: remoteId.present ? remoteId.value : this.remoteId,
  );
  ElectricityReading copyWithCompanion(ElectricityReadingsCompanion data) {
    return ElectricityReading(
      id: data.id.present ? data.id.value : this.id,
      value: data.value.present ? data.value.value : this.value,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      note: data.note.present ? data.note.value : this.note,
      imagePath: data.imagePath.present ? data.imagePath.value : this.imagePath,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ElectricityReading(')
          ..write('id: $id, ')
          ..write('value: $value, ')
          ..write('timestamp: $timestamp, ')
          ..write('note: $note, ')
          ..write('imagePath: $imagePath, ')
          ..write('isSynced: $isSynced, ')
          ..write('remoteId: $remoteId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, value, timestamp, note, imagePath, isSynced, remoteId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ElectricityReading &&
          other.id == this.id &&
          other.value == this.value &&
          other.timestamp == this.timestamp &&
          other.note == this.note &&
          other.imagePath == this.imagePath &&
          other.isSynced == this.isSynced &&
          other.remoteId == this.remoteId);
}

class ElectricityReadingsCompanion extends UpdateCompanion<ElectricityReading> {
  final Value<int> id;
  final Value<double> value;
  final Value<DateTime> timestamp;
  final Value<String?> note;
  final Value<String?> imagePath;
  final Value<bool> isSynced;
  final Value<String?> remoteId;
  const ElectricityReadingsCompanion({
    this.id = const Value.absent(),
    this.value = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.note = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.remoteId = const Value.absent(),
  });
  ElectricityReadingsCompanion.insert({
    this.id = const Value.absent(),
    required double value,
    required DateTime timestamp,
    this.note = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.remoteId = const Value.absent(),
  }) : value = Value(value),
       timestamp = Value(timestamp);
  static Insertable<ElectricityReading> custom({
    Expression<int>? id,
    Expression<double>? value,
    Expression<DateTime>? timestamp,
    Expression<String>? note,
    Expression<String>? imagePath,
    Expression<bool>? isSynced,
    Expression<String>? remoteId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (value != null) 'value': value,
      if (timestamp != null) 'timestamp': timestamp,
      if (note != null) 'note': note,
      if (imagePath != null) 'image_path': imagePath,
      if (isSynced != null) 'is_synced': isSynced,
      if (remoteId != null) 'remote_id': remoteId,
    });
  }

  ElectricityReadingsCompanion copyWith({
    Value<int>? id,
    Value<double>? value,
    Value<DateTime>? timestamp,
    Value<String?>? note,
    Value<String?>? imagePath,
    Value<bool>? isSynced,
    Value<String?>? remoteId,
  }) {
    return ElectricityReadingsCompanion(
      id: id ?? this.id,
      value: value ?? this.value,
      timestamp: timestamp ?? this.timestamp,
      note: note ?? this.note,
      imagePath: imagePath ?? this.imagePath,
      isSynced: isSynced ?? this.isSynced,
      remoteId: remoteId ?? this.remoteId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (value.present) {
      map['value'] = Variable<double>(value.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (imagePath.present) {
      map['image_path'] = Variable<String>(imagePath.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<String>(remoteId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ElectricityReadingsCompanion(')
          ..write('id: $id, ')
          ..write('value: $value, ')
          ..write('timestamp: $timestamp, ')
          ..write('note: $note, ')
          ..write('imagePath: $imagePath, ')
          ..write('isSynced: $isSynced, ')
          ..write('remoteId: $remoteId')
          ..write(')'))
        .toString();
  }
}

class $PriceContractsTable extends PriceContracts
    with TableInfo<$PriceContractsTable, PriceContract> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PriceContractsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _internalNameMeta = const VerificationMeta(
    'internalName',
  );
  @override
  late final GeneratedColumn<String> internalName = GeneratedColumn<String>(
    'internal_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pricePerKwhMeta = const VerificationMeta(
    'pricePerKwh',
  );
  @override
  late final GeneratedColumn<double> pricePerKwh = GeneratedColumn<double>(
    'price_per_kwh',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _monthlyBasePriceMeta = const VerificationMeta(
    'monthlyBasePrice',
  );
  @override
  late final GeneratedColumn<double> monthlyBasePrice = GeneratedColumn<double>(
    'monthly_base_price',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _validFromMeta = const VerificationMeta(
    'validFrom',
  );
  @override
  late final GeneratedColumn<int> validFrom = GeneratedColumn<int>(
    'valid_from',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contractEndDateMeta = const VerificationMeta(
    'contractEndDate',
  );
  @override
  late final GeneratedColumn<int> contractEndDate = GeneratedColumn<int>(
    'contract_end_date',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _monthlyAdvancePaymentMeta =
      const VerificationMeta('monthlyAdvancePayment');
  @override
  late final GeneratedColumn<double> monthlyAdvancePayment =
      GeneratedColumn<double>(
        'monthly_advance_payment',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _brennwertMeta = const VerificationMeta(
    'brennwert',
  );
  @override
  late final GeneratedColumn<double> brennwert = GeneratedColumn<double>(
    'brennwert',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _zustandszahlMeta = const VerificationMeta(
    'zustandszahl',
  );
  @override
  late final GeneratedColumn<double> zustandszahl = GeneratedColumn<double>(
    'zustandszahl',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _isSyncedMeta = const VerificationMeta(
    'isSynced',
  );
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
    'is_synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _remoteIdMeta = const VerificationMeta(
    'remoteId',
  );
  @override
  late final GeneratedColumn<String> remoteId = GeneratedColumn<String>(
    'remote_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    internalName,
    displayName,
    pricePerKwh,
    monthlyBasePrice,
    validFrom,
    contractEndDate,
    monthlyAdvancePayment,
    brennwert,
    zustandszahl,
    isSynced,
    remoteId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'price_contracts';
  @override
  VerificationContext validateIntegrity(
    Insertable<PriceContract> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('internal_name')) {
      context.handle(
        _internalNameMeta,
        internalName.isAcceptableOrUnknown(
          data['internal_name']!,
          _internalNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_internalNameMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('price_per_kwh')) {
      context.handle(
        _pricePerKwhMeta,
        pricePerKwh.isAcceptableOrUnknown(
          data['price_per_kwh']!,
          _pricePerKwhMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_pricePerKwhMeta);
    }
    if (data.containsKey('monthly_base_price')) {
      context.handle(
        _monthlyBasePriceMeta,
        monthlyBasePrice.isAcceptableOrUnknown(
          data['monthly_base_price']!,
          _monthlyBasePriceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_monthlyBasePriceMeta);
    }
    if (data.containsKey('valid_from')) {
      context.handle(
        _validFromMeta,
        validFrom.isAcceptableOrUnknown(data['valid_from']!, _validFromMeta),
      );
    } else if (isInserting) {
      context.missing(_validFromMeta);
    }
    if (data.containsKey('contract_end_date')) {
      context.handle(
        _contractEndDateMeta,
        contractEndDate.isAcceptableOrUnknown(
          data['contract_end_date']!,
          _contractEndDateMeta,
        ),
      );
    }
    if (data.containsKey('monthly_advance_payment')) {
      context.handle(
        _monthlyAdvancePaymentMeta,
        monthlyAdvancePayment.isAcceptableOrUnknown(
          data['monthly_advance_payment']!,
          _monthlyAdvancePaymentMeta,
        ),
      );
    }
    if (data.containsKey('brennwert')) {
      context.handle(
        _brennwertMeta,
        brennwert.isAcceptableOrUnknown(data['brennwert']!, _brennwertMeta),
      );
    }
    if (data.containsKey('zustandszahl')) {
      context.handle(
        _zustandszahlMeta,
        zustandszahl.isAcceptableOrUnknown(
          data['zustandszahl']!,
          _zustandszahlMeta,
        ),
      );
    }
    if (data.containsKey('is_synced')) {
      context.handle(
        _isSyncedMeta,
        isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta),
      );
    }
    if (data.containsKey('remote_id')) {
      context.handle(
        _remoteIdMeta,
        remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PriceContract map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PriceContract(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      internalName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}internal_name'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      pricePerKwh: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}price_per_kwh'],
      )!,
      monthlyBasePrice: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}monthly_base_price'],
      )!,
      validFrom: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}valid_from'],
      )!,
      contractEndDate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}contract_end_date'],
      ),
      monthlyAdvancePayment: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}monthly_advance_payment'],
      ),
      brennwert: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}brennwert'],
      )!,
      zustandszahl: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}zustandszahl'],
      )!,
      isSynced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_synced'],
      )!,
      remoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_id'],
      ),
    );
  }

  @override
  $PriceContractsTable createAlias(String alias) {
    return $PriceContractsTable(attachedDatabase, alias);
  }
}

class PriceContract extends DataClass implements Insertable<PriceContract> {
  final int id;

  /// Internal unique name, e.g. "Stadtwerke_1". Never shown to the user.
  final String internalName;

  /// Display name shown to the user, e.g. "Stadtwerke".
  final String displayName;
  final double pricePerKwh;
  final double monthlyBasePrice;

  /// Milliseconds since epoch.
  final int validFrom;
  final int? contractEndDate;
  final double? monthlyAdvancePayment;
  final double brennwert;
  final double zustandszahl;
  final bool isSynced;
  final String? remoteId;
  const PriceContract({
    required this.id,
    required this.internalName,
    required this.displayName,
    required this.pricePerKwh,
    required this.monthlyBasePrice,
    required this.validFrom,
    this.contractEndDate,
    this.monthlyAdvancePayment,
    required this.brennwert,
    required this.zustandszahl,
    required this.isSynced,
    this.remoteId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['internal_name'] = Variable<String>(internalName);
    map['display_name'] = Variable<String>(displayName);
    map['price_per_kwh'] = Variable<double>(pricePerKwh);
    map['monthly_base_price'] = Variable<double>(monthlyBasePrice);
    map['valid_from'] = Variable<int>(validFrom);
    if (!nullToAbsent || contractEndDate != null) {
      map['contract_end_date'] = Variable<int>(contractEndDate);
    }
    if (!nullToAbsent || monthlyAdvancePayment != null) {
      map['monthly_advance_payment'] = Variable<double>(monthlyAdvancePayment);
    }
    map['brennwert'] = Variable<double>(brennwert);
    map['zustandszahl'] = Variable<double>(zustandszahl);
    map['is_synced'] = Variable<bool>(isSynced);
    if (!nullToAbsent || remoteId != null) {
      map['remote_id'] = Variable<String>(remoteId);
    }
    return map;
  }

  PriceContractsCompanion toCompanion(bool nullToAbsent) {
    return PriceContractsCompanion(
      id: Value(id),
      internalName: Value(internalName),
      displayName: Value(displayName),
      pricePerKwh: Value(pricePerKwh),
      monthlyBasePrice: Value(monthlyBasePrice),
      validFrom: Value(validFrom),
      contractEndDate: contractEndDate == null && nullToAbsent
          ? const Value.absent()
          : Value(contractEndDate),
      monthlyAdvancePayment: monthlyAdvancePayment == null && nullToAbsent
          ? const Value.absent()
          : Value(monthlyAdvancePayment),
      brennwert: Value(brennwert),
      zustandszahl: Value(zustandszahl),
      isSynced: Value(isSynced),
      remoteId: remoteId == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteId),
    );
  }

  factory PriceContract.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PriceContract(
      id: serializer.fromJson<int>(json['id']),
      internalName: serializer.fromJson<String>(json['internalName']),
      displayName: serializer.fromJson<String>(json['displayName']),
      pricePerKwh: serializer.fromJson<double>(json['pricePerKwh']),
      monthlyBasePrice: serializer.fromJson<double>(json['monthlyBasePrice']),
      validFrom: serializer.fromJson<int>(json['validFrom']),
      contractEndDate: serializer.fromJson<int?>(json['contractEndDate']),
      monthlyAdvancePayment: serializer.fromJson<double?>(
        json['monthlyAdvancePayment'],
      ),
      brennwert: serializer.fromJson<double>(json['brennwert']),
      zustandszahl: serializer.fromJson<double>(json['zustandszahl']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      remoteId: serializer.fromJson<String?>(json['remoteId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'internalName': serializer.toJson<String>(internalName),
      'displayName': serializer.toJson<String>(displayName),
      'pricePerKwh': serializer.toJson<double>(pricePerKwh),
      'monthlyBasePrice': serializer.toJson<double>(monthlyBasePrice),
      'validFrom': serializer.toJson<int>(validFrom),
      'contractEndDate': serializer.toJson<int?>(contractEndDate),
      'monthlyAdvancePayment': serializer.toJson<double?>(
        monthlyAdvancePayment,
      ),
      'brennwert': serializer.toJson<double>(brennwert),
      'zustandszahl': serializer.toJson<double>(zustandszahl),
      'isSynced': serializer.toJson<bool>(isSynced),
      'remoteId': serializer.toJson<String?>(remoteId),
    };
  }

  PriceContract copyWith({
    int? id,
    String? internalName,
    String? displayName,
    double? pricePerKwh,
    double? monthlyBasePrice,
    int? validFrom,
    Value<int?> contractEndDate = const Value.absent(),
    Value<double?> monthlyAdvancePayment = const Value.absent(),
    double? brennwert,
    double? zustandszahl,
    bool? isSynced,
    Value<String?> remoteId = const Value.absent(),
  }) => PriceContract(
    id: id ?? this.id,
    internalName: internalName ?? this.internalName,
    displayName: displayName ?? this.displayName,
    pricePerKwh: pricePerKwh ?? this.pricePerKwh,
    monthlyBasePrice: monthlyBasePrice ?? this.monthlyBasePrice,
    validFrom: validFrom ?? this.validFrom,
    contractEndDate: contractEndDate.present
        ? contractEndDate.value
        : this.contractEndDate,
    monthlyAdvancePayment: monthlyAdvancePayment.present
        ? monthlyAdvancePayment.value
        : this.monthlyAdvancePayment,
    brennwert: brennwert ?? this.brennwert,
    zustandszahl: zustandszahl ?? this.zustandszahl,
    isSynced: isSynced ?? this.isSynced,
    remoteId: remoteId.present ? remoteId.value : this.remoteId,
  );
  PriceContract copyWithCompanion(PriceContractsCompanion data) {
    return PriceContract(
      id: data.id.present ? data.id.value : this.id,
      internalName: data.internalName.present
          ? data.internalName.value
          : this.internalName,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      pricePerKwh: data.pricePerKwh.present
          ? data.pricePerKwh.value
          : this.pricePerKwh,
      monthlyBasePrice: data.monthlyBasePrice.present
          ? data.monthlyBasePrice.value
          : this.monthlyBasePrice,
      validFrom: data.validFrom.present ? data.validFrom.value : this.validFrom,
      contractEndDate: data.contractEndDate.present
          ? data.contractEndDate.value
          : this.contractEndDate,
      monthlyAdvancePayment: data.monthlyAdvancePayment.present
          ? data.monthlyAdvancePayment.value
          : this.monthlyAdvancePayment,
      brennwert: data.brennwert.present ? data.brennwert.value : this.brennwert,
      zustandszahl: data.zustandszahl.present
          ? data.zustandszahl.value
          : this.zustandszahl,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PriceContract(')
          ..write('id: $id, ')
          ..write('internalName: $internalName, ')
          ..write('displayName: $displayName, ')
          ..write('pricePerKwh: $pricePerKwh, ')
          ..write('monthlyBasePrice: $monthlyBasePrice, ')
          ..write('validFrom: $validFrom, ')
          ..write('contractEndDate: $contractEndDate, ')
          ..write('monthlyAdvancePayment: $monthlyAdvancePayment, ')
          ..write('brennwert: $brennwert, ')
          ..write('zustandszahl: $zustandszahl, ')
          ..write('isSynced: $isSynced, ')
          ..write('remoteId: $remoteId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    internalName,
    displayName,
    pricePerKwh,
    monthlyBasePrice,
    validFrom,
    contractEndDate,
    monthlyAdvancePayment,
    brennwert,
    zustandszahl,
    isSynced,
    remoteId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PriceContract &&
          other.id == this.id &&
          other.internalName == this.internalName &&
          other.displayName == this.displayName &&
          other.pricePerKwh == this.pricePerKwh &&
          other.monthlyBasePrice == this.monthlyBasePrice &&
          other.validFrom == this.validFrom &&
          other.contractEndDate == this.contractEndDate &&
          other.monthlyAdvancePayment == this.monthlyAdvancePayment &&
          other.brennwert == this.brennwert &&
          other.zustandszahl == this.zustandszahl &&
          other.isSynced == this.isSynced &&
          other.remoteId == this.remoteId);
}

class PriceContractsCompanion extends UpdateCompanion<PriceContract> {
  final Value<int> id;
  final Value<String> internalName;
  final Value<String> displayName;
  final Value<double> pricePerKwh;
  final Value<double> monthlyBasePrice;
  final Value<int> validFrom;
  final Value<int?> contractEndDate;
  final Value<double?> monthlyAdvancePayment;
  final Value<double> brennwert;
  final Value<double> zustandszahl;
  final Value<bool> isSynced;
  final Value<String?> remoteId;
  const PriceContractsCompanion({
    this.id = const Value.absent(),
    this.internalName = const Value.absent(),
    this.displayName = const Value.absent(),
    this.pricePerKwh = const Value.absent(),
    this.monthlyBasePrice = const Value.absent(),
    this.validFrom = const Value.absent(),
    this.contractEndDate = const Value.absent(),
    this.monthlyAdvancePayment = const Value.absent(),
    this.brennwert = const Value.absent(),
    this.zustandszahl = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.remoteId = const Value.absent(),
  });
  PriceContractsCompanion.insert({
    this.id = const Value.absent(),
    required String internalName,
    required String displayName,
    required double pricePerKwh,
    required double monthlyBasePrice,
    required int validFrom,
    this.contractEndDate = const Value.absent(),
    this.monthlyAdvancePayment = const Value.absent(),
    this.brennwert = const Value.absent(),
    this.zustandszahl = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.remoteId = const Value.absent(),
  }) : internalName = Value(internalName),
       displayName = Value(displayName),
       pricePerKwh = Value(pricePerKwh),
       monthlyBasePrice = Value(monthlyBasePrice),
       validFrom = Value(validFrom);
  static Insertable<PriceContract> custom({
    Expression<int>? id,
    Expression<String>? internalName,
    Expression<String>? displayName,
    Expression<double>? pricePerKwh,
    Expression<double>? monthlyBasePrice,
    Expression<int>? validFrom,
    Expression<int>? contractEndDate,
    Expression<double>? monthlyAdvancePayment,
    Expression<double>? brennwert,
    Expression<double>? zustandszahl,
    Expression<bool>? isSynced,
    Expression<String>? remoteId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (internalName != null) 'internal_name': internalName,
      if (displayName != null) 'display_name': displayName,
      if (pricePerKwh != null) 'price_per_kwh': pricePerKwh,
      if (monthlyBasePrice != null) 'monthly_base_price': monthlyBasePrice,
      if (validFrom != null) 'valid_from': validFrom,
      if (contractEndDate != null) 'contract_end_date': contractEndDate,
      if (monthlyAdvancePayment != null)
        'monthly_advance_payment': monthlyAdvancePayment,
      if (brennwert != null) 'brennwert': brennwert,
      if (zustandszahl != null) 'zustandszahl': zustandszahl,
      if (isSynced != null) 'is_synced': isSynced,
      if (remoteId != null) 'remote_id': remoteId,
    });
  }

  PriceContractsCompanion copyWith({
    Value<int>? id,
    Value<String>? internalName,
    Value<String>? displayName,
    Value<double>? pricePerKwh,
    Value<double>? monthlyBasePrice,
    Value<int>? validFrom,
    Value<int?>? contractEndDate,
    Value<double?>? monthlyAdvancePayment,
    Value<double>? brennwert,
    Value<double>? zustandszahl,
    Value<bool>? isSynced,
    Value<String?>? remoteId,
  }) {
    return PriceContractsCompanion(
      id: id ?? this.id,
      internalName: internalName ?? this.internalName,
      displayName: displayName ?? this.displayName,
      pricePerKwh: pricePerKwh ?? this.pricePerKwh,
      monthlyBasePrice: monthlyBasePrice ?? this.monthlyBasePrice,
      validFrom: validFrom ?? this.validFrom,
      contractEndDate: contractEndDate ?? this.contractEndDate,
      monthlyAdvancePayment:
          monthlyAdvancePayment ?? this.monthlyAdvancePayment,
      brennwert: brennwert ?? this.brennwert,
      zustandszahl: zustandszahl ?? this.zustandszahl,
      isSynced: isSynced ?? this.isSynced,
      remoteId: remoteId ?? this.remoteId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (internalName.present) {
      map['internal_name'] = Variable<String>(internalName.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (pricePerKwh.present) {
      map['price_per_kwh'] = Variable<double>(pricePerKwh.value);
    }
    if (monthlyBasePrice.present) {
      map['monthly_base_price'] = Variable<double>(monthlyBasePrice.value);
    }
    if (validFrom.present) {
      map['valid_from'] = Variable<int>(validFrom.value);
    }
    if (contractEndDate.present) {
      map['contract_end_date'] = Variable<int>(contractEndDate.value);
    }
    if (monthlyAdvancePayment.present) {
      map['monthly_advance_payment'] = Variable<double>(
        monthlyAdvancePayment.value,
      );
    }
    if (brennwert.present) {
      map['brennwert'] = Variable<double>(brennwert.value);
    }
    if (zustandszahl.present) {
      map['zustandszahl'] = Variable<double>(zustandszahl.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<String>(remoteId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PriceContractsCompanion(')
          ..write('id: $id, ')
          ..write('internalName: $internalName, ')
          ..write('displayName: $displayName, ')
          ..write('pricePerKwh: $pricePerKwh, ')
          ..write('monthlyBasePrice: $monthlyBasePrice, ')
          ..write('validFrom: $validFrom, ')
          ..write('contractEndDate: $contractEndDate, ')
          ..write('monthlyAdvancePayment: $monthlyAdvancePayment, ')
          ..write('brennwert: $brennwert, ')
          ..write('zustandszahl: $zustandszahl, ')
          ..write('isSynced: $isSynced, ')
          ..write('remoteId: $remoteId')
          ..write(')'))
        .toString();
  }
}

class $ElectricityContractsTable extends ElectricityContracts
    with TableInfo<$ElectricityContractsTable, ElectricityContract> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ElectricityContractsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _internalNameMeta = const VerificationMeta(
    'internalName',
  );
  @override
  late final GeneratedColumn<String> internalName = GeneratedColumn<String>(
    'internal_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pricePerKwhMeta = const VerificationMeta(
    'pricePerKwh',
  );
  @override
  late final GeneratedColumn<double> pricePerKwh = GeneratedColumn<double>(
    'price_per_kwh',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _monthlyBasePriceMeta = const VerificationMeta(
    'monthlyBasePrice',
  );
  @override
  late final GeneratedColumn<double> monthlyBasePrice = GeneratedColumn<double>(
    'monthly_base_price',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _validFromMeta = const VerificationMeta(
    'validFrom',
  );
  @override
  late final GeneratedColumn<int> validFrom = GeneratedColumn<int>(
    'valid_from',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contractEndDateMeta = const VerificationMeta(
    'contractEndDate',
  );
  @override
  late final GeneratedColumn<int> contractEndDate = GeneratedColumn<int>(
    'contract_end_date',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _monthlyAdvancePaymentMeta =
      const VerificationMeta('monthlyAdvancePayment');
  @override
  late final GeneratedColumn<double> monthlyAdvancePayment =
      GeneratedColumn<double>(
        'monthly_advance_payment',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _isSyncedMeta = const VerificationMeta(
    'isSynced',
  );
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
    'is_synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _remoteIdMeta = const VerificationMeta(
    'remoteId',
  );
  @override
  late final GeneratedColumn<String> remoteId = GeneratedColumn<String>(
    'remote_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    internalName,
    displayName,
    pricePerKwh,
    monthlyBasePrice,
    validFrom,
    contractEndDate,
    monthlyAdvancePayment,
    isSynced,
    remoteId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'electricity_contracts';
  @override
  VerificationContext validateIntegrity(
    Insertable<ElectricityContract> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('internal_name')) {
      context.handle(
        _internalNameMeta,
        internalName.isAcceptableOrUnknown(
          data['internal_name']!,
          _internalNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_internalNameMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('price_per_kwh')) {
      context.handle(
        _pricePerKwhMeta,
        pricePerKwh.isAcceptableOrUnknown(
          data['price_per_kwh']!,
          _pricePerKwhMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_pricePerKwhMeta);
    }
    if (data.containsKey('monthly_base_price')) {
      context.handle(
        _monthlyBasePriceMeta,
        monthlyBasePrice.isAcceptableOrUnknown(
          data['monthly_base_price']!,
          _monthlyBasePriceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_monthlyBasePriceMeta);
    }
    if (data.containsKey('valid_from')) {
      context.handle(
        _validFromMeta,
        validFrom.isAcceptableOrUnknown(data['valid_from']!, _validFromMeta),
      );
    } else if (isInserting) {
      context.missing(_validFromMeta);
    }
    if (data.containsKey('contract_end_date')) {
      context.handle(
        _contractEndDateMeta,
        contractEndDate.isAcceptableOrUnknown(
          data['contract_end_date']!,
          _contractEndDateMeta,
        ),
      );
    }
    if (data.containsKey('monthly_advance_payment')) {
      context.handle(
        _monthlyAdvancePaymentMeta,
        monthlyAdvancePayment.isAcceptableOrUnknown(
          data['monthly_advance_payment']!,
          _monthlyAdvancePaymentMeta,
        ),
      );
    }
    if (data.containsKey('is_synced')) {
      context.handle(
        _isSyncedMeta,
        isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta),
      );
    }
    if (data.containsKey('remote_id')) {
      context.handle(
        _remoteIdMeta,
        remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ElectricityContract map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ElectricityContract(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      internalName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}internal_name'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      pricePerKwh: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}price_per_kwh'],
      )!,
      monthlyBasePrice: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}monthly_base_price'],
      )!,
      validFrom: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}valid_from'],
      )!,
      contractEndDate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}contract_end_date'],
      ),
      monthlyAdvancePayment: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}monthly_advance_payment'],
      ),
      isSynced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_synced'],
      )!,
      remoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_id'],
      ),
    );
  }

  @override
  $ElectricityContractsTable createAlias(String alias) {
    return $ElectricityContractsTable(attachedDatabase, alias);
  }
}

class ElectricityContract extends DataClass
    implements Insertable<ElectricityContract> {
  final int id;
  final String internalName;
  final String displayName;
  final double pricePerKwh;
  final double monthlyBasePrice;
  final int validFrom;
  final int? contractEndDate;
  final double? monthlyAdvancePayment;
  final bool isSynced;
  final String? remoteId;
  const ElectricityContract({
    required this.id,
    required this.internalName,
    required this.displayName,
    required this.pricePerKwh,
    required this.monthlyBasePrice,
    required this.validFrom,
    this.contractEndDate,
    this.monthlyAdvancePayment,
    required this.isSynced,
    this.remoteId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['internal_name'] = Variable<String>(internalName);
    map['display_name'] = Variable<String>(displayName);
    map['price_per_kwh'] = Variable<double>(pricePerKwh);
    map['monthly_base_price'] = Variable<double>(monthlyBasePrice);
    map['valid_from'] = Variable<int>(validFrom);
    if (!nullToAbsent || contractEndDate != null) {
      map['contract_end_date'] = Variable<int>(contractEndDate);
    }
    if (!nullToAbsent || monthlyAdvancePayment != null) {
      map['monthly_advance_payment'] = Variable<double>(monthlyAdvancePayment);
    }
    map['is_synced'] = Variable<bool>(isSynced);
    if (!nullToAbsent || remoteId != null) {
      map['remote_id'] = Variable<String>(remoteId);
    }
    return map;
  }

  ElectricityContractsCompanion toCompanion(bool nullToAbsent) {
    return ElectricityContractsCompanion(
      id: Value(id),
      internalName: Value(internalName),
      displayName: Value(displayName),
      pricePerKwh: Value(pricePerKwh),
      monthlyBasePrice: Value(monthlyBasePrice),
      validFrom: Value(validFrom),
      contractEndDate: contractEndDate == null && nullToAbsent
          ? const Value.absent()
          : Value(contractEndDate),
      monthlyAdvancePayment: monthlyAdvancePayment == null && nullToAbsent
          ? const Value.absent()
          : Value(monthlyAdvancePayment),
      isSynced: Value(isSynced),
      remoteId: remoteId == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteId),
    );
  }

  factory ElectricityContract.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ElectricityContract(
      id: serializer.fromJson<int>(json['id']),
      internalName: serializer.fromJson<String>(json['internalName']),
      displayName: serializer.fromJson<String>(json['displayName']),
      pricePerKwh: serializer.fromJson<double>(json['pricePerKwh']),
      monthlyBasePrice: serializer.fromJson<double>(json['monthlyBasePrice']),
      validFrom: serializer.fromJson<int>(json['validFrom']),
      contractEndDate: serializer.fromJson<int?>(json['contractEndDate']),
      monthlyAdvancePayment: serializer.fromJson<double?>(
        json['monthlyAdvancePayment'],
      ),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      remoteId: serializer.fromJson<String?>(json['remoteId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'internalName': serializer.toJson<String>(internalName),
      'displayName': serializer.toJson<String>(displayName),
      'pricePerKwh': serializer.toJson<double>(pricePerKwh),
      'monthlyBasePrice': serializer.toJson<double>(monthlyBasePrice),
      'validFrom': serializer.toJson<int>(validFrom),
      'contractEndDate': serializer.toJson<int?>(contractEndDate),
      'monthlyAdvancePayment': serializer.toJson<double?>(
        monthlyAdvancePayment,
      ),
      'isSynced': serializer.toJson<bool>(isSynced),
      'remoteId': serializer.toJson<String?>(remoteId),
    };
  }

  ElectricityContract copyWith({
    int? id,
    String? internalName,
    String? displayName,
    double? pricePerKwh,
    double? monthlyBasePrice,
    int? validFrom,
    Value<int?> contractEndDate = const Value.absent(),
    Value<double?> monthlyAdvancePayment = const Value.absent(),
    bool? isSynced,
    Value<String?> remoteId = const Value.absent(),
  }) => ElectricityContract(
    id: id ?? this.id,
    internalName: internalName ?? this.internalName,
    displayName: displayName ?? this.displayName,
    pricePerKwh: pricePerKwh ?? this.pricePerKwh,
    monthlyBasePrice: monthlyBasePrice ?? this.monthlyBasePrice,
    validFrom: validFrom ?? this.validFrom,
    contractEndDate: contractEndDate.present
        ? contractEndDate.value
        : this.contractEndDate,
    monthlyAdvancePayment: monthlyAdvancePayment.present
        ? monthlyAdvancePayment.value
        : this.monthlyAdvancePayment,
    isSynced: isSynced ?? this.isSynced,
    remoteId: remoteId.present ? remoteId.value : this.remoteId,
  );
  ElectricityContract copyWithCompanion(ElectricityContractsCompanion data) {
    return ElectricityContract(
      id: data.id.present ? data.id.value : this.id,
      internalName: data.internalName.present
          ? data.internalName.value
          : this.internalName,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      pricePerKwh: data.pricePerKwh.present
          ? data.pricePerKwh.value
          : this.pricePerKwh,
      monthlyBasePrice: data.monthlyBasePrice.present
          ? data.monthlyBasePrice.value
          : this.monthlyBasePrice,
      validFrom: data.validFrom.present ? data.validFrom.value : this.validFrom,
      contractEndDate: data.contractEndDate.present
          ? data.contractEndDate.value
          : this.contractEndDate,
      monthlyAdvancePayment: data.monthlyAdvancePayment.present
          ? data.monthlyAdvancePayment.value
          : this.monthlyAdvancePayment,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ElectricityContract(')
          ..write('id: $id, ')
          ..write('internalName: $internalName, ')
          ..write('displayName: $displayName, ')
          ..write('pricePerKwh: $pricePerKwh, ')
          ..write('monthlyBasePrice: $monthlyBasePrice, ')
          ..write('validFrom: $validFrom, ')
          ..write('contractEndDate: $contractEndDate, ')
          ..write('monthlyAdvancePayment: $monthlyAdvancePayment, ')
          ..write('isSynced: $isSynced, ')
          ..write('remoteId: $remoteId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    internalName,
    displayName,
    pricePerKwh,
    monthlyBasePrice,
    validFrom,
    contractEndDate,
    monthlyAdvancePayment,
    isSynced,
    remoteId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ElectricityContract &&
          other.id == this.id &&
          other.internalName == this.internalName &&
          other.displayName == this.displayName &&
          other.pricePerKwh == this.pricePerKwh &&
          other.monthlyBasePrice == this.monthlyBasePrice &&
          other.validFrom == this.validFrom &&
          other.contractEndDate == this.contractEndDate &&
          other.monthlyAdvancePayment == this.monthlyAdvancePayment &&
          other.isSynced == this.isSynced &&
          other.remoteId == this.remoteId);
}

class ElectricityContractsCompanion
    extends UpdateCompanion<ElectricityContract> {
  final Value<int> id;
  final Value<String> internalName;
  final Value<String> displayName;
  final Value<double> pricePerKwh;
  final Value<double> monthlyBasePrice;
  final Value<int> validFrom;
  final Value<int?> contractEndDate;
  final Value<double?> monthlyAdvancePayment;
  final Value<bool> isSynced;
  final Value<String?> remoteId;
  const ElectricityContractsCompanion({
    this.id = const Value.absent(),
    this.internalName = const Value.absent(),
    this.displayName = const Value.absent(),
    this.pricePerKwh = const Value.absent(),
    this.monthlyBasePrice = const Value.absent(),
    this.validFrom = const Value.absent(),
    this.contractEndDate = const Value.absent(),
    this.monthlyAdvancePayment = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.remoteId = const Value.absent(),
  });
  ElectricityContractsCompanion.insert({
    this.id = const Value.absent(),
    required String internalName,
    required String displayName,
    required double pricePerKwh,
    required double monthlyBasePrice,
    required int validFrom,
    this.contractEndDate = const Value.absent(),
    this.monthlyAdvancePayment = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.remoteId = const Value.absent(),
  }) : internalName = Value(internalName),
       displayName = Value(displayName),
       pricePerKwh = Value(pricePerKwh),
       monthlyBasePrice = Value(monthlyBasePrice),
       validFrom = Value(validFrom);
  static Insertable<ElectricityContract> custom({
    Expression<int>? id,
    Expression<String>? internalName,
    Expression<String>? displayName,
    Expression<double>? pricePerKwh,
    Expression<double>? monthlyBasePrice,
    Expression<int>? validFrom,
    Expression<int>? contractEndDate,
    Expression<double>? monthlyAdvancePayment,
    Expression<bool>? isSynced,
    Expression<String>? remoteId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (internalName != null) 'internal_name': internalName,
      if (displayName != null) 'display_name': displayName,
      if (pricePerKwh != null) 'price_per_kwh': pricePerKwh,
      if (monthlyBasePrice != null) 'monthly_base_price': monthlyBasePrice,
      if (validFrom != null) 'valid_from': validFrom,
      if (contractEndDate != null) 'contract_end_date': contractEndDate,
      if (monthlyAdvancePayment != null)
        'monthly_advance_payment': monthlyAdvancePayment,
      if (isSynced != null) 'is_synced': isSynced,
      if (remoteId != null) 'remote_id': remoteId,
    });
  }

  ElectricityContractsCompanion copyWith({
    Value<int>? id,
    Value<String>? internalName,
    Value<String>? displayName,
    Value<double>? pricePerKwh,
    Value<double>? monthlyBasePrice,
    Value<int>? validFrom,
    Value<int?>? contractEndDate,
    Value<double?>? monthlyAdvancePayment,
    Value<bool>? isSynced,
    Value<String?>? remoteId,
  }) {
    return ElectricityContractsCompanion(
      id: id ?? this.id,
      internalName: internalName ?? this.internalName,
      displayName: displayName ?? this.displayName,
      pricePerKwh: pricePerKwh ?? this.pricePerKwh,
      monthlyBasePrice: monthlyBasePrice ?? this.monthlyBasePrice,
      validFrom: validFrom ?? this.validFrom,
      contractEndDate: contractEndDate ?? this.contractEndDate,
      monthlyAdvancePayment:
          monthlyAdvancePayment ?? this.monthlyAdvancePayment,
      isSynced: isSynced ?? this.isSynced,
      remoteId: remoteId ?? this.remoteId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (internalName.present) {
      map['internal_name'] = Variable<String>(internalName.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (pricePerKwh.present) {
      map['price_per_kwh'] = Variable<double>(pricePerKwh.value);
    }
    if (monthlyBasePrice.present) {
      map['monthly_base_price'] = Variable<double>(monthlyBasePrice.value);
    }
    if (validFrom.present) {
      map['valid_from'] = Variable<int>(validFrom.value);
    }
    if (contractEndDate.present) {
      map['contract_end_date'] = Variable<int>(contractEndDate.value);
    }
    if (monthlyAdvancePayment.present) {
      map['monthly_advance_payment'] = Variable<double>(
        monthlyAdvancePayment.value,
      );
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<String>(remoteId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ElectricityContractsCompanion(')
          ..write('id: $id, ')
          ..write('internalName: $internalName, ')
          ..write('displayName: $displayName, ')
          ..write('pricePerKwh: $pricePerKwh, ')
          ..write('monthlyBasePrice: $monthlyBasePrice, ')
          ..write('validFrom: $validFrom, ')
          ..write('contractEndDate: $contractEndDate, ')
          ..write('monthlyAdvancePayment: $monthlyAdvancePayment, ')
          ..write('isSynced: $isSynced, ')
          ..write('remoteId: $remoteId')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _locationPlzMeta = const VerificationMeta(
    'locationPlz',
  );
  @override
  late final GeneratedColumn<String> locationPlz = GeneratedColumn<String>(
    'location_plz',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _locationCityMeta = const VerificationMeta(
    'locationCity',
  );
  @override
  late final GeneratedColumn<String> locationCity = GeneratedColumn<String>(
    'location_city',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _locationLatMeta = const VerificationMeta(
    'locationLat',
  );
  @override
  late final GeneratedColumn<double> locationLat = GeneratedColumn<double>(
    'location_lat',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _locationLonMeta = const VerificationMeta(
    'locationLon',
  );
  @override
  late final GeneratedColumn<double> locationLon = GeneratedColumn<double>(
    'location_lon',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _meterIntDigitsMeta = const VerificationMeta(
    'meterIntDigits',
  );
  @override
  late final GeneratedColumn<int> meterIntDigits = GeneratedColumn<int>(
    'meter_int_digits',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _electricityIntDigitsMeta =
      const VerificationMeta('electricityIntDigits');
  @override
  late final GeneratedColumn<int> electricityIntDigits = GeneratedColumn<int>(
    'electricity_int_digits',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _electricityDecDigitsMeta =
      const VerificationMeta('electricityDecDigits');
  @override
  late final GeneratedColumn<int> electricityDecDigits = GeneratedColumn<int>(
    'electricity_dec_digits',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _houseTypeMeta = const VerificationMeta(
    'houseType',
  );
  @override
  late final GeneratedColumn<String> houseType = GeneratedColumn<String>(
    'house_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _squareMetersMeta = const VerificationMeta(
    'squareMeters',
  );
  @override
  late final GeneratedColumn<int> squareMeters = GeneratedColumn<int>(
    'square_meters',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _numberOfPersonsMeta = const VerificationMeta(
    'numberOfPersons',
  );
  @override
  late final GeneratedColumn<int> numberOfPersons = GeneratedColumn<int>(
    'number_of_persons',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hasPvMeta = const VerificationMeta('hasPv');
  @override
  late final GeneratedColumn<bool> hasPv = GeneratedColumn<bool>(
    'has_pv',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("has_pv" IN (0, 1))',
    ),
  );
  static const VerificationMeta _hasSolarThermalMeta = const VerificationMeta(
    'hasSolarThermal',
  );
  @override
  late final GeneratedColumn<bool> hasSolarThermal = GeneratedColumn<bool>(
    'has_solar_thermal',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("has_solar_thermal" IN (0, 1))',
    ),
  );
  static const VerificationMeta _trackingModeMeta = const VerificationMeta(
    'trackingMode',
  );
  @override
  late final GeneratedColumn<String> trackingMode = GeneratedColumn<String>(
    'tracking_mode',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _constructionYearMeta = const VerificationMeta(
    'constructionYear',
  );
  @override
  late final GeneratedColumn<int> constructionYear = GeneratedColumn<int>(
    'construction_year',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isInsulatedMeta = const VerificationMeta(
    'isInsulated',
  );
  @override
  late final GeneratedColumn<bool> isInsulated = GeneratedColumn<bool>(
    'is_insulated',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_insulated" IN (0, 1))',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    locationPlz,
    locationCity,
    locationLat,
    locationLon,
    meterIntDigits,
    electricityIntDigits,
    electricityDecDigits,
    houseType,
    squareMeters,
    numberOfPersons,
    hasPv,
    hasSolarThermal,
    trackingMode,
    constructionYear,
    isInsulated,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('location_plz')) {
      context.handle(
        _locationPlzMeta,
        locationPlz.isAcceptableOrUnknown(
          data['location_plz']!,
          _locationPlzMeta,
        ),
      );
    }
    if (data.containsKey('location_city')) {
      context.handle(
        _locationCityMeta,
        locationCity.isAcceptableOrUnknown(
          data['location_city']!,
          _locationCityMeta,
        ),
      );
    }
    if (data.containsKey('location_lat')) {
      context.handle(
        _locationLatMeta,
        locationLat.isAcceptableOrUnknown(
          data['location_lat']!,
          _locationLatMeta,
        ),
      );
    }
    if (data.containsKey('location_lon')) {
      context.handle(
        _locationLonMeta,
        locationLon.isAcceptableOrUnknown(
          data['location_lon']!,
          _locationLonMeta,
        ),
      );
    }
    if (data.containsKey('meter_int_digits')) {
      context.handle(
        _meterIntDigitsMeta,
        meterIntDigits.isAcceptableOrUnknown(
          data['meter_int_digits']!,
          _meterIntDigitsMeta,
        ),
      );
    }
    if (data.containsKey('electricity_int_digits')) {
      context.handle(
        _electricityIntDigitsMeta,
        electricityIntDigits.isAcceptableOrUnknown(
          data['electricity_int_digits']!,
          _electricityIntDigitsMeta,
        ),
      );
    }
    if (data.containsKey('electricity_dec_digits')) {
      context.handle(
        _electricityDecDigitsMeta,
        electricityDecDigits.isAcceptableOrUnknown(
          data['electricity_dec_digits']!,
          _electricityDecDigitsMeta,
        ),
      );
    }
    if (data.containsKey('house_type')) {
      context.handle(
        _houseTypeMeta,
        houseType.isAcceptableOrUnknown(data['house_type']!, _houseTypeMeta),
      );
    }
    if (data.containsKey('square_meters')) {
      context.handle(
        _squareMetersMeta,
        squareMeters.isAcceptableOrUnknown(
          data['square_meters']!,
          _squareMetersMeta,
        ),
      );
    }
    if (data.containsKey('number_of_persons')) {
      context.handle(
        _numberOfPersonsMeta,
        numberOfPersons.isAcceptableOrUnknown(
          data['number_of_persons']!,
          _numberOfPersonsMeta,
        ),
      );
    }
    if (data.containsKey('has_pv')) {
      context.handle(
        _hasPvMeta,
        hasPv.isAcceptableOrUnknown(data['has_pv']!, _hasPvMeta),
      );
    }
    if (data.containsKey('has_solar_thermal')) {
      context.handle(
        _hasSolarThermalMeta,
        hasSolarThermal.isAcceptableOrUnknown(
          data['has_solar_thermal']!,
          _hasSolarThermalMeta,
        ),
      );
    }
    if (data.containsKey('tracking_mode')) {
      context.handle(
        _trackingModeMeta,
        trackingMode.isAcceptableOrUnknown(
          data['tracking_mode']!,
          _trackingModeMeta,
        ),
      );
    }
    if (data.containsKey('construction_year')) {
      context.handle(
        _constructionYearMeta,
        constructionYear.isAcceptableOrUnknown(
          data['construction_year']!,
          _constructionYearMeta,
        ),
      );
    }
    if (data.containsKey('is_insulated')) {
      context.handle(
        _isInsulatedMeta,
        isInsulated.isAcceptableOrUnknown(
          data['is_insulated']!,
          _isInsulatedMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AppSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSetting(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      locationPlz: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location_plz'],
      ),
      locationCity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location_city'],
      ),
      locationLat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}location_lat'],
      ),
      locationLon: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}location_lon'],
      ),
      meterIntDigits: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}meter_int_digits'],
      ),
      electricityIntDigits: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}electricity_int_digits'],
      ),
      electricityDecDigits: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}electricity_dec_digits'],
      ),
      houseType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}house_type'],
      ),
      squareMeters: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}square_meters'],
      ),
      numberOfPersons: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}number_of_persons'],
      ),
      hasPv: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}has_pv'],
      ),
      hasSolarThermal: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}has_solar_thermal'],
      ),
      trackingMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tracking_mode'],
      ),
      constructionYear: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}construction_year'],
      ),
      isInsulated: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_insulated'],
      ),
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSetting extends DataClass implements Insertable<AppSetting> {
  final int id;
  final String? locationPlz;
  final String? locationCity;
  final double? locationLat;
  final double? locationLon;
  final int? meterIntDigits;
  final int? electricityIntDigits;
  final int? electricityDecDigits;
  final String? houseType;
  final int? squareMeters;
  final int? numberOfPersons;
  final bool? hasPv;
  final bool? hasSolarThermal;
  final String? trackingMode;
  final int? constructionYear;
  final bool? isInsulated;
  const AppSetting({
    required this.id,
    this.locationPlz,
    this.locationCity,
    this.locationLat,
    this.locationLon,
    this.meterIntDigits,
    this.electricityIntDigits,
    this.electricityDecDigits,
    this.houseType,
    this.squareMeters,
    this.numberOfPersons,
    this.hasPv,
    this.hasSolarThermal,
    this.trackingMode,
    this.constructionYear,
    this.isInsulated,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || locationPlz != null) {
      map['location_plz'] = Variable<String>(locationPlz);
    }
    if (!nullToAbsent || locationCity != null) {
      map['location_city'] = Variable<String>(locationCity);
    }
    if (!nullToAbsent || locationLat != null) {
      map['location_lat'] = Variable<double>(locationLat);
    }
    if (!nullToAbsent || locationLon != null) {
      map['location_lon'] = Variable<double>(locationLon);
    }
    if (!nullToAbsent || meterIntDigits != null) {
      map['meter_int_digits'] = Variable<int>(meterIntDigits);
    }
    if (!nullToAbsent || electricityIntDigits != null) {
      map['electricity_int_digits'] = Variable<int>(electricityIntDigits);
    }
    if (!nullToAbsent || electricityDecDigits != null) {
      map['electricity_dec_digits'] = Variable<int>(electricityDecDigits);
    }
    if (!nullToAbsent || houseType != null) {
      map['house_type'] = Variable<String>(houseType);
    }
    if (!nullToAbsent || squareMeters != null) {
      map['square_meters'] = Variable<int>(squareMeters);
    }
    if (!nullToAbsent || numberOfPersons != null) {
      map['number_of_persons'] = Variable<int>(numberOfPersons);
    }
    if (!nullToAbsent || hasPv != null) {
      map['has_pv'] = Variable<bool>(hasPv);
    }
    if (!nullToAbsent || hasSolarThermal != null) {
      map['has_solar_thermal'] = Variable<bool>(hasSolarThermal);
    }
    if (!nullToAbsent || trackingMode != null) {
      map['tracking_mode'] = Variable<String>(trackingMode);
    }
    if (!nullToAbsent || constructionYear != null) {
      map['construction_year'] = Variable<int>(constructionYear);
    }
    if (!nullToAbsent || isInsulated != null) {
      map['is_insulated'] = Variable<bool>(isInsulated);
    }
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(
      id: Value(id),
      locationPlz: locationPlz == null && nullToAbsent
          ? const Value.absent()
          : Value(locationPlz),
      locationCity: locationCity == null && nullToAbsent
          ? const Value.absent()
          : Value(locationCity),
      locationLat: locationLat == null && nullToAbsent
          ? const Value.absent()
          : Value(locationLat),
      locationLon: locationLon == null && nullToAbsent
          ? const Value.absent()
          : Value(locationLon),
      meterIntDigits: meterIntDigits == null && nullToAbsent
          ? const Value.absent()
          : Value(meterIntDigits),
      electricityIntDigits: electricityIntDigits == null && nullToAbsent
          ? const Value.absent()
          : Value(electricityIntDigits),
      electricityDecDigits: electricityDecDigits == null && nullToAbsent
          ? const Value.absent()
          : Value(electricityDecDigits),
      houseType: houseType == null && nullToAbsent
          ? const Value.absent()
          : Value(houseType),
      squareMeters: squareMeters == null && nullToAbsent
          ? const Value.absent()
          : Value(squareMeters),
      numberOfPersons: numberOfPersons == null && nullToAbsent
          ? const Value.absent()
          : Value(numberOfPersons),
      hasPv: hasPv == null && nullToAbsent
          ? const Value.absent()
          : Value(hasPv),
      hasSolarThermal: hasSolarThermal == null && nullToAbsent
          ? const Value.absent()
          : Value(hasSolarThermal),
      trackingMode: trackingMode == null && nullToAbsent
          ? const Value.absent()
          : Value(trackingMode),
      constructionYear: constructionYear == null && nullToAbsent
          ? const Value.absent()
          : Value(constructionYear),
      isInsulated: isInsulated == null && nullToAbsent
          ? const Value.absent()
          : Value(isInsulated),
    );
  }

  factory AppSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSetting(
      id: serializer.fromJson<int>(json['id']),
      locationPlz: serializer.fromJson<String?>(json['locationPlz']),
      locationCity: serializer.fromJson<String?>(json['locationCity']),
      locationLat: serializer.fromJson<double?>(json['locationLat']),
      locationLon: serializer.fromJson<double?>(json['locationLon']),
      meterIntDigits: serializer.fromJson<int?>(json['meterIntDigits']),
      electricityIntDigits: serializer.fromJson<int?>(
        json['electricityIntDigits'],
      ),
      electricityDecDigits: serializer.fromJson<int?>(
        json['electricityDecDigits'],
      ),
      houseType: serializer.fromJson<String?>(json['houseType']),
      squareMeters: serializer.fromJson<int?>(json['squareMeters']),
      numberOfPersons: serializer.fromJson<int?>(json['numberOfPersons']),
      hasPv: serializer.fromJson<bool?>(json['hasPv']),
      hasSolarThermal: serializer.fromJson<bool?>(json['hasSolarThermal']),
      trackingMode: serializer.fromJson<String?>(json['trackingMode']),
      constructionYear: serializer.fromJson<int?>(json['constructionYear']),
      isInsulated: serializer.fromJson<bool?>(json['isInsulated']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'locationPlz': serializer.toJson<String?>(locationPlz),
      'locationCity': serializer.toJson<String?>(locationCity),
      'locationLat': serializer.toJson<double?>(locationLat),
      'locationLon': serializer.toJson<double?>(locationLon),
      'meterIntDigits': serializer.toJson<int?>(meterIntDigits),
      'electricityIntDigits': serializer.toJson<int?>(electricityIntDigits),
      'electricityDecDigits': serializer.toJson<int?>(electricityDecDigits),
      'houseType': serializer.toJson<String?>(houseType),
      'squareMeters': serializer.toJson<int?>(squareMeters),
      'numberOfPersons': serializer.toJson<int?>(numberOfPersons),
      'hasPv': serializer.toJson<bool?>(hasPv),
      'hasSolarThermal': serializer.toJson<bool?>(hasSolarThermal),
      'trackingMode': serializer.toJson<String?>(trackingMode),
      'constructionYear': serializer.toJson<int?>(constructionYear),
      'isInsulated': serializer.toJson<bool?>(isInsulated),
    };
  }

  AppSetting copyWith({
    int? id,
    Value<String?> locationPlz = const Value.absent(),
    Value<String?> locationCity = const Value.absent(),
    Value<double?> locationLat = const Value.absent(),
    Value<double?> locationLon = const Value.absent(),
    Value<int?> meterIntDigits = const Value.absent(),
    Value<int?> electricityIntDigits = const Value.absent(),
    Value<int?> electricityDecDigits = const Value.absent(),
    Value<String?> houseType = const Value.absent(),
    Value<int?> squareMeters = const Value.absent(),
    Value<int?> numberOfPersons = const Value.absent(),
    Value<bool?> hasPv = const Value.absent(),
    Value<bool?> hasSolarThermal = const Value.absent(),
    Value<String?> trackingMode = const Value.absent(),
    Value<int?> constructionYear = const Value.absent(),
    Value<bool?> isInsulated = const Value.absent(),
  }) => AppSetting(
    id: id ?? this.id,
    locationPlz: locationPlz.present ? locationPlz.value : this.locationPlz,
    locationCity: locationCity.present ? locationCity.value : this.locationCity,
    locationLat: locationLat.present ? locationLat.value : this.locationLat,
    locationLon: locationLon.present ? locationLon.value : this.locationLon,
    meterIntDigits: meterIntDigits.present
        ? meterIntDigits.value
        : this.meterIntDigits,
    electricityIntDigits: electricityIntDigits.present
        ? electricityIntDigits.value
        : this.electricityIntDigits,
    electricityDecDigits: electricityDecDigits.present
        ? electricityDecDigits.value
        : this.electricityDecDigits,
    houseType: houseType.present ? houseType.value : this.houseType,
    squareMeters: squareMeters.present ? squareMeters.value : this.squareMeters,
    numberOfPersons: numberOfPersons.present
        ? numberOfPersons.value
        : this.numberOfPersons,
    hasPv: hasPv.present ? hasPv.value : this.hasPv,
    hasSolarThermal: hasSolarThermal.present
        ? hasSolarThermal.value
        : this.hasSolarThermal,
    trackingMode: trackingMode.present ? trackingMode.value : this.trackingMode,
    constructionYear: constructionYear.present
        ? constructionYear.value
        : this.constructionYear,
    isInsulated: isInsulated.present ? isInsulated.value : this.isInsulated,
  );
  AppSetting copyWithCompanion(AppSettingsCompanion data) {
    return AppSetting(
      id: data.id.present ? data.id.value : this.id,
      locationPlz: data.locationPlz.present
          ? data.locationPlz.value
          : this.locationPlz,
      locationCity: data.locationCity.present
          ? data.locationCity.value
          : this.locationCity,
      locationLat: data.locationLat.present
          ? data.locationLat.value
          : this.locationLat,
      locationLon: data.locationLon.present
          ? data.locationLon.value
          : this.locationLon,
      meterIntDigits: data.meterIntDigits.present
          ? data.meterIntDigits.value
          : this.meterIntDigits,
      electricityIntDigits: data.electricityIntDigits.present
          ? data.electricityIntDigits.value
          : this.electricityIntDigits,
      electricityDecDigits: data.electricityDecDigits.present
          ? data.electricityDecDigits.value
          : this.electricityDecDigits,
      houseType: data.houseType.present ? data.houseType.value : this.houseType,
      squareMeters: data.squareMeters.present
          ? data.squareMeters.value
          : this.squareMeters,
      numberOfPersons: data.numberOfPersons.present
          ? data.numberOfPersons.value
          : this.numberOfPersons,
      hasPv: data.hasPv.present ? data.hasPv.value : this.hasPv,
      hasSolarThermal: data.hasSolarThermal.present
          ? data.hasSolarThermal.value
          : this.hasSolarThermal,
      trackingMode: data.trackingMode.present
          ? data.trackingMode.value
          : this.trackingMode,
      constructionYear: data.constructionYear.present
          ? data.constructionYear.value
          : this.constructionYear,
      isInsulated: data.isInsulated.present
          ? data.isInsulated.value
          : this.isInsulated,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
          ..write('id: $id, ')
          ..write('locationPlz: $locationPlz, ')
          ..write('locationCity: $locationCity, ')
          ..write('locationLat: $locationLat, ')
          ..write('locationLon: $locationLon, ')
          ..write('meterIntDigits: $meterIntDigits, ')
          ..write('electricityIntDigits: $electricityIntDigits, ')
          ..write('electricityDecDigits: $electricityDecDigits, ')
          ..write('houseType: $houseType, ')
          ..write('squareMeters: $squareMeters, ')
          ..write('numberOfPersons: $numberOfPersons, ')
          ..write('hasPv: $hasPv, ')
          ..write('hasSolarThermal: $hasSolarThermal, ')
          ..write('trackingMode: $trackingMode, ')
          ..write('constructionYear: $constructionYear, ')
          ..write('isInsulated: $isInsulated')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    locationPlz,
    locationCity,
    locationLat,
    locationLon,
    meterIntDigits,
    electricityIntDigits,
    electricityDecDigits,
    houseType,
    squareMeters,
    numberOfPersons,
    hasPv,
    hasSolarThermal,
    trackingMode,
    constructionYear,
    isInsulated,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSetting &&
          other.id == this.id &&
          other.locationPlz == this.locationPlz &&
          other.locationCity == this.locationCity &&
          other.locationLat == this.locationLat &&
          other.locationLon == this.locationLon &&
          other.meterIntDigits == this.meterIntDigits &&
          other.electricityIntDigits == this.electricityIntDigits &&
          other.electricityDecDigits == this.electricityDecDigits &&
          other.houseType == this.houseType &&
          other.squareMeters == this.squareMeters &&
          other.numberOfPersons == this.numberOfPersons &&
          other.hasPv == this.hasPv &&
          other.hasSolarThermal == this.hasSolarThermal &&
          other.trackingMode == this.trackingMode &&
          other.constructionYear == this.constructionYear &&
          other.isInsulated == this.isInsulated);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<int> id;
  final Value<String?> locationPlz;
  final Value<String?> locationCity;
  final Value<double?> locationLat;
  final Value<double?> locationLon;
  final Value<int?> meterIntDigits;
  final Value<int?> electricityIntDigits;
  final Value<int?> electricityDecDigits;
  final Value<String?> houseType;
  final Value<int?> squareMeters;
  final Value<int?> numberOfPersons;
  final Value<bool?> hasPv;
  final Value<bool?> hasSolarThermal;
  final Value<String?> trackingMode;
  final Value<int?> constructionYear;
  final Value<bool?> isInsulated;
  const AppSettingsCompanion({
    this.id = const Value.absent(),
    this.locationPlz = const Value.absent(),
    this.locationCity = const Value.absent(),
    this.locationLat = const Value.absent(),
    this.locationLon = const Value.absent(),
    this.meterIntDigits = const Value.absent(),
    this.electricityIntDigits = const Value.absent(),
    this.electricityDecDigits = const Value.absent(),
    this.houseType = const Value.absent(),
    this.squareMeters = const Value.absent(),
    this.numberOfPersons = const Value.absent(),
    this.hasPv = const Value.absent(),
    this.hasSolarThermal = const Value.absent(),
    this.trackingMode = const Value.absent(),
    this.constructionYear = const Value.absent(),
    this.isInsulated = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    this.id = const Value.absent(),
    this.locationPlz = const Value.absent(),
    this.locationCity = const Value.absent(),
    this.locationLat = const Value.absent(),
    this.locationLon = const Value.absent(),
    this.meterIntDigits = const Value.absent(),
    this.electricityIntDigits = const Value.absent(),
    this.electricityDecDigits = const Value.absent(),
    this.houseType = const Value.absent(),
    this.squareMeters = const Value.absent(),
    this.numberOfPersons = const Value.absent(),
    this.hasPv = const Value.absent(),
    this.hasSolarThermal = const Value.absent(),
    this.trackingMode = const Value.absent(),
    this.constructionYear = const Value.absent(),
    this.isInsulated = const Value.absent(),
  });
  static Insertable<AppSetting> custom({
    Expression<int>? id,
    Expression<String>? locationPlz,
    Expression<String>? locationCity,
    Expression<double>? locationLat,
    Expression<double>? locationLon,
    Expression<int>? meterIntDigits,
    Expression<int>? electricityIntDigits,
    Expression<int>? electricityDecDigits,
    Expression<String>? houseType,
    Expression<int>? squareMeters,
    Expression<int>? numberOfPersons,
    Expression<bool>? hasPv,
    Expression<bool>? hasSolarThermal,
    Expression<String>? trackingMode,
    Expression<int>? constructionYear,
    Expression<bool>? isInsulated,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (locationPlz != null) 'location_plz': locationPlz,
      if (locationCity != null) 'location_city': locationCity,
      if (locationLat != null) 'location_lat': locationLat,
      if (locationLon != null) 'location_lon': locationLon,
      if (meterIntDigits != null) 'meter_int_digits': meterIntDigits,
      if (electricityIntDigits != null)
        'electricity_int_digits': electricityIntDigits,
      if (electricityDecDigits != null)
        'electricity_dec_digits': electricityDecDigits,
      if (houseType != null) 'house_type': houseType,
      if (squareMeters != null) 'square_meters': squareMeters,
      if (numberOfPersons != null) 'number_of_persons': numberOfPersons,
      if (hasPv != null) 'has_pv': hasPv,
      if (hasSolarThermal != null) 'has_solar_thermal': hasSolarThermal,
      if (trackingMode != null) 'tracking_mode': trackingMode,
      if (constructionYear != null) 'construction_year': constructionYear,
      if (isInsulated != null) 'is_insulated': isInsulated,
    });
  }

  AppSettingsCompanion copyWith({
    Value<int>? id,
    Value<String?>? locationPlz,
    Value<String?>? locationCity,
    Value<double?>? locationLat,
    Value<double?>? locationLon,
    Value<int?>? meterIntDigits,
    Value<int?>? electricityIntDigits,
    Value<int?>? electricityDecDigits,
    Value<String?>? houseType,
    Value<int?>? squareMeters,
    Value<int?>? numberOfPersons,
    Value<bool?>? hasPv,
    Value<bool?>? hasSolarThermal,
    Value<String?>? trackingMode,
    Value<int?>? constructionYear,
    Value<bool?>? isInsulated,
  }) {
    return AppSettingsCompanion(
      id: id ?? this.id,
      locationPlz: locationPlz ?? this.locationPlz,
      locationCity: locationCity ?? this.locationCity,
      locationLat: locationLat ?? this.locationLat,
      locationLon: locationLon ?? this.locationLon,
      meterIntDigits: meterIntDigits ?? this.meterIntDigits,
      electricityIntDigits: electricityIntDigits ?? this.electricityIntDigits,
      electricityDecDigits: electricityDecDigits ?? this.electricityDecDigits,
      houseType: houseType ?? this.houseType,
      squareMeters: squareMeters ?? this.squareMeters,
      numberOfPersons: numberOfPersons ?? this.numberOfPersons,
      hasPv: hasPv ?? this.hasPv,
      hasSolarThermal: hasSolarThermal ?? this.hasSolarThermal,
      trackingMode: trackingMode ?? this.trackingMode,
      constructionYear: constructionYear ?? this.constructionYear,
      isInsulated: isInsulated ?? this.isInsulated,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (locationPlz.present) {
      map['location_plz'] = Variable<String>(locationPlz.value);
    }
    if (locationCity.present) {
      map['location_city'] = Variable<String>(locationCity.value);
    }
    if (locationLat.present) {
      map['location_lat'] = Variable<double>(locationLat.value);
    }
    if (locationLon.present) {
      map['location_lon'] = Variable<double>(locationLon.value);
    }
    if (meterIntDigits.present) {
      map['meter_int_digits'] = Variable<int>(meterIntDigits.value);
    }
    if (electricityIntDigits.present) {
      map['electricity_int_digits'] = Variable<int>(electricityIntDigits.value);
    }
    if (electricityDecDigits.present) {
      map['electricity_dec_digits'] = Variable<int>(electricityDecDigits.value);
    }
    if (houseType.present) {
      map['house_type'] = Variable<String>(houseType.value);
    }
    if (squareMeters.present) {
      map['square_meters'] = Variable<int>(squareMeters.value);
    }
    if (numberOfPersons.present) {
      map['number_of_persons'] = Variable<int>(numberOfPersons.value);
    }
    if (hasPv.present) {
      map['has_pv'] = Variable<bool>(hasPv.value);
    }
    if (hasSolarThermal.present) {
      map['has_solar_thermal'] = Variable<bool>(hasSolarThermal.value);
    }
    if (trackingMode.present) {
      map['tracking_mode'] = Variable<String>(trackingMode.value);
    }
    if (constructionYear.present) {
      map['construction_year'] = Variable<int>(constructionYear.value);
    }
    if (isInsulated.present) {
      map['is_insulated'] = Variable<bool>(isInsulated.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('id: $id, ')
          ..write('locationPlz: $locationPlz, ')
          ..write('locationCity: $locationCity, ')
          ..write('locationLat: $locationLat, ')
          ..write('locationLon: $locationLon, ')
          ..write('meterIntDigits: $meterIntDigits, ')
          ..write('electricityIntDigits: $electricityIntDigits, ')
          ..write('electricityDecDigits: $electricityDecDigits, ')
          ..write('houseType: $houseType, ')
          ..write('squareMeters: $squareMeters, ')
          ..write('numberOfPersons: $numberOfPersons, ')
          ..write('hasPv: $hasPv, ')
          ..write('hasSolarThermal: $hasSolarThermal, ')
          ..write('trackingMode: $trackingMode, ')
          ..write('constructionYear: $constructionYear, ')
          ..write('isInsulated: $isInsulated')
          ..write(')'))
        .toString();
  }
}

class $WeatherCachesTable extends WeatherCaches
    with TableInfo<$WeatherCachesTable, WeatherCache> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WeatherCachesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _latMeta = const VerificationMeta('lat');
  @override
  late final GeneratedColumn<double> lat = GeneratedColumn<double>(
    'lat',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lonMeta = const VerificationMeta('lon');
  @override
  late final GeneratedColumn<double> lon = GeneratedColumn<double>(
    'lon',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tempMeanMeta = const VerificationMeta(
    'tempMean',
  );
  @override
  late final GeneratedColumn<double> tempMean = GeneratedColumn<double>(
    'temp_mean',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, date, lat, lon, tempMean];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'weather_caches';
  @override
  VerificationContext validateIntegrity(
    Insertable<WeatherCache> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('lat')) {
      context.handle(
        _latMeta,
        lat.isAcceptableOrUnknown(data['lat']!, _latMeta),
      );
    } else if (isInserting) {
      context.missing(_latMeta);
    }
    if (data.containsKey('lon')) {
      context.handle(
        _lonMeta,
        lon.isAcceptableOrUnknown(data['lon']!, _lonMeta),
      );
    } else if (isInserting) {
      context.missing(_lonMeta);
    }
    if (data.containsKey('temp_mean')) {
      context.handle(
        _tempMeanMeta,
        tempMean.isAcceptableOrUnknown(data['temp_mean']!, _tempMeanMeta),
      );
    } else if (isInserting) {
      context.missing(_tempMeanMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WeatherCache map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WeatherCache(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      lat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lat'],
      )!,
      lon: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lon'],
      )!,
      tempMean: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}temp_mean'],
      )!,
    );
  }

  @override
  $WeatherCachesTable createAlias(String alias) {
    return $WeatherCachesTable(attachedDatabase, alias);
  }
}

class WeatherCache extends DataClass implements Insertable<WeatherCache> {
  final int id;
  final String date;
  final double lat;
  final double lon;
  final double tempMean;
  const WeatherCache({
    required this.id,
    required this.date,
    required this.lat,
    required this.lon,
    required this.tempMean,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['date'] = Variable<String>(date);
    map['lat'] = Variable<double>(lat);
    map['lon'] = Variable<double>(lon);
    map['temp_mean'] = Variable<double>(tempMean);
    return map;
  }

  WeatherCachesCompanion toCompanion(bool nullToAbsent) {
    return WeatherCachesCompanion(
      id: Value(id),
      date: Value(date),
      lat: Value(lat),
      lon: Value(lon),
      tempMean: Value(tempMean),
    );
  }

  factory WeatherCache.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WeatherCache(
      id: serializer.fromJson<int>(json['id']),
      date: serializer.fromJson<String>(json['date']),
      lat: serializer.fromJson<double>(json['lat']),
      lon: serializer.fromJson<double>(json['lon']),
      tempMean: serializer.fromJson<double>(json['tempMean']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'date': serializer.toJson<String>(date),
      'lat': serializer.toJson<double>(lat),
      'lon': serializer.toJson<double>(lon),
      'tempMean': serializer.toJson<double>(tempMean),
    };
  }

  WeatherCache copyWith({
    int? id,
    String? date,
    double? lat,
    double? lon,
    double? tempMean,
  }) => WeatherCache(
    id: id ?? this.id,
    date: date ?? this.date,
    lat: lat ?? this.lat,
    lon: lon ?? this.lon,
    tempMean: tempMean ?? this.tempMean,
  );
  WeatherCache copyWithCompanion(WeatherCachesCompanion data) {
    return WeatherCache(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      lat: data.lat.present ? data.lat.value : this.lat,
      lon: data.lon.present ? data.lon.value : this.lon,
      tempMean: data.tempMean.present ? data.tempMean.value : this.tempMean,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WeatherCache(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('lat: $lat, ')
          ..write('lon: $lon, ')
          ..write('tempMean: $tempMean')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, date, lat, lon, tempMean);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WeatherCache &&
          other.id == this.id &&
          other.date == this.date &&
          other.lat == this.lat &&
          other.lon == this.lon &&
          other.tempMean == this.tempMean);
}

class WeatherCachesCompanion extends UpdateCompanion<WeatherCache> {
  final Value<int> id;
  final Value<String> date;
  final Value<double> lat;
  final Value<double> lon;
  final Value<double> tempMean;
  const WeatherCachesCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.lat = const Value.absent(),
    this.lon = const Value.absent(),
    this.tempMean = const Value.absent(),
  });
  WeatherCachesCompanion.insert({
    this.id = const Value.absent(),
    required String date,
    required double lat,
    required double lon,
    required double tempMean,
  }) : date = Value(date),
       lat = Value(lat),
       lon = Value(lon),
       tempMean = Value(tempMean);
  static Insertable<WeatherCache> custom({
    Expression<int>? id,
    Expression<String>? date,
    Expression<double>? lat,
    Expression<double>? lon,
    Expression<double>? tempMean,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (lat != null) 'lat': lat,
      if (lon != null) 'lon': lon,
      if (tempMean != null) 'temp_mean': tempMean,
    });
  }

  WeatherCachesCompanion copyWith({
    Value<int>? id,
    Value<String>? date,
    Value<double>? lat,
    Value<double>? lon,
    Value<double>? tempMean,
  }) {
    return WeatherCachesCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      tempMean: tempMean ?? this.tempMean,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (lat.present) {
      map['lat'] = Variable<double>(lat.value);
    }
    if (lon.present) {
      map['lon'] = Variable<double>(lon.value);
    }
    if (tempMean.present) {
      map['temp_mean'] = Variable<double>(tempMean.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WeatherCachesCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('lat: $lat, ')
          ..write('lon: $lon, ')
          ..write('tempMean: $tempMean')
          ..write(')'))
        .toString();
  }
}

class $AdvancePaymentChangesTable extends AdvancePaymentChanges
    with TableInfo<$AdvancePaymentChangesTable, AdvancePaymentChange> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AdvancePaymentChangesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _contractTypeMeta = const VerificationMeta(
    'contractType',
  );
  @override
  late final GeneratedColumn<String> contractType = GeneratedColumn<String>(
    'contract_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _validFromMeta = const VerificationMeta(
    'validFrom',
  );
  @override
  late final GeneratedColumn<int> validFrom = GeneratedColumn<int>(
    'valid_from',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isSyncedMeta = const VerificationMeta(
    'isSynced',
  );
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
    'is_synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _remoteIdMeta = const VerificationMeta(
    'remoteId',
  );
  @override
  late final GeneratedColumn<String> remoteId = GeneratedColumn<String>(
    'remote_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    contractType,
    amount,
    validFrom,
    isSynced,
    remoteId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'advance_payment_changes';
  @override
  VerificationContext validateIntegrity(
    Insertable<AdvancePaymentChange> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('contract_type')) {
      context.handle(
        _contractTypeMeta,
        contractType.isAcceptableOrUnknown(
          data['contract_type']!,
          _contractTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_contractTypeMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('valid_from')) {
      context.handle(
        _validFromMeta,
        validFrom.isAcceptableOrUnknown(data['valid_from']!, _validFromMeta),
      );
    } else if (isInserting) {
      context.missing(_validFromMeta);
    }
    if (data.containsKey('is_synced')) {
      context.handle(
        _isSyncedMeta,
        isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta),
      );
    }
    if (data.containsKey('remote_id')) {
      context.handle(
        _remoteIdMeta,
        remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AdvancePaymentChange map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AdvancePaymentChange(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      contractType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}contract_type'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
      validFrom: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}valid_from'],
      )!,
      isSynced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_synced'],
      )!,
      remoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_id'],
      ),
    );
  }

  @override
  $AdvancePaymentChangesTable createAlias(String alias) {
    return $AdvancePaymentChangesTable(attachedDatabase, alias);
  }
}

class AdvancePaymentChange extends DataClass
    implements Insertable<AdvancePaymentChange> {
  final int id;
  final String contractType;
  final double amount;
  final int validFrom;
  final bool isSynced;
  final String? remoteId;
  const AdvancePaymentChange({
    required this.id,
    required this.contractType,
    required this.amount,
    required this.validFrom,
    required this.isSynced,
    this.remoteId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['contract_type'] = Variable<String>(contractType);
    map['amount'] = Variable<double>(amount);
    map['valid_from'] = Variable<int>(validFrom);
    map['is_synced'] = Variable<bool>(isSynced);
    if (!nullToAbsent || remoteId != null) {
      map['remote_id'] = Variable<String>(remoteId);
    }
    return map;
  }

  AdvancePaymentChangesCompanion toCompanion(bool nullToAbsent) {
    return AdvancePaymentChangesCompanion(
      id: Value(id),
      contractType: Value(contractType),
      amount: Value(amount),
      validFrom: Value(validFrom),
      isSynced: Value(isSynced),
      remoteId: remoteId == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteId),
    );
  }

  factory AdvancePaymentChange.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AdvancePaymentChange(
      id: serializer.fromJson<int>(json['id']),
      contractType: serializer.fromJson<String>(json['contractType']),
      amount: serializer.fromJson<double>(json['amount']),
      validFrom: serializer.fromJson<int>(json['validFrom']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      remoteId: serializer.fromJson<String?>(json['remoteId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'contractType': serializer.toJson<String>(contractType),
      'amount': serializer.toJson<double>(amount),
      'validFrom': serializer.toJson<int>(validFrom),
      'isSynced': serializer.toJson<bool>(isSynced),
      'remoteId': serializer.toJson<String?>(remoteId),
    };
  }

  AdvancePaymentChange copyWith({
    int? id,
    String? contractType,
    double? amount,
    int? validFrom,
    bool? isSynced,
    Value<String?> remoteId = const Value.absent(),
  }) => AdvancePaymentChange(
    id: id ?? this.id,
    contractType: contractType ?? this.contractType,
    amount: amount ?? this.amount,
    validFrom: validFrom ?? this.validFrom,
    isSynced: isSynced ?? this.isSynced,
    remoteId: remoteId.present ? remoteId.value : this.remoteId,
  );
  AdvancePaymentChange copyWithCompanion(AdvancePaymentChangesCompanion data) {
    return AdvancePaymentChange(
      id: data.id.present ? data.id.value : this.id,
      contractType: data.contractType.present
          ? data.contractType.value
          : this.contractType,
      amount: data.amount.present ? data.amount.value : this.amount,
      validFrom: data.validFrom.present ? data.validFrom.value : this.validFrom,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AdvancePaymentChange(')
          ..write('id: $id, ')
          ..write('contractType: $contractType, ')
          ..write('amount: $amount, ')
          ..write('validFrom: $validFrom, ')
          ..write('isSynced: $isSynced, ')
          ..write('remoteId: $remoteId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, contractType, amount, validFrom, isSynced, remoteId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AdvancePaymentChange &&
          other.id == this.id &&
          other.contractType == this.contractType &&
          other.amount == this.amount &&
          other.validFrom == this.validFrom &&
          other.isSynced == this.isSynced &&
          other.remoteId == this.remoteId);
}

class AdvancePaymentChangesCompanion
    extends UpdateCompanion<AdvancePaymentChange> {
  final Value<int> id;
  final Value<String> contractType;
  final Value<double> amount;
  final Value<int> validFrom;
  final Value<bool> isSynced;
  final Value<String?> remoteId;
  const AdvancePaymentChangesCompanion({
    this.id = const Value.absent(),
    this.contractType = const Value.absent(),
    this.amount = const Value.absent(),
    this.validFrom = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.remoteId = const Value.absent(),
  });
  AdvancePaymentChangesCompanion.insert({
    this.id = const Value.absent(),
    required String contractType,
    required double amount,
    required int validFrom,
    this.isSynced = const Value.absent(),
    this.remoteId = const Value.absent(),
  }) : contractType = Value(contractType),
       amount = Value(amount),
       validFrom = Value(validFrom);
  static Insertable<AdvancePaymentChange> custom({
    Expression<int>? id,
    Expression<String>? contractType,
    Expression<double>? amount,
    Expression<int>? validFrom,
    Expression<bool>? isSynced,
    Expression<String>? remoteId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (contractType != null) 'contract_type': contractType,
      if (amount != null) 'amount': amount,
      if (validFrom != null) 'valid_from': validFrom,
      if (isSynced != null) 'is_synced': isSynced,
      if (remoteId != null) 'remote_id': remoteId,
    });
  }

  AdvancePaymentChangesCompanion copyWith({
    Value<int>? id,
    Value<String>? contractType,
    Value<double>? amount,
    Value<int>? validFrom,
    Value<bool>? isSynced,
    Value<String?>? remoteId,
  }) {
    return AdvancePaymentChangesCompanion(
      id: id ?? this.id,
      contractType: contractType ?? this.contractType,
      amount: amount ?? this.amount,
      validFrom: validFrom ?? this.validFrom,
      isSynced: isSynced ?? this.isSynced,
      remoteId: remoteId ?? this.remoteId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (contractType.present) {
      map['contract_type'] = Variable<String>(contractType.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (validFrom.present) {
      map['valid_from'] = Variable<int>(validFrom.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<String>(remoteId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AdvancePaymentChangesCompanion(')
          ..write('id: $id, ')
          ..write('contractType: $contractType, ')
          ..write('amount: $amount, ')
          ..write('validFrom: $validFrom, ')
          ..write('isSynced: $isSynced, ')
          ..write('remoteId: $remoteId')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $MeterReadingsTable meterReadings = $MeterReadingsTable(this);
  late final $ElectricityReadingsTable electricityReadings =
      $ElectricityReadingsTable(this);
  late final $PriceContractsTable priceContracts = $PriceContractsTable(this);
  late final $ElectricityContractsTable electricityContracts =
      $ElectricityContractsTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final $WeatherCachesTable weatherCaches = $WeatherCachesTable(this);
  late final $AdvancePaymentChangesTable advancePaymentChanges =
      $AdvancePaymentChangesTable(this);
  late final ReadingsDao readingsDao = ReadingsDao(this as AppDatabase);
  late final ElectricityReadingsDao electricityReadingsDao =
      ElectricityReadingsDao(this as AppDatabase);
  late final ContractsDao contractsDao = ContractsDao(this as AppDatabase);
  late final ElectricityContractsDao electricityContractsDao =
      ElectricityContractsDao(this as AppDatabase);
  late final SettingsDao settingsDao = SettingsDao(this as AppDatabase);
  late final WeatherDao weatherDao = WeatherDao(this as AppDatabase);
  late final AdvancePaymentChangesDao advancePaymentChangesDao =
      AdvancePaymentChangesDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    meterReadings,
    electricityReadings,
    priceContracts,
    electricityContracts,
    appSettings,
    weatherCaches,
    advancePaymentChanges,
  ];
}

typedef $$MeterReadingsTableCreateCompanionBuilder =
    MeterReadingsCompanion Function({
      Value<int> id,
      required double value,
      required DateTime timestamp,
      Value<String?> note,
      Value<String?> imagePath,
      Value<bool> isSynced,
      Value<String?> remoteId,
    });
typedef $$MeterReadingsTableUpdateCompanionBuilder =
    MeterReadingsCompanion Function({
      Value<int> id,
      Value<double> value,
      Value<DateTime> timestamp,
      Value<String?> note,
      Value<String?> imagePath,
      Value<bool> isSynced,
      Value<String?> remoteId,
    });

class $$MeterReadingsTableFilterComposer
    extends Composer<_$AppDatabase, $MeterReadingsTable> {
  $$MeterReadingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MeterReadingsTableOrderingComposer
    extends Composer<_$AppDatabase, $MeterReadingsTable> {
  $$MeterReadingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MeterReadingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MeterReadingsTable> {
  $$MeterReadingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get imagePath =>
      $composableBuilder(column: $table.imagePath, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumn<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);
}

class $$MeterReadingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MeterReadingsTable,
          MeterReading,
          $$MeterReadingsTableFilterComposer,
          $$MeterReadingsTableOrderingComposer,
          $$MeterReadingsTableAnnotationComposer,
          $$MeterReadingsTableCreateCompanionBuilder,
          $$MeterReadingsTableUpdateCompanionBuilder,
          (
            MeterReading,
            BaseReferences<_$AppDatabase, $MeterReadingsTable, MeterReading>,
          ),
          MeterReading,
          PrefetchHooks Function()
        > {
  $$MeterReadingsTableTableManager(_$AppDatabase db, $MeterReadingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MeterReadingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MeterReadingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MeterReadingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<double> value = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String?> imagePath = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
              }) => MeterReadingsCompanion(
                id: id,
                value: value,
                timestamp: timestamp,
                note: note,
                imagePath: imagePath,
                isSynced: isSynced,
                remoteId: remoteId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required double value,
                required DateTime timestamp,
                Value<String?> note = const Value.absent(),
                Value<String?> imagePath = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
              }) => MeterReadingsCompanion.insert(
                id: id,
                value: value,
                timestamp: timestamp,
                note: note,
                imagePath: imagePath,
                isSynced: isSynced,
                remoteId: remoteId,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MeterReadingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MeterReadingsTable,
      MeterReading,
      $$MeterReadingsTableFilterComposer,
      $$MeterReadingsTableOrderingComposer,
      $$MeterReadingsTableAnnotationComposer,
      $$MeterReadingsTableCreateCompanionBuilder,
      $$MeterReadingsTableUpdateCompanionBuilder,
      (
        MeterReading,
        BaseReferences<_$AppDatabase, $MeterReadingsTable, MeterReading>,
      ),
      MeterReading,
      PrefetchHooks Function()
    >;
typedef $$ElectricityReadingsTableCreateCompanionBuilder =
    ElectricityReadingsCompanion Function({
      Value<int> id,
      required double value,
      required DateTime timestamp,
      Value<String?> note,
      Value<String?> imagePath,
      Value<bool> isSynced,
      Value<String?> remoteId,
    });
typedef $$ElectricityReadingsTableUpdateCompanionBuilder =
    ElectricityReadingsCompanion Function({
      Value<int> id,
      Value<double> value,
      Value<DateTime> timestamp,
      Value<String?> note,
      Value<String?> imagePath,
      Value<bool> isSynced,
      Value<String?> remoteId,
    });

class $$ElectricityReadingsTableFilterComposer
    extends Composer<_$AppDatabase, $ElectricityReadingsTable> {
  $$ElectricityReadingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ElectricityReadingsTableOrderingComposer
    extends Composer<_$AppDatabase, $ElectricityReadingsTable> {
  $$ElectricityReadingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ElectricityReadingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ElectricityReadingsTable> {
  $$ElectricityReadingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get imagePath =>
      $composableBuilder(column: $table.imagePath, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumn<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);
}

class $$ElectricityReadingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ElectricityReadingsTable,
          ElectricityReading,
          $$ElectricityReadingsTableFilterComposer,
          $$ElectricityReadingsTableOrderingComposer,
          $$ElectricityReadingsTableAnnotationComposer,
          $$ElectricityReadingsTableCreateCompanionBuilder,
          $$ElectricityReadingsTableUpdateCompanionBuilder,
          (
            ElectricityReading,
            BaseReferences<
              _$AppDatabase,
              $ElectricityReadingsTable,
              ElectricityReading
            >,
          ),
          ElectricityReading,
          PrefetchHooks Function()
        > {
  $$ElectricityReadingsTableTableManager(
    _$AppDatabase db,
    $ElectricityReadingsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ElectricityReadingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ElectricityReadingsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ElectricityReadingsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<double> value = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String?> imagePath = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
              }) => ElectricityReadingsCompanion(
                id: id,
                value: value,
                timestamp: timestamp,
                note: note,
                imagePath: imagePath,
                isSynced: isSynced,
                remoteId: remoteId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required double value,
                required DateTime timestamp,
                Value<String?> note = const Value.absent(),
                Value<String?> imagePath = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
              }) => ElectricityReadingsCompanion.insert(
                id: id,
                value: value,
                timestamp: timestamp,
                note: note,
                imagePath: imagePath,
                isSynced: isSynced,
                remoteId: remoteId,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ElectricityReadingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ElectricityReadingsTable,
      ElectricityReading,
      $$ElectricityReadingsTableFilterComposer,
      $$ElectricityReadingsTableOrderingComposer,
      $$ElectricityReadingsTableAnnotationComposer,
      $$ElectricityReadingsTableCreateCompanionBuilder,
      $$ElectricityReadingsTableUpdateCompanionBuilder,
      (
        ElectricityReading,
        BaseReferences<
          _$AppDatabase,
          $ElectricityReadingsTable,
          ElectricityReading
        >,
      ),
      ElectricityReading,
      PrefetchHooks Function()
    >;
typedef $$PriceContractsTableCreateCompanionBuilder =
    PriceContractsCompanion Function({
      Value<int> id,
      required String internalName,
      required String displayName,
      required double pricePerKwh,
      required double monthlyBasePrice,
      required int validFrom,
      Value<int?> contractEndDate,
      Value<double?> monthlyAdvancePayment,
      Value<double> brennwert,
      Value<double> zustandszahl,
      Value<bool> isSynced,
      Value<String?> remoteId,
    });
typedef $$PriceContractsTableUpdateCompanionBuilder =
    PriceContractsCompanion Function({
      Value<int> id,
      Value<String> internalName,
      Value<String> displayName,
      Value<double> pricePerKwh,
      Value<double> monthlyBasePrice,
      Value<int> validFrom,
      Value<int?> contractEndDate,
      Value<double?> monthlyAdvancePayment,
      Value<double> brennwert,
      Value<double> zustandszahl,
      Value<bool> isSynced,
      Value<String?> remoteId,
    });

class $$PriceContractsTableFilterComposer
    extends Composer<_$AppDatabase, $PriceContractsTable> {
  $$PriceContractsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get internalName => $composableBuilder(
    column: $table.internalName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get pricePerKwh => $composableBuilder(
    column: $table.pricePerKwh,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get monthlyBasePrice => $composableBuilder(
    column: $table.monthlyBasePrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get validFrom => $composableBuilder(
    column: $table.validFrom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get contractEndDate => $composableBuilder(
    column: $table.contractEndDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get monthlyAdvancePayment => $composableBuilder(
    column: $table.monthlyAdvancePayment,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get brennwert => $composableBuilder(
    column: $table.brennwert,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get zustandszahl => $composableBuilder(
    column: $table.zustandszahl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PriceContractsTableOrderingComposer
    extends Composer<_$AppDatabase, $PriceContractsTable> {
  $$PriceContractsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get internalName => $composableBuilder(
    column: $table.internalName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get pricePerKwh => $composableBuilder(
    column: $table.pricePerKwh,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get monthlyBasePrice => $composableBuilder(
    column: $table.monthlyBasePrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get validFrom => $composableBuilder(
    column: $table.validFrom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get contractEndDate => $composableBuilder(
    column: $table.contractEndDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get monthlyAdvancePayment => $composableBuilder(
    column: $table.monthlyAdvancePayment,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get brennwert => $composableBuilder(
    column: $table.brennwert,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get zustandszahl => $composableBuilder(
    column: $table.zustandszahl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PriceContractsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PriceContractsTable> {
  $$PriceContractsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get internalName => $composableBuilder(
    column: $table.internalName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<double> get pricePerKwh => $composableBuilder(
    column: $table.pricePerKwh,
    builder: (column) => column,
  );

  GeneratedColumn<double> get monthlyBasePrice => $composableBuilder(
    column: $table.monthlyBasePrice,
    builder: (column) => column,
  );

  GeneratedColumn<int> get validFrom =>
      $composableBuilder(column: $table.validFrom, builder: (column) => column);

  GeneratedColumn<int> get contractEndDate => $composableBuilder(
    column: $table.contractEndDate,
    builder: (column) => column,
  );

  GeneratedColumn<double> get monthlyAdvancePayment => $composableBuilder(
    column: $table.monthlyAdvancePayment,
    builder: (column) => column,
  );

  GeneratedColumn<double> get brennwert =>
      $composableBuilder(column: $table.brennwert, builder: (column) => column);

  GeneratedColumn<double> get zustandszahl => $composableBuilder(
    column: $table.zustandszahl,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumn<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);
}

class $$PriceContractsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PriceContractsTable,
          PriceContract,
          $$PriceContractsTableFilterComposer,
          $$PriceContractsTableOrderingComposer,
          $$PriceContractsTableAnnotationComposer,
          $$PriceContractsTableCreateCompanionBuilder,
          $$PriceContractsTableUpdateCompanionBuilder,
          (
            PriceContract,
            BaseReferences<_$AppDatabase, $PriceContractsTable, PriceContract>,
          ),
          PriceContract,
          PrefetchHooks Function()
        > {
  $$PriceContractsTableTableManager(
    _$AppDatabase db,
    $PriceContractsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PriceContractsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PriceContractsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PriceContractsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> internalName = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<double> pricePerKwh = const Value.absent(),
                Value<double> monthlyBasePrice = const Value.absent(),
                Value<int> validFrom = const Value.absent(),
                Value<int?> contractEndDate = const Value.absent(),
                Value<double?> monthlyAdvancePayment = const Value.absent(),
                Value<double> brennwert = const Value.absent(),
                Value<double> zustandszahl = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
              }) => PriceContractsCompanion(
                id: id,
                internalName: internalName,
                displayName: displayName,
                pricePerKwh: pricePerKwh,
                monthlyBasePrice: monthlyBasePrice,
                validFrom: validFrom,
                contractEndDate: contractEndDate,
                monthlyAdvancePayment: monthlyAdvancePayment,
                brennwert: brennwert,
                zustandszahl: zustandszahl,
                isSynced: isSynced,
                remoteId: remoteId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String internalName,
                required String displayName,
                required double pricePerKwh,
                required double monthlyBasePrice,
                required int validFrom,
                Value<int?> contractEndDate = const Value.absent(),
                Value<double?> monthlyAdvancePayment = const Value.absent(),
                Value<double> brennwert = const Value.absent(),
                Value<double> zustandszahl = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
              }) => PriceContractsCompanion.insert(
                id: id,
                internalName: internalName,
                displayName: displayName,
                pricePerKwh: pricePerKwh,
                monthlyBasePrice: monthlyBasePrice,
                validFrom: validFrom,
                contractEndDate: contractEndDate,
                monthlyAdvancePayment: monthlyAdvancePayment,
                brennwert: brennwert,
                zustandszahl: zustandszahl,
                isSynced: isSynced,
                remoteId: remoteId,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PriceContractsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PriceContractsTable,
      PriceContract,
      $$PriceContractsTableFilterComposer,
      $$PriceContractsTableOrderingComposer,
      $$PriceContractsTableAnnotationComposer,
      $$PriceContractsTableCreateCompanionBuilder,
      $$PriceContractsTableUpdateCompanionBuilder,
      (
        PriceContract,
        BaseReferences<_$AppDatabase, $PriceContractsTable, PriceContract>,
      ),
      PriceContract,
      PrefetchHooks Function()
    >;
typedef $$ElectricityContractsTableCreateCompanionBuilder =
    ElectricityContractsCompanion Function({
      Value<int> id,
      required String internalName,
      required String displayName,
      required double pricePerKwh,
      required double monthlyBasePrice,
      required int validFrom,
      Value<int?> contractEndDate,
      Value<double?> monthlyAdvancePayment,
      Value<bool> isSynced,
      Value<String?> remoteId,
    });
typedef $$ElectricityContractsTableUpdateCompanionBuilder =
    ElectricityContractsCompanion Function({
      Value<int> id,
      Value<String> internalName,
      Value<String> displayName,
      Value<double> pricePerKwh,
      Value<double> monthlyBasePrice,
      Value<int> validFrom,
      Value<int?> contractEndDate,
      Value<double?> monthlyAdvancePayment,
      Value<bool> isSynced,
      Value<String?> remoteId,
    });

class $$ElectricityContractsTableFilterComposer
    extends Composer<_$AppDatabase, $ElectricityContractsTable> {
  $$ElectricityContractsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get internalName => $composableBuilder(
    column: $table.internalName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get pricePerKwh => $composableBuilder(
    column: $table.pricePerKwh,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get monthlyBasePrice => $composableBuilder(
    column: $table.monthlyBasePrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get validFrom => $composableBuilder(
    column: $table.validFrom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get contractEndDate => $composableBuilder(
    column: $table.contractEndDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get monthlyAdvancePayment => $composableBuilder(
    column: $table.monthlyAdvancePayment,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ElectricityContractsTableOrderingComposer
    extends Composer<_$AppDatabase, $ElectricityContractsTable> {
  $$ElectricityContractsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get internalName => $composableBuilder(
    column: $table.internalName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get pricePerKwh => $composableBuilder(
    column: $table.pricePerKwh,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get monthlyBasePrice => $composableBuilder(
    column: $table.monthlyBasePrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get validFrom => $composableBuilder(
    column: $table.validFrom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get contractEndDate => $composableBuilder(
    column: $table.contractEndDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get monthlyAdvancePayment => $composableBuilder(
    column: $table.monthlyAdvancePayment,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ElectricityContractsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ElectricityContractsTable> {
  $$ElectricityContractsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get internalName => $composableBuilder(
    column: $table.internalName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<double> get pricePerKwh => $composableBuilder(
    column: $table.pricePerKwh,
    builder: (column) => column,
  );

  GeneratedColumn<double> get monthlyBasePrice => $composableBuilder(
    column: $table.monthlyBasePrice,
    builder: (column) => column,
  );

  GeneratedColumn<int> get validFrom =>
      $composableBuilder(column: $table.validFrom, builder: (column) => column);

  GeneratedColumn<int> get contractEndDate => $composableBuilder(
    column: $table.contractEndDate,
    builder: (column) => column,
  );

  GeneratedColumn<double> get monthlyAdvancePayment => $composableBuilder(
    column: $table.monthlyAdvancePayment,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumn<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);
}

class $$ElectricityContractsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ElectricityContractsTable,
          ElectricityContract,
          $$ElectricityContractsTableFilterComposer,
          $$ElectricityContractsTableOrderingComposer,
          $$ElectricityContractsTableAnnotationComposer,
          $$ElectricityContractsTableCreateCompanionBuilder,
          $$ElectricityContractsTableUpdateCompanionBuilder,
          (
            ElectricityContract,
            BaseReferences<
              _$AppDatabase,
              $ElectricityContractsTable,
              ElectricityContract
            >,
          ),
          ElectricityContract,
          PrefetchHooks Function()
        > {
  $$ElectricityContractsTableTableManager(
    _$AppDatabase db,
    $ElectricityContractsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ElectricityContractsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ElectricityContractsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ElectricityContractsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> internalName = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<double> pricePerKwh = const Value.absent(),
                Value<double> monthlyBasePrice = const Value.absent(),
                Value<int> validFrom = const Value.absent(),
                Value<int?> contractEndDate = const Value.absent(),
                Value<double?> monthlyAdvancePayment = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
              }) => ElectricityContractsCompanion(
                id: id,
                internalName: internalName,
                displayName: displayName,
                pricePerKwh: pricePerKwh,
                monthlyBasePrice: monthlyBasePrice,
                validFrom: validFrom,
                contractEndDate: contractEndDate,
                monthlyAdvancePayment: monthlyAdvancePayment,
                isSynced: isSynced,
                remoteId: remoteId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String internalName,
                required String displayName,
                required double pricePerKwh,
                required double monthlyBasePrice,
                required int validFrom,
                Value<int?> contractEndDate = const Value.absent(),
                Value<double?> monthlyAdvancePayment = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
              }) => ElectricityContractsCompanion.insert(
                id: id,
                internalName: internalName,
                displayName: displayName,
                pricePerKwh: pricePerKwh,
                monthlyBasePrice: monthlyBasePrice,
                validFrom: validFrom,
                contractEndDate: contractEndDate,
                monthlyAdvancePayment: monthlyAdvancePayment,
                isSynced: isSynced,
                remoteId: remoteId,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ElectricityContractsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ElectricityContractsTable,
      ElectricityContract,
      $$ElectricityContractsTableFilterComposer,
      $$ElectricityContractsTableOrderingComposer,
      $$ElectricityContractsTableAnnotationComposer,
      $$ElectricityContractsTableCreateCompanionBuilder,
      $$ElectricityContractsTableUpdateCompanionBuilder,
      (
        ElectricityContract,
        BaseReferences<
          _$AppDatabase,
          $ElectricityContractsTable,
          ElectricityContract
        >,
      ),
      ElectricityContract,
      PrefetchHooks Function()
    >;
typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<int> id,
      Value<String?> locationPlz,
      Value<String?> locationCity,
      Value<double?> locationLat,
      Value<double?> locationLon,
      Value<int?> meterIntDigits,
      Value<int?> electricityIntDigits,
      Value<int?> electricityDecDigits,
      Value<String?> houseType,
      Value<int?> squareMeters,
      Value<int?> numberOfPersons,
      Value<bool?> hasPv,
      Value<bool?> hasSolarThermal,
      Value<String?> trackingMode,
      Value<int?> constructionYear,
      Value<bool?> isInsulated,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<int> id,
      Value<String?> locationPlz,
      Value<String?> locationCity,
      Value<double?> locationLat,
      Value<double?> locationLon,
      Value<int?> meterIntDigits,
      Value<int?> electricityIntDigits,
      Value<int?> electricityDecDigits,
      Value<String?> houseType,
      Value<int?> squareMeters,
      Value<int?> numberOfPersons,
      Value<bool?> hasPv,
      Value<bool?> hasSolarThermal,
      Value<String?> trackingMode,
      Value<int?> constructionYear,
      Value<bool?> isInsulated,
    });

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get locationPlz => $composableBuilder(
    column: $table.locationPlz,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get locationCity => $composableBuilder(
    column: $table.locationCity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get locationLat => $composableBuilder(
    column: $table.locationLat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get locationLon => $composableBuilder(
    column: $table.locationLon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get meterIntDigits => $composableBuilder(
    column: $table.meterIntDigits,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get electricityIntDigits => $composableBuilder(
    column: $table.electricityIntDigits,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get electricityDecDigits => $composableBuilder(
    column: $table.electricityDecDigits,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get houseType => $composableBuilder(
    column: $table.houseType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get squareMeters => $composableBuilder(
    column: $table.squareMeters,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get numberOfPersons => $composableBuilder(
    column: $table.numberOfPersons,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hasPv => $composableBuilder(
    column: $table.hasPv,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hasSolarThermal => $composableBuilder(
    column: $table.hasSolarThermal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get trackingMode => $composableBuilder(
    column: $table.trackingMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get constructionYear => $composableBuilder(
    column: $table.constructionYear,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isInsulated => $composableBuilder(
    column: $table.isInsulated,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get locationPlz => $composableBuilder(
    column: $table.locationPlz,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get locationCity => $composableBuilder(
    column: $table.locationCity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get locationLat => $composableBuilder(
    column: $table.locationLat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get locationLon => $composableBuilder(
    column: $table.locationLon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get meterIntDigits => $composableBuilder(
    column: $table.meterIntDigits,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get electricityIntDigits => $composableBuilder(
    column: $table.electricityIntDigits,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get electricityDecDigits => $composableBuilder(
    column: $table.electricityDecDigits,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get houseType => $composableBuilder(
    column: $table.houseType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get squareMeters => $composableBuilder(
    column: $table.squareMeters,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get numberOfPersons => $composableBuilder(
    column: $table.numberOfPersons,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hasPv => $composableBuilder(
    column: $table.hasPv,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hasSolarThermal => $composableBuilder(
    column: $table.hasSolarThermal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get trackingMode => $composableBuilder(
    column: $table.trackingMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get constructionYear => $composableBuilder(
    column: $table.constructionYear,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isInsulated => $composableBuilder(
    column: $table.isInsulated,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get locationPlz => $composableBuilder(
    column: $table.locationPlz,
    builder: (column) => column,
  );

  GeneratedColumn<String> get locationCity => $composableBuilder(
    column: $table.locationCity,
    builder: (column) => column,
  );

  GeneratedColumn<double> get locationLat => $composableBuilder(
    column: $table.locationLat,
    builder: (column) => column,
  );

  GeneratedColumn<double> get locationLon => $composableBuilder(
    column: $table.locationLon,
    builder: (column) => column,
  );

  GeneratedColumn<int> get meterIntDigits => $composableBuilder(
    column: $table.meterIntDigits,
    builder: (column) => column,
  );

  GeneratedColumn<int> get electricityIntDigits => $composableBuilder(
    column: $table.electricityIntDigits,
    builder: (column) => column,
  );

  GeneratedColumn<int> get electricityDecDigits => $composableBuilder(
    column: $table.electricityDecDigits,
    builder: (column) => column,
  );

  GeneratedColumn<String> get houseType =>
      $composableBuilder(column: $table.houseType, builder: (column) => column);

  GeneratedColumn<int> get squareMeters => $composableBuilder(
    column: $table.squareMeters,
    builder: (column) => column,
  );

  GeneratedColumn<int> get numberOfPersons => $composableBuilder(
    column: $table.numberOfPersons,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get hasPv =>
      $composableBuilder(column: $table.hasPv, builder: (column) => column);

  GeneratedColumn<bool> get hasSolarThermal => $composableBuilder(
    column: $table.hasSolarThermal,
    builder: (column) => column,
  );

  GeneratedColumn<String> get trackingMode => $composableBuilder(
    column: $table.trackingMode,
    builder: (column) => column,
  );

  GeneratedColumn<int> get constructionYear => $composableBuilder(
    column: $table.constructionYear,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isInsulated => $composableBuilder(
    column: $table.isInsulated,
    builder: (column) => column,
  );
}

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSettingsTable,
          AppSetting,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (
            AppSetting,
            BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
          ),
          AppSetting,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> locationPlz = const Value.absent(),
                Value<String?> locationCity = const Value.absent(),
                Value<double?> locationLat = const Value.absent(),
                Value<double?> locationLon = const Value.absent(),
                Value<int?> meterIntDigits = const Value.absent(),
                Value<int?> electricityIntDigits = const Value.absent(),
                Value<int?> electricityDecDigits = const Value.absent(),
                Value<String?> houseType = const Value.absent(),
                Value<int?> squareMeters = const Value.absent(),
                Value<int?> numberOfPersons = const Value.absent(),
                Value<bool?> hasPv = const Value.absent(),
                Value<bool?> hasSolarThermal = const Value.absent(),
                Value<String?> trackingMode = const Value.absent(),
                Value<int?> constructionYear = const Value.absent(),
                Value<bool?> isInsulated = const Value.absent(),
              }) => AppSettingsCompanion(
                id: id,
                locationPlz: locationPlz,
                locationCity: locationCity,
                locationLat: locationLat,
                locationLon: locationLon,
                meterIntDigits: meterIntDigits,
                electricityIntDigits: electricityIntDigits,
                electricityDecDigits: electricityDecDigits,
                houseType: houseType,
                squareMeters: squareMeters,
                numberOfPersons: numberOfPersons,
                hasPv: hasPv,
                hasSolarThermal: hasSolarThermal,
                trackingMode: trackingMode,
                constructionYear: constructionYear,
                isInsulated: isInsulated,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> locationPlz = const Value.absent(),
                Value<String?> locationCity = const Value.absent(),
                Value<double?> locationLat = const Value.absent(),
                Value<double?> locationLon = const Value.absent(),
                Value<int?> meterIntDigits = const Value.absent(),
                Value<int?> electricityIntDigits = const Value.absent(),
                Value<int?> electricityDecDigits = const Value.absent(),
                Value<String?> houseType = const Value.absent(),
                Value<int?> squareMeters = const Value.absent(),
                Value<int?> numberOfPersons = const Value.absent(),
                Value<bool?> hasPv = const Value.absent(),
                Value<bool?> hasSolarThermal = const Value.absent(),
                Value<String?> trackingMode = const Value.absent(),
                Value<int?> constructionYear = const Value.absent(),
                Value<bool?> isInsulated = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                id: id,
                locationPlz: locationPlz,
                locationCity: locationCity,
                locationLat: locationLat,
                locationLon: locationLon,
                meterIntDigits: meterIntDigits,
                electricityIntDigits: electricityIntDigits,
                electricityDecDigits: electricityDecDigits,
                houseType: houseType,
                squareMeters: squareMeters,
                numberOfPersons: numberOfPersons,
                hasPv: hasPv,
                hasSolarThermal: hasSolarThermal,
                trackingMode: trackingMode,
                constructionYear: constructionYear,
                isInsulated: isInsulated,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSettingsTable,
      AppSetting,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (
        AppSetting,
        BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
      ),
      AppSetting,
      PrefetchHooks Function()
    >;
typedef $$WeatherCachesTableCreateCompanionBuilder =
    WeatherCachesCompanion Function({
      Value<int> id,
      required String date,
      required double lat,
      required double lon,
      required double tempMean,
    });
typedef $$WeatherCachesTableUpdateCompanionBuilder =
    WeatherCachesCompanion Function({
      Value<int> id,
      Value<String> date,
      Value<double> lat,
      Value<double> lon,
      Value<double> tempMean,
    });

class $$WeatherCachesTableFilterComposer
    extends Composer<_$AppDatabase, $WeatherCachesTable> {
  $$WeatherCachesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lon => $composableBuilder(
    column: $table.lon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get tempMean => $composableBuilder(
    column: $table.tempMean,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WeatherCachesTableOrderingComposer
    extends Composer<_$AppDatabase, $WeatherCachesTable> {
  $$WeatherCachesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lon => $composableBuilder(
    column: $table.lon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get tempMean => $composableBuilder(
    column: $table.tempMean,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WeatherCachesTableAnnotationComposer
    extends Composer<_$AppDatabase, $WeatherCachesTable> {
  $$WeatherCachesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<double> get lat =>
      $composableBuilder(column: $table.lat, builder: (column) => column);

  GeneratedColumn<double> get lon =>
      $composableBuilder(column: $table.lon, builder: (column) => column);

  GeneratedColumn<double> get tempMean =>
      $composableBuilder(column: $table.tempMean, builder: (column) => column);
}

class $$WeatherCachesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WeatherCachesTable,
          WeatherCache,
          $$WeatherCachesTableFilterComposer,
          $$WeatherCachesTableOrderingComposer,
          $$WeatherCachesTableAnnotationComposer,
          $$WeatherCachesTableCreateCompanionBuilder,
          $$WeatherCachesTableUpdateCompanionBuilder,
          (
            WeatherCache,
            BaseReferences<_$AppDatabase, $WeatherCachesTable, WeatherCache>,
          ),
          WeatherCache,
          PrefetchHooks Function()
        > {
  $$WeatherCachesTableTableManager(_$AppDatabase db, $WeatherCachesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WeatherCachesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WeatherCachesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WeatherCachesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<double> lat = const Value.absent(),
                Value<double> lon = const Value.absent(),
                Value<double> tempMean = const Value.absent(),
              }) => WeatherCachesCompanion(
                id: id,
                date: date,
                lat: lat,
                lon: lon,
                tempMean: tempMean,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String date,
                required double lat,
                required double lon,
                required double tempMean,
              }) => WeatherCachesCompanion.insert(
                id: id,
                date: date,
                lat: lat,
                lon: lon,
                tempMean: tempMean,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WeatherCachesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WeatherCachesTable,
      WeatherCache,
      $$WeatherCachesTableFilterComposer,
      $$WeatherCachesTableOrderingComposer,
      $$WeatherCachesTableAnnotationComposer,
      $$WeatherCachesTableCreateCompanionBuilder,
      $$WeatherCachesTableUpdateCompanionBuilder,
      (
        WeatherCache,
        BaseReferences<_$AppDatabase, $WeatherCachesTable, WeatherCache>,
      ),
      WeatherCache,
      PrefetchHooks Function()
    >;
typedef $$AdvancePaymentChangesTableCreateCompanionBuilder =
    AdvancePaymentChangesCompanion Function({
      Value<int> id,
      required String contractType,
      required double amount,
      required int validFrom,
      Value<bool> isSynced,
      Value<String?> remoteId,
    });
typedef $$AdvancePaymentChangesTableUpdateCompanionBuilder =
    AdvancePaymentChangesCompanion Function({
      Value<int> id,
      Value<String> contractType,
      Value<double> amount,
      Value<int> validFrom,
      Value<bool> isSynced,
      Value<String?> remoteId,
    });

class $$AdvancePaymentChangesTableFilterComposer
    extends Composer<_$AppDatabase, $AdvancePaymentChangesTable> {
  $$AdvancePaymentChangesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contractType => $composableBuilder(
    column: $table.contractType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get validFrom => $composableBuilder(
    column: $table.validFrom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AdvancePaymentChangesTableOrderingComposer
    extends Composer<_$AppDatabase, $AdvancePaymentChangesTable> {
  $$AdvancePaymentChangesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contractType => $composableBuilder(
    column: $table.contractType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get validFrom => $composableBuilder(
    column: $table.validFrom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AdvancePaymentChangesTableAnnotationComposer
    extends Composer<_$AppDatabase, $AdvancePaymentChangesTable> {
  $$AdvancePaymentChangesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get contractType => $composableBuilder(
    column: $table.contractType,
    builder: (column) => column,
  );

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<int> get validFrom =>
      $composableBuilder(column: $table.validFrom, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumn<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);
}

class $$AdvancePaymentChangesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AdvancePaymentChangesTable,
          AdvancePaymentChange,
          $$AdvancePaymentChangesTableFilterComposer,
          $$AdvancePaymentChangesTableOrderingComposer,
          $$AdvancePaymentChangesTableAnnotationComposer,
          $$AdvancePaymentChangesTableCreateCompanionBuilder,
          $$AdvancePaymentChangesTableUpdateCompanionBuilder,
          (
            AdvancePaymentChange,
            BaseReferences<
              _$AppDatabase,
              $AdvancePaymentChangesTable,
              AdvancePaymentChange
            >,
          ),
          AdvancePaymentChange,
          PrefetchHooks Function()
        > {
  $$AdvancePaymentChangesTableTableManager(
    _$AppDatabase db,
    $AdvancePaymentChangesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AdvancePaymentChangesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$AdvancePaymentChangesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$AdvancePaymentChangesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> contractType = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<int> validFrom = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
              }) => AdvancePaymentChangesCompanion(
                id: id,
                contractType: contractType,
                amount: amount,
                validFrom: validFrom,
                isSynced: isSynced,
                remoteId: remoteId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String contractType,
                required double amount,
                required int validFrom,
                Value<bool> isSynced = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
              }) => AdvancePaymentChangesCompanion.insert(
                id: id,
                contractType: contractType,
                amount: amount,
                validFrom: validFrom,
                isSynced: isSynced,
                remoteId: remoteId,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AdvancePaymentChangesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AdvancePaymentChangesTable,
      AdvancePaymentChange,
      $$AdvancePaymentChangesTableFilterComposer,
      $$AdvancePaymentChangesTableOrderingComposer,
      $$AdvancePaymentChangesTableAnnotationComposer,
      $$AdvancePaymentChangesTableCreateCompanionBuilder,
      $$AdvancePaymentChangesTableUpdateCompanionBuilder,
      (
        AdvancePaymentChange,
        BaseReferences<
          _$AppDatabase,
          $AdvancePaymentChangesTable,
          AdvancePaymentChange
        >,
      ),
      AdvancePaymentChange,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$MeterReadingsTableTableManager get meterReadings =>
      $$MeterReadingsTableTableManager(_db, _db.meterReadings);
  $$ElectricityReadingsTableTableManager get electricityReadings =>
      $$ElectricityReadingsTableTableManager(_db, _db.electricityReadings);
  $$PriceContractsTableTableManager get priceContracts =>
      $$PriceContractsTableTableManager(_db, _db.priceContracts);
  $$ElectricityContractsTableTableManager get electricityContracts =>
      $$ElectricityContractsTableTableManager(_db, _db.electricityContracts);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
  $$WeatherCachesTableTableManager get weatherCaches =>
      $$WeatherCachesTableTableManager(_db, _db.weatherCaches);
  $$AdvancePaymentChangesTableTableManager get advancePaymentChanges =>
      $$AdvancePaymentChangesTableTableManager(_db, _db.advancePaymentChanges);
}
