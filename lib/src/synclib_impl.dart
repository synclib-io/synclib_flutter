import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:ffi/ffi.dart';
import 'synclib_bindings.dart';

/// Exception thrown when a synclib operation fails
class SynclibException implements Exception {
  final String message;
  final int? code;

  SynclibException(this.message, [this.code]);

  @override
  String toString() => 'SynclibException: $message${code != null ? ' (code: $code)' : ''}';
}

/// Represents a change operation type
enum SynclibOperation {
  insert(synclibOpInsert),
  update(synclibOpUpdate),
  delete(synclibOpDelete);

  final int value;
  const SynclibOperation(this.value);

  static SynclibOperation fromValue(int value) {
    return SynclibOperation.values.firstWhere((e) => e.value == value);
  }
}

/// Represents a tracked database change
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

  @override
  String toString() =>
      'Change(seqnum: $seqnum, table: $tableName, rowId: $rowId, op: $operation)';
}

/// Merkle tree information for a table
class MerkleInfo {
  /// Hex-encoded SHA256 root hash
  final String rootHash;

  /// Number of blocks in the tree
  final int blockCount;

  /// Total number of rows
  final int rowCount;

  MerkleInfo({
    required this.rootHash,
    required this.blockCount,
    required this.rowCount,
  });

  @override
  String toString() =>
      'MerkleInfo(rootHash: ${rootHash.substring(0, 16)}..., blocks: $blockCount, rows: $rowCount)';
}

/// Main database interface for synclib
class SynclibDatabase {
  final SynclibBindings _bindings;
  Pointer<SynclibDb>? _db;
  final String _dbPath;

  /// Stream controller for local change notifications.
  /// Emits whenever a tracked write operation occurs.
  final StreamController<Change> _localChangeController =
      StreamController<Change>.broadcast();

  /// Stream of local changes as they occur.
  /// Subscribe to this to be notified immediately when writes happen.
  Stream<Change> get localChanges => _localChangeController.stream;

  SynclibDatabase._(this._bindings, this._dbPath);

  /// Open a database connection
  static Future<SynclibDatabase> open(String dbPath) async {
    final bindings = _loadBindings();
    final db = SynclibDatabase._(bindings, dbPath);
    await db._open();
    return db;
  }

  /// Load the native library based on platform
  static SynclibBindings _loadBindings() {
    final DynamicLibrary lib;

    if (Platform.isAndroid) {
      // Android: Load the synclib_flutter.so which contains the static libsynclib.a
      lib = DynamicLibrary.open('libsynclib_flutter.so');
    } else if (Platform.isIOS || Platform.isMacOS) {
      // iOS/macOS: Use process() since the static library is linked into the app
      lib = DynamicLibrary.process();
    } else if (Platform.isLinux) {
      lib = DynamicLibrary.open('libsynclib.so');
    } else if (Platform.isWindows) {
      lib = DynamicLibrary.open('synclib.dll');
    } else {
      throw UnsupportedError('Platform not supported');
    }

    return SynclibBindings(lib);
  }

  Future<void> _open() async {
    final pathPtr = _dbPath.toNativeUtf8();
    final dbPtr = calloc<Pointer<SynclibDb>>();

    try {
      final result = _bindings.open(pathPtr, dbPtr);
      if (result != synclibOk) {
        throw SynclibException('Failed to open database: $_dbPath', result);
      }
      _db = dbPtr.value;
    } finally {
      calloc.free(pathPtr);
      calloc.free(dbPtr);
    }
  }

  void _ensureOpen() {
    if (_db == null) {
      throw SynclibException('Database is not open');
    }
  }

  String _getLastError() {
    if (_db == null) return 'Database not open';
    final errorPtr = _bindings.getError(_db!);
    return errorPtr.toDartString();
  }

