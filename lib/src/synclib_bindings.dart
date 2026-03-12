import 'dart:ffi';
import 'package:ffi/ffi.dart';

// Return codes
const int synclibOk = 0;
const int synclibError = -1;
const int synclibNoMoreChanges = 1;

// Operation types
const int synclibOpInsert = 1;
const int synclibOpUpdate = 2;
const int synclibOpDelete = 3;

// SQLite column types
const int sqliteInteger = 1;
const int sqliteFloat = 2;
const int sqliteText = 3;
const int sqliteBlob = 4;
const int sqliteNull = 5;

// Opaque database handle
final class SynclibDb extends Opaque {}

// Change record structure
final class SynclibChange extends Struct {
  @Int64()
  external int seqnum;

  external Pointer<Utf8> tableName;
  external Pointer<Utf8> rowId;

  @Int32()
  external int operation;

  external Pointer<Utf8> data;
}

// Native function signatures
typedef SynclibOpenNative = Int32 Function(
  Pointer<Utf8> dbPath,
  Pointer<Pointer<SynclibDb>> db,
);
typedef SynclibOpenDart = int Function(
  Pointer<Utf8> dbPath,
  Pointer<Pointer<SynclibDb>> db,
);

typedef SynclibCloseNative = Void Function(Pointer<SynclibDb> db);
typedef SynclibCloseDart = void Function(Pointer<SynclibDb> db);

typedef SynclibWriteNative = Int32 Function(
  Pointer<SynclibDb> db,
  Pointer<Utf8> tableName,
  Pointer<Utf8> rowId,
  Int32 operation,
  Pointer<Utf8> sql,
  Pointer<Utf8> data,
);
typedef SynclibWriteDart = int Function(
  Pointer<SynclibDb> db,
  Pointer<Utf8> tableName,
  Pointer<Utf8> rowId,
  int operation,
  Pointer<Utf8> sql,
  Pointer<Utf8> data,
);

typedef SynclibWriteParamsNative = Int32 Function(
  Pointer<SynclibDb> db,
  Pointer<Utf8> tableName,
  Pointer<Utf8> rowId,
  Int32 operation,
  Pointer<Utf8> sql,
  Pointer<Pointer<Utf8>> params,
  Int32 paramCount,
  Pointer<Utf8> data,
);
typedef SynclibWriteParamsDart = int Function(
  Pointer<SynclibDb> db,
  Pointer<Utf8> tableName,
  Pointer<Utf8> rowId,
  int operation,
  Pointer<Utf8> sql,
  Pointer<Pointer<Utf8>> params,
  int paramCount,
  Pointer<Utf8> data,
);

typedef SynclibWriteParamsTypedNative = Int32 Function(
  Pointer<SynclibDb> db,
  Pointer<Utf8> tableName,
  Pointer<Utf8> rowId,
  Int32 operation,
  Pointer<Utf8> sql,
  Pointer<Pointer<Utf8>> textParams,
  Pointer<Pointer<Uint8>> blobParams,
  Pointer<Int32> blobSizes,
  Pointer<Int32> paramTypes,
  Int32 paramCount,
  Pointer<Utf8> data,
);
typedef SynclibWriteParamsTypedDart = int Function(
  Pointer<SynclibDb> db,
  Pointer<Utf8> tableName,
  Pointer<Utf8> rowId,
  int operation,
  Pointer<Utf8> sql,
  Pointer<Pointer<Utf8>> textParams,
  Pointer<Pointer<Uint8>> blobParams,
  Pointer<Int32> blobSizes,
  Pointer<Int32> paramTypes,
  int paramCount,
  Pointer<Utf8> data,
);

typedef SynclibExecNative = Int32 Function(
  Pointer<SynclibDb> db,
  Pointer<Utf8> sql,
);
typedef SynclibExecDart = int Function(
  Pointer<SynclibDb> db,
  Pointer<Utf8> sql,
);

