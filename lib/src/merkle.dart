/// Merkle tree implementation for sync integrity verification.
///
/// On web platforms, uses WASM (synclib_hash) when initialized for
/// cross-platform consistency with C, Elixir, and TypeScript.
/// Falls back to pure Dart implementation if WASM is not initialized.
///
/// On native platforms (iOS, Android, macOS), use FFI bindings to synclibc
/// which internally uses the same C hash library.
///
/// Hash format:
/// - Row hash: SHA256(row_id + "|" + sorted_json(row_data)) -> lowercase hex
/// - Block hash: SHA256(concat of row hash hex strings) -> lowercase hex
/// - Merkle root: Binary tree of block hashes, odd node passed up as-is

import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'synclib_hash_web.dart'
    if (dart.library.io) 'synclib_hash_stub.dart';

/// Default number of rows per block for Merkle tree computation
const int defaultBlockSize = 100;

/// Merkle tree info for a table
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
      'MerkleInfo(rootHash: ${rootHash.isEmpty ? "(empty)" : "${rootHash.substring(0, 16)}..."}, blocks: $blockCount, rows: $rowCount)';
}

/// Block hash result with row count
class BlockHashResult {
  final String hash;
  final int rowCount;

  BlockHashResult({required this.hash, required this.rowCount});
}

/// Abstract interface for database queries.
/// Implement this to connect MerkleComputer to your database.
abstract class MerkleDatabase {
  /// Execute a read query and return results as maps
  Future<List<Map<String, dynamic>>> read(String sql);
}

/// MerkleComputer - Computes Merkle tree hashes for database tables
///
/// This class provides methods to compute row hashes, block hashes,
/// and Merkle roots for efficient sync integrity checking.
///
/// Uses WASM (synclib_hash) on web when initialized, otherwise uses
/// pure Dart implementation which produces identical results.
class MerkleComputer {
  final MerkleDatabase _db;

  /// Columns that store JSONB binary data and need json() wrapper in queries.
  /// These are converted to text JSON before hashing for cross-platform consistency.
  final List<String> jsonbColumns;

  /// Columns to exclude from SELECT and hash computation entirely.
  /// row_hash: avoid circular dependency (hash including itself).
  /// Array columns (e.g. triballeaders, subscribedto, participants): server
  /// skips {:array, _} fields via is_array_field?, client must match.
  final List<String> skipColumns;

  MerkleComputer(this._db, {
    this.jsonbColumns = const ['document'],
    this.skipColumns = const ['row_hash'],
  });

  /// Check if WASM is available and should be used
  bool get _useWasm => isWasmInitialized;

  /// Build a SELECT clause that wraps JSONB columns with json() for text output
  /// and skips columns in [skipColumns] (infrastructure + array columns).
  Future<String> _buildSelectClause(String tableName) async {
    final pragmaResult = await _db.read('PRAGMA table_info($tableName)');
    if (pragmaResult.isEmpty) {
      return 'SELECT * FROM $tableName';
    }

    final columns = pragmaResult
        .map((row) {
          final colName = row['name'] as String;
          if (skipColumns.contains(colName)) return null;
          if (jsonbColumns.contains(colName)) {
            return 'json($colName) as $colName';
          }
          return colName;
        })
        .where((c) => c != null)
        .join(', ');

    return 'SELECT $columns FROM $tableName';
  }

  /// Pre-process a row map to parse JSONB string columns into proper maps.
  Map<String, dynamic> _parseJsonbColumns(Map<String, dynamic> row) {
    if (jsonbColumns.isEmpty) {
      return row;
    }

    final result = Map<String, dynamic>.from(row);
    for (final col in jsonbColumns) {
      final value = result[col];
      if (value is String && value.isNotEmpty) {
        try {
          result[col] = jsonDecode(value);
        } catch (e) {
          // If parsing fails, leave as-is
        }
      }
    }
    return result;
  }

  // ==========================================================================
  // Pure Dart hash functions (fallback when WASM not available)
  // ==========================================================================

  /// Compute SHA256 hash and return as lowercase hex string
  String _sha256Hex(String data) {
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Escape a string for JSON
  String _escapeJsonString(String str) {
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      final ch = str[i];
      switch (ch) {
        case '"':
          buffer.write('\\"');
          break;
        case '\\':
          buffer.write('\\\\');
          break;
        case '\b':
          buffer.write('\\b');
          break;
        case '\f':
          buffer.write('\\f');
          break;
        case '\n':
          buffer.write('\\n');
          break;
        case '\r':
          buffer.write('\\r');
          break;
        case '\t':
          buffer.write('\\t');
          break;
        default:
          final code = ch.codeUnitAt(0);
          if (code < 32) {
            buffer.write('\\u${code.toRadixString(16).padLeft(4, '0')}');
          } else {
            buffer.write(ch);
          }
      }
    }
    return buffer.toString();
  }

