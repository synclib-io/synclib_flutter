// NOT USED, now using drift
// import 'dart:async';
// import 'dart:js_interop';
// import 'dart:js_interop_unsafe';
// import 'package:web/web.dart' as web;

// /// Exception thrown when a synclib operation fails on web
// class SynclibException implements Exception {
//   final String message;
//   final int? code;

//   SynclibException(this.message, [this.code]);

//   @override
//   String toString() =>
//       'SynclibException: $message${code != null ? ' (code: $code)' : ''}';
// }

// /// Represents a change operation type
// enum SynclibOperation {
//   insert(1),
//   update(2),
//   delete(3);

//   final int value;
//   const SynclibOperation(this.value);

//   static SynclibOperation fromValue(int value) {
//     return SynclibOperation.values.firstWhere((e) => e.value == value);
//   }
// }

// /// Represents a tracked database change
// class Change {
//   final int seqnum;
//   final String tableName;
//   final String rowId;
//   final SynclibOperation operation;
//   final String? data;

//   Change({
//     required this.seqnum,
//     required this.tableName,
//     required this.rowId,
//     required this.operation,
//     this.data,
//   });

//   @override
//   String toString() =>
//       'Change(seqnum: $seqnum, table: $tableName, rowId: $rowId, op: $operation)';
// }

// /// JavaScript interop for WASM module
// @JS()
// @staticInterop
// class SynclibModule {}

// extension SynclibModuleExtension on SynclibModule {
//   external JSFunction get _synclib_open;
//   external JSFunction get _synclib_close;
//   external JSFunction get _synclib_write;
//   external JSFunction get _synclib_exec;
//   external JSFunction get _synclib_read;
//   external JSFunction get _synclib_read_raw;
//   external JSFunction get _synclib_get_schema_version;
//   external JSFunction get _synclib_set_schema_version;
//   external JSFunction get _synclib_get_pending_changes;
//   external JSFunction get _synclib_mark_synced;
//   external JSFunction get _synclib_apply_remote;
//   external JSFunction get _synclib_begin_bulk_remote;
//   external JSFunction get _synclib_exec_bulk_remote;
//   external JSFunction get _synclib_end_bulk_remote;
//   external JSFunction get _synclib_get_error;
//   external JSFunction get _malloc;
//   external JSFunction get _free;
//   external JSFunction get getValue;
//   external JSFunction get setValue;
//   external JSFunction get UTF8ToString;
//   external JSFunction get stringToUTF8;
//   external JSFunction get lengthBytesUTF8;
//   external JSFunction get addFunction;
//   external JSFunction get removeFunction;
//   external JSFunction get HEAPU8;
// }

// /// Web implementation of synclib using WebAssembly
// class SynclibDatabase {
//   static SynclibModule? _module;
//   int? _dbPtr;
//   final String _dbPath;

//   SynclibDatabase._(this._dbPath);

//   /// Open a database connection
//   static Future<SynclibDatabase> open(String dbPath) async {
//     await _ensureModuleLoaded();
//     final db = SynclibDatabase._(dbPath);
//     await db._open();
//     return db;
//   }

//   /// Load the WASM module
//   static Future<void> _ensureModuleLoaded() async {
//     if (_module != null) return;

//     // Load the WASM module
//     final scriptElement = web.document.createElement('script') as web.HTMLScriptElement;
//     scriptElement.src = 'assets/packages/synclib_flutter/assets/synclib.js';

//     final completer = Completer<void>();
//     scriptElement.onload = (event) {
//       completer.complete();
//     }.toJS;

//     scriptElement.onerror = (event) {
//       completer.completeError('Failed to load synclib WASM module');
//     }.toJS;

//     web.document.head!.appendChild(scriptElement);
//     await completer.future;

//     // Initialize the module
//     final createModule = globalContext['createSyncLibModule'] as JSFunction;
//     _module = await (createModule.callAsFunction() as JSPromise).toDart as SynclibModule;
//   }

//   Future<void> _open() async {
//     final module = _module!;