  /// Execute a write operation (INSERT, UPDATE, DELETE) with change tracking
  Future<void> write({
    required String tableName,
    required String rowId,
    required SynclibOperation operation,
    required String sql,
    String? data,
  }) async {
    _ensureOpen();

    final tablePtr = tableName.toNativeUtf8();
    final rowIdPtr = rowId.toNativeUtf8();
    final sqlPtr = sql.toNativeUtf8();
    final dataPtr = data != null ? data.toNativeUtf8() : nullptr;

    try {
      final result = _bindings.write(
        _db!,
        tablePtr,
        rowIdPtr,
        operation.value,
        sqlPtr,
        dataPtr,
      );

      if (result != synclibOk) {
        throw SynclibException('Write failed: ${_getLastError()}', result);
      }

      // Notify listeners of the local change
      _localChangeController.add(Change(
        seqnum: 0, // Actual seqnum assigned by C layer, not known here
        tableName: tableName,
        rowId: rowId,
        operation: operation,
        data: data,
      ));
    } finally {
      calloc.free(tablePtr);
      calloc.free(rowIdPtr);
      calloc.free(sqlPtr);
      if (dataPtr != nullptr) {
        calloc.free(dataPtr);
      }
    }
  }

  /// Execute a write operation with parameterized query (INSERT, UPDATE, DELETE)
  /// Supports ? placeholders in SQL for safe parameter binding
  ///
  /// Example for JSONB:
  /// ```dart
  /// await db.writeWithParams(
  ///   tableName: 'users',
  ///   rowId: userId,
  ///   operation: SynclibOperation.update,
  ///   sql: 'UPDATE users SET document = jsonb(?), name = ? WHERE id = ?',
  ///   params: [jsonString, 'John Doe', userId],
  ///   data: jsonString,
  /// );
  /// ```
  /// Write with parameterized query (for JSONB support)
  ///
  /// Supports String, int, double, and Uint8List parameters:
  /// - String: Bound with sqlite3_bind_text
  /// - int/double: Converted to string and bound with sqlite3_bind_text
  /// - Uint8List: Bound with sqlite3_bind_blob (for JSONB binary data)
  Future<void> writeWithParams({
    required String tableName,
    required String rowId,
    required SynclibOperation operation,
    required String sql,
    required List<dynamic> params, // Can be String?, int, double, Uint8List, or null
    String? data,
  }) async {
    _ensureOpen();

    final tablePtr = tableName.toNativeUtf8();
    final rowIdPtr = rowId.toNativeUtf8();
    final sqlPtr = sql.toNativeUtf8();
    final dataPtr = data != null ? data.toNativeUtf8() : nullptr;

    // Allocate arrays for both string and blob parameters
    final paramsPtr = calloc<Pointer<Utf8>>(params.length);
    final blobsPtr = calloc<Pointer<Uint8>>(params.length);
    final blobSizesPtr = calloc<Int32>(params.length);
    final paramTypesPtr = calloc<Int32>(params.length); // 0=null, 1=text, 2=blob

    final paramPtrs = <Pointer<Utf8>>[];
    final blobPtrs = <Pointer<Uint8>>[];

    try {
      // Convert each parameter to native format
      for (int i = 0; i < params.length; i++) {
        final param = params[i];

        if (param == null) {
          paramTypesPtr[i] = 0; // NULL
          paramsPtr[i] = nullptr;
          blobsPtr[i] = nullptr;
          blobSizesPtr[i] = 0;
        } else if (param is Uint8List) {
          paramTypesPtr[i] = 2; // BLOB
          paramsPtr[i] = nullptr;

          // Allocate native memory for blob
          final blobPtr = calloc<Uint8>(param.length);
          blobPtrs.add(blobPtr);

          // Copy bytes to native memory
          for (int j = 0; j < param.length; j++) {
            blobPtr[j] = param[j];
          }

          blobsPtr[i] = blobPtr;
          blobSizesPtr[i] = param.length;
        } else if (param is String) {
          paramTypesPtr[i] = 1; // TEXT
          final paramPtr = param.toNativeUtf8();
          paramPtrs.add(paramPtr);
          paramsPtr[i] = paramPtr;
          blobsPtr[i] = nullptr;
          blobSizesPtr[i] = 0;
        } else if (param is int || param is double) {
          // Convert numbers to string for TEXT binding (SQLite will coerce to INTEGER/REAL)
          paramTypesPtr[i] = 1; // TEXT
          final paramPtr = param.toString().toNativeUtf8();
          paramPtrs.add(paramPtr);
          paramsPtr[i] = paramPtr;
          blobsPtr[i] = nullptr;
          blobSizesPtr[i] = 0;
        } else {
          throw ArgumentError('Parameter at index $i must be String, int, double, Uint8List, or null');
        }
      }

      final result = _bindings.writeParamsTyped(
        _db!,
        tablePtr,
        rowIdPtr,
        operation.value,
        sqlPtr,
        paramsPtr,
        blobsPtr,
        blobSizesPtr,
        paramTypesPtr,
        params.length,
        dataPtr,
      );

      if (result != synclibOk) {
        throw SynclibException('Write with params failed: ${_getLastError()}', result);
      }

      // Notify listeners of the local change
      _localChangeController.add(Change(
        seqnum: 0, // Actual seqnum assigned by C layer, not known here
        tableName: tableName,
        rowId: rowId,
        operation: operation,
        data: data,
      ));
    } finally {
      calloc.free(tablePtr);
      calloc.free(rowIdPtr);
      calloc.free(sqlPtr);
      if (dataPtr != nullptr) {
        calloc.free(dataPtr);
      }

      // Free all parameter strings
      for (final paramPtr in paramPtrs) {
        calloc.free(paramPtr);
      }

      // Free all blob data
      for (final blobPtr in blobPtrs) {
        calloc.free(blobPtr);
      }

      calloc.free(paramsPtr);
      calloc.free(blobsPtr);
      calloc.free(blobSizesPtr);
      calloc.free(paramTypesPtr);
    }
  }

