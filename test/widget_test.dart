import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:blue_pulse/core/constants/app_constants.dart';
import 'package:blue_pulse/core/di/injection.dart';
import 'package:blue_pulse/core/utils/signal_math.dart';
import 'package:blue_pulse/data/datasources/local_database.dart';
import 'package:blue_pulse/data/models/ble_device_model.dart';
import 'package:blue_pulse/data/repositories/device_history_repository.dart';
import 'package:blue_pulse/main.dart';
import 'package:blue_pulse/services/ble_service.dart';
import 'package:blue_pulse/services/permission_service.dart';
import 'package:material_ui/material_ui.dart';
import 'package:blue_pulse/viewmodels/history_viewmodel.dart';
import 'package:blue_pulse/viewmodels/radar_viewmodel.dart';
import 'package:blue_pulse/viewmodels/scanner_viewmodel.dart';
import 'package:blue_pulse/views/history/history_screen.dart';
import 'package:blue_pulse/views/radar/radar_screen.dart';
import 'package:blue_pulse/views/scanner/scanner_screen.dart';

class MockBleService implements BleService {
  final _scanController = StreamController<List<ScanResult>>.broadcast();
  final _adapterController = StreamController<BluetoothAdapterState>.broadcast();
  final _isScanningController = StreamController<bool>.broadcast();

  @override
  Stream<List<ScanResult>> get scanResultsStream => _scanController.stream;

  @override
  Stream<BluetoothAdapterState> get adapterStateStream => _adapterController.stream;

  @override
  Stream<bool> get isScanningStream => _isScanningController.stream;

  @override
  bool get isScanning => false;

  @override
  Future<bool> get isSupported => Future.value(true);

  @override
  Future<void> startScan({Duration? timeout = AppConstants.scanTimeout}) async {}

  @override
  Future<void> stopScan() async {}
}

class MockPermissionService implements PermissionService {
  @override
  Future<bool> requestBlePermissions() async => true;

  @override
  Future<bool> checkBlePermissions() async => true;

  @override
  Future<void> openSettings() async {}
}

class MockDeviceHistoryRepository implements DeviceHistoryRepository {
  @override
  Future<void> upsertDevice(BleDeviceModel device) async {}

  @override
  Future<List<BleDeviceModel>> getHistory() async => [];

  @override
  Future<void> deleteDevice(String id) async {}

  @override
  Future<void> clearAll() async {}
}

void main() {
  setUp(() async {
    await locator.reset();
    locator.registerLazySingleton<LocalDatabase>(LocalDatabase.new);
    locator.registerLazySingleton<DeviceHistoryRepository>(MockDeviceHistoryRepository.new);
    locator.registerLazySingleton<PermissionService>(MockPermissionService.new);
    locator.registerLazySingleton<BleService>(MockBleService.new);
    locator.registerFactory<ScannerViewModel>(
      () => ScannerViewModel(
        bleService: locator<BleService>(),
        historyRepository: locator<DeviceHistoryRepository>(),
        permissionService: locator<PermissionService>(),
      ),
    );
    locator.registerFactoryParam<RadarViewModel, BleDeviceModel, void>(
      (device, _) => RadarViewModel(
        bleService: locator<BleService>(),
        historyRepository: locator<DeviceHistoryRepository>(),
        initialDevice: device,
      ),
    );
    locator.registerFactory<HistoryViewModel>(
      () => HistoryViewModel(locator<DeviceHistoryRepository>()),
    );
  });

  tearDown(() async {
    await locator.reset();
  });

  testWidgets('BluePulse App smoke test - renders ScannerScreen and AppBar title', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    // Verify BluePulse dashboard title is rendered
    expect(find.text('BluePulse'), findsOneWidget);

    // Verify initial scanner status badge is visible
    expect(find.text('Siap'), findsOneWidget);

    // Verify search input field is rendered
    expect(find.text('Cari nama atau MAC...'), findsOneWidget);

    // Verify RSSI threshold chips are displayed
    expect(find.text('Semua'), findsOneWidget);
    expect(find.text('≥ -80 dBm'), findsOneWidget);
    expect(find.text('≥ -70 dBm'), findsOneWidget);
    expect(find.text('≥ -60 dBm'), findsOneWidget);
  });

  testWidgets('navigates from ScannerScreen to RadarScreen on device tap', (tester) async {
    final viewModel = locator<ScannerViewModel>();
    final testDevice = BleDeviceModel(
      id: 'AA:BB:CC:DD:EE:01',
      name: 'Test Beacon One',
      rawRssi: -55,
      smoothedRssi: -55.0,
      estimatedDistance: 2.0,
      zone: ProximityZone.strong,
      lastSeen: DateTime.now(),
    );

    viewModel.addDeviceForTesting(testDevice);

    await tester.pumpWidget(MaterialApp(
      home: ScannerScreen(viewModel: viewModel),
    ));
    await tester.pump();

    // Verify device is displayed in list
    expect(find.text('Test Beacon One'), findsOneWidget);

    // Tap on device card
    await tester.tap(find.text('Test Beacon One'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify RadarScreen is rendered
    expect(find.byType(RadarScreen), findsOneWidget);
    expect(find.text('ESTIMASI JARAK'), findsOneWidget);
    expect(find.text('AA:BB:CC:DD:EE:01'), findsOneWidget);
  });

  testWidgets('navigates from ScannerScreen to HistoryScreen on history icon tap', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    // Verify history icon button is present in AppBar
    final historyButtonFinder = find.byTooltip('Riwayat Perangkat');
    expect(historyButtonFinder, findsOneWidget);

    // Tap on history button
    await tester.tap(historyButtonFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify HistoryScreen is rendered
    expect(find.byType(HistoryScreen), findsOneWidget);
    expect(find.text('Riwayat Perangkat'), findsOneWidget);
  });
}
