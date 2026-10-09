import 'package:flutter_test/flutter_test.dart';

import 'package:blue_pulse/core/utils/signal_math.dart';
import 'package:blue_pulse/data/models/ble_device_model.dart';
import 'package:blue_pulse/data/repositories/device_history_repository.dart';
import 'package:blue_pulse/viewmodels/history_viewmodel.dart';

class MockDeviceHistoryRepository implements DeviceHistoryRepository {
  List<BleDeviceModel> devices = [];
  bool shouldThrowOnGetHistory = false;
  bool shouldThrowOnDelete = false;
  bool shouldThrowOnClearAll = false;

  int getHistoryCallCount = 0;
  int deleteDeviceCallCount = 0;
  int clearAllCallCount = 0;
  String? lastDeletedId;

  @override
  Future<void> upsertDevice(BleDeviceModel device) async {
    final index = devices.indexWhere((d) => d.id == device.id);
    if (index >= 0) {
      devices[index] = device;
    } else {
      devices.add(device);
    }
  }

  @override
  Future<List<BleDeviceModel>> getHistory() async {
    getHistoryCallCount++;
    if (shouldThrowOnGetHistory) {
      throw Exception('Database query failed');
    }
    return List.from(devices);
  }

  @override
  Future<void> deleteDevice(String id) async {
    deleteDeviceCallCount++;
    lastDeletedId = id;
    if (shouldThrowOnDelete) {
      throw Exception('Failed to delete device $id');
    }
    devices.removeWhere((d) => d.id == id);
  }

  @override
  Future<void> clearAll() async {
    clearAllCallCount++;
    if (shouldThrowOnClearAll) {
      throw Exception('Failed to clear database');
    }
    devices.clear();
  }
}

BleDeviceModel createDummyDevice({
  required String id,
  required String name,
  required int rawRssi,
  required ProximityZone zone,
  required DateTime lastSeen,
}) {
  return BleDeviceModel(
    id: id,
    name: name,
    rawRssi: rawRssi,
    smoothedRssi: rawRssi.toDouble(),
    estimatedDistance: 1.5,
    zone: zone,
    lastSeen: lastSeen,
  );
}