typedef SynclibGetSchemaVersionNative = Int32 Function(
  Pointer<SynclibDb> db,
  Pointer<Int32> version,
);
typedef SynclibGetSchemaVersionDart = int Function(
  Pointer<SynclibDb> db,
  Pointer<Int32> version,
);

typedef SynclibSetSchemaVersionNative = Int32 Function(
  Pointer<SynclibDb> db,
  Int32 version,
);
typedef SynclibSetSchemaVersionDart = int Function(
  Pointer<SynclibDb> db,
  int version,
);

typedef SynclibGetPendingChangesNative = Int32 Function(
  Pointer<SynclibDb> db,
  Pointer<Pointer<SynclibChange>> changes,
  Pointer<Int32> count,
  Int32 limit,
);
typedef SynclibGetPendingChangesDart = int Function(
  Pointer<SynclibDb> db,
  Pointer<Pointer<SynclibChange>> changes,
  Pointer<Int32> count,
  int limit,
);

typedef SynclibMarkSyncedNative = Int32 Function(
  Pointer<SynclibDb> db,
  Int64 seqnum,
);
typedef SynclibMarkSyncedDart = int Function(
  Pointer<SynclibDb> db,
  int seqnum,
);

typedef SynclibDeleteChangeNative = Int32 Function(
  Pointer<SynclibDb> db,
  Int64 seqnum,
);
typedef SynclibDeleteChangeDart = int Function(
  Pointer<SynclibDb> db,
  int seqnum,
);

typedef SynclibApplyRemoteNative = Int32 Function(
  Pointer<SynclibDb> db,
  Pointer<Utf8> tableName,
  Pointer<Utf8> rowId,
  Int32 operation,
  Pointer<Utf8> sql,
  Pointer<Utf8> data,
);
typedef SynclibApplyRemoteDart = int Function(
  Pointer<SynclibDb> db,
  Pointer<Utf8> tableName,
  Pointer<Utf8> rowId,
  int operation,
  Pointer<Utf8> sql,
  Pointer<Utf8> data,
);

typedef SynclibApplyRemoteParamsNative = Int32 Function(
  Pointer<SynclibDb> db,
  Pointer<Utf8> tableName,
  Pointer<Utf8> rowId,
  Int32 operation,
  Pointer<Utf8> sql,
  Pointer<Pointer<Utf8>> params,
  Int32 paramCount,
  Pointer<Utf8> data,
);
typedef SynclibApplyRemoteParamsDart = int Function(
  Pointer<SynclibDb> db,
  Pointer<Utf8> tableName,
  Pointer<Utf8> rowId,
  int operation,
  Pointer<Utf8> sql,
  Pointer<Pointer<Utf8>> params,
  int paramCount,
  Pointer<Utf8> data,
);

typedef SynclibApplyRemoteParamsTypedNative = Int32 Function(
  Pointer<SynclibDb> db,
  Pointer<Utf8> tableName,
  Pointer<Utf8> rowId,
  Int32 operation,
  Pointer<Utf8> sql,
  Pointer<Pointer<Utf8>> textParams,
  Pointer<Pointer<Uint8>> blobParams,
  Pointer<Int32> blobSizes,
  Pointer<Int32> paramTypes,
  Int32 paramCount,
  Pointer<Utf8> data,
);
typedef SynclibApplyRemoteParamsTypedDart = int Function(
  Pointer<SynclibDb> db,
  Pointer<Utf8> tableName,
  Pointer<Utf8> rowId,
  int operation,
  Pointer<Utf8> sql,
  Pointer<Pointer<Utf8>> textParams,
  Pointer<Pointer<Uint8>> blobParams,
  Pointer<Int32> blobSizes,
  Pointer<Int32> paramTypes,
  int paramCount,
  Pointer<Utf8> data,
);

typedef SynclibBeginBulkRemoteNative = Int32 Function(Pointer<SynclibDb> db);
typedef SynclibBeginBulkRemoteDart = int Function(Pointer<SynclibDb> db);