  /// Execute SQL without change tracking (for DDL, setup, etc.)
  Future<void> exec(String sql) async {
    _ensureOpen();

    final sqlPtr = sql.toNativeUtf8();
    try {
      final result = _bindings.exec(_db!, sqlPtr);
      if (result != synclibOk) {
        throw SynclibException('Exec failed: ${_getLastError()}', result);
      }
    } finally {
      calloc.free(sqlPtr);
    }
  }

  /// Get current schema version
  Future<int> getSchemaVersion() async {
    _ensureOpen();

    final versionPtr = calloc<Int32>();
    try {
      final result = _bindings.getSchemaVersion(_db!, versionPtr);
      if (result != synclibOk) {
        throw SynclibException(
            'Failed to get schema version: ${_getLastError()}', result);
      }
      return versionPtr.value;
    } finally {
      calloc.free(versionPtr);
    }
  }

  /// Set schema version
  Future<void> setSchemaVersion(int version) async {
    _ensureOpen();

    final result = _bindings.setSchemaVersion(_db!, version);
    if (result != synclibOk) {
      throw SynclibException(
          'Failed to set schema version: ${_getLastError()}', result);
    }
  }

  /// Skip local row_hash computation (server-authoritative mode)
  Future<void> skipLocalHash(bool skip) async {
    _ensureOpen();

    final result = _bindings.setSkipLocalHash(_db!, skip ? 1 : 0);
    if (result != synclibOk) {
      throw SynclibException(
          'Failed to set skip local hash: ${_getLastError()}', result);
    }
  }

  /// Get pending changes that need to be synced
  Future<List<Change>> getPendingChanges({int limit = 100}) async {
    _ensureOpen();

    final changesPtr = calloc<Pointer<SynclibChange>>();
    final countPtr = calloc<Int32>();

    try {
      final result =
          _bindings.getPendingChanges(_db!, changesPtr, countPtr, limit);

      if (result == synclibNoMoreChanges) {
        return [];
      }

      if (result != synclibOk) {
        throw SynclibException(
            'Failed to get pending changes: ${_getLastError()}', result);
      }

      final count = countPtr.value;
      final changes = <Change>[];

      for (var i = 0; i < count; i++) {
        final change = changesPtr.value.elementAt(i).ref;
        changes.add(Change(
          seqnum: change.seqnum,
          tableName: change.tableName.toDartString(),
          rowId: change.rowId.toDartString(),
          operation: SynclibOperation.fromValue(change.operation),
          data: change.data != nullptr ? change.data.toDartString() : null,
        ));
      }

      _bindings.freeChanges(changesPtr.value, count);
      return changes;
    } finally {
      calloc.free(changesPtr);
      calloc.free(countPtr);
    }
  }

  /// Mark changes as synced up to the given sequence number
  Future<void> markSynced(int seqnum) async {
    _ensureOpen();

    final result = _bindings.markSynced(_db!, seqnum);
    if (result != synclibOk) {
      throw SynclibException('Failed to mark synced: ${_getLastError()}', result);
    }
  }

  /// Delete a specific change by sequence number
  /// Use this for precise cleanup after server acknowledgment
  Future<void> deleteChange(int seqnum) async {
    _ensureOpen();

    final result = _bindings.deleteChange(_db!, seqnum);
    if (result != synclibOk) {
      throw SynclibException('Failed to delete change: ${_getLastError()}', result);
    }
  }

