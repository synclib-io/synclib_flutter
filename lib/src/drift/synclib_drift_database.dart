import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

part 'synclib_drift_database.g.dart';

/// The _synclib_changes table that tracks all modifications
class SynclibChanges extends Table {
  @override
  String get tableName => '_synclib_changes';

  IntColumn get seqnum => integer().autoIncrement()();
  TextColumn get table => text()();
  TextColumn get rowId => text()();
  TextColumn get operation => text()(); // 'insert', 'update', 'delete'
  TextColumn get data => text().nullable()(); // JSON data
  IntColumn get synced => integer().withDefault(const Constant(0))();
}

/// The _synclib_metadata table for schema versioning
class SynclibMetadata extends Table {
  @override
  String get tableName => '_synclib_metadata';

  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(tables: [SynclibChanges, SynclibMetadata])
class SynclibDriftDatabase extends _$SynclibDriftDatabase {
  SynclibDriftDatabase(QueryExecutor e) : super(e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
      );

  /// Record a change in the changes table
  Future<int> recordChange({
    required String tableName,
    required String rowId,
    required String operation,
    String? data,
  }) async {
    return into(synclibChanges).insert(
      SynclibChangesCompanion.insert(
        table: tableName,
        rowId: rowId,
        operation: operation,
        data: Value(data),
        synced: const Value(0),
      ),
    );
  }

  /// Get pending changes (not yet synced)
  Future<List<SynclibChange>> getPendingChanges({int limit = 100}) {
    return (select(synclibChanges)
          ..where((t) => t.synced.equals(0))
          ..orderBy([(t) => OrderingTerm.asc(t.seqnum)])
          ..limit(limit))
        .get();
  }

  /// Mark changes as synced up to a sequence number
  Future<int> markSynced(int seqnum) {
    return (update(synclibChanges)
          ..where((t) => t.seqnum.isSmallerOrEqualValue(seqnum)))
        .write(const SynclibChangesCompanion(synced: Value(1)));
  }

  /// Delete a specific change by sequence number
  /// Use this for precise cleanup after server acknowledgment
  Future<int> deleteChange(int seqnum) {
    return (delete(synclibChanges)..where((t) => t.seqnum.equals(seqnum))).go();
  }

  /// Get schema version
  Future<int> getSchemaVersion() async {
    final result = await (select(synclibMetadata)
          ..where((t) => t.key.equals('schema_version')))
        .getSingleOrNull();

    if (result == null) {
      return 0;
    }

    return int.tryParse(result.value) ?? 0;
  }

  /// Set schema version
  Future<void> setSchemaVersion(int version) async {
    await into(synclibMetadata).insertOnConflictUpdate(
      SynclibMetadataCompanion.insert(
        key: 'schema_version',
        value: version.toString(),
      ),
    );
  }

  /// Get metadata value by key
  Future<String?> getMetadata(String key) async {
    final result = await (select(synclibMetadata)
          ..where((t) => t.key.equals(key)))
        .getSingleOrNull();

    return result?.value;
  }

  /// Set metadata value
  Future<void> setMetadata(String key, String value) async {
    await into(synclibMetadata).insertOnConflictUpdate(
      SynclibMetadataCompanion.insert(
        key: key,
        value: value,
      ),
    );
  }

  /// Execute raw SQL (for custom tables and queries)
  Future<void> execRaw(String sql) async {
    await customStatement(sql);
  }

  /// Execute raw SQL with parameters
  Future<void> execRawWithParams(String sql, List<dynamic> params) async {
    await customStatement(sql, params);
  }

  /// Execute raw SQL query and return results
  Future<List<Map<String, dynamic>>> queryRaw(String sql) async {
    final result = await customSelect(sql, readsFrom: {}).get();
    return result.map((row) => row.data).toList();
  }
}