typedef SynclibExecBulkRemoteNative = Int32 Function(
  Pointer<SynclibDb> db,
  Pointer<Utf8> sql,
);
typedef SynclibExecBulkRemoteDart = int Function(
  Pointer<SynclibDb> db,
  Pointer<Utf8> sql,
);

typedef SynclibEndBulkRemoteNative = Int32 Function(
  Pointer<SynclibDb> db,
  Int32 rollback,
);
typedef SynclibEndBulkRemoteDart = int Function(
  Pointer<SynclibDb> db,
  int rollback,
);

typedef SynclibUpdateRowHashNative = Int32 Function(
  Pointer<SynclibDb> db,
  Pointer<Utf8> tableName,
  Pointer<Utf8> rowId,
);
typedef SynclibUpdateRowHashDart = int Function(
  Pointer<SynclibDb> db,
  Pointer<Utf8> tableName,
  Pointer<Utf8> rowId,
);

typedef SynclibBackfillRowHashesNative = Int32 Function(
  Pointer<SynclibDb> db,
  Pointer<Utf8> tableName,
);
typedef SynclibBackfillRowHashesDart = int Function(
  Pointer<SynclibDb> db,
  Pointer<Utf8> tableName,
);

typedef SynclibSetHashColumnsNative = Int32 Function(
  Pointer<SynclibDb> db,
  Pointer<Utf8> tableName,
  Pointer<Utf8> columnsJson,
);
typedef SynclibSetHashColumnsDart = int Function(
  Pointer<SynclibDb> db,
  Pointer<Utf8> tableName,
  Pointer<Utf8> columnsJson,
);

typedef SynclibFreeChangesNative = Void Function(
  Pointer<SynclibChange> changes,
  Int32 count,
);
typedef SynclibFreeChangesDart = void Function(
  Pointer<SynclibChange> changes,
  int count,
);

typedef SynclibRowToJsonNative = Int32 Function(
  Pointer<SynclibDb> db,
  Pointer<Utf8> tableName,
  Pointer<Utf8> rowId,
  Pointer<Pointer<Utf8>> jsonOut,
);
typedef SynclibRowToJsonDart = int Function(
  Pointer<SynclibDb> db,
  Pointer<Utf8> tableName,
  Pointer<Utf8> rowId,
  Pointer<Pointer<Utf8>> jsonOut,
);

typedef SynclibGetErrorNative = Pointer<Utf8> Function(Pointer<SynclibDb> db);
typedef SynclibGetErrorDart = Pointer<Utf8> Function(Pointer<SynclibDb> db);

// Callback typedef for synclib_read (simple string-based)
typedef SynclibReadCallbackNative = Int32 Function(
  Pointer<Void> userData,
  Int32 argc,
  Pointer<Pointer<Utf8>> argv,
  Pointer<Pointer<Utf8>> colNames,
);
typedef SynclibReadCallbackDart = int Function(
  Pointer<Void> userData,
  int argc,
  Pointer<Pointer<Utf8>> argv,
  Pointer<Pointer<Utf8>> colNames,
);

typedef SynclibReadNative = Int32 Function(
  Pointer<SynclibDb> db,
  Pointer<Utf8> sql,
  Pointer<NativeFunction<SynclibReadCallbackNative>> callback,
  Pointer<Void> userData,
);
typedef SynclibReadDart = int Function(
  Pointer<SynclibDb> db,
  Pointer<Utf8> sql,
  Pointer<NativeFunction<SynclibReadCallbackNative>> callback,
  Pointer<Void> userData,
);

// Column value structure for synclib_read_raw
final class SynclibColumnValue extends Struct {
  @Int32()
  external int type; // SQLITE type constants

  external Pointer<Utf8> textValue;
  external Pointer<Void> blobValue;

  @Int32()
  external int blobSize;

  @Int64()
  external int intValue;

  @Double()
  external double floatValue;
}