  /// Encode a value for JSON with consistent formatting.
  String _encodeValue(dynamic value) {
    if (value == null) {
      return 'null';
    } else if (value is int) {
      return value.toString();
    } else if (value is double) {
      if (value == value.truncateToDouble()) {
        return value.toInt().toString();
      } else {
        return value.toString();
      }
    } else if (value is bool) {
      return value.toString();
    } else if (value is Map) {
      final sortedKeys = value.keys.map((k) => k.toString()).toList()..sort();
      final parts = <String>[];
      for (final key in sortedKeys) {
        final escapedKey = _escapeJsonString(key);
        final encodedVal = _encodeValue(value[key]);
        parts.add('"$escapedKey":$encodedVal');
      }
      return '{${parts.join(',')}}';
    } else if (value is List) {
      final encodedItems = value.map((item) => _encodeValue(item)).toList();
      return '[${encodedItems.join(',')}]';
    } else {
      final escapedValue = _escapeJsonString(value.toString());
      return '"$escapedValue"';
    }
  }

  /// Build Merkle root using pure Dart (fallback)
  String _buildMerkleRootDart(List<String> hashes) {
    if (hashes.isEmpty) return '';
    if (hashes.length == 1) return hashes.first;

    var currentLevel = List<String>.from(hashes);

    while (currentLevel.length > 1) {
      final nextLevel = <String>[];

      for (int i = 0; i < currentLevel.length; i += 2) {
        final left = currentLevel[i];

        if (i + 1 < currentLevel.length) {
          final right = currentLevel[i + 1];
          final combined = left + right;
          nextLevel.add(_sha256Hex(combined));
        } else {
          // Odd node - pass up as-is (NOT duplicated)
          nextLevel.add(left);
        }
      }

      currentLevel = nextLevel;
    }

    return currentLevel.first;
  }

  // ==========================================================================
  // Public API - uses WASM when available, otherwise pure Dart
  // ==========================================================================

  /// Build sorted JSON from a row map.
  /// Keys are sorted alphabetically. JSONB columns are skipped.
  /// Uses WASM on web for cross-platform consistency (SINGLE SOURCE OF TRUTH).
  String buildSortedJson(Map<String, dynamic> row) {
    if (_useWasm) {
      // Use WASM for cross-platform consistency
      final inputJson = jsonEncode(row);
      return wasmBuildSortedJsonFromJson(inputJson, jsonbColumns);
    }

    // Fallback to pure Dart for native platforms or when WASM not initialized
    return _buildSortedJsonDart(row);
  }

  /// Pure Dart implementation of sorted JSON building.
  /// Used on native platforms where FFI handles hashing.
  String _buildSortedJsonDart(Map<String, dynamic> row) {
    final sortedKeys = row.keys.toList()..sort();
    final parts = <String>[];

    for (final key in sortedKeys) {
      if (jsonbColumns.contains(key)) continue;
      if (skipColumns.contains(key)) continue;

      final value = row[key];
      final escapedKey = _escapeJsonString(key);
      final encodedValue = _encodeValue(value);
      parts.add('"$escapedKey":$encodedValue');
    }

    return '{${parts.join(',')}}';
  }

  /// Compute hash for a single row.
  ///
  /// Format: SHA256(row_id + "|" + sorted_json(row_data))
  Future<String> rowHash(
    String tableName,
    String rowId, {
    String primaryKeyColumn = 'id',
  }) async {
    final selectClause = await _buildSelectClause(tableName);
    final rows = await _db.read(
      "$selectClause WHERE $primaryKeyColumn = '$rowId'",
    );

    if (rows.isEmpty) {
      throw Exception('Row not found: $tableName.$rowId');
    }

    final row = _parseJsonbColumns(rows.first);
    final sortedJson = buildSortedJson(row);

    if (_useWasm) {
      return wasmRowHash(rowId, sortedJson);
    }

    final hashInput = '$rowId|$sortedJson';
    return _sha256Hex(hashInput);
  }

  /// Compute hash for a single row from its data map.
  String rowHashFromData(String rowId, Map<String, dynamic> row) {
    final sortedJson = buildSortedJson(row);

    if (_useWasm) {
      return wasmRowHash(rowId, sortedJson);
    }

    final hashInput = '$rowId|$sortedJson';
    return _sha256Hex(hashInput);
  }

