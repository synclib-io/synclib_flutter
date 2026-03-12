/// Platform-agnostic interface for synclib_flutter
///
/// This file conditionally exports the correct implementation based on platform:
/// - Web: Uses Drift with sql.js (synclib_drift_web.dart)
/// - Native (iOS/Android/macOS): Uses FFI implementation (synclib_impl.dart)

// Conditional exports based on platform
// The stub is the default, but gets replaced by platform-specific implementation
export 'synclib_impl_stub.dart'
    if (dart.library.js) 'synclib_drift_web.dart'  // Web platform (Drift + sql.js)
    if (dart.library.io) 'synclib_impl.dart';  // Native platforms (FFI)
