/// Stub implementation - should never be used
/// Real implementations are in synclib_impl.dart (native) and synclib_web.dart (web)

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
}

class SynclibDatabase {
  static Future<SynclibDatabase> open(String dbPath) {
    throw UnsupportedError('Platform not supported');
  }

  /// Stream of local changes as they occur.
  Stream<Change> get localChanges => throw UnsupportedError('Platform not supported');

  Future<void> write({
    required String tableName,
    required String rowId,
    required SynclibOperation operation,
    required String sql,
    String? data,
  }) {
    throw UnsupportedError('Platform not supported');
  }

  Future<void> writeWithParams({
    required String tableName,
    required String rowId,
    required SynclibOperation operation,
    required String sql,
    required List<dynamic> params,
    String? data,
  }) {
    throw UnsupportedError('Platform not supported');
  }

  Future<void> exec(String sql) {
    throw UnsupportedError('Platform not supported');
  }

  Future<List<Map<String, dynamic>>> read(String sql) {
    throw UnsupportedError('Platform not supported');
  }

  Future<List<Map<String, dynamic>>> readRaw(String sql) {
    throw UnsupportedError('Platform not supported');
  }

  Future<void> applyRemote({
    required String tableName,
    required String rowId,
    required SynclibOperation operation,
    required String sql,
    String? data,
  }) {
    throw UnsupportedError('Platform not supported');
  }

  Future<void> applyRemoteWithParams({
    required String tableName,
    required String rowId,
    required SynclibOperation operation,
    required String sql,
    required List<dynamic> params,
    String? data,
  }) {
    throw UnsupportedError('Platform not supported');
  }

  Future<void> skipLocalHash(bool skip) {
    throw UnsupportedError('Platform not supported');
  }

  Future<List<Change>> getPendingChanges({int limit = 100}) {
    throw UnsupportedError('Platform not supported');
  }

  Future<void> markSynced(int seqnum) {
    throw UnsupportedError('Platform not supported');
  }

  Future<void> deleteChange(int seqnum) {
    throw UnsupportedError('Platform not supported');
  }

  Future<void> beginBulkRemote() {
    throw UnsupportedError('Platform not supported');
  }

  Future<void> execBulkRemote(String sql) {
    throw UnsupportedError('Platform not supported');
  }

  Future<void> endBulkRemote({bool rollback = false}) {
    throw UnsupportedError('Platform not supported');
  }

  Future<void> updateRowHash(String tableName, String rowId) {
    throw UnsupportedError('Platform not supported');
  }

  Future<void> backfillRowHashes(String tableName) {
    throw UnsupportedError('Platform not supported');
  }

  Future<void> setHashColumns(String tableName, String columnsJson) {
    throw UnsupportedError('Platform not supported');
  }

  Future<int> getSchemaVersion() {
    throw UnsupportedError('Platform not supported');
  }

  Future<void> setSchemaVersion(int version) {
    throw UnsupportedError('Platform not supported');
  }

  Future<void> close() {
    throw UnsupportedError('Platform not supported');
  }
}
