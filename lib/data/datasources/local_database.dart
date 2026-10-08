import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'package:blue_pulse/core/constants/app_constants.dart';

/// SQLite Database DataSource for persisting discovered BLE device history.
class LocalDatabase {
  LocalDatabase([this._database]);

  Database? _database;

  /// Returns the open [Database] instance, initializing it lazily if not already open.
  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    _database = await _initDatabase();
    return _database!;
  }

  /// Initializes the SQLite database and executes initial schema migrations.
  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = p.join(databasesPath, AppConstants.databaseName);

    return await openDatabase(
      path,
      version: AppConstants.databaseVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE ${AppConstants.historyTableName} (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            last_rssi INTEGER NOT NULL,
            last_distance REAL NOT NULL,
            last_zone TEXT NOT NULL,
            first_seen INTEGER NOT NULL,
            last_seen INTEGER NOT NULL
          );
        ''');

        await db.execute('''
          CREATE INDEX IF NOT EXISTS idx_last_seen ON ${AppConstants.historyTableName}(last_seen DESC);
        ''');
      },
    );
  }

  /// Closes the underlying database connection.
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
