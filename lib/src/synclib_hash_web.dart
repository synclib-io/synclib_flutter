/// WASM-based hash functions for Dart web platform.
///
/// This module loads synclib_hash.wasm via JS interop to ensure
/// cross-platform hash consistency with C, Elixir, and TypeScript.
@JS()
library synclib_hash_web;

import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// JavaScript module interface for synclib_hash WASM
@JS('createSynclibHashModule')
external JSPromise<JSObject> _createSynclibHashModule();

/// Global WASM module instance
JSObject? _wasmModule;
bool _isInitializing = false;
Completer<void>? _initCompleter;

/// Check if the WASM module is initialized
bool get isWasmInitialized => _wasmModule != null;

/// Initialize the WASM module.
/// Call this once before using any hash functions.
///
/// The WASM file must be served from the web server.
/// Typically place synclib_hash.js and synclib_hash.wasm in web/
Future<void> initSynclibHashWasm() async {
  if (_wasmModule != null) return;

  if (_isInitializing) {
    await _initCompleter?.future;
    return;
  }

  _isInitializing = true;
  _initCompleter = Completer<void>();

  try {
    final module = await _createSynclibHashModule().toDart;
    _wasmModule = module;
    _initCompleter?.complete();
  } catch (e) {
    _initCompleter?.completeError(e);
    rethrow;
  } finally {
    _isInitializing = false;
  }
}

/// Compute SHA256 hash and return as lowercase hex string.
String wasmSha256Hex(String data) {
  if (_wasmModule == null) {
    throw StateError('WASM module not initialized. Call initSynclibHashWasm() first.');
  }

  final module = _wasmModule!;

  // Get helper functions
  final lengthBytesUTF8 = module['lengthBytesUTF8'] as JSFunction;
  final stringToUTF8 = module['stringToUTF8'] as JSFunction;
  final UTF8ToString = module['UTF8ToString'] as JSFunction;
  final malloc = module['_malloc'] as JSFunction;
  final free = module['_free'] as JSFunction;
  final synclibFree = module['_synclib_free'] as JSFunction;
  final synclibSha256Hex = module['_synclib_sha256_hex'] as JSFunction;

  // Allocate memory for input
  final dataJs = data.toJS;
  final dataLen = (lengthBytesUTF8.callAsFunction(null, dataJs) as JSNumber).toDartInt;
  final dataPtr = (malloc.callAsFunction(null, (dataLen + 1).toJS) as JSNumber).toDartInt;

  try {
    // Write string to WASM memory
    stringToUTF8.callAsFunction(null, dataJs, dataPtr.toJS, (dataLen + 1).toJS);

    // Call synclib_sha256_hex
    final resultPtr = (synclibSha256Hex.callAsFunction(null, dataPtr.toJS, dataLen.toJS) as JSNumber).toDartInt;

    // Read result
    final result = (UTF8ToString.callAsFunction(null, resultPtr.toJS) as JSString).toDart;

    // Free result
    synclibFree.callAsFunction(null, resultPtr.toJS);

    return result;
  } finally {
    // Free input
    free.callAsFunction(null, dataPtr.toJS);
  }
}

/// Compute row hash using WASM.
///
/// Format: SHA256(row_id + "|" + sorted_json) -> lowercase hex (64 chars)
String wasmRowHash(String rowId, String sortedJson) {
  if (_wasmModule == null) {
    throw StateError('WASM module not initialized. Call initSynclibHashWasm() first.');
  }

  final module = _wasmModule!;

  final lengthBytesUTF8 = module['lengthBytesUTF8'] as JSFunction;
  final stringToUTF8 = module['stringToUTF8'] as JSFunction;
  final UTF8ToString = module['UTF8ToString'] as JSFunction;
  final malloc = module['_malloc'] as JSFunction;
  final free = module['_free'] as JSFunction;
  final synclibFree = module['_synclib_free'] as JSFunction;
  final synclibRowHash = module['_synclib_row_hash'] as JSFunction;

  // Allocate memory for inputs
  final idJs = rowId.toJS;
  final jsonJs = sortedJson.toJS;

  final idLen = (lengthBytesUTF8.callAsFunction(null, idJs) as JSNumber).toDartInt;
  final jsonLen = (lengthBytesUTF8.callAsFunction(null, jsonJs) as JSNumber).toDartInt;

  final idPtr = (malloc.callAsFunction(null, (idLen + 1).toJS) as JSNumber).toDartInt;
  final jsonPtr = (malloc.callAsFunction(null, (jsonLen + 1).toJS) as JSNumber).toDartInt;

  try {
    stringToUTF8.callAsFunction(null, idJs, idPtr.toJS, (idLen + 1).toJS);
    stringToUTF8.callAsFunction(null, jsonJs, jsonPtr.toJS, (jsonLen + 1).toJS);

    final resultPtr = (synclibRowHash.callAsFunction(null, idPtr.toJS, jsonPtr.toJS) as JSNumber).toDartInt;
    final result = (UTF8ToString.callAsFunction(null, resultPtr.toJS) as JSString).toDart;

    synclibFree.callAsFunction(null, resultPtr.toJS);
    return result;
  } finally {
    free.callAsFunction(null, idPtr.toJS);
    free.callAsFunction(null, jsonPtr.toJS);
  }
}