  /// Apply a remote change from another client/server
  Future<void> applyRemote({
    required String tableName,
    required String rowId,
    required SynclibOperation operation,
    required String sql,
    String? data,
  }) async {
    _ensureOpen();

    final tablePtr = tableName.toNativeUtf8();
    final rowIdPtr = rowId.toNativeUtf8();
    final sqlPtr = sql.toNativeUtf8();
    final dataPtr = data != null ? data.toNativeUtf8() : nullptr;

    try {
      final result = _bindings.applyRemote(
        _db!,
        tablePtr,
        rowIdPtr,
        operation.value,
        sqlPtr,
        dataPtr,
      );

      if (result != synclibOk) {
        throw SynclibException('Apply remote failed: ${_getLastError()}', result);
      }
    } finally {
      calloc.free(tablePtr);
      calloc.free(rowIdPtr);
      calloc.free(sqlPtr);
      if (dataPtr != nullptr) {
        calloc.free(dataPtr);
      }
    }
  }

  /// Apply a remote change with parameterized query (for JSONB support)
  ///
  /// Supports String, int, double, and Uint8List parameters:
  /// - String: Bound with sqlite3_bind_text
  /// - int/double: Converted to string and bound with sqlite3_bind_text
  /// - Uint8List: Bound with sqlite3_bind_blob (for JSONB binary data)
  Future<void> applyRemoteWithParams({
    required String tableName,
    required String rowId,
    required SynclibOperation operation,
    required String sql,
    required List<dynamic> params, // Can be String?, int, double, Uint8List, or null
    String? data,
  }) async {
    _ensureOpen();

    final tablePtr = tableName.toNativeUtf8();
    final rowIdPtr = rowId.toNativeUtf8();
    final sqlPtr = sql.toNativeUtf8();
    final dataPtr = data != null ? data.toNativeUtf8() : nullptr;

    // Allocate arrays for both string and blob parameters
    final paramsPtr = calloc<Pointer<Utf8>>(params.length);
    final blobsPtr = calloc<Pointer<Uint8>>(params.length);
    final blobSizesPtr = calloc<Int32>(params.length);
    final paramTypesPtr = calloc<Int32>(params.length); // 0=null, 1=text, 2=blob

    final paramPtrs = <Pointer<Utf8>>[];
    final blobPtrs = <Pointer<Uint8>>[];

    try {
      // Convert each parameter to native format
      for (int i = 0; i < params.length; i++) {
        final param = params[i];

        if (param == null) {
          paramTypesPtr[i] = 0; // NULL
          paramsPtr[i] = nullptr;
          blobsPtr[i] = nullptr;
          blobSizesPtr[i] = 0;
        } else if (param is Uint8List) {
          paramTypesPtr[i] = 2; // BLOB
          paramsPtr[i] = nullptr;

          // Allocate native memory for blob
          final blobPtr = calloc<Uint8>(param.length);
          blobPtrs.add(blobPtr);

          // Copy bytes to native memory
          for (int j = 0; j < param.length; j++) {
            blobPtr[j] = param[j];
          }

          blobsPtr[i] = blobPtr;
          blobSizesPtr[i] = param.length;
        } else if (param is String) {
          paramTypesPtr[i] = 1; // TEXT
          final paramPtr = param.toNativeUtf8();
          paramPtrs.add(paramPtr);
          paramsPtr[i] = paramPtr;
          blobsPtr[i] = nullptr;
          blobSizesPtr[i] = 0;
        } else if (param is int || param is double) {
          // Convert numbers to string for TEXT binding (SQLite will coerce to INTEGER/REAL)
          paramTypesPtr[i] = 1; // TEXT
          final paramPtr = param.toString().toNativeUtf8();
          paramPtrs.add(paramPtr);
          paramsPtr[i] = paramPtr;
          blobsPtr[i] = nullptr;
          blobSizesPtr[i] = 0;
        } else {
          throw ArgumentError('Parameter at index $i must be String, int, double, Uint8List, or null');
        }
      }

      final result = _bindings.applyRemoteParamsTyped(
        _db!,
        tablePtr,
        rowIdPtr,
        operation.value,
        sqlPtr,
        paramsPtr,
        blobsPtr,
        blobSizesPtr,
        paramTypesPtr,
        params.length,
        dataPtr,
      );

      if (result != synclibOk) {
        throw SynclibException('Apply remote with params failed: ${_getLastError()}', result);
      }
    } finally {
      calloc.free(tablePtr);
      calloc.free(rowIdPtr);
      calloc.free(sqlPtr);
      if (dataPtr != nullptr) {
        calloc.free(dataPtr);
      }

      // Free all parameter strings
      for (final paramPtr in paramPtrs) {
        calloc.free(paramPtr);
      }

      // Free all blob data
      for (final blobPtr in blobPtrs) {
        calloc.free(blobPtr);
      }

      calloc.free(paramsPtr);
      calloc.free(blobsPtr);
      calloc.free(blobSizesPtr);
      calloc.free(paramTypesPtr);
    }
  }

