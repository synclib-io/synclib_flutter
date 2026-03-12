// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'synclib_drift_database.dart';

// ignore_for_file: type=lint
class $SynclibChangesTable extends SynclibChanges
    with TableInfo<$SynclibChangesTable, SynclibChange> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SynclibChangesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _seqnumMeta = const VerificationMeta('seqnum');
  @override
  late final GeneratedColumn<int> seqnum = GeneratedColumn<int>(
    'seqnum',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _tableMeta = const VerificationMeta('table');
  @override
  late final GeneratedColumn<String> table = GeneratedColumn<String>(
    'table',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rowIdMeta = const VerificationMeta('rowId');
  @override
  late final GeneratedColumn<String> rowId = GeneratedColumn<String>(
    'row_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _operationMeta = const VerificationMeta(
    'operation',
  );
  @override
  late final GeneratedColumn<String> operation = GeneratedColumn<String>(
    'operation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dataMeta = const VerificationMeta('data');
  @override
  late final GeneratedColumn<String> data = GeneratedColumn<String>(
    'data',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<int> synced = GeneratedColumn<int>(
    'synced',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    seqnum,
    table,
    rowId,
    operation,
    data,
    synced,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = '_synclib_changes';
  @override
  VerificationContext validateIntegrity(
    Insertable<SynclibChange> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('seqnum')) {
      context.handle(
        _seqnumMeta,
        seqnum.isAcceptableOrUnknown(data['seqnum']!, _seqnumMeta),
      );
    }
    if (data.containsKey('table')) {
      context.handle(
        _tableMeta,
        table.isAcceptableOrUnknown(data['table']!, _tableMeta),
      );
    } else if (isInserting) {
      context.missing(_tableMeta);
    }
    if (data.containsKey('row_id')) {
      context.handle(
        _rowIdMeta,
        rowId.isAcceptableOrUnknown(data['row_id']!, _rowIdMeta),
      );
    } else if (isInserting) {
      context.missing(_rowIdMeta);
    }
    if (data.containsKey('operation')) {
      context.handle(
        _operationMeta,
        operation.isAcceptableOrUnknown(data['operation']!, _operationMeta),
      );
    } else if (isInserting) {
      context.missing(_operationMeta);
    }
    if (data.containsKey('data')) {
      context.handle(
        _dataMeta,
        this.data.isAcceptableOrUnknown(data['data']!, _dataMeta),
      );
    }
    if (data.containsKey('synced')) {
      context.handle(
        _syncedMeta,
        synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {seqnum};
  @override
  SynclibChange map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SynclibChange(
      seqnum: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seqnum'],
      )!,
      table: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}table'],
      )!,
      rowId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}row_id'],
      )!,
      operation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation'],
      )!,
      data: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}data'],
      ),
      synced: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}synced'],
      )!,
    );
  }

  @override
  $SynclibChangesTable createAlias(String alias) {
    return $SynclibChangesTable(attachedDatabase, alias);
  }
}

