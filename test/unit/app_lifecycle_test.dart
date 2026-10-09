import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:blue_pulse/core/constants/app_constants.dart';
import 'package:blue_pulse/core/utils/signal_math.dart';
import 'package:blue_pulse/data/models/ble_device_model.dart';
import 'package:blue_pulse/data/repositories/device_history_repository.dart';
import 'package:blue_pulse/services/ble_service.dart';
import 'package:blue_pulse/services/permission_service.dart';
import 'package:blue_pulse/viewmodels/radar_viewmodel.dart';
import 'package:blue_pulse/viewmodels/scanner_viewmodel.dart';
import 'package:blue_pulse/views/radar/radar_screen.dart';
import 'package:blue_pulse/views/scanner/scanner_screen.dart';
import 'package:blue_pulse/views/scanner/widgets/ble_permission_dialog.dart';
import 'package:blue_pulse/views/scanner/widgets/bluetooth_warning_banner.dart';

class FakeBleService implements BleService {
  final scanResultsController = StreamController<List<ScanResult>>.broadcast();
  final adapterStateController =
      StreamController<BluetoothAdapterState>.broadcast();
  final isScanningController = StreamController<bool>.broadcast();

  bool _isScanning = false;
  bool startScanCalled = false;
  bool stopScanCalled = false;
  int startScanCount = 0;
  int stopScanCount = 0;

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
    startScanCount++;
    _isScanning = true;
    isScanningController.add(true);
  }

  @override
  Future<void> stopScan() async {
    stopScanCalled = true;
    stopScanCount++;
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
  Future<List<BleDeviceModel>> getHistory() async =>
      List.unmodifiable(upsertedDevices);

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
  bool openSettingsCalled = false;

  @override
  Future<bool> requestBlePermissions() async {
    requestBlePermissionsCalled = true;
    return permissionsGranted;
  }

  @override
  Future<bool> checkBlePermissions() async => permissionsGranted;

  @override
  Future<void> openSettings() async {
    openSettingsCalled = true;
  }
}