//     // Allocate string in WASM memory
//     final pathLength = (module.lengthBytesUTF8.callAsFunction(null, _dbPath.toJS) as JSNumber).toDartInt;
//     final pathPtr = (module._malloc.callAsFunction(null, (pathLength + 1).toJS) as JSNumber).toDartInt;
//     module.stringToUTF8.callAsFunction(null, _dbPath.toJS, pathPtr.toJS, (pathLength + 1).toJS);

//     // Allocate pointer for db handle
//     final dbPtrPtr = (module._malloc.callAsFunction(null, 4.toJS) as JSNumber).toDartInt;

//     // Call synclib_open
//     final result = (module._synclib_open.callAsFunction(null, pathPtr.toJS, dbPtrPtr.toJS) as JSNumber).toDartInt;

//     if (result != 0) {
//       module._free.callAsFunction(null, pathPtr.toJS);
//       module._free.callAsFunction(null, dbPtrPtr.toJS);
//       throw SynclibException('Failed to open database: $_dbPath', result);
//     }

//     _dbPtr = (module.getValue.callAsFunction(null, dbPtrPtr.toJS, 'i32'.toJS) as JSNumber).toDartInt;

//     module._free.callAsFunction(null, pathPtr.toJS);
//     module._free.callAsFunction(null, dbPtrPtr.toJS);
//   }

//   void _ensureOpen() {
//     if (_dbPtr == null) {
//       throw SynclibException('Database is not open');
//     }
//   }

//   String _getLastError() {
//     if (_dbPtr == null) return 'Database not open';
//     final module = _module!;
//     final errorPtr = (module._synclib_get_error.callAsFunction(null, _dbPtr!.toJS) as JSNumber).toDartInt;
//     return (module.UTF8ToString.callAsFunction(null, errorPtr.toJS) as JSString).toDart;
//   }

//   /// Execute SQL without change tracking
//   Future<void> exec(String sql) async {
//     _ensureOpen();
//     final module = _module!;

//     final sqlLength = (module.lengthBytesUTF8.callAsFunction(null, sql.toJS) as JSNumber).toDartInt;
//     final sqlPtr = (module._malloc.callAsFunction(null, (sqlLength + 1).toJS) as JSNumber).toDartInt;
//     module.stringToUTF8.callAsFunction(null, sql.toJS, sqlPtr.toJS, (sqlLength + 1).toJS);

//     final result = (module._synclib_exec.callAsFunction(null, _dbPtr!.toJS, sqlPtr.toJS) as JSNumber).toDartInt;
//     module._free.callAsFunction(null, sqlPtr.toJS);

//     if (result != 0) {
//       throw SynclibException('Exec failed: ${_getLastError()}', result);
//     }
//   }

//   /// Get current schema version
//   Future<int> getSchemaVersion() async {
//     _ensureOpen();
//     final module = _module!;

//     final versionPtr = (module._malloc.callAsFunction(null, 4.toJS) as JSNumber).toDartInt;
//     final result = (module._synclib_get_schema_version.callAsFunction(null, _dbPtr!.toJS, versionPtr.toJS) as JSNumber).toDartInt;

//     if (result != 0) {
//       module._free.callAsFunction(null, versionPtr.toJS);
//       throw SynclibException('Failed to get schema version: ${_getLastError()}', result);
//     }

//     final version = (module.getValue.callAsFunction(null, versionPtr.toJS, 'i32'.toJS) as JSNumber).toDartInt;
//     module._free.callAsFunction(null, versionPtr.toJS);

//     return version;
//   }

//   /// Set schema version
//   Future<void> setSchemaVersion(int version) async {
//     _ensureOpen();
//     final module = _module!;

//     final result = (module._synclib_set_schema_version.callAsFunction(null, _dbPtr!.toJS, version.toJS) as JSNumber).toDartInt;
//     if (result != 0) {
//       throw SynclibException('Failed to set schema version: ${_getLastError()}', result);
//     }
//   }

