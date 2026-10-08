import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';

import 'package:blue_pulse/core/utils/signal_math.dart';
import 'package:blue_pulse/data/datasources/local_database.dart';
import 'package:blue_pulse/data/models/ble_device_model.dart';
import 'package:blue_pulse/data/repositories/device_history_repository.dart';

class FakeDatabase extends Fake implements Database {
  final Map<String, Map<String, dynamic>> _storage = {};

  @override
  Future<List<Map<String, dynamic>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    var items = _storage.values.toList();
    if (where != null && whereArgs != null && whereArgs.isNotEmpty) {
      final id = whereArgs.first as String;
      items = items.where((element) => element['id'] == id).toList();
    }
    if (orderBy == 'last_seen DESC') {
      items.sort((a, b) => (b['last_seen'] as int).compareTo(a['last_seen'] as int));
    }
    if (limit != null) {
      items = items.take(limit).toList();
    }
    return items;
  }

  @override
  Future<int> insert(
    String table,
    Map<String, Object?> values, {
    String? nullColumnHack,
    ConflictAlgorithm? conflictAlgorithm,
  }) async {
    final id = values['id'] as String;
    _storage[id] = Map<String, dynamic>.from(values);
    return 1;
  }

  @override
  Future<int> delete(
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    if (where == null) {
      final count = _storage.length;
      _storage.clear();
      return count;
    }
    if (whereArgs != null && whereArgs.isNotEmpty) {
      final id = whereArgs.first as String;
      return _storage.remove(id) != null ? 1 : 0;
    }
    return 0;
  }
}

class FakeLocalDatabase extends Fake implements LocalDatabase {
  FakeLocalDatabase(this._db);

  final Database _db;

  @override
  Future<Database> get database async => _db;
}

void main() {
  late FakeDatabase fakeDb;
  late FakeLocalDatabase fakeLocalDb;
  late DeviceHistoryRepository repository;

  setUp(() {
    fakeDb = FakeDatabase();
    fakeLocalDb = FakeLocalDatabase(fakeDb);
    repository = DeviceHistoryRepositoryImpl(fakeLocalDb);
  });

  group('DeviceHistoryRepositoryImpl', () {
    final t1 = DateTime(2026, 10, 8, 10, 0, 0);
    final t2 = DateTime(2026, 10, 8, 11, 0, 0);
    final t3 = DateTime(2026, 10, 8, 12, 0, 0);

    test('upsertDevice inserts new device and preserves firstSeen on subsequent update', () async {
      final deviceInitial = BleDeviceModel(
        id: 'AA:11',
        name: 'Beacon Initial',
        rawRssi: -75,
        smoothedRssi: -75.0,
        estimatedDistance: 12.0,
        zone: ProximityZone.weak,
        lastSeen: t1,
        firstSeen: t1,
      );

      await repository.upsertDevice(deviceInitial);

      final history1 = await repository.getHistory();
      expect(history1.length, 1);
      expect(history1.first.id, 'AA:11');
      expect(history1.first.name, 'Beacon Initial');
      expect(history1.first.firstSeen, t1);
      expect(history1.first.lastSeen, t1);

      // Now update the device with new RSSI and new lastSeen
      final deviceUpdated = BleDeviceModel(
        id: 'AA:11',
        name: 'Beacon Renamed',
        rawRssi: -40,
        smoothedRssi: -45.0,
        estimatedDistance: 2.0,
        zone: ProximityZone.strong,
        lastSeen: t2,
        firstSeen: t2, // Even if caller passes t2 as firstSeen, repository should preserve t1
      );

      await repository.upsertDevice(deviceUpdated);

      final history2 = await repository.getHistory();
      expect(history2.length, 1);
      expect(history2.first.id, 'AA:11');
      expect(history2.first.name, 'Beacon Renamed');
      expect(history2.first.rawRssi, -40);
      expect(history2.first.firstSeen, t1); // Preserved original discovery timestamp
      expect(history2.first.lastSeen, t2); // Updated last seen
    });

    test('getHistory returns records ordered by lastSeen DESC', () async {
      final d1 = BleDeviceModel(
        id: 'DEV_1',
        name: 'Device 1',
        rawRssi: -80,
        smoothedRssi: -80.0,
        estimatedDistance: 15.0,
        zone: ProximityZone.veryWeak,
        lastSeen: t1,
      );
      final d2 = BleDeviceModel(
        id: 'DEV_2',
        name: 'Device 2',
        rawRssi: -40,
        smoothedRssi: -40.0,
        estimatedDistance: 2.0,
        zone: ProximityZone.strong,
        lastSeen: t3,
      );
      final d3 = BleDeviceModel(
        id: 'DEV_3',
        name: 'Device 3',
        rawRssi: -60,
        smoothedRssi: -60.0,
        estimatedDistance: 6.0,
        zone: ProximityZone.fair,
        lastSeen: t2,
      );

      await repository.upsertDevice(d1);
      await repository.upsertDevice(d2);
      await repository.upsertDevice(d3);

      final history = await repository.getHistory();
      expect(history.length, 3);
      expect(history[0].id, 'DEV_2'); // t3 is newest
      expect(history[1].id, 'DEV_3'); // t2 is middle
      expect(history[2].id, 'DEV_1'); // t1 is oldest
    });

    test('deleteDevice removes individual device by id', () async {
      final d1 = BleDeviceModel(
        id: 'TARGET',
        name: 'Target',
        rawRssi: -50,
        smoothedRssi: -50.0,
        estimatedDistance: 3.0,
        zone: ProximityZone.strong,
        lastSeen: t1,
      );
      final d2 = BleDeviceModel(
        id: 'OTHER',
        name: 'Other',
        rawRssi: -60,
        smoothedRssi: -60.0,
        estimatedDistance: 6.0,
        zone: ProximityZone.fair,
        lastSeen: t1,
      );

      await repository.upsertDevice(d1);
      await repository.upsertDevice(d2);

      await repository.deleteDevice('TARGET');

      final remaining = await repository.getHistory();
      expect(remaining.length, 1);
      expect(remaining.first.id, 'OTHER');
    });

    test('clearAll removes all devices from table', () async {
      final d1 = BleDeviceModel(
        id: 'DEV_1',
        name: 'Device 1',
        rawRssi: -50,
        smoothedRssi: -50.0,
        estimatedDistance: 3.0,
        zone: ProximityZone.strong,
        lastSeen: t1,
      );
      await repository.upsertDevice(d1);

      await repository.clearAll();

      final history = await repository.getHistory();
      expect(history, isEmpty);
    });
  });
}