  /// Compute hash for a block of rows.
  ///
  /// When [hashColumns] is null (default):
  ///   Fast path: reads precomputed row_hash values if available.
  ///   Slow path: loads full rows and computes hashes per row.
  ///
  /// When [hashColumns] is set:
  ///   SELECTs only id + hashColumns (very fast). Skips precomputed row_hash
  ///   since it includes all columns and wouldn't match the subset hash.
  ///
  /// Block hash: SHA256(concat of row hash hex strings)
  Future<BlockHashResult> blockHash(
    String tableName,
    int blockIndex, {
    int blockSize = defaultBlockSize,
    String primaryKeyColumn = 'id',
    List<String>? hashColumns,
    List<String>? scopedRowIds,
  }) async {
    final offset = blockIndex * blockSize;

    // Build optional WHERE clause for channel scoping.
    // When the server provides scoped row_ids, we only hash those rows
    // instead of ALL rows in the table (which may include rows from other channels).
    final scopeFilter = scopedRowIds != null
        ? "AND $primaryKeyColumn IN (${scopedRowIds.map((id) => "'$id'").join(',')})"
        : '';

    // Fast path: try precomputed row_hash values.
    // When synclib_set_hash_columns() has been called, the precomputed row_hash
    // uses the same column subset as the server, so fast path is valid.
    try {
      final precomputed = await _db.read(
        'SELECT row_hash FROM $tableName '
        'WHERE deleted_at IS NULL AND row_hash IS NOT NULL $scopeFilter '
        'ORDER BY $primaryKeyColumn LIMIT $blockSize OFFSET $offset',
      );

      if (precomputed.isNotEmpty) {
        final rowHashes = precomputed
            .map((r) => r['row_hash'] as String?)
            .where((h) => h != null && h.isNotEmpty)
            .cast<String>()
            .toList();

        if (rowHashes.length == precomputed.length) {
          // All rows have precomputed hashes
          String blockHashValue;
          if (_useWasm) {
            blockHashValue = wasmBlockHash(rowHashes);
          } else {
            blockHashValue = _sha256Hex(rowHashes.join(''));
          }
          return BlockHashResult(
              hash: blockHashValue, rowCount: rowHashes.length);
        }
      }
    } catch (_) {
      // Column might not exist yet - fall through to slow path
    }

    // Build SELECT: either specific hashColumns or full row
    String selectSql;
    if (hashColumns != null) {
      final cols = [primaryKeyColumn, ...hashColumns].join(', ');
      selectSql = 'SELECT $cols FROM $tableName';
    } else {
      selectSql = await _buildSelectClause(tableName);
    }

    final rows = await _db.read(
      '$selectSql WHERE deleted_at IS NULL $scopeFilter '
      'ORDER BY $primaryKeyColumn LIMIT $blockSize OFFSET $offset',
    );

    if (rows.isEmpty) {
      return BlockHashResult(hash: '', rowCount: 0);
    }

    // Compute hash for each row
    final rowHashes = <String>[];
    for (final rawRow in rows) {
      // When using hashColumns, no jsonb parsing needed (we selected simple columns)
      final row = hashColumns != null ? rawRow : _parseJsonbColumns(rawRow);
      final rowId = row[primaryKeyColumn].toString();
      final sortedJson = buildSortedJson(row);

      if (_useWasm) {
        rowHashes.add(wasmRowHash(rowId, sortedJson));
      } else {
        final hashInput = '$rowId|$sortedJson';
        rowHashes.add(_sha256Hex(hashInput));
      }
    }

    // Compute block hash
    String blockHashValue;
    if (_useWasm) {
      blockHashValue = wasmBlockHash(rowHashes);
    } else {
      blockHashValue = _sha256Hex(rowHashes.join(''));
    }

    return BlockHashResult(hash: blockHashValue, rowCount: rows.length);
  }

  /// Compute block hash from a list of row hashes.
  String blockHashFromRowHashes(List<String> rowHashes) {
    if (rowHashes.isEmpty) {
      return _useWasm ? wasmSha256Hex('') : _sha256Hex('');
    }

    if (_useWasm) {
      return wasmBlockHash(rowHashes);
    }

    return _sha256Hex(rowHashes.join(''));
  }

  /// Build Merkle root from an array of hashes.
  /// Odd nodes are passed up as-is (not duplicated).
  String buildMerkleRoot(List<String> hashes) {
    if (_useWasm) {
      return wasmMerkleRoot(hashes);
    }

    return _buildMerkleRootDart(hashes);
  }

