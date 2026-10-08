import 'package:blue_pulse/core/constants/app_constants.dart';
import 'package:blue_pulse/data/datasources/local_database.dart';
import 'package:blue_pulse/data/models/ble_device_model.dart';

/// Repository interface contract for managing discovered BLE device history persistence.
abstract interface class DeviceHistoryRepository {
  /// Inserts or updates a discovered BLE device in persistent storage.
  Future<void> upsertDevice(BleDeviceModel device);

  /// Retrieves the list of historically observed devices, ordered newest first.
  Future<List<BleDeviceModel>> getHistory();

  /// Removes an individual device entry by its hardware identifier.
  Future<void> deleteDevice(String id);

  /// Clears the entire device history database table.
  Future<void> clearAll();
}

/// Concrete SQLite implementation of [DeviceHistoryRepository].
class DeviceHistoryRepositoryImpl(final LocalDatabase _localDatabase)
    implements DeviceHistoryRepository {

  @override
  Future<void> upsertDevice(BleDeviceModel device) async {
    final db = await _localDatabase.database;

    // Check if the device already exists to preserve the initial first_seen timestamp
    final existingRows = await db.query(
      AppConstants.historyTableName,
      columns: ['first_seen'],
      where: 'id = ?',
      whereArgs: [device.id],
      limit: 1,
    );

    final firstSeenMillis = existingRows.isNotEmpty
        ? (existingRows.first['first_seen'] as num).toInt()
        : (device.firstSeen ?? device.lastSeen).millisecondsSinceEpoch;

    final map = device.toMap();
    map['first_seen'] = firstSeenMillis;

    await db.insert(
      AppConstants.historyTableName,
      map,
      conflictAlgorithm: .replace,
    );
  }

  @override
  Future<List<BleDeviceModel>> getHistory() async {
    final db = await _localDatabase.database;
    final rows = await db.query(
      AppConstants.historyTableName,
      orderBy: 'last_seen DESC',
    );

    return rows.map(BleDeviceModel.fromMap).toList();
  }

  @override
  Future<void> deleteDevice(String id) async {
    final db = await _localDatabase.database;
    await db.delete(
      AppConstants.historyTableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> clearAll() async {
    final db = await _localDatabase.database;
    await db.delete(AppConstants.historyTableName);
  }
}
