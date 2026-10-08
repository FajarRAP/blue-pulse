import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'package:blue_pulse/core/constants/app_constants.dart';

/// Contract interface for Bluetooth Low Energy (BLE) scanning and hardware radio lifecycle.
abstract interface class BleService {
  /// Stream emitting real-time lists of discovered BLE scan results.
  Stream<List<ScanResult>> get scanResultsStream;

  /// Stream emitting current Bluetooth adapter power state (e.g. on, off, unauthorized).
  Stream<BluetoothAdapterState> get adapterStateStream;

  /// Stream emitting whether BLE scanning is actively running.
  Stream<bool> get isScanningStream;

  /// Starts scanning for nearby BLE peripheral devices.
  Future<void> startScan({Duration? timeout = AppConstants.scanTimeout});

  /// Immediately terminates an ongoing BLE scan operation.
  Future<void> stopScan();

  /// Synchronously checks if a scan is currently active.
  bool get isScanning;

  /// Asynchronously checks if Bluetooth LE hardware is supported by the device.
  Future<bool> get isSupported;
}

/// Concrete implementation of [BleService] wrapping `FlutterBluePlus`.
class BleServiceImpl implements BleService {
  @override
  Stream<List<ScanResult>> get scanResultsStream => FlutterBluePlus.scanResults;

  @override
  Stream<BluetoothAdapterState> get adapterStateStream => FlutterBluePlus.adapterState;

  @override
  Stream<bool> get isScanningStream => FlutterBluePlus.isScanning;

  @override
  bool get isScanning => FlutterBluePlus.isScanningNow;

  @override
  Future<bool> get isSupported => FlutterBluePlus.isSupported;

  @override
  Future<void> startScan({Duration? timeout = AppConstants.scanTimeout}) async {
    if (FlutterBluePlus.isScanningNow) {
      return;
    }
    await FlutterBluePlus.startScan(
      timeout: timeout,
      androidUsesFineLocation: false,
    );
  }

  @override
  Future<void> stopScan() async {
    if (!FlutterBluePlus.isScanningNow) {
      return;
    }
    await FlutterBluePlus.stopScan();
  }
}
