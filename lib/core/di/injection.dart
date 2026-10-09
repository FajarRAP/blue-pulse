import 'package:get_it/get_it.dart';

import 'package:blue_pulse/data/datasources/local_database.dart';
import 'package:blue_pulse/data/models/ble_device_model.dart';
import 'package:blue_pulse/data/repositories/device_history_repository.dart';
import 'package:blue_pulse/services/ble_service.dart';
import 'package:blue_pulse/services/permission_service.dart';
import 'package:blue_pulse/viewmodels/history_viewmodel.dart';
import 'package:blue_pulse/viewmodels/radar_viewmodel.dart';
import 'package:blue_pulse/viewmodels/scanner_viewmodel.dart';

/// Global Service Locator instance powered by GetIt.
final locator = GetIt.instance;

/// Sets up the dependency injection container for BluePulse.
///
/// Registers core singletons for data sources, repositories, platform services,
/// and factory registrations for feature ViewModels.
Future<void> setupLocator() async {
  // --- Data Sources ---
  locator.registerLazySingleton<LocalDatabase>(LocalDatabase.new);

  // --- Repositories ---
  locator.registerLazySingleton<DeviceHistoryRepository>(
    () => DeviceHistoryRepositoryImpl(locator<LocalDatabase>()),
  );

  // --- Platform & Hardware Services ---
  locator.registerLazySingleton<PermissionService>(
    PermissionServiceImpl.new,
  );

  locator.registerLazySingleton<BleService>(
    BleServiceImpl.new,
  );

  // --- ViewModels ---
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
}