/// Compute block hash from row hashes using WASM.
///
/// Format: SHA256(row_hash_1 + row_hash_2 + ... + row_hash_n) -> lowercase hex
String wasmBlockHash(List<String> rowHashes) {
  if (_wasmModule == null) {
    throw StateError('WASM module not initialized. Call initSynclibHashWasm() first.');
  }

  if (rowHashes.isEmpty) {
    return wasmSha256Hex('');
  }

  final module = _wasmModule!;

  final lengthBytesUTF8 = module['lengthBytesUTF8'] as JSFunction;
  final stringToUTF8 = module['stringToUTF8'] as JSFunction;
  final UTF8ToString = module['UTF8ToString'] as JSFunction;
  final malloc = module['_malloc'] as JSFunction;
  final free = module['_free'] as JSFunction;
  final synclibFree = module['_synclib_free'] as JSFunction;
  final synclibBlockHash = module['_synclib_block_hash'] as JSFunction;

  // HEAPU32 for writing pointers
  final HEAPU32 = module['HEAPU32'] as JSObject;

  // Allocate array of pointers (4 bytes each for 32-bit pointers)
  final arrayPtr = (malloc.callAsFunction(null, (rowHashes.length * 4).toJS) as JSNumber).toDartInt;
  final hashPtrs = <int>[];

  try {
    // Allocate and write each hash string
    for (var i = 0; i < rowHashes.length; i++) {
      final hash = rowHashes[i];
      final hashJs = hash.toJS;
      final len = (lengthBytesUTF8.callAsFunction(null, hashJs) as JSNumber).toDartInt;
      final ptr = (malloc.callAsFunction(null, (len + 1).toJS) as JSNumber).toDartInt;
      stringToUTF8.callAsFunction(null, hashJs, ptr.toJS, (len + 1).toJS);
      hashPtrs.add(ptr);

      // Write pointer to array (HEAPU32 is indexed by 4-byte units)
      HEAPU32.setProperty(((arrayPtr >> 2) + i).toJS, ptr.toJS);
    }

    final resultPtr = (synclibBlockHash.callAsFunction(null, arrayPtr.toJS, rowHashes.length.toJS) as JSNumber).toDartInt;
    final result = (UTF8ToString.callAsFunction(null, resultPtr.toJS) as JSString).toDart;

    synclibFree.callAsFunction(null, resultPtr.toJS);
    return result;
  } finally {
    // Free hash strings
    for (final ptr in hashPtrs) {
      free.callAsFunction(null, ptr.toJS);
    }
    // Free array
    free.callAsFunction(null, arrayPtr.toJS);
  }
}

