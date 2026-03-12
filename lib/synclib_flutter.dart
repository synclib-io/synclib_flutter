library synclib_flutter;

// Export platform-agnostic interface
export 'src/synclib_platform_interface.dart' show SynclibDatabase, Change, SynclibOperation, SynclibException;

// Export Merkle tree implementation
// On web: uses WASM (synclib_hash) when initialized, otherwise falls back to pure Dart
// On native: uses FFI to synclibc which internally uses synclib_hash
export 'src/merkle.dart' show MerkleComputer, MerkleDatabase, MerkleInfo, BlockHashResult, defaultBlockSize;

// Export WASM initialization for web platform
// Call initSynclibHashWasm() before using MerkleComputer on web for cross-platform consistency
export 'src/synclib_hash_web.dart'
    if (dart.library.io) 'src/synclib_hash_stub.dart'
    show initSynclibHashWasm, isWasmInitialized;
