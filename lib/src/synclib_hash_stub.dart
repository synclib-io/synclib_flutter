/// Stub implementation for native platforms.
///
/// On native platforms (iOS, Android, macOS), WASM is not used.
/// Instead, the FFI bindings to synclibc handle merkle hashing,
/// which internally uses the same C hash library (synclib_hash).
///
/// This stub ensures the conditional import compiles on native platforms.

/// Always returns false on native platforms - use FFI bindings instead.
bool get isWasmInitialized => false;

/// Not implemented on native platforms.
Future<void> initSynclibHashWasm() async {
  throw UnsupportedError(
    'WASM hash functions are not available on native platforms. '
    'Use FFI bindings to synclibc instead.',
  );
}

/// Not implemented on native platforms.
String wasmSha256Hex(String data) {
  throw UnsupportedError('Use FFI bindings on native platforms');
}

/// Not implemented on native platforms.
String wasmRowHash(String rowId, String sortedJson) {
  throw UnsupportedError('Use FFI bindings on native platforms');
}

/// Not implemented on native platforms.
String wasmBlockHash(List<String> rowHashes) {
  throw UnsupportedError('Use FFI bindings on native platforms');
}

/// Not implemented on native platforms.
String wasmMerkleRoot(List<String> blockHashes) {
  throw UnsupportedError('Use FFI bindings on native platforms');
}

/// Not implemented on native platforms.
String wasmBuildSortedJsonFromJson(String inputJson, List<String> skipKeys) {
  throw UnsupportedError('Use FFI bindings on native platforms');
}