void main() {
  group('Milestone 6: App Lifecycle Management (Pause & Resume)', () {
    late FakeBleService fakeBleService;
    late FakeDeviceHistoryRepository fakeHistoryRepository;
    late FakePermissionService fakePermissionService;
    late ScannerViewModel scannerViewModel;

    setUp(() {
      fakeBleService = FakeBleService();
      fakeHistoryRepository = FakeDeviceHistoryRepository();
      fakePermissionService = FakePermissionService();

      scannerViewModel = ScannerViewModel(
        bleService: fakeBleService,
        historyRepository: fakeHistoryRepository,
        permissionService: fakePermissionService,
      );
    });

    tearDown(() {
      scannerViewModel.dispose();
      fakeBleService.dispose();
    });

    test(
        'onAppPaused stops active scan and sets wasScanningBeforePaused to true',
        () async {
      await scannerViewModel.startScan();
      expect(scannerViewModel.isScanning, isTrue);
      expect(fakeBleService.startScanCalled, isTrue);

      scannerViewModel.onAppPaused();
      await pumpEventQueue();

      expect(scannerViewModel.wasScanningBeforePaused, isTrue);
      expect(fakeBleService.stopScanCalled, isTrue);
      expect(scannerViewModel.isScanning, isFalse);
    });

    test(
        'onAppPaused does not set wasScanningBeforePaused if scanning was not active',
        () async {
      expect(scannerViewModel.isScanning, isFalse);

      scannerViewModel.onAppPaused();
      await pumpEventQueue();

      expect(scannerViewModel.wasScanningBeforePaused, isFalse);
      expect(fakeBleService.stopScanCalled, isFalse);
    });

    test(
        'onAppResumed automatically resumes scan if wasScanningBeforePaused was true',
        () async {
      await scannerViewModel.startScan();
      scannerViewModel.onAppPaused();
      await pumpEventQueue();

      expect(scannerViewModel.wasScanningBeforePaused, isTrue);
      expect(scannerViewModel.isScanning, isFalse);

      // App returns to foreground
      scannerViewModel.onAppResumed();
      await pumpEventQueue();

      expect(scannerViewModel.wasScanningBeforePaused, isFalse);
      expect(fakeBleService.startScanCount, equals(2));
      expect(scannerViewModel.isScanning, isTrue);
    });

    test('onAppResumed does not start scan if wasScanningBeforePaused is false',
        () async {
      expect(scannerViewModel.wasScanningBeforePaused, isFalse);
      expect(scannerViewModel.isScanning, isFalse);

      scannerViewModel.onAppResumed();
      await pumpEventQueue();

      expect(fakeBleService.startScanCalled, isFalse);
      expect(scannerViewModel.isScanning, isFalse);
    });
  });

  group('Milestone 6: Edge-Case Resilience (Bluetooth State Changes)', () {
    late FakeBleService fakeBleService;
    late FakeDeviceHistoryRepository fakeHistoryRepository;
    late FakePermissionService fakePermissionService;
    late ScannerViewModel scannerViewModel;

    setUp(() {
      fakeBleService = FakeBleService();
      fakeHistoryRepository = FakeDeviceHistoryRepository();
      fakePermissionService = FakePermissionService();

      scannerViewModel = ScannerViewModel(
        bleService: fakeBleService,
        historyRepository: fakeHistoryRepository,
        permissionService: fakePermissionService,
      );
    });

    tearDown(() {
      scannerViewModel.dispose();
      fakeBleService.dispose();
    });

    test(
        'turning Bluetooth off during active scan safely stops scan and sets error message',
        () async {
      await scannerViewModel.startScan();
      expect(scannerViewModel.isScanning, isTrue);

      // Simulate Bluetooth hardware turned off
      fakeBleService.adapterStateController.add(BluetoothAdapterState.off);
      await pumpEventQueue();

      expect(scannerViewModel.adapterState, equals(BluetoothAdapterState.off));
      expect(fakeBleService.stopScanCalled, isTrue);
      expect(scannerViewModel.isScanning, isFalse);
      expect(scannerViewModel.errorMessage,
          contains('Bluetooth dalam keadaan mati'));
    });

    test(
        'turning Bluetooth back on automatically dismisses error banner in ScannerViewModel',
        () async {
      fakeBleService.adapterStateController.add(BluetoothAdapterState.off);
      await pumpEventQueue();
      expect(scannerViewModel.errorMessage, isNotNull);

      // Turn Bluetooth back on
      fakeBleService.adapterStateController.add(BluetoothAdapterState.on);
      await pumpEventQueue();

      expect(scannerViewModel.adapterState, equals(BluetoothAdapterState.on));
      expect(scannerViewModel.errorMessage, isNull);
    });

    test(
        'RadarViewModel reacts to Bluetooth turned off by marking zone lost and setting isBluetoothDisabled',
        () async {
      final initialDevice = BleDeviceModel(
        id: 'TRACK_DEV_01',
        name: 'Target Tracker',
        rawRssi: -50,
        smoothedRssi: -50.0,
        estimatedDistance: 1.0,
        zone: ProximityZone.strong,
        lastSeen: DateTime.now(),
      );

      final radarViewModel = RadarViewModel(
        bleService: fakeBleService,
        historyRepository: fakeHistoryRepository,
        initialDevice: initialDevice,
      );

      expect(radarViewModel.isLost, isFalse);
      expect(radarViewModel.isBluetoothDisabled, isFalse);

      // Simulate user turning off Bluetooth
      fakeBleService.adapterStateController.add(BluetoothAdapterState.off);
      await pumpEventQueue();

      expect(radarViewModel.isBluetoothDisabled, isTrue);
      expect(radarViewModel.isLost, isTrue);
      expect(radarViewModel.targetDevice.zone, equals(ProximityZone.lost));

      // Simulate Bluetooth turned back on
      fakeBleService.adapterStateController.add(BluetoothAdapterState.on);
      await pumpEventQueue();

      expect(radarViewModel.isBluetoothDisabled, isFalse);

      radarViewModel.dispose();
    });
  });

  group('Milestone 6: Edge-Case Resilience (Permission Handling)', () {
    late FakeBleService fakeBleService;
    late FakeDeviceHistoryRepository fakeHistoryRepository;
    late FakePermissionService fakePermissionService;
    late ScannerViewModel scannerViewModel;

    setUp(() {
      fakeBleService = FakeBleService();
      fakeHistoryRepository = FakeDeviceHistoryRepository();
      fakePermissionService = FakePermissionService();

      scannerViewModel = ScannerViewModel(
        bleService: fakeBleService,
        historyRepository: fakeHistoryRepository,
        permissionService: fakePermissionService,
      );
    });

    tearDown(() {
      scannerViewModel.dispose();
      fakeBleService.dispose();
    });

    test(
        'permission denied sets isPermissionDenied to true and sets error message',
        () async {
      fakePermissionService.permissionsGranted = false;

      await scannerViewModel.startScan();

      expect(scannerViewModel.isPermissionDenied, isTrue);
      expect(scannerViewModel.isScanning, isFalse);
      expect(scannerViewModel.errorMessage,
          contains('Izin Bluetooth dan Lokasi diperlukan'));
    });

    test('openAppSettings calls permissionService.openSettings', () async {
      await scannerViewModel.openAppSettings();
      expect(fakePermissionService.openSettingsCalled, isTrue);
    });

    test('clearPermissionDenied resets isPermissionDenied flag', () async {
      fakePermissionService.permissionsGranted = false;
      await scannerViewModel.startScan();
      expect(scannerViewModel.isPermissionDenied, isTrue);

      scannerViewModel.clearPermissionDenied();
      expect(scannerViewModel.isPermissionDenied, isFalse);
    });
  });

  group('Milestone 7: Configuration Changes, Rotation & Widget Verification',
      () {
    late FakeBleService fakeBleService;
    late FakeDeviceHistoryRepository fakeHistoryRepository;
    late FakePermissionService fakePermissionService;
    late ScannerViewModel scannerViewModel;

    setUp(() {
      fakeBleService = FakeBleService();
      fakeHistoryRepository = FakeDeviceHistoryRepository();
      fakePermissionService = FakePermissionService();

      scannerViewModel = ScannerViewModel(
        bleService: fakeBleService,
        historyRepository: fakeHistoryRepository,
        permissionService: fakePermissionService,
      );
    });

    tearDown(() {
      scannerViewModel.dispose();
      fakeBleService.dispose();
    });

    testWidgets(
        'ScannerScreen preserves discovered devices on screen orientation change',
        (tester) async {
      final testDevice = BleDeviceModel(
        id: 'DEV_PRESERVED',
        name: 'Preserved Device',
        rawRssi: -50,
        smoothedRssi: -50.0,
        estimatedDistance: 1.0,
        zone: ProximityZone.strong,
        lastSeen: DateTime.now(),
      );

      scannerViewModel.addDeviceForTesting(testDevice);

      // Start in portrait mode
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(MaterialApp(
        home: ScannerScreen(viewModel: scannerViewModel),
      ));
      await tester.pump();

      expect(find.text('Preserved Device'), findsOneWidget);

      // Rotate to landscape mode
      tester.view.physicalSize = const Size(800, 400);
      await tester.pump();

      // Verify device list remains preserved
      expect(find.text('Preserved Device'), findsOneWidget);
      expect(scannerViewModel.totalDevicesCount, equals(1));

      // Clean up widget tree
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets(
        'RadarScreen displays Bluetooth Dinonaktifkan badge and does not overflow in landscape',
        (tester) async {
      final testDevice = BleDeviceModel(
        id: 'DEV_RADAR_01',
        name: 'Radar Target',
        rawRssi: -60,
        smoothedRssi: -60.0,
        estimatedDistance: 2.5,
        zone: ProximityZone.fair,
        lastSeen: DateTime.now(),
      );

      final radarViewModel = RadarViewModel(
        bleService: fakeBleService,
        historyRepository: fakeHistoryRepository,
        initialDevice: testDevice,
      );

      // Rotate to landscape
      tester.view.physicalSize = const Size(800, 400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(MaterialApp(
        home: RadarScreen(
          targetDevice: testDevice,
          viewModel: radarViewModel,
        ),
      ));
      await tester.pump();

      // Verify active tracking status initially
      expect(find.text('Melacak...'), findsOneWidget);

      // Trigger Bluetooth off
      fakeBleService.adapterStateController.add(BluetoothAdapterState.off);
      await tester.pump(const Duration(milliseconds: 100));

      // Verify badge updates to "Bluetooth Dinonaktifkan"
      expect(find.text('Bluetooth Dinonaktifkan'), findsOneWidget);

      // Verify banner appears
      expect(find.byType(BluetoothWarningBanner), findsOneWidget);

      // Verify no overflow error occurred
      expect(tester.takeException(), isNull);

      // Clean up widget tree and controller
      await tester.pumpWidget(const SizedBox());
      radarViewModel.dispose();
    });

    testWidgets(
        'BlePermissionDialog renders with informative text and open settings button',
        (tester) async {
      var settingsOpened = false;
      var dismissed = false;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: BlePermissionDialog(
            onOpenSettings: () => settingsOpened = true,
            onDismiss: () => dismissed = true,
          ),
        ),
      ));
      await tester.pump();

      expect(find.text('Izin Bluetooth Diperlukan'), findsOneWidget);
      expect(find.text('Buka Pengaturan'), findsOneWidget);
      expect(find.text('Batal'), findsOneWidget);

      await tester.tap(find.text('Buka Pengaturan'));
      await tester.pump();
      expect(settingsOpened, isTrue);

      await tester.tap(find.text('Batal'));
      await tester.pump();
      expect(dismissed, isTrue);
    });

    testWidgets(
        'BluetoothWarningBanner renders message and fires callback on button tap',
        (tester) async {
      var actionFired = false;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: BluetoothWarningBanner(
            message: 'Bluetooth dalam keadaan mati.',
            actionLabel: 'Coba Lagi',
            onAction: () => actionFired = true,
          ),
        ),
      ));
      await tester.pump();

      expect(find.text('Bluetooth dalam keadaan mati.'), findsOneWidget);
      expect(find.text('Coba Lagi'), findsOneWidget);

      await tester.tap(find.text('Coba Lagi'));
      await tester.pump();
      expect(actionFired, isTrue);
    });
  });
}