// Callback typedef for synclib_read_raw (full type support)
typedef SynclibReadRawCallbackNative = Int32 Function(
  Pointer<Void> userData,
  Int32 colCount,
  Pointer<Pointer<Utf8>> colNames,
  Pointer<SynclibColumnValue> values,
);
typedef SynclibReadRawCallbackDart = int Function(
  Pointer<Void> userData,
  int colCount,
  Pointer<Pointer<Utf8>> colNames,
  Pointer<SynclibColumnValue> values,
);

typedef SynclibReadRawNative = Int32 Function(
  Pointer<SynclibDb> db,
  Pointer<Utf8> sql,
  Pointer<NativeFunction<SynclibReadRawCallbackNative>> callback,
  Pointer<Void> userData,
);
typedef SynclibReadRawDart = int Function(
  Pointer<SynclibDb> db,
  Pointer<Utf8> sql,
  Pointer<NativeFunction<SynclibReadRawCallbackNative>> callback,
  Pointer<Void> userData,
);

// ============================================================================
// Merkle Tree FFI Types
// ============================================================================

// Default block size
const int synclibDefaultBlockSize = 100;

// Merkle info structure
final class SynclibMerkleInfo extends Struct {
  external Pointer<Utf8> rootHash;

  @Int32()
  external int blockCount;

  @Int32()
  external int rowCount;
}

// synclib_row_hash
typedef SynclibRowHashNative = Int32 Function(
  Pointer<SynclibDb> db,
  Pointer<Utf8> tableName,
  Pointer<Utf8> rowId,
  Pointer<Pointer<Utf8>> hashOut,
);
typedef SynclibRowHashDart = int Function(
  Pointer<SynclibDb> db,
  Pointer<Utf8> tableName,
  Pointer<Utf8> rowId,
  Pointer<Pointer<Utf8>> hashOut,
);

// synclib_db_row_json (debug - get sorted JSON for a row)
typedef SynclibRowJsonNative = Int32 Function(
  Pointer<SynclibDb> db,
  Pointer<Utf8> tableName,
  Pointer<Utf8> rowId,
  Pointer<Pointer<Utf8>> jsonOut,
);
typedef SynclibRowJsonDart = int Function(
  Pointer<SynclibDb> db,
  Pointer<Utf8> tableName,
  Pointer<Utf8> rowId,
  Pointer<Pointer<Utf8>> jsonOut,
);

// synclib_block_hash
typedef SynclibBlockHashNative = Int32 Function(
  Pointer<SynclibDb> db,
  Pointer<Utf8> tableName,
  Int32 blockIndex,
  Int32 blockSize,
  Pointer<Pointer<Utf8>> hashOut,
  Pointer<Int32> rowCountOut,
);
typedef SynclibBlockHashDart = int Function(
  Pointer<SynclibDb> db,
  Pointer<Utf8> tableName,
  int blockIndex,
  int blockSize,
  Pointer<Pointer<Utf8>> hashOut,
  Pointer<Int32> rowCountOut,
);

// synclib_merkle_root
typedef SynclibMerkleRootNative = Int32 Function(
  Pointer<SynclibDb> db,
  Pointer<Utf8> tableName,
  Int32 blockSize,
  Pointer<SynclibMerkleInfo> infoOut,
);
typedef SynclibMerkleRootDart = int Function(
  Pointer<SynclibDb> db,
  Pointer<Utf8> tableName,
  int blockSize,
  Pointer<SynclibMerkleInfo> infoOut,
);

// synclib_merkle_block_hashes
typedef SynclibMerkleBlockHashesNative = Int32 Function(
  Pointer<SynclibDb> db,
  Pointer<Utf8> tableName,
  Int32 blockSize,
  Pointer<Pointer<Pointer<Utf8>>> blockHashesOut,
  Pointer<Int32> blockCountOut,
);
typedef SynclibMerkleBlockHashesDart = int Function(
  Pointer<SynclibDb> db,
  Pointer<Utf8> tableName,
  int blockSize,
  Pointer<Pointer<Pointer<Utf8>>> blockHashesOut,
  Pointer<Int32> blockCountOut,
);

