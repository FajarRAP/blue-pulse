import 'package:flutter_test/flutter_test.dart';

import 'package:blue_pulse/core/utils/signal_math.dart';
import 'package:blue_pulse/data/models/ble_device_model.dart';

void main() {
  group('BleDeviceModel - Entity & Serialization', () {
    final now = DateTime(2026, 10, 8, 12, 0, 0);

    test('initializes with required named parameters correctly', () {
      final device = BleDeviceModel(
        id: 'AA:BB:CC:DD:EE:FF',
        name: 'Smart Beacon Pro',
        rawRssi: -45,
        smoothedRssi: -47.2,
        estimatedDistance: 2.1,
        zone: ProximityZone.strong,
        lastSeen: now,
      );

      expect(device.id, 'AA:BB:CC:DD:EE:FF');
      expect(device.name, 'Smart Beacon Pro');
      expect(device.rawRssi, -45);
      expect(device.smoothedRssi, -47.2);
      expect(device.estimatedDistance, 2.1);
      expect(device.zone, ProximityZone.strong);
      expect(device.lastSeen, now);
      expect(device.firstSeen, now);
      expect(device.txPower, isNull);
    });

    test('copyWith updates specified fields only', () {
      final device = BleDeviceModel(
        id: 'AA:BB:CC:DD:EE:FF',
        name: 'Device A',
        rawRssi: -70,
        smoothedRssi: -70.0,
        estimatedDistance: 10.0,
        zone: ProximityZone.weak,
        lastSeen: now,
      );

      final updated = device.copyWith(
        rawRssi: -35,
        zone: ProximityZone.strong,
      );

      expect(updated.id, 'AA:BB:CC:DD:EE:FF');
      expect(updated.name, 'Device A');
      expect(updated.rawRssi, -35);
      expect(updated.smoothedRssi, -70.0);
      expect(updated.zone, ProximityZone.strong);
      expect(updated.lastSeen, now);
    });

    test('toMap serializes properly for SQLite', () {
      final first = DateTime(2026, 10, 8, 10, 0, 0);
      final last = DateTime(2026, 10, 8, 12, 0, 0);

      final device = BleDeviceModel(
        id: '11:22:33:44:55:66',
        name: 'Beacon 123',
        rawRssi: -25,
        smoothedRssi: -25.0,
        estimatedDistance: 0.5,
        zone: ProximityZone.veryStrong,
        lastSeen: last,
        firstSeen: first,
      );

      final map = device.toMap();

      expect(map['id'], '11:22:33:44:55:66');
      expect(map['name'], 'Beacon 123');
      expect(map['last_rssi'], -25);
      expect(map['last_distance'], 0.5);
      expect(map['last_zone'], 'veryStrong');
      expect(map['first_seen'], first.millisecondsSinceEpoch);
      expect(map['last_seen'], last.millisecondsSinceEpoch);
    });

    test('fromMap reconstitutes BleDeviceModel from SQLite row', () {
      final first = DateTime(2026, 10, 8, 10, 0, 0);
      final last = DateTime(2026, 10, 8, 12, 0, 0);

      final row = <String, dynamic>{
        'id': '99:88:77:66:55:44',
        'name': 'Fitness Tracker',
        'last_rssi': -65,
        'last_distance': 4.8,
        'last_zone': 'fair',
        'first_seen': first.millisecondsSinceEpoch,
        'last_seen': last.millisecondsSinceEpoch,
      };

      final device = BleDeviceModel.fromMap(row);

      expect(device.id, '99:88:77:66:55:44');
      expect(device.name, 'Fitness Tracker');
      expect(device.rawRssi, -65);
      expect(device.smoothedRssi, -65.0);
      expect(device.estimatedDistance, 4.8);
      expect(device.zone, ProximityZone.fair);
      expect(device.firstSeen, first);
      expect(device.lastSeen, last);
    });

    test('fromMap falls back to "Unknown Device" when name is null or empty', () {
      final row = <String, dynamic>{
        'id': '00:00:00:00:00:00',
        'name': '',
        'last_rssi': -85,
        'last_distance': 22.0,
        'last_zone': 'veryWeak',
        'last_seen': now.millisecondsSinceEpoch,
      };

      final device = BleDeviceModel.fromMap(row);
      expect(device.name, 'Unknown Device');
    });

    test('equality and hashCode are based on Equatable value equality', () {
      final device1 = BleDeviceModel(
        id: 'AA:BB:CC',
        name: 'Device 1',
        rawRssi: -50,
        smoothedRssi: -50.0,
        estimatedDistance: 2.0,
        zone: ProximityZone.strong,
        lastSeen: now,
      );

      final device2 = BleDeviceModel(
        id: 'AA:BB:CC',
        name: 'Device 1',
        rawRssi: -50,
        smoothedRssi: -50.0,
        estimatedDistance: 2.0,
        zone: ProximityZone.strong,
        lastSeen: now,
      );

      final deviceDifferent = device1.copyWith(rawRssi: -30);

      expect(device1, equals(device2));
      expect(device1.hashCode, equals(device2.hashCode));
      expect(device1, isNot(equals(deviceDifferent)));
    });
  });
}
