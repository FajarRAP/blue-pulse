import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:blue_pulse/core/constants/app_constants.dart';
import 'package:blue_pulse/core/utils/signal_math.dart';
import 'package:blue_pulse/data/models/ble_device_model.dart';
import 'package:blue_pulse/data/repositories/device_history_repository.dart';
import 'package:blue_pulse/services/ble_service.dart';
import 'package:blue_pulse/viewmodels/radar_viewmodel.dart';

class FakeBleService implements BleService {
  final scanResultsController = StreamController<List<ScanResult>>.broadcast();
  final adapterStateController =
      StreamController<BluetoothAdapterState>.broadcast();
  final isScanningController = StreamController<bool>.broadcast();

  bool _isScanning = false;
  bool startScanCalled = false;
  bool stopScanCalled = false;

  @override
  Stream<List<ScanResult>> get scanResultsStream =>
      scanResultsController.stream;

  @override
  Stream<BluetoothAdapterState> get adapterStateStream =>
      adapterStateController.stream;

  @override
  Stream<bool> get isScanningStream => isScanningController.stream;

  @override
  bool get isScanning => _isScanning;

  @override
  Future<bool> get isSupported => Future.value(true);

  @override
  Future<void> startScan({Duration? timeout = AppConstants.scanTimeout}) async {
    startScanCalled = true;
    _isScanning = true;
    isScanningController.add(true);
  }

  @override
  Future<void> stopScan() async {
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
      manufacturerData: const {},
      serviceData: const {},
      serviceUuids: const [],
    ),
    rssi: rssi,
    timeStamp: timeStamp ?? DateTime.now(),
  );
}