// synclib_get_block_row_ids
typedef SynclibGetBlockRowIdsNative = Int32 Function(
  Pointer<SynclibDb> db,
  Pointer<Utf8> tableName,
  Int32 blockIndex,
  Int32 blockSize,
  Pointer<Pointer<Pointer<Utf8>>> rowIdsOut,
  Pointer<Int32> countOut,
);
typedef SynclibGetBlockRowIdsDart = int Function(
  Pointer<SynclibDb> db,
  Pointer<Utf8> tableName,
  int blockIndex,
  int blockSize,
  Pointer<Pointer<Pointer<Utf8>>> rowIdsOut,
  Pointer<Int32> countOut,
);

// synclib_free_merkle_info
typedef SynclibFreeMerkleInfoNative = Void Function(
  Pointer<SynclibMerkleInfo> info,
);
typedef SynclibFreeMerkleInfoDart = void Function(
  Pointer<SynclibMerkleInfo> info,
);

// synclib_free_string_array
typedef SynclibFreeStringArrayNative = Void Function(
  Pointer<Pointer<Utf8>> strings,
  Int32 count,
);
typedef SynclibFreeStringArrayDart = void Function(
  Pointer<Pointer<Utf8>> strings,
  int count,
);

/// Bindings to the native synclib C library
class SynclibBindings {
  final DynamicLibrary _lib;

  SynclibBindings(this._lib);

  late final SynclibOpenDart open = _lib
      .lookup<NativeFunction<SynclibOpenNative>>('synclib_open')
      .asFunction();

  late final SynclibCloseDart close = _lib
      .lookup<NativeFunction<SynclibCloseNative>>('synclib_close')
      .asFunction();

  late final SynclibWriteDart write = _lib
      .lookup<NativeFunction<SynclibWriteNative>>('synclib_write')
      .asFunction();

  late final SynclibWriteParamsDart writeParams = _lib
      .lookup<NativeFunction<SynclibWriteParamsNative>>('synclib_write_params')
      .asFunction();

  late final SynclibWriteParamsTypedDart writeParamsTyped = _lib
      .lookup<NativeFunction<SynclibWriteParamsTypedNative>>('synclib_write_params_typed')
      .asFunction();

  late final SynclibExecDart exec = _lib
      .lookup<NativeFunction<SynclibExecNative>>('synclib_exec')
      .asFunction();

  late final SynclibGetSchemaVersionDart getSchemaVersion = _lib
      .lookup<NativeFunction<SynclibGetSchemaVersionNative>>(
          'synclib_get_schema_version')
      .asFunction();

  late final SynclibSetSchemaVersionDart setSchemaVersion = _lib
      .lookup<NativeFunction<SynclibSetSchemaVersionNative>>(
          'synclib_set_schema_version')
      .asFunction();

  late final SynclibGetPendingChangesDart getPendingChanges = _lib
      .lookup<NativeFunction<SynclibGetPendingChangesNative>>(
          'synclib_get_pending_changes')
      .asFunction();

  late final SynclibMarkSyncedDart markSynced = _lib
      .lookup<NativeFunction<SynclibMarkSyncedNative>>('synclib_mark_synced')
      .asFunction();

  late final SynclibDeleteChangeDart deleteChange = _lib
      .lookup<NativeFunction<SynclibDeleteChangeNative>>('synclib_delete_change')
      .asFunction();

  late final SynclibApplyRemoteDart applyRemote = _lib
      .lookup<NativeFunction<SynclibApplyRemoteNative>>('synclib_apply_remote')
      .asFunction();

  late final SynclibApplyRemoteParamsDart applyRemoteParams = _lib
      .lookup<NativeFunction<SynclibApplyRemoteParamsNative>>('synclib_apply_remote_params')
      .asFunction();