  /// Begin bulk remote operation mode for efficient batch imports
  Future<void> beginBulkRemote() async {
    _ensureOpen();

    final result = _bindings.beginBulkRemote(_db!);
    if (result != synclibOk) {
      throw SynclibException(
          'Failed to begin bulk remote: ${_getLastError()}', result);
    }
  }

  /// Execute SQL in bulk remote mode
  Future<void> execBulkRemote(String sql) async {
    _ensureOpen();

    final sqlPtr = sql.toNativeUtf8();
    try {
      final result = _bindings.execBulkRemote(_db!, sqlPtr);
      if (result != synclibOk) {
        throw SynclibException(
            'Bulk remote exec failed: ${_getLastError()}', result);
      }
    } finally {
      calloc.free(sqlPtr);
    }
  }

  /// End bulk remote operation mode
  Future<void> endBulkRemote({bool rollback = false}) async {
    _ensureOpen();

    final result = _bindings.endBulkRemote(_db!, rollback ? 1 : 0);
    if (result != synclibOk) {
      throw SynclibException(
          'Failed to end bulk remote: ${_getLastError()}', result);
    }
  }

  /// Recompute and store row_hash for a single row after bulk writes
  Future<void> updateRowHash(String tableName, String rowId) async {
    _ensureOpen();

    final tablePtr = tableName.toNativeUtf8();
    final rowIdPtr = rowId.toNativeUtf8();
    try {
      _bindings.updateRowHash(_db!, tablePtr, rowIdPtr);
    } finally {
      calloc.free(tablePtr);
      calloc.free(rowIdPtr);
    }
  }

  /// Backfill row_hash for all rows with NULL row_hash in a table.
  /// Idempotent: no-op if all rows already have hashes.
  Future<void> backfillRowHashes(String tableName) async {
    _ensureOpen();

    final tablePtr = tableName.toNativeUtf8();
    try {
      _bindings.backfillRowHashes(_db!, tablePtr);
    } finally {
      calloc.free(tablePtr);
    }
  }

  /// Configure which columns are included in row_hash for a table.
  /// When set, only id + the named columns are hashed (whitelist mode).
  /// If config changes, existing row_hash values are invalidated.
  Future<void> setHashColumns(String tableName, String columnsJson) async {
    _ensureOpen();

    final tablePtr = tableName.toNativeUtf8();
    final jsonPtr = columnsJson.toNativeUtf8();
    try {
      final rc = _bindings.setHashColumns(_db!, tablePtr, jsonPtr);
      if (rc != synclibOk) {
        throw SynclibException('setHashColumns failed for $tableName');
      }
    } finally {
      calloc.free(tablePtr);
      calloc.free(jsonPtr);
    }
  }

  /// Extract a row as JSON
  Future<String> rowToJson(String tableName, String rowId) async {
    _ensureOpen();

    final tablePtr = tableName.toNativeUtf8();
    final rowIdPtr = rowId.toNativeUtf8();
    final jsonOutPtr = calloc<Pointer<Utf8>>();

    try {
      final result = _bindings.rowToJson(_db!, tablePtr, rowIdPtr, jsonOutPtr);
      if (result != synclibOk) {
        throw SynclibException('Row to JSON failed: ${_getLastError()}', result);
      }

      final json = jsonOutPtr.value.toDartString();
      // Note: In real implementation, you'd need to free the returned string
      // This would require a synclib_free_string function in the C API
      return json;
    } finally {
      calloc.free(tablePtr);
      calloc.free(rowIdPtr);
      calloc.free(jsonOutPtr);
    }
  }

  // ============================================================================
  // Merkle Tree Methods
  // ============================================================================