void main() {
  late FakeBleService fakeBleService;
  late FakeDeviceHistoryRepository fakeHistoryRepository;
  late BleDeviceModel testInitialDevice;
  late DateTime currentTime;

  setUp(() {
    fakeBleService = FakeBleService();
    fakeHistoryRepository = FakeDeviceHistoryRepository();
    currentTime = DateTime(2026, 10, 9, 2, 0, 0);

    testInitialDevice = BleDeviceModel(
      id: 'TARGET_DEVICE_1',
      name: 'Initial Tracker',
      rawRssi: -50,
      smoothedRssi: -50.0,
      estimatedDistance: 1.0,
      zone: ProximityZone.strong,
      lastSeen: currentTime,
      txPower: -59,
    );
  });

  tearDown(() {
    fakeBleService.dispose();
  });

  RadarViewModel createViewModel({
    BleDeviceModel? initialDevice,
    DateTime Function()? nowProvider,
  }) {
    return RadarViewModel(
      bleService: fakeBleService,
      historyRepository: fakeHistoryRepository,
      initialDevice: initialDevice ?? testInitialDevice,
      nowProvider: nowProvider ?? () => currentTime,
    );
  }

  group('RadarViewModel - Initial State & Auto Scan Start', () {
    test('initializes targetDevice from initialDevice and sets isLost to false',
        () {
      final viewModel = createViewModel();

      expect(viewModel.targetDevice.id, equals('TARGET_DEVICE_1'));
      expect(viewModel.targetDevice.name, equals('Initial Tracker'));
      expect(viewModel.targetDevice.rawRssi, equals(-50));
      expect(viewModel.targetDevice.smoothedRssi, equals(-50.0));
      expect(viewModel.targetDevice.zone, equals(ProximityZone.strong));
      expect(viewModel.isLost, isFalse);
      expect(viewModel.timeSinceLastPacket, equals(Duration.zero));
      expect(fakeBleService.startScanCalled, isTrue);

      viewModel.dispose();
    });

    test('initializes isLost to true if initial device zone is lost', () {
      final lostDevice = testInitialDevice.copyWith(zone: ProximityZone.lost);
      final viewModel = createViewModel(initialDevice: lostDevice);

      expect(viewModel.isLost, isTrue);
      expect(viewModel.stabilityScore, equals('Terputus'));
      expect(viewModel.packetRate, equals(0.0));

      viewModel.dispose();
    });
  });

  group('RadarViewModel - Target Packet Filtering & Signal Smoothing', () {
    test('updates smoothed RSSI via EMA and calculates distance on target packet',
        () async {
      final viewModel = createViewModel();

      // Send packet for target device with RSSI = -40 dBm
      currentTime = currentTime.add(const Duration(milliseconds: 500));
      fakeBleService.scanResultsController.add([
        buildScanResult(
          id: 'TARGET_DEVICE_1',
          name: 'Updated Tracker Name',
          rssi: -40,
          txPower: -59,
          timeStamp: currentTime,
        ),
      ]);
      await pumpEventQueue();

      final updated = viewModel.targetDevice;
      expect(updated.rawRssi, equals(-40));
      // EMA: alpha * -40 + (1 - alpha) * -50 = 0.35 * -40 + 0.65 * -50 = -14 + -32.5 = -46.5
      expect(updated.smoothedRssi, closeTo(-46.5, 0.01));
      expect(updated.name, equals('Updated Tracker Name'));
      expect(updated.zone, equals(ProximityZone.strong));
      expect(updated.estimatedDistance, closeTo(0.16, 0.05));
      expect(viewModel.isLost, isFalse);

      // Verify repository upsert
      expect(fakeHistoryRepository.upsertedDevices.length, equals(1));
      expect(
        fakeHistoryRepository.upsertedDevices.first.id,
        equals('TARGET_DEVICE_1'),
      );

      viewModel.dispose();
    });

    test('ignores advertising packets from other peripheral devices', () async {
      final viewModel = createViewModel();

      // Send packet from different peripheral
      fakeBleService.scanResultsController.add([
        buildScanResult(
          id: 'OTHER_DEVICE_99',
          name: 'Noise Beacon',
          rssi: -30,
          txPower: -59,
        ),
      ]);
      await pumpEventQueue();

      // Target device state should remain unchanged
      expect(viewModel.targetDevice.id, equals('TARGET_DEVICE_1'));
      expect(viewModel.targetDevice.rawRssi, equals(-50));
      expect(fakeHistoryRepository.upsertedDevices, isEmpty);

      viewModel.dispose();
    });
  });

  group('RadarViewModel - Stability Score & Packet Rate Calculation', () {
    test('calculates stabilityScore as Sangat Stabil when delta variance is low',
        () async {
      final viewModel = createViewModel();

      // Send series of stable RSSI packets
      final stableRssis = [-50, -51, -50, -52, -51];
      for (final rssi in stableRssis) {
        currentTime = currentTime.add(const Duration(milliseconds: 200));
        fakeBleService.scanResultsController.add([
          buildScanResult(
            id: 'TARGET_DEVICE_1',
            name: 'Initial Tracker',
            rssi: rssi,
            timeStamp: currentTime,
          ),
        ]);
        await pumpEventQueue();
      }

      expect(viewModel.stabilityScore, equals('Sangat Stabil'));

      viewModel.dispose();
    });

    test('calculates stabilityScore as Fluktuatif when RSSI has high volatility',
        () async {
      final viewModel = createViewModel();

      // Send series of volatile RSSI readings
      final volatileRssis = [-40, -85, -42, -90, -38];
      for (final rssi in volatileRssis) {
        currentTime = currentTime.add(const Duration(milliseconds: 200));
        fakeBleService.scanResultsController.add([
          buildScanResult(
            id: 'TARGET_DEVICE_1',
            name: 'Initial Tracker',
            rssi: rssi,
            timeStamp: currentTime,
          ),
        ]);
        await pumpEventQueue();
      }

      expect(viewModel.stabilityScore, equals('Fluktuatif'));

      viewModel.dispose();
    });

    test('calculates packetRate correctly based on recent packet receptions',
        () async {
      final viewModel = createViewModel();

      // Send 5 packets within 1 second
      for (var i = 0; i < 5; i++) {
        currentTime = currentTime.add(const Duration(milliseconds: 200));
        fakeBleService.scanResultsController.add([
          buildScanResult(
            id: 'TARGET_DEVICE_1',
            name: 'Initial Tracker',
            rssi: -55,
            timeStamp: currentTime,
          ),
        ]);
        await pumpEventQueue();
      }

      expect(viewModel.packetRate, greaterThan(0.0));
      expect(viewModel.packetRate, closeTo(5.0, 1.0));

      viewModel.dispose();
    });
  });

  group('RadarViewModel - Signal Lost Watchdog', () {
    test('triggers ProximityZone.lost and isLost = true after >10s timeout',
        () async {
      final viewModel = createViewModel();
      expect(viewModel.isLost, isFalse);

      // Advance time past signalLostThreshold (10s) to 11s
      currentTime = currentTime.add(const Duration(seconds: 11));
      viewModel.checkWatchdog();

      expect(viewModel.isLost, isTrue);
      expect(viewModel.targetDevice.zone, equals(ProximityZone.lost));
      expect(viewModel.stabilityScore, equals('Terputus'));
      expect(viewModel.packetRate, equals(0.0));

      viewModel.dispose();
    });

    test('recovers from isLost when target packet is received again', () async {
      final viewModel = createViewModel();

      // Trigger lost state
      currentTime = currentTime.add(const Duration(seconds: 11));
      viewModel.checkWatchdog();
      expect(viewModel.isLost, isTrue);

      // New packet received
      currentTime = currentTime.add(const Duration(seconds: 1));
      fakeBleService.scanResultsController.add([
        buildScanResult(
          id: 'TARGET_DEVICE_1',
          name: 'Initial Tracker',
          rssi: -45,
          txPower: -59,
          timeStamp: currentTime,
        ),
      ]);
      await pumpEventQueue();

      expect(viewModel.isLost, isFalse);
      expect(viewModel.targetDevice.zone, equals(ProximityZone.strong));
      expect(viewModel.targetDevice.rawRssi, equals(-45));

      viewModel.dispose();
    });

    test('does not trigger lost state when time elapsed is <= 10 seconds',
        () async {
      final viewModel = createViewModel();

      // Advance time to 8 seconds (less than 10s threshold)
      currentTime = currentTime.add(const Duration(seconds: 8));
      viewModel.checkWatchdog();

      expect(viewModel.isLost, isFalse);
      expect(viewModel.targetDevice.zone, equals(ProximityZone.strong));

      viewModel.dispose();
    });
  });

  group('RadarViewModel - Lifecycle and Resource Disposal', () {
    test('dispose cancels timers and subscriptions safely', () {
      final viewModel = createViewModel();
      expect(() => viewModel.dispose(), returnsNormally);
    });
  });
}