  /// Compute Merkle root for a table.
  ///
  /// When [scopedRowIds] is provided, only those rows are included in the
  /// merkle computation. This is used when the server scopes a table to a
  /// subset of rows for a given channel (e.g. only the current user on a
  /// user channel, even though the client has other users from tribe channels).
  Future<MerkleInfo> merkleRoot(
    String tableName, {
    int blockSize = defaultBlockSize,
    String primaryKeyColumn = 'id',
    List<String>? hashColumns,
    List<String>? scopedRowIds,
  }) async {
    // When scoped, count only the scoped rows
    final String countSql;
    if (scopedRowIds != null) {
      final idList = scopedRowIds.map((id) => "'$id'").join(',');
      countSql = 'SELECT COUNT(*) as count FROM $tableName WHERE deleted_at IS NULL AND $primaryKeyColumn IN ($idList)';
    } else {
      countSql = 'SELECT COUNT(*) as count FROM $tableName WHERE deleted_at IS NULL';
    }

    final countResult = await _db.read(countSql);
    final rowCount = (countResult.first['count'] as int?) ?? 0;

    if (rowCount == 0) {
      final emptyHash = _useWasm ? wasmSha256Hex('') : _sha256Hex('');
      return MerkleInfo(rootHash: emptyHash, blockCount: 0, rowCount: 0);
    }

    final blockCount = (rowCount / blockSize).ceil();

    final blockHashes = <String>[];
    for (int i = 0; i < blockCount; i++) {
      final result = await blockHash(
        tableName,
        i,
        blockSize: blockSize,
        primaryKeyColumn: primaryKeyColumn,
        hashColumns: hashColumns,
        scopedRowIds: scopedRowIds,
      );
      blockHashes.add(result.hash);
    }

    final rootHash = buildMerkleRoot(blockHashes);

    return MerkleInfo(
      rootHash: rootHash,
      blockCount: blockCount,
      rowCount: rowCount,
    );
  }

  /// Get all block hashes for a table.
  Future<List<String>> merkleBlockHashes(
    String tableName, {
    int blockSize = defaultBlockSize,
    String primaryKeyColumn = 'id',
    List<String>? hashColumns,
    List<String>? scopedRowIds,
  }) async {
    final String countSql;
    if (scopedRowIds != null) {
      final idList = scopedRowIds.map((id) => "'$id'").join(',');
      countSql = 'SELECT COUNT(*) as count FROM $tableName WHERE deleted_at IS NULL AND $primaryKeyColumn IN ($idList)';
    } else {
      countSql = 'SELECT COUNT(*) as count FROM $tableName WHERE deleted_at IS NULL';
    }

    final countResult = await _db.read(countSql);
    final rowCount = (countResult.first['count'] as int?) ?? 0;

    if (rowCount == 0) return [];

    final blockCount = (rowCount / blockSize).ceil();

    final blockHashes = <String>[];
    for (int i = 0; i < blockCount; i++) {
      final result = await blockHash(
        tableName,
        i,
        blockSize: blockSize,
        primaryKeyColumn: primaryKeyColumn,
        hashColumns: hashColumns,
        scopedRowIds: scopedRowIds,
      );
      blockHashes.add(result.hash);
    }

    return blockHashes;
  }

  /// Get row IDs in a specific block.
  Future<List<String>> getBlockRowIds(
    String tableName,
    int blockIndex, {
    int blockSize = defaultBlockSize,
    String primaryKeyColumn = 'id',
    List<String>? scopedRowIds,
  }) async {
    final offset = blockIndex * blockSize;
    final scopeFilter = scopedRowIds != null
        ? "AND $primaryKeyColumn IN (${scopedRowIds.map((id) => "'$id'").join(',')})"
        : '';

    final rows = await _db.read(
      'SELECT $primaryKeyColumn FROM $tableName WHERE deleted_at IS NULL $scopeFilter ORDER BY $primaryKeyColumn LIMIT $blockSize OFFSET $offset',
    );

    return rows.map((row) => row[primaryKeyColumn].toString()).toList();
  }

  /// Compare Merkle roots between local and remote.
  Future<bool> compareRoots(
    String tableName,
    String remoteRootHash, {
    int blockSize = defaultBlockSize,
    List<String>? hashColumns,
  }) async {
    final localInfo = await merkleRoot(tableName, blockSize: blockSize, hashColumns: hashColumns);
    return localInfo.rootHash == remoteRootHash;
  }

  /// Find differing blocks between local and remote.
  Future<List<int>> findDifferingBlocks(
    String tableName,
    List<String> remoteBlockHashes, {
    int blockSize = defaultBlockSize,
    List<String>? hashColumns,
    List<String>? scopedRowIds,
  }) async {
    final localBlockHashes = await merkleBlockHashes(
      tableName,
      blockSize: blockSize,
      hashColumns: hashColumns,
      scopedRowIds: scopedRowIds,
    );
    final differingBlocks = <int>[];

    final maxBlocks = localBlockHashes.length > remoteBlockHashes.length
        ? localBlockHashes.length
        : remoteBlockHashes.length;

    for (int i = 0; i < maxBlocks; i++) {
      final localHash = i < localBlockHashes.length ? localBlockHashes[i] : '';
      final remoteHash =
          i < remoteBlockHashes.length ? remoteBlockHashes[i] : '';

      if (localHash != remoteHash) {
        differingBlocks.add(i);
      }
    }

    return differingBlocks;
  }
}
