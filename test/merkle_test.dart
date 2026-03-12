/// Cross-platform Merkle hash consistency tests for Dart implementation.
///
/// These tests verify that the pure Dart Merkle implementation produces
/// the same hashes as TypeScript, C, and Elixir.

import 'package:test/test.dart';
import 'package:synclib_flutter/src/merkle.dart';

/// Mock database that returns pre-defined rows
class MockMerkleDatabase implements MerkleDatabase {
  final Map<String, List<Map<String, dynamic>>> tables = {};

  void addTable(String name, List<Map<String, dynamic>> rows) {
    tables[name] = rows;
  }

  @override
  Future<List<Map<String, dynamic>>> read(String sql) async {
    // Parse simple SQL queries for testing
    final sqlLower = sql.toLowerCase();

    // COUNT query
    if (sqlLower.contains('count(*)')) {
      final tableMatch = RegExp(r'from\s+(\w+)').firstMatch(sqlLower);
      if (tableMatch != null) {
        final tableName = tableMatch.group(1)!;
        final rows = tables[tableName] ?? [];
        return [{'count': rows.length}];
      }
    }

    // SELECT with WHERE (single row lookup)
    if (sqlLower.contains('where')) {
      final tableMatch = RegExp(r'from\s+(\w+)').firstMatch(sqlLower);
      final idMatch = RegExp(r"=\s*'([^']+)'").firstMatch(sql);
      if (tableMatch != null && idMatch != null) {
        final tableName = tableMatch.group(1)!;
        final rowId = idMatch.group(1)!;
        final rows = tables[tableName] ?? [];
        return rows.where((r) => r['id'].toString() == rowId).toList();
      }
    }

    // SELECT with ORDER BY, LIMIT, OFFSET (block query)
    if (sqlLower.contains('order by')) {
      final tableMatch = RegExp(r'from\s+(\w+)').firstMatch(sqlLower);
      final limitMatch = RegExp(r'limit\s+(\d+)').firstMatch(sqlLower);
      final offsetMatch = RegExp(r'offset\s+(\d+)').firstMatch(sqlLower);

      if (tableMatch != null) {
        final tableName = tableMatch.group(1)!;
        final limit = limitMatch != null ? int.parse(limitMatch.group(1)!) : 100;
        final offset = offsetMatch != null ? int.parse(offsetMatch.group(1)!) : 0;

        var rows = tables[tableName] ?? [];
        // Sort by id
        rows = List.from(rows)..sort((a, b) => a['id'].toString().compareTo(b['id'].toString()));
        // Apply offset and limit
        if (offset < rows.length) {
          final end = (offset + limit) < rows.length ? (offset + limit) : rows.length;
          return rows.sublist(offset, end);
        }
        return [];
      }
    }

    return [];
  }
}

