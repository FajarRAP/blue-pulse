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
      expect(device.firstSeen, isNull);
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

    test('toMap serializes properly reflecting 100% of device_history schema', () {
      final first = DateTime(2026, 10, 8, 10, 0, 0);
      final last = DateTime(2026, 10, 8, 12, 0, 0);

      final device = BleDeviceModel(
        id: '11:22:33:44:55:66',
        name: 'Beacon 123',
        rawRssi: -25,
        smoothedRssi: -26.5,
        estimatedDistance: 0.5,
        zone: ProximityZone.veryStrong,
        lastSeen: last,
        firstSeen: first,
        txPower: -59,
      );

      final map = device.toMap();

      expect(map['id'], '11:22:33:44:55:66');
      expect(map['name'], 'Beacon 123');
      expect(map['raw_rssi'], -25);
      expect(map['smoothed_rssi'], -26.5);
      expect(map['estimated_distance'], 0.5);
      expect(map['proximity_zone'], 'veryStrong');
      expect(map['tx_power'], -59);
      expect(map['first_seen'], first.millisecondsSinceEpoch);
      expect(map['last_seen'], last.millisecondsSinceEpoch);
    });

    test('fromMap reconstitutes BleDeviceModel from SQLite row', () {
      final first = DateTime(2026, 10, 8, 10, 0, 0);
      final last = DateTime(2026, 10, 8, 12, 0, 0);

      final row = <String, dynamic>{
        'id': '99:88:77:66:55:44',
        'name': 'Fitness Tracker',
        'raw_rssi': -65,
        'smoothed_rssi': -66.2,
        'estimated_distance': 4.8,
        'proximity_zone': 'fair',
        'tx_power': -59,
        'first_seen': first.millisecondsSinceEpoch,
        'last_seen': last.millisecondsSinceEpoch,
      };

      final device = BleDeviceModel.fromMap(row);

      expect(device.id, '99:88:77:66:55:44');
      expect(device.name, 'Fitness Tracker');
      expect(device.rawRssi, -65);
      expect(device.smoothedRssi, -66.2);
      expect(device.estimatedDistance, 4.8);
      expect(device.zone, ProximityZone.fair);
      expect(device.txPower, -59);
      expect(device.firstSeen, first);
      expect(device.lastSeen, last);
    });

    test('fromMap handles null tx_power correctly', () {
      final row = <String, dynamic>{
        'id': '00:00:00:00:00:00',
        'name': 'Unknown Device',
        'raw_rssi': -85,
        'smoothed_rssi': -85.0,
        'estimated_distance': 22.0,
        'proximity_zone': 'veryWeak',
        'tx_power': null,
        'first_seen': now.millisecondsSinceEpoch,
        'last_seen': now.millisecondsSinceEpoch,
      };

      final device = BleDeviceModel.fromMap(row);
      expect(device.name, 'Unknown Device');
      expect(device.txPower, isNull);
      expect(device.zone, ProximityZone.veryWeak);
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
