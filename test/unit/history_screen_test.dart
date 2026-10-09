import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:blue_pulse/core/di/injection.dart';
import 'package:blue_pulse/core/utils/signal_math.dart';
import 'package:blue_pulse/data/datasources/local_database.dart';
import 'package:blue_pulse/data/models/ble_device_model.dart';
import 'package:blue_pulse/data/repositories/device_history_repository.dart';
import 'package:blue_pulse/services/ble_service.dart';
import 'package:blue_pulse/services/permission_service.dart';
import 'package:blue_pulse/viewmodels/history_viewmodel.dart';
import 'package:blue_pulse/viewmodels/radar_viewmodel.dart';
import 'package:blue_pulse/views/history/history_screen.dart';
import 'package:blue_pulse/views/radar/radar_screen.dart';

class FakeDeviceHistoryRepository implements DeviceHistoryRepository {
  List<BleDeviceModel> devices = [];

  @override
  Future<void> upsertDevice(BleDeviceModel device) async {
    devices.add(device);
  }

  @override
  Future<List<BleDeviceModel>> getHistory() async {
    return List.from(devices);
  }

  @override
  Future<void> deleteDevice(String id) async {
    devices.removeWhere((d) => d.id == id);
  }

  @override
  Future<void> clearAll() async {
    devices.clear();
  }
}

class FakeBleService implements BleService {
  @override
  Stream<List<ScanResult>> get scanResultsStream => const Stream.empty();

  @override
  Stream<BluetoothAdapterState> get adapterStateStream => const Stream.empty();

  @override
  Stream<bool> get isScanningStream => const Stream.empty();

  @override
  bool get isScanning => false;

  @override
  Future<bool> get isSupported => Future.value(true);

  @override
  Future<void> startScan({Duration? timeout}) async {}

  @override
  Future<void> stopScan() async {}
}

class FakePermissionService implements PermissionService {
  @override
  Future<bool> requestBlePermissions() async => true;

  @override
  Future<bool> checkBlePermissions() async => true;

  @override
  Future<void> openSettings() async {}
}

void main() {
  late FakeDeviceHistoryRepository fakeRepository;

  setUp(() async {
    await locator.reset();
    fakeRepository = FakeDeviceHistoryRepository();

    locator.registerLazySingleton<LocalDatabase>(LocalDatabase.new);
    locator.registerLazySingleton<DeviceHistoryRepository>(() => fakeRepository);
    locator.registerLazySingleton<PermissionService>(FakePermissionService.new);
    locator.registerLazySingleton<BleService>(FakeBleService.new);
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

  testWidgets('HistoryScreen displays empty state when no devices exist', (tester) async {
    fakeRepository.devices = [];

    await tester.pumpWidget(const MaterialApp(
      home: HistoryScreen(),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Riwayat Perangkat'), findsOneWidget);
    expect(find.text('Belum Ada Riwayat'), findsOneWidget);
    expect(
      find.text('Perangkat BLE yang terdeteksi saat pemindaian akan otomatis tercatat di sini.'),
      findsOneWidget,
    );
  });

  testWidgets('HistoryScreen displays device cards when history has data', (tester) async {
    final now = DateTime.now();
    fakeRepository.devices = [
      BleDeviceModel(
        id: 'AA:BB:CC:11:22:33',
        name: 'Pulse Tracker Alpha',
        rawRssi: -54,
        smoothedRssi: -54.0,
        estimatedDistance: 1.8,
        zone: ProximityZone.strong,
        lastSeen: now,
      ),
    ];

    await tester.pumpWidget(const MaterialApp(
      home: HistoryScreen(),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Pulse Tracker Alpha'), findsOneWidget);
    expect(find.text('AA:BB:CC:11:22:33'), findsOneWidget);
    expect(find.text('-54 dBm'), findsOneWidget);
    expect(find.text('1.8 m'), findsOneWidget);
    expect(find.text('Kuat'), findsOneWidget);
    expect(find.textContaining('Terakhir terlihat:'), findsOneWidget);
  });

  testWidgets('HistoryScreen card tap navigates to RadarScreen', (tester) async {
    fakeRepository.devices = [
      BleDeviceModel(
        id: 'AA:BB:CC:11:22:33',
        name: 'Pulse Tracker Alpha',
        rawRssi: -54,
        smoothedRssi: -54.0,
        estimatedDistance: 1.8,
        zone: ProximityZone.strong,
        lastSeen: DateTime.now(),
      ),
    ];

    await tester.pumpWidget(const MaterialApp(
      home: HistoryScreen(),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Tap on the device card
    await tester.tap(find.text('Pulse Tracker Alpha'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(RadarScreen), findsOneWidget);
    expect(find.text('ESTIMASI JARAK'), findsOneWidget);
  });

  testWidgets('HistoryScreen individual delete prompts confirmation and deletes device', (tester) async {
    fakeRepository.devices = [
      BleDeviceModel(
        id: 'AA:BB:CC:11:22:33',
        name: 'Pulse Tracker Alpha',
        rawRssi: -54,
        smoothedRssi: -54.0,
        estimatedDistance: 1.8,
        zone: ProximityZone.strong,
        lastSeen: DateTime.now(),
      ),
    ];

    await tester.pumpWidget(const MaterialApp(
      home: HistoryScreen(),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Pulse Tracker Alpha'), findsOneWidget);

    // Tap delete icon
    final deleteIconFinder = find.byTooltip('Hapus dari Riwayat');
    expect(deleteIconFinder, findsOneWidget);
    await tester.tap(deleteIconFinder);
    await tester.pumpAndSettle();

    // Verify confirmation dialog
    expect(find.text('Hapus Perangkat?'), findsOneWidget);
    expect(find.text('Hapus'), findsOneWidget);

    // Confirm deletion
    await tester.tap(find.text('Hapus'));
    await tester.pumpAndSettle();

    // Verify empty state is now displayed
    expect(find.text('Belum Ada Riwayat'), findsOneWidget);
    expect(fakeRepository.devices, isEmpty);
  });

  testWidgets('HistoryScreen clear all history prompts confirmation and wipes list', (tester) async {
    fakeRepository.devices = [
      BleDeviceModel(
        id: 'DEV-1',
        name: 'Device 1',
        rawRssi: -50,
        smoothedRssi: -50.0,
        estimatedDistance: 1.5,
        zone: ProximityZone.strong,
        lastSeen: DateTime.now(),
      ),
      BleDeviceModel(
        id: 'DEV-2',
        name: 'Device 2',
        rawRssi: -70,
        smoothedRssi: -70.0,
        estimatedDistance: 5.0,
        zone: ProximityZone.fair,
        lastSeen: DateTime.now(),
      ),
    ];

    await tester.pumpWidget(const MaterialApp(
      home: HistoryScreen(),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Device 1'), findsOneWidget);
    expect(find.text('Device 2'), findsOneWidget);

    // Tap clear all icon in AppBar
    final clearAllFinder = find.byTooltip('Hapus Semua Riwayat');
    expect(clearAllFinder, findsOneWidget);
    await tester.tap(clearAllFinder);
    await tester.pumpAndSettle();

    // Verify confirmation dialog
    expect(find.text('Hapus Semua Riwayat?'), findsOneWidget);
    expect(find.text('Hapus Semua'), findsOneWidget);

    // Confirm clear all
    await tester.tap(find.text('Hapus Semua'));
    await tester.pumpAndSettle();

    // Verify empty state is rendered and repository is empty
    expect(find.text('Belum Ada Riwayat'), findsOneWidget);
    expect(fakeRepository.devices, isEmpty);
  });
}