//   /// Execute a read-only query and return results as a list of maps
//   ///
//   /// Example:
//   /// ```dart
//   /// final results = await db.read('SELECT * FROM users WHERE active = 1');
//   /// for (final row in results) {
//   ///   print('Name: ${row['name']}, Email: ${row['email']}');
//   /// }
//   /// ```
//   Future<List<Map<String, dynamic>>> read(String sql) async {
//     _ensureOpen();
//     final module = _module!;

//     final results = <Map<String, dynamic>>[];

//     // Create a JavaScript callback function
//     final callback = (int argc, int argvPtr, int colNamesPtr) {
//       final row = <String, dynamic>{};

//       for (int i = 0; i < argc; i++) {
//         // Get column name
//         final colNamePtr = (module.getValue.callAsFunction(null, (colNamesPtr + i * 4).toJS, 'i32'.toJS) as JSNumber).toDartInt;
//         final colName = (module.UTF8ToString.callAsFunction(null, colNamePtr.toJS) as JSString).toDart;

//         // Get value
//         final valuePtr = (module.getValue.callAsFunction(null, (argvPtr + i * 4).toJS, 'i32'.toJS) as JSNumber).toDartInt;

//         if (valuePtr == 0) {
//           row[colName] = null;
//         } else {
//           final value = (module.UTF8ToString.callAsFunction(null, valuePtr.toJS) as JSString).toDart;
//           // Try to parse as number if possible
//           final intValue = int.tryParse(value);
//           if (intValue != null) {
//             row[colName] = intValue;
//           } else {
//             final doubleValue = double.tryParse(value);
//             if (doubleValue != null) {
//               row[colName] = doubleValue;
//             } else {
//               row[colName] = value;
//             }
//           }
//         }
//       }

//       results.add(row);
//       return 0; // Continue iteration
//     }.toJS;

//     // Register the callback function
//     final callbackPtr = (module.addFunction.callAsFunction(null, callback, 'iiii'.toJS) as JSNumber).toDartInt;

//     final sqlLength = (module.lengthBytesUTF8.callAsFunction(null, sql.toJS) as JSNumber).toDartInt;
//     final sqlPtr = (module._malloc.callAsFunction(null, (sqlLength + 1).toJS) as JSNumber).toDartInt;
//     module.stringToUTF8.callAsFunction(null, sql.toJS, sqlPtr.toJS, (sqlLength + 1).toJS);

//     try {
//       final result = (module._synclib_read.callAsFunction(null, _dbPtr!.toJS, sqlPtr.toJS, callbackPtr.toJS, 0.toJS) as JSNumber).toDartInt;

//       if (result != 0) {
//         throw SynclibException('Read failed: ${_getLastError()}', result);
//       }

//       return results;
//     } finally {
//       module._free.callAsFunction(null, sqlPtr.toJS);
//       module.removeFunction.callAsFunction(null, callbackPtr.toJS);
//     }
//   }

//   /// Execute a read-only query with full type support including BLOBs
//   ///
//   /// This method properly handles all SQLite types including BLOBs.
//   /// BLOB columns are returned as Uint8List.
//   ///
//   /// Example:
//   /// ```dart
//   /// final results = await db.readRaw('SELECT id, document FROM users');
//   /// for (final row in results) {
//   ///   final documentBlob = row['document'] as Uint8List;
//   ///   final doc = jsonb.decode(documentBlob);
//   /// }
//   /// ```
//   Future<List<Map<String, dynamic>>> readRaw(String sql) async {
//     _ensureOpen();
//     final module = _module!;

//     final results = <Map<String, dynamic>>[];

//     // SQLite type constants
//     const sqliteInteger = 1;
//     const sqliteFloat = 2;
//     const sqliteText = 3;
//     const sqliteBlob = 4;
//     const sqliteNull = 5;

//     // Create a JavaScript callback function
//     // Callback signature: (userData, colCount, colNamesPtr, valuesPtr) => int
//     final callback = (int userData, int colCount, int colNamesPtr, int valuesPtr) {
//       final row = <String, dynamic>{};

//       // Size of synclib_column_value_t struct (type=4, text=4, blob=4, blobSize=4, int=8, float=8 = 32 bytes)
//       const structSize = 32;

