import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:blue_pulse/core/constants/app_constants.dart';
import 'package:blue_pulse/core/utils/signal_math.dart';
import 'package:blue_pulse/data/models/ble_device_model.dart';
import 'package:blue_pulse/data/repositories/device_history_repository.dart';
import 'package:blue_pulse/services/ble_service.dart';
import 'package:blue_pulse/services/permission_service.dart';
import 'package:blue_pulse/viewmodels/scanner_viewmodel.dart';

/// Test doubles for BleService, DeviceHistoryRepository, and PermissionService.
class FakeBleService implements BleService {
  final scanResultsController = StreamController<List<ScanResult>>.broadcast();
  final adapterStateController = StreamController<BluetoothAdapterState>.broadcast();
  final isScanningController = StreamController<bool>.broadcast();

  bool _isScanning = false;
  bool startScanCalled = false;
  bool stopScanCalled = false;
  Exception? startScanException;
  Exception? stopScanException;

  @override
  Stream<List<ScanResult>> get scanResultsStream => scanResultsController.stream;

  @override
  Stream<BluetoothAdapterState> get adapterStateStream => adapterStateController.stream;

  @override
  Stream<bool> get isScanningStream => isScanningController.stream;

  @override
  bool get isScanning => _isScanning;

  @override
  Future<bool> get isSupported => Future.value(true);

  @override
  Future<void> startScan({Duration? timeout = AppConstants.scanTimeout}) async {
    if (startScanException != null) {
      throw startScanException!;
    }
    startScanCalled = true;
    _isScanning = true;
    isScanningController.add(true);
  }

  @override
  Future<void> stopScan() async {
    if (stopScanException != null) {
      throw stopScanException!;
    }
    stopScanCalled = true;
    _isScanning = false;
    isScanningController.add(false);
  }

  void dispose() {
    scanResultsController.close();
    adapterStateController.close();
    isScanningController.close();
  }
}

class FakeDeviceHistoryRepository implements DeviceHistoryRepository {
  final upsertedDevices = <BleDeviceModel>[];

  @override
  Future<void> upsertDevice(BleDeviceModel device) async {
    upsertedDevices.add(device);
  }

  @override
  Future<List<BleDeviceModel>> getHistory() async {
    return List.unmodifiable(upsertedDevices);
  }

  @override
  Future<void> deleteDevice(String id) async {
    upsertedDevices.removeWhere((d) => d.id == id);
  }

  @override
  Future<void> clearAll() async {
    upsertedDevices.clear();
  }
}

class FakePermissionService implements PermissionService {
  bool permissionsGranted = true;
  bool requestBlePermissionsCalled = false;

  @override
  Future<bool> requestBlePermissions() async {
    requestBlePermissionsCalled = true;
    return permissionsGranted;
  }

  @override
  Future<bool> checkBlePermissions() async {
    return permissionsGranted;
  }

  @override
  Future<void> openSettings() async {}
}

ScanResult buildScanResult({
  required String id,
  required String name,
  required int rssi,
  int? txPower = -59,
  DateTime? timeStamp,
}) {
  return ScanResult(
    device: BluetoothDevice(remoteId: DeviceIdentifier(id)),
    advertisementData: AdvertisementData(
      advName: name,
      txPowerLevel: txPower,
      appearance: null,
      connectable: true,
      manufacturerData: {},
      serviceData: {},
      serviceUuids: [],
    ),
    rssi: rssi,
    timeStamp: timeStamp ?? DateTime.now(),
  );
}

