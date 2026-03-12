/// Drift-based implementation for web platform
/// Uses sql.js (SQLite compiled to WebAssembly) via Drift

import 'dart:async';
import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';
import 'drift/synclib_drift_database.dart';
import 'merkle.dart';

// Constants (equivalent to native bindings)
const int synclibOk = 0;
const int synclibError = 1;
const int synclibNoMoreChanges = 2;

class SynclibException implements Exception {
  final String message;
  SynclibException(this.message);

  @override
  String toString() => 'SynclibException: $message';
}

enum SynclibOperation {
  insert,
  update,
  delete,
}

class Change {
  final int seqnum;
  final String tableName;
  final String rowId;
  final SynclibOperation operation;
  final String? data;

  Change({
    required this.seqnum,
    required this.tableName,
    required this.rowId,
    required this.operation,
    this.data,
  });

  factory Change.fromDriftRow(SynclibChange row) {
    return Change(
      seqnum: row.seqnum,
      tableName: row.table,
      rowId: row.rowId,
      operation: _parseOperation(row.operation),
      data: row.data,
    );
  }

  static SynclibOperation _parseOperation(String op) {
    switch (op.toLowerCase()) {
      case 'insert':
        return SynclibOperation.insert;
      case 'update':
        return SynclibOperation.update;
      case 'delete':
        return SynclibOperation.delete;
      default:
        throw SynclibException('Unknown operation: $op');
    }
  }
}

class SynclibDatabase implements MerkleDatabase {
  SynclibDriftDatabase? _db;
  String? _dbPath;
  bool _inBulkMode = false;
  MerkleComputer? _merkleComputer;

  /// Stream controller for local change notifications.
  /// Emits whenever a tracked write operation occurs.
  final StreamController<Change> _localChangeController =
      StreamController<Change>.broadcast();

  /// Stream of local changes as they occur.
  /// Subscribe to this to be notified immediately when writes happen.
  Stream<Change> get localChanges => _localChangeController.stream;

  // Cache of opened databases by path
  static final Map<String, SynclibDatabase> _instances = {};

  /// Open a database connection using Drift with WasmDatabase (web)
  static Future<SynclibDatabase> open(String dbPath) async {
    // Return existing instance if already opened
    if (_instances.containsKey(dbPath)) {
      return _instances[dbPath]!;
    }

    final instance = SynclibDatabase._();
    instance._dbPath = dbPath;

    // Open Drift database with WasmDatabase for web
    final database = await WasmDatabase.open(
      databaseName: dbPath,
      sqlite3Uri: Uri.parse('sqlite3.wasm'),
      driftWorkerUri: Uri.parse('drift_worker.js'),
    );

    instance._db = SynclibDriftDatabase(database.resolvedExecutor);

    // Cache the instance
    _instances[dbPath] = instance;

    return instance;
  }

  SynclibDatabase._();

  void _ensureOpen() {
    if (_db == null) {
      throw SynclibException('Database not open');
    }
  }

  /// Execute a write operation with change tracking
  Future<void> write({
    required String tableName,
    required String rowId,
    required SynclibOperation operation,
    required String sql,
    String? data,
  }) async {
    _ensureOpen();

    await _db!.transaction(() async {
      // Execute the actual SQL
      await _db!.execRaw(sql);

      // Record the change
      await _db!.recordChange(
        tableName: tableName,
        rowId: rowId,
        operation: operation.name,
        data: data,
      );
    });

    // Notify listeners of the local change
    _localChangeController.add(Change(
      seqnum: 0, // Actual seqnum assigned by Drift, not known here
      tableName: tableName,
      rowId: rowId,
      operation: operation,
      data: data,
    ));
  }

  /// Execute a write operation with parameters and change tracking
  Future<void> writeWithParams({
    required String tableName,
    required String rowId,
    required SynclibOperation operation,
    required String sql,
    required List<dynamic> params,
    String? data,
  }) async {
    _ensureOpen();

    await _db!.transaction(() async {
      // Execute the actual SQL with parameters
      await _db!.execRawWithParams(sql, params);

      // Record the change
      await _db!.recordChange(
        tableName: tableName,
        rowId: rowId,
        operation: operation.name,
        data: data,
      );
    });

    // Notify listeners of the local change
    _localChangeController.add(Change(
      seqnum: 0, // Actual seqnum assigned by Drift, not known here
      tableName: tableName,
      rowId: rowId,
      operation: operation,
      data: data,
    ));
  }

  /// Execute SQL without change tracking (e.g., DDL, CREATE TABLE)
  Future<void> exec(String sql) async {
    _ensureOpen();
    await _db!.execRaw(sql);
  }

