import 'dart:convert';

import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

class LocalProductDatabase {
  static const spacesTable = 'spaces';
  static const productsTable = 'products';
  static const recordsTable = 'care_records';
  static const requestsTable = 'search_requests';
  static const submissionsTable = 'submissions';
  static const metadataTable = 'app_metadata';

  static const dataTables = {
    spacesTable,
    productsTable,
    recordsTable,
    requestsTable,
    submissionsTable,
  };

  Database? _database;

  Future<Database> get database async {
    final existing = _database;
    if (existing != null) {
      return existing;
    }
    final databasePath = await getDatabasesPath();
    final opened = await openDatabase(
      path.join(databasePath, 'clean_up_user_data.db'),
      version: 1,
      onCreate: (database, version) async {
        for (final table in dataTables) {
          await database.execute(
            'CREATE TABLE $table ('
            'id TEXT PRIMARY KEY, '
            'sort_order INTEGER NOT NULL, '
            'payload TEXT NOT NULL'
            ')',
          );
        }
        await database.execute(
          'CREATE TABLE $metadataTable ('
          'key TEXT PRIMARY KEY, '
          'value TEXT NOT NULL'
          ')',
        );
      },
    );
    _database = opened;
    return opened;
  }

  Future<List<Map<String, Object?>>> readItems(String table) async {
    _checkTable(table);
    final db = await database;
    final rows = await db.query(table, orderBy: 'sort_order ASC');
    return [
      for (final row in rows)
        Map<String, Object?>.from(
          jsonDecode(row['payload']! as String) as Map,
        ),
    ];
  }

  Future<void> writeItems(
    String table,
    List<Map<String, Object?>> items,
  ) async {
    _checkTable(table);
    final db = await database;
    await db.transaction((transaction) async {
      await _replaceItems(transaction, table, items);
    });
  }

  Future<String?> readMetadata(String key) async {
    final db = await database;
    final rows = await db.query(
      metadataTable,
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first['value']! as String;
  }

  Future<void> writeMetadata(String key, String value) async {
    final db = await database;
    await db.insert(
      metadataTable,
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> replaceAllData({
    required Map<String, List<Map<String, Object?>>> tables,
    required Map<String, String> metadata,
  }) async {
    for (final table in tables.keys) {
      _checkTable(table);
    }
    final db = await database;
    await db.transaction((transaction) async {
      for (final entry in tables.entries) {
        await _replaceItems(transaction, entry.key, entry.value);
      }
      for (final entry in metadata.entries) {
        await transaction.insert(
          metadataTable,
          {'key': entry.key, 'value': entry.value},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<void> clearUserData() async {
    final db = await database;
    await db.transaction((transaction) async {
      for (final table in dataTables) {
        await transaction.delete(table);
      }
      await transaction.delete(metadataTable);
    });
  }

  Future<void> _replaceItems(
    DatabaseExecutor executor,
    String table,
    List<Map<String, Object?>> items,
  ) async {
    await executor.delete(table);
    for (var index = 0; index < items.length; index++) {
      final item = items[index];
      final id = item['id'];
      if (id is! String || id.isEmpty) {
        throw const FormatException('저장 항목의 ID가 올바르지 않아요.');
      }
      await executor.insert(
        table,
        {
          'id': id,
          'sort_order': index,
          'payload': jsonEncode(item),
        },
      );
    }
  }

  void _checkTable(String table) {
    if (!dataTables.contains(table)) {
      throw ArgumentError.value(table, 'table', 'Unknown data table');
    }
  }
}