void main() {
  late FakeBleService fakeBleService;
  late FakeDeviceHistoryRepository fakeHistoryRepository;
  late FakePermissionService fakePermissionService;
  late ScannerViewModel viewModel;

  setUp(() {
    fakeBleService = FakeBleService();
    fakeHistoryRepository = FakeDeviceHistoryRepository();
    fakePermissionService = FakePermissionService();

    viewModel = ScannerViewModel(
      bleService: fakeBleService,
      historyRepository: fakeHistoryRepository,
      permissionService: fakePermissionService,
    );
  });

  tearDown(() {
    viewModel.dispose();
    fakeBleService.dispose();
  });

  group('ScannerViewModel - Auto-Sorting (RSSI Descending)', () {
    test('auto-sorts devices from strongest to weakest signal (-30 dBm above -80 dBm)', () async {
      // Simulate real-time discovery of 4 devices in arbitrary order
      fakeBleService.scanResultsController.add([
        buildScanResult(id: 'ID_WEAK', name: 'Weak Beacon', rssi: -80),
        buildScanResult(id: 'ID_STRONG', name: 'Strong Tracker', rssi: -30),
        buildScanResult(id: 'ID_FAIR', name: 'Fair Device', rssi: -55),
        buildScanResult(id: 'ID_LOST', name: 'Far Away Device', rssi: -95),
      ]);

      // Allow microtask/stream event queue to process
      await pumpEventQueue();

      final sorted = viewModel.filteredAndSortedDevices;
      expect(sorted.length, equals(4));

      // -30 dBm must be at the very top (index 0)
      expect(sorted[0].id, equals('ID_STRONG'));
      expect(sorted[0].rawRssi, equals(-30));

      // -55 dBm comes second
      expect(sorted[1].id, equals('ID_FAIR'));
      expect(sorted[1].rawRssi, equals(-55));

      // -80 dBm comes third
      expect(sorted[2].id, equals('ID_WEAK'));
      expect(sorted[2].rawRssi, equals(-80));

      // -95 dBm comes last
      expect(sorted[3].id, equals('ID_LOST'));
      expect(sorted[3].rawRssi, equals(-95));

      // Explicit verification: -30 dBm is strictly above -80 dBm
      expect(sorted[0].rawRssi, greaterThan(sorted[2].rawRssi));
    });

    test('preserves descending sort order when device RSSI updates dynamically', () async {
      fakeBleService.scanResultsController.add([
        buildScanResult(id: 'DEV_A', name: 'Device A', rssi: -70),
        buildScanResult(id: 'DEV_B', name: 'Device B', rssi: -40),
      ]);
      await pumpEventQueue();

      var sorted = viewModel.filteredAndSortedDevices;
      expect(sorted[0].id, equals('DEV_B'));
      expect(sorted[1].id, equals('DEV_A'));

      // Device A moves closer and now has -35 dBm (stronger than Device B at -40 dBm)
      fakeBleService.scanResultsController.add([
        buildScanResult(id: 'DEV_A', name: 'Device A', rssi: -35),
      ]);
      await pumpEventQueue();

      sorted = viewModel.filteredAndSortedDevices;
      expect(sorted[0].id, equals('DEV_A'));
      expect(sorted[0].rawRssi, equals(-35));
      expect(sorted[1].id, equals('DEV_B'));
      expect(sorted[1].rawRssi, equals(-40));
    });
  });

  group('ScannerViewModel - Multi-Filter (Search & RSSI Threshold)', () {
    setUp(() async {
      fakeBleService.scanResultsController.add([
        buildScanResult(id: 'AA:BB:CC:11:22:33', name: 'Mi Band 7', rssi: -45),
        buildScanResult(id: 'DD:EE:FF:44:55:66', name: 'Galaxy Watch 6', rssi: -65),
        buildScanResult(id: '11:22:33:AA:BB:CC', name: 'Apple Watch Ultra', rssi: -75),
        buildScanResult(id: '77:88:99:00:11:22', name: 'Smart Tag Pro', rssi: -85),
      ]);
      await pumpEventQueue();
    });

    test('filters devices by case-insensitive name match', () {
      viewModel.setSearchQuery('galaxy');
      var results = viewModel.filteredAndSortedDevices;
      expect(results.length, equals(1));
      expect(results.first.name, equals('Galaxy Watch 6'));

      viewModel.setSearchQuery('WATCH');
      results = viewModel.filteredAndSortedDevices;
      expect(results.length, equals(2));
      expect(results.map((d) => d.name), containsAll(['Galaxy Watch 6', 'Apple Watch Ultra']));
    });

    test('filters devices by MAC address / UUID match', () {
      viewModel.setSearchQuery('DD:EE');
      var results = viewModel.filteredAndSortedDevices;
      expect(results.length, equals(1));
      expect(results.first.id, equals('DD:EE:FF:44:55:66'));

      // Case-insensitive MAC match
      viewModel.setSearchQuery('aa:bb');
      results = viewModel.filteredAndSortedDevices;
      expect(results.length, equals(2));
      expect(results.map((d) => d.id), containsAll(['AA:BB:CC:11:22:33', '11:22:33:AA:BB:CC']));
    });

    test('filters devices by RSSI threshold (>= threshold)', () {
      // Threshold -70 dBm: only -45 and -65 should pass (-75 and -85 excluded)
      viewModel.setRssiThreshold(-70);
      var results = viewModel.filteredAndSortedDevices;
      expect(results.length, equals(2));
      expect(results.map((d) => d.name), containsAll(['Mi Band 7', 'Galaxy Watch 6']));

      // Threshold -60 dBm: only -45 should pass
      viewModel.setRssiThreshold(-60);
      results = viewModel.filteredAndSortedDevices;
      expect(results.length, equals(1));
      expect(results.first.name, equals('Mi Band 7'));

      // Threshold -80 dBm: -45, -65, -75 should pass
      viewModel.setRssiThreshold(-80);
      results = viewModel.filteredAndSortedDevices;
      expect(results.length, equals(3));
      expect(results.any((d) => d.name == 'Smart Tag Pro'), isFalse);

      // Threshold null: all pass
      viewModel.setRssiThreshold(null);
      results = viewModel.filteredAndSortedDevices;
      expect(results.length, equals(4));
    });

    test('combines search query and RSSI threshold simultaneously', () {
      viewModel.setSearchQuery('watch');
      viewModel.setRssiThreshold(-70);

      final results = viewModel.filteredAndSortedDevices;
      // "Galaxy Watch 6" (-65 dBm) matches both 'watch' and >= -70
      // "Apple Watch Ultra" (-75 dBm) matches 'watch' but fails >= -70
      expect(results.length, equals(1));
      expect(results.first.name, equals('Galaxy Watch 6'));
    });

    test('clearFilters resets search query and threshold', () {
      viewModel.setSearchQuery('tag');
      viewModel.setRssiThreshold(-80);
      expect(viewModel.hasActiveFilters, isTrue);

      viewModel.clearFilters();

      expect(viewModel.searchQuery, isEmpty);
      expect(viewModel.rssiThreshold, isNull);
      expect(viewModel.hasActiveFilters, isFalse);
      expect(viewModel.filteredAndSortedDevices.length, equals(4));
    });
  });

  group('ScannerViewModel - State Transitions (Scan Lifecycle)', () {
    test('startScan initiates scanning when permissions are granted', () async {
      fakePermissionService.permissionsGranted = true;

      await viewModel.startScan();

      expect(fakePermissionService.requestBlePermissionsCalled, isTrue);
      expect(fakeBleService.startScanCalled, isTrue);
      expect(viewModel.isScanning, isTrue);
      expect(viewModel.errorMessage, isNull);
    });

    test('startScan aborts and displays error if permissions are denied', () async {
      fakePermissionService.permissionsGranted = false;

      await viewModel.startScan();

      expect(fakePermissionService.requestBlePermissionsCalled, isTrue);
      expect(fakeBleService.startScanCalled, isFalse);
      expect(viewModel.isScanning, isFalse);
      expect(viewModel.errorMessage, contains('Izin Bluetooth dan Lokasi'));
    });

    test('stopScan terminates active scan operation', () async {
      fakePermissionService.permissionsGranted = true;
      await viewModel.startScan();
      expect(viewModel.isScanning, isTrue);

      await viewModel.stopScan();

      expect(fakeBleService.stopScanCalled, isTrue);
      expect(viewModel.isScanning, isFalse);
    });

    test('reacts to Bluetooth adapter state changes', () async {
      fakeBleService.adapterStateController.add(BluetoothAdapterState.off);
      await pumpEventQueue();

      expect(viewModel.adapterState, equals(BluetoothAdapterState.off));
      expect(viewModel.errorMessage, contains('Bluetooth dalam keadaan mati'));

      // Adapter turned back on
      fakeBleService.adapterStateController.add(BluetoothAdapterState.on);
      await pumpEventQueue();

      expect(viewModel.adapterState, equals(BluetoothAdapterState.on));
      expect(viewModel.errorMessage, isNull);
    });
  });

  group('ScannerViewModel - Real-time Signal Processing & DB Upsert', () {
    test('calculates telemetry and debounces persistence to DeviceHistoryRepository', () async {
      final now = DateTime.now();
      fakeBleService.scanResultsController.add([
        buildScanResult(
          id: 'TEST_DEV',
          name: 'Telemetry Beacon',
          rssi: -40,
          txPower: -59,
          timeStamp: now,
        ),
      ]);
      await pumpEventQueue();

      final device = viewModel.filteredAndSortedDevices.first;
      expect(device.zone, equals(ProximityZone.strong));
      expect(device.smoothedRssi, equals(-40.0));
      expect(device.estimatedDistance, closeTo(0.16, 0.05));

      // Repository upsert was called
      expect(fakeHistoryRepository.upsertedDevices.length, equals(1));
      expect(fakeHistoryRepository.upsertedDevices.first.id, equals('TEST_DEV'));
    });
  });
}