void main() {
  group('SHA256 basic', () {
    final computer = MerkleComputer(MockMerkleDatabase());

    test('hashes empty string correctly', () {
      // Access private method via sorted json of empty object
      final hash = computer.buildMerkleRoot([]);
      // Empty should return empty
      expect(hash, '');
    });
  });

  group('JSON escaping', () {
    final computer = MerkleComputer(MockMerkleDatabase());

    test('escapes double quotes', () {
      final json = computer.buildSortedJson({'text': 'Hello "World"'});
      expect(json, '{"text":"Hello \\"World\\""}');
    });

    test('escapes backslashes', () {
      final json = computer.buildSortedJson({'path': 'C:\\Users\\test'});
      expect(json, '{"path":"C:\\\\Users\\\\test"}');
    });

    test('sorts keys alphabetically', () {
      final json = computer.buildSortedJson({'z': 1, 'a': 2, 'm': 3});
      expect(json, '{"a":2,"m":3,"z":1}');
    });

    test('handles null values', () {
      final json = computer.buildSortedJson({'id': 'test', 'data': null});
      expect(json, '{"data":null,"id":"test"}');
    });

    test('handles boolean values', () {
      final json = computer.buildSortedJson({'active': true, 'deleted': false});
      expect(json, '{"active":true,"deleted":false}');
    });
  });

  group('Test Vector: single_row_simple', () {
    late MockMerkleDatabase db;
    late MerkleComputer computer;

    final row = {'id': 'abc123', 'name': 'John Doe', 'age': 30};
    const expectedSortedJson = '{"age":30,"id":"abc123","name":"John Doe"}';
    const expectedRowHash = 'a18e156799a62c452a3335a0bffeb68ee4766744fa8a87eb22ef690cf0fc7fd2';
    const expectedBlockHash = '8fdc1b10d493c753c4986d5d3e1423114d189c2c0819b449bf64e7718c5a2108';
    const expectedMerkleRoot = '8fdc1b10d493c753c4986d5d3e1423114d189c2c0819b449bf64e7718c5a2108';

    setUp(() {
      db = MockMerkleDatabase();
      db.addTable('test_simple', [row]);
      computer = MerkleComputer(db);
    });

    test('produces correct sorted JSON', () {
      expect(computer.buildSortedJson(row), expectedSortedJson);
    });

    test('produces correct row hash', () async {
      final hash = await computer.rowHash('test_simple', 'abc123');
      expect(hash, expectedRowHash);
    });

    test('produces correct block hash', () async {
      final result = await computer.blockHash('test_simple', 0);
      expect(result.hash, expectedBlockHash);
      expect(result.rowCount, 1);
    });

    test('produces correct merkle root', () async {
      final info = await computer.merkleRoot('test_simple');
      expect(info.rootHash, expectedMerkleRoot);
      expect(info.blockCount, 1);
      expect(info.rowCount, 1);
    });
  });

  group('Test Vector: two_rows_one_block', () {
    late MockMerkleDatabase db;
    late MerkleComputer computer;

    final rows = [
      {'id': 'row1', 'value': 'first'},
      {'id': 'row2', 'value': 'second'},
    ];
    const expectedRowHashes = [
      'cfbbfbe9e97bfaf76ea6be56049fd164f99cb63249ba29ec0534f7356b73a1cd',
      '3dcec0029e6bcf589129743455264aa354594130a01a8d255a0ee6ac6a761ccd',
    ];
    const expectedBlockHash = '8ad2e4889e3d3277b45728d9ef43b4e5ed2525c3e62a575b66cf7d08de8f585c';

    setUp(() {
      db = MockMerkleDatabase();
      db.addTable('test_two', rows);
      computer = MerkleComputer(db);
    });

    test('produces correct row hashes', () async {
      final hash1 = await computer.rowHash('test_two', 'row1');
      final hash2 = await computer.rowHash('test_two', 'row2');
      expect(hash1, expectedRowHashes[0]);
      expect(hash2, expectedRowHashes[1]);
    });

    test('produces correct block hash', () async {
      final result = await computer.blockHash('test_two', 0);
      expect(result.hash, expectedBlockHash);
      expect(result.rowCount, 2);
    });
  });

  group('Test Vector: null_and_boolean', () {
    late MerkleComputer computer;

    final row = {'id': 'test1', 'active': true, 'deleted': false, 'metadata': null};
    const expectedSortedJson = '{"active":true,"deleted":false,"id":"test1","metadata":null}';
    const expectedRowHash = '2389dd0671288d112dc56ee23dfd2c578fcb657b31a2b274ad0a3fe95341c8bb';

    setUp(() {
      computer = MerkleComputer(MockMerkleDatabase());
    });

    test('produces correct sorted JSON', () {
      expect(computer.buildSortedJson(row), expectedSortedJson);
    });

    test('produces correct row hash', () {
      final hash = computer.rowHashFromData('test1', row);
      expect(hash, expectedRowHash);
    });
  });

  group('Test Vector: special_characters', () {
    late MockMerkleDatabase db;
    late MerkleComputer computer;

    final row = {'id': 'esc1', 'text': 'Hello "World"', 'path': 'C:\\Users\\test'};
    const expectedSortedJson = '{"id":"esc1","path":"C:\\\\Users\\\\test","text":"Hello \\"World\\""}';
    const expectedRowHash = 'e772acfd9030b2ccf34426ea8ccfb2b126e23ca3f6763509e7b66fc60d5619af';

    setUp(() {
      db = MockMerkleDatabase();
      db.addTable('test_special', [row]);
      computer = MerkleComputer(db);
    });

    test('produces correct sorted JSON', () {
      expect(computer.buildSortedJson(row), expectedSortedJson);
    });

    test('produces correct row hash', () async {
      final hash = await computer.rowHash('test_special', 'esc1');
      expect(hash, expectedRowHash);
    });
  });

  group('Test Vector: three_blocks', () {
    late MockMerkleDatabase db;
    late MerkleComputer computer;

    final rows = [
      {'id': 'a1', 'x': 1},
      {'id': 'a2', 'x': 2},
      {'id': 'b1', 'x': 3},
      {'id': 'b2', 'x': 4},
      {'id': 'c1', 'x': 5},
      {'id': 'c2', 'x': 6},
    ];
    const expectedRowHashes = [
      '9ee3f8025f07785e61dc77c23e2f6c1fe1113a23c9abdb68fd10d1c9707ad5cd',
      '63c714fa9b002e1db006209888d89e202bd4ec344be9793a3810376a5993fced',
      'a44e09ec351797bd90d724bb2cac91fb15791d4c7377998703c209de40d87aee',
      '7baff5f1145421d996dda97045cd4dae7719ff3c849a83a53ad033d9eddd8327',
      '6f88ab3dc8a61010ba4bdb59792f2f309368a4259f16032366cb2247215ab9fa',
      '60c988c51f2a4b0a45196e4049df75aee8296ed45f4ba850cbc6ad9397a19418',
    ];
    const expectedBlockHashes = [
      'e55702f1dcbd9c1fa93a07767a73f9a064d8f1140f46091ba3b5b1dab781d6da',
      '4f151c0c3092e2031a1818791f2aa5b337d3e8714d850ea1da94c77703f914e1',
      'abcced946272edc888c8ba37b3e148e91de153e49c68c8a614c2f7697ae55a38',
    ];
    const expectedMerkleRoot = 'ab66c51807f7dfa2bd8431cd7b642b04818fe3a0425d0eae8d418b275e798f82';

    setUp(() {
      db = MockMerkleDatabase();
      db.addTable('test_blocks', rows);
      computer = MerkleComputer(db);
    });

    test('produces correct row hashes', () {
      for (int i = 0; i < rows.length; i++) {
        final hash = computer.rowHashFromData(rows[i]['id'] as String, rows[i]);
        expect(hash, expectedRowHashes[i], reason: 'Row ${rows[i]['id']} hash mismatch');
      }
    });

    test('produces correct block hashes', () async {
      for (int i = 0; i < 3; i++) {
        final result = await computer.blockHash('test_blocks', i, blockSize: 2);
        expect(result.hash, expectedBlockHashes[i], reason: 'Block $i hash mismatch');
        expect(result.rowCount, 2);
      }
    });

    test('produces correct merkle root', () async {
      final info = await computer.merkleRoot('test_blocks', blockSize: 2);
      expect(info.rootHash, expectedMerkleRoot);
      expect(info.blockCount, 3);
      expect(info.rowCount, 6);
    });

    test('buildMerkleRoot handles odd block count correctly', () {
      // With 3 blocks, the tree should be:
      // Level 0: [block0, block1, block2]
      // Level 1: [hash(block0+block1), block2]  <- block2 passed up as-is
      // Level 2: [hash(level1[0]+block2)]
      final root = computer.buildMerkleRoot(expectedBlockHashes);
      expect(root, expectedMerkleRoot);
    });
  });

  group('Edge cases', () {
    late MockMerkleDatabase db;
    late MerkleComputer computer;

    setUp(() {
      db = MockMerkleDatabase();
      computer = MerkleComputer(db);
    });

    test('empty table returns empty merkle root', () async {
      db.addTable('empty_table', []);
      final info = await computer.merkleRoot('empty_table');
      expect(info.rootHash, '');
      expect(info.blockCount, 0);
      expect(info.rowCount, 0);
    });

    test('single block merkle root equals block hash', () async {
      db.addTable('single_block', [
        {'id': '1', 'value': 'a'},
        {'id': '2', 'value': 'b'},
      ]);
      final info = await computer.merkleRoot('single_block', blockSize: 10);
      final blockResult = await computer.blockHash('single_block', 0, blockSize: 10);
      expect(info.rootHash, blockResult.hash);
    });
  });
}
