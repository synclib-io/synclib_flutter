import 'package:flutter/material.dart';
import 'package:synclib_flutter/synclib_flutter.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  SynclibDatabase? _db;
  String _status = 'Not initialized';
  List<Change> _changes = [];
  List<Map<String, dynamic>> _users = [];

  @override
  void initState() {
    super.initState();
    _initDatabase();
  }

  Future<void> _initDatabase() async {
    try {
      // Get application documents directory
      final directory = await getApplicationDocumentsDirectory();
      final dbPath = '${directory.path}/test.db';

      setState(() => _status = 'Opening database at $dbPath...');

      // Open database
      _db = await SynclibDatabase.open(dbPath);

      // Create a test table
      await _db!.exec('''
        CREATE TABLE IF NOT EXISTS users (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          email TEXT
        )
      ''');

      setState(() => _status = 'Database initialized successfully');
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  Future<void> _insertUser() async {
    if (_db == null) {
      setState(() => _status = 'Database not open');
      return;
    }

    try {
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final name = 'User $id';
      final email = 'user$id@example.com';

      await _db!.write(
        tableName: 'users',
        rowId: id,
        operation: SynclibOperation.insert,
        sql: "INSERT INTO users (id, name, email) VALUES ('$id', '$name', '$email')",
        data: '{"id":"$id","name":"$name","email":"$email"}',
      );

      setState(() => _status = 'Inserted user: $name');
      await _loadChanges();
    } catch (e) {
      setState(() => _status = 'Insert error: $e');
    }
  }

  Future<void> _loadChanges() async {
    if (_db == null) return;

    try {
      final changes = await _db!.getPendingChanges(limit: 10);
      setState(() {
        _changes = changes;
        _status = 'Loaded ${changes.length} pending changes';
      });
    } catch (e) {
      setState(() => _status = 'Load changes error: $e');
    }
  }

  Future<void> _markSynced() async {
    if (_db == null || _changes.isEmpty) return;

    try {
      final lastSeqnum = _changes.last.seqnum;
      await _db!.markSynced(lastSeqnum);
      setState(() => _status = 'Marked changes as synced up to $lastSeqnum');
      await _loadChanges();
    } catch (e) {
      setState(() => _status = 'Mark synced error: $e');
    }
  }

  Future<void> _readUsers() async {
    if (_db == null) {
      setState(() => _status = 'Database not open');
      return;
    }

    try {
      final users = await _db!.read('SELECT * FROM users ORDER BY id DESC LIMIT 10');
      setState(() {
        _users = users;
        _status = 'Loaded ${users.length} users from database';
      });
    } catch (e) {
      setState(() => _status = 'Read error: $e');
    }
  }

  @override
  void dispose() {
    _db?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Synclib Flutter Example'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Status: $_status',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _insertUser,
                child: const Text('Insert User'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _loadChanges,
                child: const Text('Load Pending Changes'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _changes.isNotEmpty ? _markSynced : null,
                child: const Text('Mark All as Synced'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _readUsers,
                child: const Text('Read Users (SELECT)'),
              ),
              const SizedBox(height: 20),
              Text(
                'Users in Database (${_users.length}):',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              Expanded(
                child: _users.isEmpty
                    ? const Center(child: Text('No users loaded. Click "Read Users" button.'))
                    : ListView.builder(
                        itemCount: _users.length,
                        itemBuilder: (context, index) {
                          final user = _users[index];
                          return Card(
                            child: ListTile(
                              title: Text(user['name']?.toString() ?? 'Unknown'),
                              subtitle: Text(
                                'ID: ${user['id']}\n'
                                'Email: ${user['email']?.toString() ?? "N/A"}',
                              ),
                              isThreeLine: true,
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 20),
              Text(
                'Pending Changes (${_changes.length}):',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 150,
                child: _changes.isEmpty
                    ? const Center(child: Text('No pending changes'))
                    : ListView.builder(
                        itemCount: _changes.length,
                        itemBuilder: (context, index) {
                          final change = _changes[index];
                          return Card(
                            child: ListTile(
                              title: Text('${change.operation.name.toUpperCase()} - ${change.tableName}'),
                              subtitle: Text(
                                'Row ID: ${change.rowId}\n'
                                'Seqnum: ${change.seqnum}',
                              ),
                              dense: true,
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