  /// Compute SHA256 hash of a single row
  ///
  /// Hash is computed as: SHA256(row_id || '|' || sorted_json(row_data))
  /// This ensures consistent hashing across platforms.
  Future<String> rowHash(String tableName, String rowId) async {
    _ensureOpen();

    final tablePtr = tableName.toNativeUtf8();
    final rowIdPtr = rowId.toNativeUtf8();
    final hashOutPtr = calloc<Pointer<Utf8>>();

    try {
      final result = _bindings.rowHash(_db!, tablePtr, rowIdPtr, hashOutPtr);
      if (result != synclibOk) {
        throw SynclibException('Row hash failed: ${_getLastError()}', result);
      }

      final hash = hashOutPtr.value.toDartString();
      // Free the returned string
      calloc.free(hashOutPtr.value);
      return hash;
    } finally {
      calloc.free(tablePtr);
      calloc.free(rowIdPtr);
      calloc.free(hashOutPtr);
    }
  }

  /// Compute SHA256 hash of a block of rows
  ///
  /// Returns a tuple of (hash, rowCount) where rowCount is the actual
  /// number of rows in the block.
  Future<(String hash, int rowCount)> blockHash(
    String tableName,
    int blockIndex, {
    int blockSize = synclibDefaultBlockSize,
  }) async {
    _ensureOpen();

    final tablePtr = tableName.toNativeUtf8();
    final hashOutPtr = calloc<Pointer<Utf8>>();
    final rowCountPtr = calloc<Int32>();

    try {
      final result = _bindings.blockHash(
        _db!,
        tablePtr,
        blockIndex,
        blockSize,
        hashOutPtr,
        rowCountPtr,
      );

      if (result != synclibOk) {
        throw SynclibException('Block hash failed: ${_getLastError()}', result);
      }

      final hash = hashOutPtr.value.toDartString();
      final rowCount = rowCountPtr.value;

      // Free the returned string
      calloc.free(hashOutPtr.value);

      return (hash, rowCount);
    } finally {
      calloc.free(tablePtr);
      calloc.free(hashOutPtr);
      calloc.free(rowCountPtr);
    }
  }

  /// Compute Merkle root hash for a table
  ///
  /// Returns [MerkleInfo] containing the root hash, block count, and row count.
  Future<MerkleInfo> merkleRoot(
    String tableName, {
    int blockSize = synclibDefaultBlockSize,
  }) async {
    _ensureOpen();

    final tablePtr = tableName.toNativeUtf8();
    final infoPtr = calloc<SynclibMerkleInfo>();

    try {
      final result = _bindings.merkleRoot(_db!, tablePtr, blockSize, infoPtr);

      if (result != synclibOk) {
        throw SynclibException('Merkle root failed: ${_getLastError()}', result);
      }

      final info = infoPtr.ref;
      final rootHash = info.rootHash.toDartString();
      final blockCount = info.blockCount;
      final rowCount = info.rowCount;

      // Free the root_hash string inside the struct
      _bindings.freeMerkleInfo(infoPtr);

      return MerkleInfo(
        rootHash: rootHash,
        blockCount: blockCount,
        rowCount: rowCount,
      );
    } finally {
      calloc.free(tablePtr);
      calloc.free(infoPtr);
    }
  }

  /// Get all block hashes for a table
  ///
  /// Returns a list of hex-encoded block hashes in order.
  /// Useful for comparing block-by-block with server.
  Future<List<String>> merkleBlockHashes(
    String tableName, {
    int blockSize = synclibDefaultBlockSize,
  }) async {
    _ensureOpen();

    final tablePtr = tableName.toNativeUtf8();
    final hashesOutPtr = calloc<Pointer<Pointer<Utf8>>>();
    final countPtr = calloc<Int32>();

    try {
      final result = _bindings.merkleBlockHashes(
        _db!,
        tablePtr,
        blockSize,
        hashesOutPtr,
        countPtr,
      );

      if (result != synclibOk) {
        throw SynclibException('Merkle block hashes failed: ${_getLastError()}', result);
      }

      final count = countPtr.value;
      if (count == 0) {
        return [];
      }

      final hashes = <String>[];
      final hashesPtr = hashesOutPtr.value;

      for (int i = 0; i < count; i++) {
        hashes.add(hashesPtr[i].toDartString());
      }

      // Free the string array
      _bindings.freeStringArray(hashesPtr, count);

      return hashes;
    } finally {
      calloc.free(tablePtr);
      calloc.free(hashesOutPtr);
      calloc.free(countPtr);
    }
  }