  /// Execute a read query
  Future<List<Map<String, dynamic>>> read(String sql) async {
    _ensureOpen();
    return await _db!.queryRaw(sql);
  }

  /// Execute a read query (raw - same as read for Drift)
  Future<List<Map<String, dynamic>>> readRaw(String sql) async {
    return await read(sql);
  }

  /// Apply a remote change without creating a local change record
  Future<void> applyRemote({
    required String tableName,
    required String rowId,
    required SynclibOperation operation,
    required String sql,
    String? data,
  }) async {
    _ensureOpen();
    await _db!.execRaw(sql);
  }

  /// Apply remote change with parameters
  Future<void> applyRemoteWithParams({
    required String tableName,
    required String rowId,
    required SynclibOperation operation,
    required String sql,
    required List<dynamic> params,
    String? data,
  }) async {
    _ensureOpen();
    // Execute SQL with parameters using Drift's customStatement
    await _db!.execRawWithParams(sql, params);
  }

  /// Get pending changes that haven't been synced
  Future<List<Change>> getPendingChanges({int limit = 100}) async {
    _ensureOpen();
    final driftChanges = await _db!.getPendingChanges(limit: limit);
    return driftChanges.map((c) => Change.fromDriftRow(c)).toList();
  }

  /// Mark changes as synced up to the given sequence number
  Future<void> markSynced(int seqnum) async {
    _ensureOpen();
    await _db!.markSynced(seqnum);
  }

  /// Delete a specific change by sequence number
  /// Use this for precise cleanup after server acknowledgment
  Future<void> deleteChange(int seqnum) async {
    _ensureOpen();
    await _db!.deleteChange(seqnum);
  }

  /// Begin bulk remote operation mode (transaction)
  Future<void> beginBulkRemote() async {
    _ensureOpen();
    _inBulkMode = true;
    // Drift handles transactions internally, we'll track state
  }

  /// Execute SQL in bulk remote mode
  Future<void> execBulkRemote(String sql) async {
    _ensureOpen();
    if (!_inBulkMode) {
      throw SynclibException('Not in bulk mode. Call beginBulkRemote() first.');
    }
    await _db!.execRaw(sql);
  }

  /// End bulk remote mode
  Future<void> endBulkRemote({bool rollback = false}) async {
    _ensureOpen();
    if (!_inBulkMode) {
      throw SynclibException('Not in bulk mode.');
    }
    _inBulkMode = false;
    // Drift auto-commits, rollback would need to be handled differently
    if (rollback) {
      throw SynclibException('Rollback not yet implemented for web');
    }
  }

  /// No-op on web — row_hash precomputation is native-only
  Future<void> updateRowHash(String tableName, String rowId) async {}

  /// No-op on web — row_hash precomputation is native-only
  Future<void> backfillRowHashes(String tableName) async {}

  /// No-op on web — row_hash config is native-only
  Future<void> setHashColumns(String tableName, String columnsJson) async {}

  MerkleComputer get _merkle => _merkleComputer ??= MerkleComputer(this);

  /// Compute SHA256 hash of a single row: SHA256(row_id + "|" + sorted_json)
  Future<String> rowHash(String tableName, String rowId) async {
    _ensureOpen();
    return _merkle.rowHash(tableName, rowId);
  }

  /// Get the canonical sorted JSON for a row (for debugging hash mismatches)
  Future<String> rowJson(String tableName, String rowId) async {
    _ensureOpen();
    final rows = await read(
      "SELECT * FROM $tableName WHERE id = '$rowId'",
    );
    if (rows.isEmpty) throw SynclibException('Row not found: $tableName.$rowId');
    // Remove infrastructure columns before building sorted JSON
    final row = Map<String, dynamic>.from(rows.first);
    row.remove('row_hash');
    return _merkle.buildSortedJson(row);
  }

  /// Compute Merkle tree root hash for a table
  Future<MerkleInfo> merkleRoot(String tableName, {int blockSize = defaultBlockSize}) async {
    _ensureOpen();
    return _merkle.merkleRoot(tableName, blockSize: blockSize);
  }

  /// Get all block hashes for a table
  Future<List<String>> merkleBlockHashes(String tableName, {int blockSize = defaultBlockSize}) async {
    _ensureOpen();
    return _merkle.merkleBlockHashes(tableName, blockSize: blockSize);
  }

  /// Get current schema version
  Future<int> getSchemaVersion() async {
    _ensureOpen();
    return await _db!.getSchemaVersion();
  }

  /// Set schema version
  Future<void> setSchemaVersion(int version) async {
    _ensureOpen();
    await _db!.setSchemaVersion(version);
  }

  /// Close the database
  Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
      // Remove from cache
      if (_dbPath != null) {
        _instances.remove(_dbPath);
      }
    }
    await _localChangeController.close();
  }
}
