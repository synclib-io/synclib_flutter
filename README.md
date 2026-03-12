# synclib_flutter

Flutter wrapper for synclib - a cross-platform SQLite library with automatic change tracking for syncing.

## Features

- 🔄 **Automatic Change Tracking**: Every write operation (INSERT, UPDATE, DELETE) is automatically tracked
- 📱 **Cross-Platform**: Support for Android, iOS, and Web (WASM)
- 🚀 **Sync-Ready**: Get pending changes and mark them as synced with simple API calls
- 💪 **Bulk Operations**: Efficient bulk remote operations for large data transfers
- 🎯 **Simple API**: Clean, idiomatic Dart API wrapping the native C library

## Platform Support

| Platform | Status |
|----------|--------|
| Android  | ✅ arm64-v8a, armeabi-v7a, x86, x86_64 |
| iOS      | ✅ arm64, x86_64 (simulator) |
| Web      | ✅ WebAssembly |

## Installation

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  synclib_flutter:
    path: ../synclib_flutter  # or your path
```

### Building Native Libraries

Before using the plugin, you need to build the native libraries:

#### For iOS/Android/macOS

```bash
cd synclibc
./build-cross-platform.sh
cd ../synclib_flutter
./scripts/build_native.sh
```

This will:
1. Build the synclib C library for all platforms
2. Copy the compiled libraries to the appropriate Flutter plugin directories

#### For Web (WebAssembly)

To build and set up the web version, you'll need Emscripten:

1. **Install Emscripten** (if not already installed):
```bash
cd ~
git clone https://github.com/emscripten-core/emsdk.git
cd emsdk
./emsdk install latest
./emsdk activate latest
source ./emsdk_env.sh
```

2. **Build the WASM module**:
```bash
cd /path/to/synclibc
source ~/emsdk/emsdk_env.sh  # Make sure Emscripten is in PATH
./build-cross-platform.sh wasm
```

This will create:
- `build/wasm/synclib.js` - JavaScript glue code (68KB)
- `build/wasm/synclib.wasm` - WebAssembly binary (1.2MB)

3. **Copy WASM files to Flutter plugin**:
```bash
# Create web assets directory
mkdir -p /path/to/synclib_flutter/lib/src/web

# Copy WASM files
cp build/wasm/synclib.js /path/to/synclib_flutter/lib/src/web/
cp build/wasm/synclib.wasm /path/to/synclib_flutter/lib/src/web/
```

4. **Verify pubspec.yaml includes web assets**:
```yaml
flutter:
  assets:
    - lib/src/web/synclib.js
    - lib/src/web/synclib.wasm
```

The web assets are already configured in `pubspec.yaml` and will be automatically bundled when building for Flutter web.

## Usage

### Basic Example

```dart
import 'package:synclib_flutter/synclib_flutter.dart';

// Open database
final db = await SynclibDatabase.open('/path/to/database.db');

// Create a table (untracked DDL operation)
await db.exec('''
  CREATE TABLE IF NOT EXISTS users (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT
  )
''');

// Insert with change tracking
await db.write(
  tableName: 'users',
  rowId: '1',
  operation: SynclibOperation.insert,
  sql: "INSERT INTO users (id, name, email) VALUES ('1', 'Alice', 'alice@example.com')",
  data: '{"id":"1","name":"Alice","email":"alice@example.com"}',
);

// Read data from database (simple string-based)
// Use json() to convert JSONB columns to text
final users = await db.read('SELECT id, name, json(document) as document FROM users');
for (final user in users) {
  print('User: ${user['name']}');
  final doc = jsonDecode(user['document'] as String);
}

// OR read BLOB/JSONB columns directly with readRaw()
final rawUsers = await db.readRaw('SELECT id, name, document FROM users');
for (final user in rawUsers) {
  print('User: ${user['name']}');
  final documentBlob = user['document'] as Uint8List;
  final doc = jsonb.decode(documentBlob);
}

// Get pending changes
final changes = await db.getPendingChanges(limit: 100);
for (final change in changes) {
  print('Change: ${change.operation} on ${change.tableName}');
  print('  Row ID: ${change.rowId}');
  print('  Data: ${change.data}');
}

// Mark changes as synced
if (changes.isNotEmpty) {
  await db.markSynced(changes.last.seqnum);
}

// Close database
await db.close();
```

### Applying Remote Changes

```dart
// Apply a change from another client (doesn't create local change record)
await db.applyRemote(
  tableName: 'users',
  rowId: '2',
  operation: SynclibOperation.insert,
  sql: "INSERT INTO users (id, name, email) VALUES ('2', 'Bob', 'bob@example.com')",
  data: '{"id":"2","name":"Bob","email":"bob@example.com"}',
);
```

### Bulk Remote Operations

For efficient batch imports:

```dart
await db.beginBulkRemote();

try {
  for (final row in largeDataSet) {
    await db.execBulkRemote(
      "INSERT INTO users (id, name, email) VALUES ('${row.id}', '${row.name}', '${row.email}')"
    );
  }
  await db.endBulkRemote(); // Commits transaction
} catch (e) {
  await db.endBulkRemote(rollback: true); // Rollback on error
  rethrow;
}
```

## API Reference

### SynclibDatabase

Main database interface.

#### Methods

- `static Future<SynclibDatabase> open(String dbPath)` - Open database connection
- `Future<void> write({...})` - Execute write operation with change tracking
- `Future<void> exec(String sql)` - Execute SQL without change tracking (for DDL)
- `Future<List<Map<String, dynamic>>> read(String sql)` - Execute read-only query (string-based, use json() for BLOBs)
- `Future<List<Map<String, dynamic>>> readRaw(String sql)` - Execute read-only query with BLOB support
- `Future<List<Change>> getPendingChanges({int limit = 100})` - Get pending changes
- `Future<void> markSynced(int seqnum)` - Mark changes as synced up to seqnum
- `Future<void> applyRemote({...})` - Apply remote change without tracking
- `Future<void> beginBulkRemote()` - Begin bulk remote operation mode
- `Future<void> execBulkRemote(String sql)` - Execute in bulk remote mode
- `Future<void> endBulkRemote({bool rollback = false})` - End bulk remote mode
- `Future<int> getSchemaVersion()` - Get current schema version
- `Future<void> setSchemaVersion(int version)` - Set schema version
- `Future<void> close()` - Close database connection

### SynclibOperation

Enum for operation types:
- `SynclibOperation.insert`
- `SynclibOperation.update`
- `SynclibOperation.delete`

### Change

Represents a tracked database change:
- `int seqnum` - Sequence number (monotonically increasing)
- `String tableName` - Table name
- `String rowId` - Row ID (primary key)
- `SynclibOperation operation` - Operation type
- `String? data` - JSON-encoded row data (null for DELETE)

## Example App

See the [example](example/) directory for a complete working example. Run it with:

```bash
cd example
flutter run
```

## Architecture

### Native (Android/iOS)

Uses Dart FFI to call the synclib C library directly. The native libraries are compiled ahead of time and bundled with the app.

### Web

Uses WebAssembly (Emscripten) to run the synclib C library in the browser. The WASM module is loaded at runtime using JavaScript interop.