  /// Get row IDs in a specific block
  ///
  /// Returns the row IDs (ordered by id) that belong to a given block.
  /// Useful for fetching specific block data after detecting a mismatch.
  Future<List<String>> getBlockRowIds(
    String tableName,
    int blockIndex, {
    int blockSize = synclibDefaultBlockSize,
  }) async {
    _ensureOpen();

    final tablePtr = tableName.toNativeUtf8();
    final rowIdsOutPtr = calloc<Pointer<Pointer<Utf8>>>();
    final countPtr = calloc<Int32>();

    try {
      final result = _bindings.getBlockRowIds(
        _db!,
        tablePtr,
        blockIndex,
        blockSize,
        rowIdsOutPtr,
        countPtr,
      );

      if (result != synclibOk) {
        throw SynclibException('Get block row IDs failed: ${_getLastError()}', result);
      }

      final count = countPtr.value;
      if (count == 0) {
        return [];
      }

      final rowIds = <String>[];
      final rowIdsPtr = rowIdsOutPtr.value;

      for (int i = 0; i < count; i++) {
        rowIds.add(rowIdsPtr[i].toDartString());
      }

      // Free the string array
      _bindings.freeStringArray(rowIdsPtr, count);

      return rowIds;
    } finally {
      calloc.free(tablePtr);
      calloc.free(rowIdsOutPtr);
      calloc.free(countPtr);
    }
  }

  /// Get the canonical sorted JSON for a specific row (debug helper)
  ///
  /// Returns the exact JSON string that would be hashed for merkle verification.
  /// Useful for comparing with server-side JSON to debug hash mismatches.
  Future<String> rowJson(String tableName, String rowId) async {
    _ensureOpen();

    final tablePtr = tableName.toNativeUtf8();
    final rowIdPtr = rowId.toNativeUtf8();
    final jsonOutPtr = calloc<Pointer<Utf8>>();

    try {
      final result = _bindings.rowJson(_db!, tablePtr, rowIdPtr, jsonOutPtr);

      if (result != synclibOk) {
        throw SynclibException('Row JSON failed: ${_getLastError()}', result);
      }

      final json = jsonOutPtr.value.toDartString();

      // Free the json string (allocated by C library)
      calloc.free(jsonOutPtr.value);

      return json;
    } finally {
      calloc.free(tablePtr);
      calloc.free(rowIdPtr);
      calloc.free(jsonOutPtr);
    }
  }

  /// Execute a read-only query and return results as a list of maps
  ///
  /// This is the simple string-based version. Use this when you wrap BLOB columns
  /// with json() in your SQL, or when you don't need BLOB support.
  ///
  /// Note: BLOB columns cannot be read with this method. Use readRaw() instead,
  /// or wrap BLOB columns with json() in your SQL query.
  ///
  /// Example:
  /// ```dart
  /// // Works great with json() wrapper
  /// final results = await db.read('SELECT id, json(document) as document FROM users');
  /// for (final row in results) {
  ///   final docString = row['document'] as String;
  ///   final doc = jsonDecode(docString);
  /// }
  /// ```
  Future<List<Map<String, dynamic>>> read(String sql) async {
    _ensureOpen();

    // Clear the global pending results before executing
    _pendingResults.clear();

    final sqlPtr = sql.toNativeUtf8();
    final callbackPtr = Pointer.fromFunction<SynclibReadCallbackNative>(_readCallback, 1);

    try {
      final result = _bindings.read(_db!, sqlPtr, callbackPtr, nullptr);
      if (result != synclibOk) {
        throw SynclibException('Read failed: ${_getLastError()}', result);
      }

      // Return a copy of the results and clear the global storage
      final results = List<Map<String, dynamic>>.from(_pendingResults);
      _pendingResults.clear();
      return results;
    } finally {
      calloc.free(sqlPtr);
    }
  }

