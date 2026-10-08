import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

/// Contract interface for managing runtime Bluetooth and Location permissions.
abstract interface class PermissionService {
  /// Prompts the user for runtime BLE permissions based on host OS version.
  /// Returns `true` if all necessary permissions are granted.
  Future<bool> requestBlePermissions();

  /// Checks whether required runtime BLE permissions are currently granted.
  Future<bool> checkBlePermissions();

  /// Navigates the user directly to the application OS settings screen.
  Future<void> openSettings();
}

/// Concrete implementation of [PermissionService] using `permission_handler`.
class PermissionServiceImpl implements PermissionService {
  @override
  Future<bool> requestBlePermissions() async {
    if (Platform.isAndroid) {
      final statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.locationWhenInUse,
      ].request();

      final scanGranted = statuses[Permission.bluetoothScan]?.isGranted ?? false;
      final connectGranted = statuses[Permission.bluetoothConnect]?.isGranted ?? false;
      final locationGranted = statuses[Permission.locationWhenInUse]?.isGranted ?? false;

      // On Android 12+ (API 31+), scan and connect permissions are required.
      // On Android 11 and lower, location permission is required.
      return (scanGranted && connectGranted) || locationGranted;
    } else if (Platform.isIOS) {
      final status = await Permission.bluetooth.request();
      return status.isGranted;
    }
    return true;
  }

  @override
  Future<bool> checkBlePermissions() async {
    if (Platform.isAndroid) {
      final scanGranted = await Permission.bluetoothScan.isGranted;
      final connectGranted = await Permission.bluetoothConnect.isGranted;
      final locationGranted = await Permission.locationWhenInUse.isGranted;

      return (scanGranted && connectGranted) || locationGranted;
    } else if (Platform.isIOS) {
      return await Permission.bluetooth.isGranted;
    }
    return true;
  }

  @override
  Future<void> openSettings() async {
    await openAppSettings();
  }
}