//       for (int i = 0; i < colCount; i++) {
//         // Get column name
//         final colNamePtr = (module.getValue.callAsFunction(null, (colNamesPtr + i * 4).toJS, 'i32'.toJS) as JSNumber).toDartInt;
//         final colName = (module.UTF8ToString.callAsFunction(null, colNamePtr.toJS) as JSString).toDart;

//         // Get value struct
//         final valueStructPtr = valuesPtr + (i * structSize);

//         final type = (module.getValue.callAsFunction(null, valueStructPtr.toJS, 'i32'.toJS) as JSNumber).toDartInt;

//         switch (type) {
//           case sqliteInteger:
//             final intValue = (module.getValue.callAsFunction(null, (valueStructPtr + 16).toJS, 'i64'.toJS) as JSNumber).toDartInt;
//             row[colName] = intValue;
//             break;

//           case sqliteFloat:
//             final floatValue = (module.getValue.callAsFunction(null, (valueStructPtr + 24).toJS, 'double'.toJS) as JSNumber).toDartDouble;
//             row[colName] = floatValue;
//             break;

//           case sqliteText:
//             final textPtr = (module.getValue.callAsFunction(null, (valueStructPtr + 4).toJS, 'i32'.toJS) as JSNumber).toDartInt;
//             if (textPtr != 0) {
//               final text = (module.UTF8ToString.callAsFunction(null, textPtr.toJS) as JSString).toDart;
//               row[colName] = text;
//             } else {
//               row[colName] = null;
//             }
//             break;

//           case sqliteBlob:
//             final blobPtr = (module.getValue.callAsFunction(null, (valueStructPtr + 8).toJS, 'i32'.toJS) as JSNumber).toDartInt;
//             final blobSize = (module.getValue.callAsFunction(null, (valueStructPtr + 12).toJS, 'i32'.toJS) as JSNumber).toDartInt;

//             if (blobPtr != 0 && blobSize > 0) {
//               // Copy BLOB data from WASM memory to Dart Uint8List
//               final bytes = Uint8List(blobSize);
//               final heapU8 = module.HEAPU8 as JSArray;
//               for (int j = 0; j < blobSize; j++) {
//                 bytes[j] = ((heapU8.callMethod('get'.toJS, (blobPtr + j).toJS) as JSNumber?)?.toDartInt ?? 0) as int;
//               }
//               row[colName] = bytes;
//             } else {
//               row[colName] = null;
//             }
//             break;

//           case sqliteNull:
//           default:
//             row[colName] = null;
//             break;
//         }
//       }

//       results.add(row);
//       return 0; // Continue iteration
//     }.toJS;

//     // Register the callback function with signature 'iiii' (4 int parameters)
//     final callbackPtr = (module.addFunction.callAsFunction(null, callback, 'iiii'.toJS) as JSNumber).toDartInt;

//     final sqlLength = (module.lengthBytesUTF8.callAsFunction(null, sql.toJS) as JSNumber).toDartInt;
//     final sqlPtr = (module._malloc.callAsFunction(null, (sqlLength + 1).toJS) as JSNumber).toDartInt;
//     module.stringToUTF8.callAsFunction(null, sql.toJS, sqlPtr.toJS, (sqlLength + 1).toJS);

//     try {
//       final result = (module._synclib_read_raw.callAsFunction(null, _dbPtr!.toJS, sqlPtr.toJS, callbackPtr.toJS, 0.toJS) as JSNumber).toDartInt;

//       if (result != 0) {
//         throw SynclibException('Read failed: ${_getLastError()}', result);
//       }

//       return results;
//     } finally {
//       module._free.callAsFunction(null, sqlPtr.toJS);
//       module.removeFunction.callAsFunction(null, callbackPtr.toJS);
//     }
//   }

//   // Additional methods would follow similar patterns...
//   // For brevity, showing the essential structure

//   /// Close the database connection
//   Future<void> close() async {
//     if (_dbPtr != null) {
//       _module!._synclib_close.callAsFunction(null, _dbPtr!.toJS);
//       _dbPtr = null;
//     }
//   }

//   /// Check if database is open
//   bool get isOpen => _dbPtr != null;
// }