  /// Execute a read-only query with full type support including BLOBs
  ///
  /// This method properly handles all SQLite types including BLOBs.
  /// BLOB columns are returned as Uint8List.
  ///
  /// Use this when you need to read BLOB/JSONB columns directly without
  /// wrapping them with json() in your SQL.
  ///
  /// Example:
  /// ```dart
  /// // Reads BLOB columns directly
  /// final results = await db.readRaw('SELECT id, document FROM users');
  /// for (final row in results) {
  ///   final documentBlob = row['document'] as Uint8List;
  ///   final doc = jsonb.decode(documentBlob);  // Decode JSONB
  /// }
  /// ```
  Future<List<Map<String, dynamic>>> readRaw(String sql) async {
    _ensureOpen();

    // Clear the global pending results before executing
    _pendingResults.clear();

    final sqlPtr = sql.toNativeUtf8();
    final callbackPtr = Pointer.fromFunction<SynclibReadRawCallbackNative>(_readRawCallback, 1);

    try {
      final result = _bindings.readRaw(_db!, sqlPtr, callbackPtr, nullptr);
      if (result != synclibOk) {
        throw SynclibException('Read failed: ${_getLastError()}', result);
      }

      // Return a copy of the results and clear the global storage
      final results = List<Map<String, dynamic>>.from(_pendingResults);
      _pendingResults.clear();
      return results;
    } finally {
      calloc.free(sqlPtr);
    }
  }

  /// Close the database connection
  Future<void> close() async {
    if (_db != null) {
      _bindings.close(_db!);
      _db = null;
    }
    await _localChangeController.close();
  }

  /// Check if database is open
  bool get isOpen => _db != null;

  static int _readCallback(Pointer<Void> userData, int argc, Pointer<Pointer<Utf8>> argv, Pointer<Pointer<Utf8>> colNames) {
    try {
      final row = <String, dynamic>{};

      for (int i = 0; i < argc; i++) {
        final colName = colNames[i].toDartString();
        final valuePtr = argv[i];

        // NULL values have null pointers
        if (valuePtr.address == 0) {
          row[colName] = null;
        } else {
          try {
            final value = valuePtr.toDartString();
            // Try to parse as number if possible
            final intValue = int.tryParse(value);
            if (intValue != null) {
              row[colName] = intValue;
            } else {
              final doubleValue = double.tryParse(value);
              if (doubleValue != null) {
                row[colName] = doubleValue;
              } else {
                row[colName] = value;
              }
            }
          } catch (e) {
            // Handle UTF-8 decode errors (e.g., JSONB binary data)
            // This happens when trying to read JSONB columns without json() wrapper
            // Use readRaw() for queries that need to handle BLOB/JSONB data,
            // or wrap JSONB columns with json() in your SQL query
            print('Warning: Column $colName contains binary data that cannot be read as text. '
                  'Use json(column_name) in your SQL query or use readRaw() instead.');
            row[colName] = null;
          }
        }
      }

      // Store in global map temporarily
      _pendingResults.add(row);
      return 0; // Continue iteration
    } catch (e) {
      // Don't abort query on error
      print('Error in read callback: $e');
      return 0;
    }
  }

  static int _readRawCallback(Pointer<Void> userData, int colCount, Pointer<Pointer<Utf8>> colNames, Pointer<SynclibColumnValue> values) {
    try {
      final row = <String, dynamic>{};

      for (int i = 0; i < colCount; i++) {
        final colName = colNames[i].toDartString();
        final value = values.elementAt(i).ref;

        switch (value.type) {
          case sqliteInteger:
            row[colName] = value.intValue;
            break;

          case sqliteFloat:
            row[colName] = value.floatValue;
            break;

          case sqliteText:
            if (value.textValue.address != 0) {
              row[colName] = value.textValue.toDartString();
            } else {
              row[colName] = null;
            }
            break;

          case sqliteBlob:
            if (value.blobValue.address != 0 && value.blobSize > 0) {
              // Copy BLOB data to Dart Uint8List
              final blobPtr = value.blobValue.cast<Uint8>();
              final bytes = Uint8List(value.blobSize);
              for (int j = 0; j < value.blobSize; j++) {
                bytes[j] = blobPtr[j];
              }
              row[colName] = bytes;
            } else {
              row[colName] = null;
            }
            break;

          case sqliteNull:
          default:
            row[colName] = null;
            break;
        }
      }

      // Store in global map temporarily
      _pendingResults.add(row);
      return 0; // Continue iteration
    } catch (e) {
      // Don't abort query on error - log and continue
      print('Error in read callback: $e');
      return 0;
    }
  }
}

// Global storage for pending results (workaround for FFI callback limitations)
final _pendingResults = <Map<String, dynamic>>[];