class SynclibChange extends DataClass implements Insertable<SynclibChange> {
  final int seqnum;
  final String table;
  final String rowId;
  final String operation;
  final String? data;
  final int synced;
  const SynclibChange({
    required this.seqnum,
    required this.table,
    required this.rowId,
    required this.operation,
    this.data,
    required this.synced,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['seqnum'] = Variable<int>(seqnum);
    map['table'] = Variable<String>(table);
    map['row_id'] = Variable<String>(rowId);
    map['operation'] = Variable<String>(operation);
    if (!nullToAbsent || data != null) {
      map['data'] = Variable<String>(data);
    }
    map['synced'] = Variable<int>(synced);
    return map;
  }

  SynclibChangesCompanion toCompanion(bool nullToAbsent) {
    return SynclibChangesCompanion(
      seqnum: Value(seqnum),
      table: Value(table),
      rowId: Value(rowId),
      operation: Value(operation),
      data: data == null && nullToAbsent ? const Value.absent() : Value(data),
      synced: Value(synced),
    );
  }

  factory SynclibChange.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SynclibChange(
      seqnum: serializer.fromJson<int>(json['seqnum']),
      table: serializer.fromJson<String>(json['table']),
      rowId: serializer.fromJson<String>(json['rowId']),
      operation: serializer.fromJson<String>(json['operation']),
      data: serializer.fromJson<String?>(json['data']),
      synced: serializer.fromJson<int>(json['synced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'seqnum': serializer.toJson<int>(seqnum),
      'table': serializer.toJson<String>(table),
      'rowId': serializer.toJson<String>(rowId),
      'operation': serializer.toJson<String>(operation),
      'data': serializer.toJson<String?>(data),
      'synced': serializer.toJson<int>(synced),
    };
  }

  SynclibChange copyWith({
    int? seqnum,
    String? table,
    String? rowId,
    String? operation,
    Value<String?> data = const Value.absent(),
    int? synced,
  }) => SynclibChange(
    seqnum: seqnum ?? this.seqnum,
    table: table ?? this.table,
    rowId: rowId ?? this.rowId,
    operation: operation ?? this.operation,
    data: data.present ? data.value : this.data,
    synced: synced ?? this.synced,
  );
  SynclibChange copyWithCompanion(SynclibChangesCompanion data) {
    return SynclibChange(
      seqnum: data.seqnum.present ? data.seqnum.value : this.seqnum,
      table: data.table.present ? data.table.value : this.table,
      rowId: data.rowId.present ? data.rowId.value : this.rowId,
      operation: data.operation.present ? data.operation.value : this.operation,
      data: data.data.present ? data.data.value : this.data,
      synced: data.synced.present ? data.synced.value : this.synced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SynclibChange(')
          ..write('seqnum: $seqnum, ')
          ..write('table: $table, ')
          ..write('rowId: $rowId, ')
          ..write('operation: $operation, ')
          ..write('data: $data, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(seqnum, table, rowId, operation, data, synced);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SynclibChange &&
          other.seqnum == this.seqnum &&
          other.table == this.table &&
          other.rowId == this.rowId &&
          other.operation == this.operation &&
          other.data == this.data &&
          other.synced == this.synced);
}

class SynclibChangesCompanion extends UpdateCompanion<SynclibChange> {
  final Value<int> seqnum;
  final Value<String> table;
  final Value<String> rowId;
  final Value<String> operation;
  final Value<String?> data;
  final Value<int> synced;
  const SynclibChangesCompanion({
    this.seqnum = const Value.absent(),
    this.table = const Value.absent(),
    this.rowId = const Value.absent(),
    this.operation = const Value.absent(),
    this.data = const Value.absent(),
    this.synced = const Value.absent(),
  });
  SynclibChangesCompanion.insert({
    this.seqnum = const Value.absent(),
    required String table,
    required String rowId,
    required String operation,
    this.data = const Value.absent(),
    this.synced = const Value.absent(),
  }) : table = Value(table),
       rowId = Value(rowId),
       operation = Value(operation);
  static Insertable<SynclibChange> custom({
    Expression<int>? seqnum,
    Expression<String>? table,
    Expression<String>? rowId,
    Expression<String>? operation,
    Expression<String>? data,
    Expression<int>? synced,
  }) {
    return RawValuesInsertable({
      if (seqnum != null) 'seqnum': seqnum,
      if (table != null) 'table': table,
      if (rowId != null) 'row_id': rowId,
      if (operation != null) 'operation': operation,
      if (data != null) 'data': data,
      if (synced != null) 'synced': synced,
    });
  }

  SynclibChangesCompanion copyWith({
    Value<int>? seqnum,
    Value<String>? table,
    Value<String>? rowId,
    Value<String>? operation,
    Value<String?>? data,
    Value<int>? synced,
  }) {
    return SynclibChangesCompanion(
      seqnum: seqnum ?? this.seqnum,
      table: table ?? this.table,
      rowId: rowId ?? this.rowId,
      operation: operation ?? this.operation,
      data: data ?? this.data,
      synced: synced ?? this.synced,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (seqnum.present) {
      map['seqnum'] = Variable<int>(seqnum.value);
    }
    if (table.present) {
      map['table'] = Variable<String>(table.value);
    }
    if (rowId.present) {
      map['row_id'] = Variable<String>(rowId.value);
    }
    if (operation.present) {
      map['operation'] = Variable<String>(operation.value);
    }
    if (data.present) {
      map['data'] = Variable<String>(data.value);
    }
    if (synced.present) {
      map['synced'] = Variable<int>(synced.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SynclibChangesCompanion(')
          ..write('seqnum: $seqnum, ')
          ..write('table: $table, ')
          ..write('rowId: $rowId, ')
          ..write('operation: $operation, ')
          ..write('data: $data, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }
}

class $SynclibMetadataTable extends SynclibMetadata
    with TableInfo<$SynclibMetadataTable, SynclibMetadataData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SynclibMetadataTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = '_synclib_metadata';
  @override
  VerificationContext validateIntegrity(
    Insertable<SynclibMetadataData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SynclibMetadataData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SynclibMetadataData(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $SynclibMetadataTable createAlias(String alias) {
    return $SynclibMetadataTable(attachedDatabase, alias);
  }
}

class SynclibMetadataData extends DataClass
    implements Insertable<SynclibMetadataData> {
  final String key;
  final String value;
  const SynclibMetadataData({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SynclibMetadataCompanion toCompanion(bool nullToAbsent) {
    return SynclibMetadataCompanion(key: Value(key), value: Value(value));
  }

  factory SynclibMetadataData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SynclibMetadataData(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  SynclibMetadataData copyWith({String? key, String? value}) =>
      SynclibMetadataData(key: key ?? this.key, value: value ?? this.value);
  SynclibMetadataData copyWithCompanion(SynclibMetadataCompanion data) {
    return SynclibMetadataData(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SynclibMetadataData(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SynclibMetadataData &&
          other.key == this.key &&
          other.value == this.value);
}

class SynclibMetadataCompanion extends UpdateCompanion<SynclibMetadataData> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SynclibMetadataCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SynclibMetadataCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<SynclibMetadataData> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SynclibMetadataCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SynclibMetadataCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SynclibMetadataCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$SynclibDriftDatabase extends GeneratedDatabase {
  _$SynclibDriftDatabase(QueryExecutor e) : super(e);
  $SynclibDriftDatabaseManager get managers =>
      $SynclibDriftDatabaseManager(this);
  late final $SynclibChangesTable synclibChanges = $SynclibChangesTable(this);
  late final $SynclibMetadataTable synclibMetadata = $SynclibMetadataTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    synclibChanges,
    synclibMetadata,
  ];
}

typedef $$SynclibChangesTableCreateCompanionBuilder =
    SynclibChangesCompanion Function({
      Value<int> seqnum,
      required String table,
      required String rowId,
      required String operation,
      Value<String?> data,
      Value<int> synced,
    });
typedef $$SynclibChangesTableUpdateCompanionBuilder =
    SynclibChangesCompanion Function({
      Value<int> seqnum,
      Value<String> table,
      Value<String> rowId,
      Value<String> operation,
      Value<String?> data,
      Value<int> synced,
    });

class $$SynclibChangesTableFilterComposer
    extends Composer<_$SynclibDriftDatabase, $SynclibChangesTable> {
  $$SynclibChangesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get seqnum => $composableBuilder(
    column: $table.seqnum,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get table => $composableBuilder(
    column: $table.table,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rowId => $composableBuilder(
    column: $table.rowId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SynclibChangesTableOrderingComposer
    extends Composer<_$SynclibDriftDatabase, $SynclibChangesTable> {
  $$SynclibChangesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get seqnum => $composableBuilder(
    column: $table.seqnum,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get table => $composableBuilder(
    column: $table.table,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rowId => $composableBuilder(
    column: $table.rowId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SynclibChangesTableAnnotationComposer
    extends Composer<_$SynclibDriftDatabase, $SynclibChangesTable> {
  $$SynclibChangesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get seqnum =>
      $composableBuilder(column: $table.seqnum, builder: (column) => column);

  GeneratedColumn<String> get table =>
      $composableBuilder(column: $table.table, builder: (column) => column);

  GeneratedColumn<String> get rowId =>
      $composableBuilder(column: $table.rowId, builder: (column) => column);

  GeneratedColumn<String> get operation =>
      $composableBuilder(column: $table.operation, builder: (column) => column);

  GeneratedColumn<String> get data =>
      $composableBuilder(column: $table.data, builder: (column) => column);

  GeneratedColumn<int> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);
}

class $$SynclibChangesTableTableManager
    extends
        RootTableManager<
          _$SynclibDriftDatabase,
          $SynclibChangesTable,
          SynclibChange,
          $$SynclibChangesTableFilterComposer,
          $$SynclibChangesTableOrderingComposer,
          $$SynclibChangesTableAnnotationComposer,
          $$SynclibChangesTableCreateCompanionBuilder,
          $$SynclibChangesTableUpdateCompanionBuilder,
          (
            SynclibChange,
            BaseReferences<
              _$SynclibDriftDatabase,
              $SynclibChangesTable,
              SynclibChange
            >,
          ),
          SynclibChange,
          PrefetchHooks Function()
        > {
  $$SynclibChangesTableTableManager(
    _$SynclibDriftDatabase db,
    $SynclibChangesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SynclibChangesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SynclibChangesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SynclibChangesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> seqnum = const Value.absent(),
                Value<String> table = const Value.absent(),
                Value<String> rowId = const Value.absent(),
                Value<String> operation = const Value.absent(),
                Value<String?> data = const Value.absent(),
                Value<int> synced = const Value.absent(),
              }) => SynclibChangesCompanion(
                seqnum: seqnum,
                table: table,
                rowId: rowId,
                operation: operation,
                data: data,
                synced: synced,
              ),
          createCompanionCallback:
              ({
                Value<int> seqnum = const Value.absent(),
                required String table,
                required String rowId,
                required String operation,
                Value<String?> data = const Value.absent(),
                Value<int> synced = const Value.absent(),
              }) => SynclibChangesCompanion.insert(
                seqnum: seqnum,
                table: table,
                rowId: rowId,
                operation: operation,
                data: data,
                synced: synced,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SynclibChangesTableProcessedTableManager =
    ProcessedTableManager<
      _$SynclibDriftDatabase,
      $SynclibChangesTable,
      SynclibChange,
      $$SynclibChangesTableFilterComposer,
      $$SynclibChangesTableOrderingComposer,
      $$SynclibChangesTableAnnotationComposer,
      $$SynclibChangesTableCreateCompanionBuilder,
      $$SynclibChangesTableUpdateCompanionBuilder,
      (
        SynclibChange,
        BaseReferences<
          _$SynclibDriftDatabase,
          $SynclibChangesTable,
          SynclibChange
        >,
      ),
      SynclibChange,
      PrefetchHooks Function()
    >;
typedef $$SynclibMetadataTableCreateCompanionBuilder =
    SynclibMetadataCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$SynclibMetadataTableUpdateCompanionBuilder =
    SynclibMetadataCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$SynclibMetadataTableFilterComposer
    extends Composer<_$SynclibDriftDatabase, $SynclibMetadataTable> {
  $$SynclibMetadataTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SynclibMetadataTableOrderingComposer
    extends Composer<_$SynclibDriftDatabase, $SynclibMetadataTable> {
  $$SynclibMetadataTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SynclibMetadataTableAnnotationComposer
    extends Composer<_$SynclibDriftDatabase, $SynclibMetadataTable> {
  $$SynclibMetadataTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SynclibMetadataTableTableManager
    extends
        RootTableManager<
          _$SynclibDriftDatabase,
          $SynclibMetadataTable,
          SynclibMetadataData,
          $$SynclibMetadataTableFilterComposer,
          $$SynclibMetadataTableOrderingComposer,
          $$SynclibMetadataTableAnnotationComposer,
          $$SynclibMetadataTableCreateCompanionBuilder,
          $$SynclibMetadataTableUpdateCompanionBuilder,
          (
            SynclibMetadataData,
            BaseReferences<
              _$SynclibDriftDatabase,
              $SynclibMetadataTable,
              SynclibMetadataData
            >,
          ),
          SynclibMetadataData,
          PrefetchHooks Function()
        > {
  $$SynclibMetadataTableTableManager(
    _$SynclibDriftDatabase db,
    $SynclibMetadataTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SynclibMetadataTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SynclibMetadataTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SynclibMetadataTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SynclibMetadataCompanion(
                key: key,
                value: value,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => SynclibMetadataCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SynclibMetadataTableProcessedTableManager =
    ProcessedTableManager<
      _$SynclibDriftDatabase,
      $SynclibMetadataTable,
      SynclibMetadataData,
      $$SynclibMetadataTableFilterComposer,
      $$SynclibMetadataTableOrderingComposer,
      $$SynclibMetadataTableAnnotationComposer,
      $$SynclibMetadataTableCreateCompanionBuilder,
      $$SynclibMetadataTableUpdateCompanionBuilder,
      (
        SynclibMetadataData,
        BaseReferences<
          _$SynclibDriftDatabase,
          $SynclibMetadataTable,
          SynclibMetadataData
        >,
      ),
      SynclibMetadataData,
      PrefetchHooks Function()
    >;

class $SynclibDriftDatabaseManager {
  final _$SynclibDriftDatabase _db;
  $SynclibDriftDatabaseManager(this._db);
  $$SynclibChangesTableTableManager get synclibChanges =>
      $$SynclibChangesTableTableManager(_db, _db.synclibChanges);
  $$SynclibMetadataTableTableManager get synclibMetadata =>
      $$SynclibMetadataTableTableManager(_db, _db.synclibMetadata);
}