  late final SynclibApplyRemoteParamsTypedDart applyRemoteParamsTyped = _lib
      .lookup<NativeFunction<SynclibApplyRemoteParamsTypedNative>>('synclib_apply_remote_params_typed')
      .asFunction();

  late final SynclibBeginBulkRemoteDart beginBulkRemote = _lib
      .lookup<NativeFunction<SynclibBeginBulkRemoteNative>>(
          'synclib_begin_bulk_remote')
      .asFunction();

  late final SynclibExecBulkRemoteDart execBulkRemote = _lib
      .lookup<NativeFunction<SynclibExecBulkRemoteNative>>(
          'synclib_exec_bulk_remote')
      .asFunction();

  late final SynclibEndBulkRemoteDart endBulkRemote = _lib
      .lookup<NativeFunction<SynclibEndBulkRemoteNative>>(
          'synclib_end_bulk_remote')
      .asFunction();

  late final SynclibFreeChangesDart freeChanges = _lib
      .lookup<NativeFunction<SynclibFreeChangesNative>>('synclib_free_changes')
      .asFunction();

  late final SynclibRowToJsonDart rowToJson = _lib
      .lookup<NativeFunction<SynclibRowToJsonNative>>('synclib_row_to_json')
      .asFunction();

  late final SynclibGetErrorDart getError = _lib
      .lookup<NativeFunction<SynclibGetErrorNative>>('synclib_get_error')
      .asFunction();

  late final SynclibReadDart read = _lib
      .lookup<NativeFunction<SynclibReadNative>>('synclib_read')
      .asFunction();

  late final SynclibReadRawDart readRaw = _lib
      .lookup<NativeFunction<SynclibReadRawNative>>('synclib_read_raw')
      .asFunction();

  // Merkle tree functions (database-aware wrappers)
  late final SynclibRowHashDart rowHash = _lib
      .lookup<NativeFunction<SynclibRowHashNative>>('synclib_db_row_hash')
      .asFunction();

  late final SynclibRowJsonDart rowJson = _lib
      .lookup<NativeFunction<SynclibRowJsonNative>>('synclib_db_row_json')
      .asFunction();

  late final SynclibBlockHashDart blockHash = _lib
      .lookup<NativeFunction<SynclibBlockHashNative>>('synclib_db_block_hash')
      .asFunction();

  late final SynclibMerkleRootDart merkleRoot = _lib
      .lookup<NativeFunction<SynclibMerkleRootNative>>('synclib_db_merkle_root')
      .asFunction();

  late final SynclibMerkleBlockHashesDart merkleBlockHashes = _lib
      .lookup<NativeFunction<SynclibMerkleBlockHashesNative>>('synclib_merkle_block_hashes')
      .asFunction();

  late final SynclibGetBlockRowIdsDart getBlockRowIds = _lib
      .lookup<NativeFunction<SynclibGetBlockRowIdsNative>>('synclib_get_block_row_ids')
      .asFunction();

  late final SynclibFreeMerkleInfoDart freeMerkleInfo = _lib
      .lookup<NativeFunction<SynclibFreeMerkleInfoNative>>('synclib_free_merkle_info')
      .asFunction();

  late final SynclibFreeStringArrayDart freeStringArray = _lib
      .lookup<NativeFunction<SynclibFreeStringArrayNative>>('synclib_free_string_array')
      .asFunction();

  late final SynclibUpdateRowHashDart updateRowHash = _lib
      .lookup<NativeFunction<SynclibUpdateRowHashNative>>('synclib_update_row_hash')
      .asFunction();

  late final SynclibBackfillRowHashesDart backfillRowHashes = _lib
      .lookup<NativeFunction<SynclibBackfillRowHashesNative>>('synclib_backfill_row_hashes')
      .asFunction();

  late final SynclibSetHashColumnsDart setHashColumns = _lib
      .lookup<NativeFunction<SynclibSetHashColumnsNative>>('synclib_set_hash_columns')
      .asFunction();
}
