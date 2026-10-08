import 'package:get_it/get_it.dart';

/// Global Service Locator instance powered by GetIt.
final locator = GetIt.instance;

/// Sets up the dependency injection container for BluePulse.
///
/// Services, data sources, and repositories will be registered here
/// as they are implemented across upcoming milestones.
Future<void> setupLocator() async {
  // Services & Repositories registrations will be plugged in Milestone 2:
  // - PermissionService (lazy singleton)
  // - LocalDatabase (lazy singleton)
  // - IDeviceHistoryRepository (lazy singleton)
  // - IBleService (lazy singleton)
}