void main() {
  late MockDeviceHistoryRepository repository;
  late HistoryViewModel viewModel;

  setUp(() {
    repository = MockDeviceHistoryRepository();
    viewModel = HistoryViewModel(repository);
  });

  tearDown(() {
    viewModel.dispose();
  });

  group('HistoryViewModel - Initial State', () {
    test('initial state has empty devices, not loading, and no error', () {
      expect(viewModel.devices, isEmpty);
      expect(viewModel.isEmpty, isTrue);
      expect(viewModel.isLoading, isFalse);
      expect(viewModel.errorMessage, isNull);
    });
  });

  group('HistoryViewModel - Loading History', () {
    test('loadHistory populates devices correctly from repository', () async {
      final now = DateTime.now();
      final device1 = createDummyDevice(
        id: 'AA:BB:CC:11:22:33',
        name: 'Device Alpha',
        rawRssi: -50,
        zone: ProximityZone.strong,
        lastSeen: now,
      );
      final device2 = createDummyDevice(
        id: 'DD:EE:FF:44:55:66',
        name: 'Device Beta',
        rawRssi: -75,
        zone: ProximityZone.weak,
        lastSeen: now.subtract(const Duration(minutes: 5)),
      );

      repository.devices = [device1, device2];

      final notifications = <bool>[];
      viewModel.addListener(() => notifications.add(viewModel.isLoading));

      await viewModel.loadHistory();

      expect(repository.getHistoryCallCount, equals(1));
      expect(viewModel.devices.length, equals(2));
      expect(viewModel.devices[0].id, equals('AA:BB:CC:11:22:33'));
      expect(viewModel.devices[1].id, equals('DD:EE:FF:44:55:66'));
      expect(viewModel.isEmpty, isFalse);
      expect(viewModel.isLoading, isFalse);
      expect(viewModel.errorMessage, isNull);

      // Verify that notifyListeners was called during loading transition
      expect(notifications, contains(true));
      expect(notifications.last, isFalse);
    });

    test('loadHistory handles empty repository state gracefully', () async {
      repository.devices = [];

      await viewModel.loadHistory();

      expect(repository.getHistoryCallCount, equals(1));
      expect(viewModel.devices, isEmpty);
      expect(viewModel.isEmpty, isTrue);
      expect(viewModel.isLoading, isFalse);
      expect(viewModel.errorMessage, isNull);
    });

    test('loadHistory catches and sets errorMessage on query failure', () async {
      repository.shouldThrowOnGetHistory = true;

      await viewModel.loadHistory();

      expect(repository.getHistoryCallCount, equals(1));
      expect(viewModel.devices, isEmpty);
      expect(viewModel.isLoading, isFalse);
      expect(viewModel.errorMessage, contains('Database query failed'));
    });

    test('refreshHistory delegates to loadHistory', () async {
      repository.devices = [
        createDummyDevice(
          id: 'AA:11:22:33:44:55',
          name: 'Device Fresh',
          rawRssi: -45,
          zone: ProximityZone.strong,
          lastSeen: DateTime.now(),
        ),
      ];

      await viewModel.refreshHistory();

      expect(repository.getHistoryCallCount, equals(1));
      expect(viewModel.devices.length, equals(1));
      expect(viewModel.devices.first.name, equals('Device Fresh'));
    });
  });

  group('HistoryViewModel - Delete Device', () {
    test('deleteDevice invokes repository and removes item from local list', () async {
      final now = DateTime.now();
      final device1 = createDummyDevice(
        id: 'DEV-01',
        name: 'Alpha',
        rawRssi: -50,
        zone: ProximityZone.strong,
        lastSeen: now,
      );
      final device2 = createDummyDevice(
        id: 'DEV-02',
        name: 'Beta',
        rawRssi: -60,
        zone: ProximityZone.fair,
        lastSeen: now,
      );

      repository.devices = [device1, device2];
      await viewModel.loadHistory();
      expect(viewModel.devices.length, equals(2));

      var notified = false;
      viewModel.addListener(() => notified = true);

      await viewModel.deleteDevice('DEV-01');

      expect(repository.deleteDeviceCallCount, equals(1));
      expect(repository.lastDeletedId, equals('DEV-01'));
      expect(viewModel.devices.length, equals(1));
      expect(viewModel.devices.first.id, equals('DEV-02'));
      expect(repository.devices.length, equals(1));
      expect(notified, isTrue);
      expect(viewModel.errorMessage, isNull);
    });

    test('deleteDevice sets errorMessage when repository deletion fails', () async {
      final device = createDummyDevice(
        id: 'DEV-FAIL',
        name: 'Faulty Device',
        rawRssi: -50,
        zone: ProximityZone.strong,
        lastSeen: DateTime.now(),
      );

      repository.devices = [device];
      await viewModel.loadHistory();

      repository.shouldThrowOnDelete = true;

      var notified = false;
      viewModel.addListener(() => notified = true);

      await viewModel.deleteDevice('DEV-FAIL');

      expect(repository.deleteDeviceCallCount, equals(1));
      expect(viewModel.devices.length, equals(1)); // Device kept since deletion failed
      expect(viewModel.errorMessage, contains('Failed to delete device DEV-FAIL'));
      expect(notified, isTrue);
    });
  });

  group('HistoryViewModel - Clear All History', () {
    test('clearAllHistory wipes repository records and clears local list', () async {
      final now = DateTime.now();
      repository.devices = [
        createDummyDevice(
          id: 'DEV-01',
          name: 'Device 1',
          rawRssi: -40,
          zone: ProximityZone.strong,
          lastSeen: now,
        ),
        createDummyDevice(
          id: 'DEV-02',
          name: 'Device 2',
          rawRssi: -65,
          zone: ProximityZone.fair,
          lastSeen: now,
        ),
      ];

      await viewModel.loadHistory();
      expect(viewModel.devices.length, equals(2));
      expect(viewModel.isEmpty, isFalse);

      var notified = false;
      viewModel.addListener(() => notified = true);

      await viewModel.clearAllHistory();

      expect(repository.clearAllCallCount, equals(1));
      expect(viewModel.devices, isEmpty);
      expect(viewModel.isEmpty, isTrue);
      expect(repository.devices, isEmpty);
      expect(notified, isTrue);
      expect(viewModel.errorMessage, isNull);
    });

    test('clearAllHistory sets errorMessage when repository clear fails', () async {
      repository.devices = [
        createDummyDevice(
          id: 'DEV-01',
          name: 'Device 1',
          rawRssi: -40,
          zone: ProximityZone.strong,
          lastSeen: DateTime.now(),
        ),
      ];

      await viewModel.loadHistory();
      repository.shouldThrowOnClearAll = true;

      var notified = false;
      viewModel.addListener(() => notified = true);

      await viewModel.clearAllHistory();

      expect(repository.clearAllCallCount, equals(1));
      expect(viewModel.devices.length, equals(1)); // Retained on error
      expect(viewModel.errorMessage, contains('Failed to clear database'));
      expect(notified, isTrue);
    });
  });
}