/// Build Merkle root from block hashes using WASM.
///
/// Uses binary tree structure. Odd nodes are passed up as-is (not duplicated).
String wasmMerkleRoot(List<String> blockHashes) {
  if (_wasmModule == null) {
    throw StateError('WASM module not initialized. Call initSynclibHashWasm() first.');
  }

  if (blockHashes.isEmpty) {
    return '';
  }

  if (blockHashes.length == 1) {
    return blockHashes[0];
  }

  final module = _wasmModule!;

  final lengthBytesUTF8 = module['lengthBytesUTF8'] as JSFunction;
  final stringToUTF8 = module['stringToUTF8'] as JSFunction;
  final UTF8ToString = module['UTF8ToString'] as JSFunction;
  final malloc = module['_malloc'] as JSFunction;
  final free = module['_free'] as JSFunction;
  final synclibFree = module['_synclib_free'] as JSFunction;
  final synclibMerkleRoot = module['_synclib_merkle_root'] as JSFunction;

  final HEAPU32 = module['HEAPU32'] as JSObject;

  // Allocate array of pointers
  final arrayPtr = (malloc.callAsFunction(null, (blockHashes.length * 4).toJS) as JSNumber).toDartInt;
  final hashPtrs = <int>[];

  try {
    for (var i = 0; i < blockHashes.length; i++) {
      final hash = blockHashes[i];
      final hashJs = hash.toJS;
      final len = (lengthBytesUTF8.callAsFunction(null, hashJs) as JSNumber).toDartInt;
      final ptr = (malloc.callAsFunction(null, (len + 1).toJS) as JSNumber).toDartInt;
      stringToUTF8.callAsFunction(null, hashJs, ptr.toJS, (len + 1).toJS);
      hashPtrs.add(ptr);

      HEAPU32.setProperty(((arrayPtr >> 2) + i).toJS, ptr.toJS);
    }

    final resultPtr = (synclibMerkleRoot.callAsFunction(null, arrayPtr.toJS, blockHashes.length.toJS) as JSNumber).toDartInt;
    final result = (UTF8ToString.callAsFunction(null, resultPtr.toJS) as JSString).toDart;

    synclibFree.callAsFunction(null, resultPtr.toJS);
    return result;
  } finally {
    for (final ptr in hashPtrs) {
      free.callAsFunction(null, ptr.toJS);
    }
    free.callAsFunction(null, arrayPtr.toJS);
  }
}

/// Build sorted JSON from a JSON string using WASM.
/// This is the SINGLE SOURCE OF TRUTH for sorted JSON building across all platforms.
///
/// Keys are sorted alphabetically. Specified keys are skipped.
/// Returns canonical sorted JSON string.
String wasmBuildSortedJsonFromJson(String inputJson, List<String> skipKeys) {
  if (_wasmModule == null) {
    throw StateError('WASM module not initialized. Call initSynclibHashWasm() first.');
  }

  final module = _wasmModule!;

  final lengthBytesUTF8 = module['lengthBytesUTF8'] as JSFunction;
  final stringToUTF8 = module['stringToUTF8'] as JSFunction;
  final UTF8ToString = module['UTF8ToString'] as JSFunction;
  final malloc = module['_malloc'] as JSFunction;
  final free = module['_free'] as JSFunction;
  final synclibFree = module['_synclib_free'] as JSFunction;
  final synclibBuildSortedJson = module['_synclib_build_sorted_json_from_json'] as JSFunction;

  final HEAPU32 = module['HEAPU32'] as JSObject;

  // Allocate and write input JSON
  final inputJs = inputJson.toJS;
  final inputLen = (lengthBytesUTF8.callAsFunction(null, inputJs) as JSNumber).toDartInt;
  final inputPtr = (malloc.callAsFunction(null, (inputLen + 1).toJS) as JSNumber).toDartInt;
  stringToUTF8.callAsFunction(null, inputJs, inputPtr.toJS, (inputLen + 1).toJS);

  // Allocate skip keys array
  final skipKeysPtr = skipKeys.isNotEmpty
      ? (malloc.callAsFunction(null, (skipKeys.length * 4).toJS) as JSNumber).toDartInt
      : 0;
  final skipKeyPtrs = <int>[];

  try {
    // Write skip keys
    for (var i = 0; i < skipKeys.length; i++) {
      final key = skipKeys[i];
      final keyJs = key.toJS;
      final keyLen = (lengthBytesUTF8.callAsFunction(null, keyJs) as JSNumber).toDartInt;
      final keyPtr = (malloc.callAsFunction(null, (keyLen + 1).toJS) as JSNumber).toDartInt;
      stringToUTF8.callAsFunction(null, keyJs, keyPtr.toJS, (keyLen + 1).toJS);
      skipKeyPtrs.add(keyPtr);

      HEAPU32.setProperty(((skipKeysPtr >> 2) + i).toJS, keyPtr.toJS);
    }

    // Call WASM function
    final resultPtr = (synclibBuildSortedJson.callAsFunction(
      null,
      inputPtr.toJS,
      skipKeysPtr.toJS,
      skipKeys.length.toJS,
    ) as JSNumber).toDartInt;

    if (resultPtr == 0) {
      return '{}';
    }

    final result = (UTF8ToString.callAsFunction(null, resultPtr.toJS) as JSString).toDart;
    synclibFree.callAsFunction(null, resultPtr.toJS);
    return result;
  } finally {
    // Free memory
    free.callAsFunction(null, inputPtr.toJS);
    for (final ptr in skipKeyPtrs) {
      free.callAsFunction(null, ptr.toJS);
    }
    if (skipKeysPtr != 0) {
      free.callAsFunction(null, skipKeysPtr.toJS);
    }
  }
}
