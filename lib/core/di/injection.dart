import 'package:get_it/get_it.dart';

import 'package:blue_pulse/data/datasources/local_database.dart';
import 'package:blue_pulse/data/repositories/device_history_repository.dart';
import 'package:blue_pulse/services/ble_service.dart';
import 'package:blue_pulse/services/permission_service.dart';

/// Global Service Locator instance powered by GetIt.
final locator = GetIt.instance;

/// Sets up the dependency injection container for BluePulse.
///
/// Registers core singletons for data sources, repositories, and platform services.
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
}
