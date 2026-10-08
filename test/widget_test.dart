import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:blue_pulse/core/constants/app_constants.dart';
import 'package:blue_pulse/core/di/injection.dart';
import 'package:blue_pulse/data/datasources/local_database.dart';
import 'package:blue_pulse/data/models/ble_device_model.dart';
import 'package:blue_pulse/data/repositories/device_history_repository.dart';
import 'package:blue_pulse/main.dart';
import 'package:blue_pulse/services/ble_service.dart';
import 'package:blue_pulse/services/permission_service.dart';
import 'package:blue_pulse/viewmodels/scanner_viewmodel.dart';

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
}
