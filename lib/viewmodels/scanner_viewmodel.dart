import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'package:blue_pulse/core/constants/app_constants.dart';
import 'package:blue_pulse/core/utils/signal_math.dart';
import 'package:blue_pulse/data/models/ble_device_model.dart';
import 'package:blue_pulse/data/repositories/device_history_repository.dart';
import 'package:blue_pulse/services/ble_service.dart';
import 'package:blue_pulse/services/permission_service.dart';

/// ViewModel for Screen 1: Dashboard Scanner.
///
/// Coordinates Bluetooth Low Energy scanning, real-time signal processing,
/// auto-sorting by RSSI descending, multi-criteria filtering, and debounced
/// persistence to the local SQLite database.
class ScannerViewModel extends ChangeNotifier {
  final BleService bleService;
  final DeviceHistoryRepository historyRepository;
  final PermissionService permissionService;

  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<BluetoothAdapterState>? _adapterStateSubscription;
  StreamSubscription<bool>? _isScanningSubscription;

  final _devices = <String, BleDeviceModel>{};
  final _lastDbWriteTimes = <String, DateTime>{};

  bool _isScanning = false;
  String _searchQuery = '';
  int? _rssiThreshold;
  BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;
  String? _errorMessage;

  ScannerViewModel({
    required this.bleService,
    required this.historyRepository,
    required this.permissionService,
  }) {
    _init();
  }

  void _init() {
    _isScanning = bleService.isScanning;

    _isScanningSubscription = bleService.isScanningStream.listen((scanning) {
      if (_isScanning != scanning) {
        _isScanning = scanning;
        notifyListeners();
      }
    });

    _adapterStateSubscription = bleService.adapterStateStream.listen((state) {
      _adapterState = state;
      if (state == BluetoothAdapterState.off) {
        _errorMessage = 'Bluetooth dalam keadaan mati. Silakan aktifkan Bluetooth.';
      } else if (state == BluetoothAdapterState.unauthorized) {
        _errorMessage = 'Akses Bluetooth tidak diizinkan. Silakan periksa izin perangkat.';
      } else if (_errorMessage != null &&
          (_errorMessage!.contains('Bluetooth dalam keadaan mati') ||
              _errorMessage!.contains('Akses Bluetooth tidak diizinkan'))) {
        _errorMessage = null;
      }
      notifyListeners();
    });

    _scanSubscription = bleService.scanResultsStream.listen(_onScanResults);
  }

  // --- Getters ---

  /// Indicates whether the BLE scanner is actively scanning.
  bool get isScanning => _isScanning;

  /// Active search query string (matches name or MAC address).
  String get searchQuery => _searchQuery;

  /// Current RSSI filter threshold in dBm (e.g. -80, -70, -60, or null for all).
  int? get rssiThreshold => _rssiThreshold;

  /// Current Bluetooth adapter power and authorization state.
  BluetoothAdapterState get adapterState => _adapterState;

  /// Active error or warning message, if any.
  String? get errorMessage => _errorMessage;

  /// Total count of all discovered devices currently held in memory.
  int get totalDevicesCount => _devices.length;

  /// Indicates whether any filter criteria (query or threshold) is active.
  bool get hasActiveFilters => _searchQuery.isNotEmpty || _rssiThreshold != null;

  /// Filtered and auto-sorted list of discovered BLE devices.
  ///
  /// - **Auto-Sort Wajib**: Urutkan dari sinyal terkuat ke terlemah (**RSSI descending**, misal `-35 dBm` berada di atas `-75 dBm`).
  /// - **Filter Pencarian**: Case-insensitive match pada `name` atau `id` (MAC/UUID).
  /// - **Filter Threshold**: Jika `rssiThreshold != null`, hanya tampilkan perangkat dengan `rawRssi >= rssiThreshold`.
  List<BleDeviceModel> get filteredAndSortedDevices {
    final filtered = _devices.values.where((device) {
      // 1. RSSI Threshold filter (rawRssi >= rssiThreshold)
      if (_rssiThreshold != null && device.rawRssi < _rssiThreshold!) {
        return false;
      }

      // 2. Search query filter (case-insensitive name or ID/MAC match)
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesName = device.name.toLowerCase().contains(query);
        final matchesId = device.id.toLowerCase().contains(query);
        if (!matchesName && !matchesId) {
          return false;
        }
      }

      return true;
    }).toList();

    // Auto-Sort: Strongest signal first (RSSI descending)
    filtered.sort((a, b) {
      final rssiComparison = b.rawRssi.compareTo(a.rawRssi);
      if (rssiComparison != 0) {
        return rssiComparison;
      }
      return b.lastSeen.compareTo(a.lastSeen);
    });

    return filtered;
  }

  // --- Actions & Business Logic ---

  /// Requests required BLE runtime permissions and starts BLE scanning.
  Future<void> startScan() async {
    _errorMessage = null;

    final hasPermission = await permissionService.requestBlePermissions();
    if (!hasPermission) {
      _errorMessage = 'Izin Bluetooth dan Lokasi diperlukan untuk memindai perangkat.';
      notifyListeners();
      return;
    }

    if (_adapterState == BluetoothAdapterState.off) {
      _errorMessage = 'Bluetooth dalam keadaan mati. Silakan aktifkan Bluetooth.';
      notifyListeners();
      return;
    }

    try {
      await bleService.startScan();
    } catch (e) {
      _errorMessage = 'Gagal memulai pemindaian: $e';
      notifyListeners();
    }
  }

  /// Terminates an ongoing BLE scan.
  Future<void> stopScan() async {
    try {
      await bleService.stopScan();
    } catch (e) {
      _errorMessage = 'Gagal menghentikan pemindaian: $e';
      notifyListeners();
    }
  }

  /// Updates the active search query filter.
  void setSearchQuery(String query) {
    if (_searchQuery == query) return;
    _searchQuery = query;
    notifyListeners();
  }

  /// Sets or clears the RSSI signal threshold filter.
  void setRssiThreshold(int? threshold) {
    if (_rssiThreshold == threshold) return;
    _rssiThreshold = threshold;
    notifyListeners();
  }

  /// Resets both search query and RSSI threshold filters.
  void clearFilters() {
    if (_searchQuery.isEmpty && _rssiThreshold == null) return;
    _searchQuery = '';
    _rssiThreshold = null;
    notifyListeners();
  }

  /// Clears the active error message banner.
  void clearErrorMessage() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  /// Processes raw scan results emitted by [BleService], calculating telemetry and debouncing SQLite upserts.
  void _onScanResults(List<ScanResult> results) {
    final now = DateTime.now();

    for (final result in results) {
      final id = result.device.remoteId.str;
      final advName = result.advertisementData.advName;
      final platformName = result.device.platformName;
      final name = advName.isNotEmpty
          ? advName
          : (platformName.isNotEmpty ? platformName : 'Unknown Device');

      final existing = _devices[id];
      final prevSmoothed = existing?.smoothedRssi ?? 0.0;
      final smoothed = SignalMath.smoothRssi(prevSmoothed, result.rssi);
      final txPower = result.advertisementData.txPowerLevel ?? AppConstants.defaultTxPower;
      final distance = SignalMath.calculateDistance(result.rssi, txPower: txPower);
      final zone = SignalMath.classifyZone(result.rssi);

      final model = BleDeviceModel(
        id: id,
        name: name,
        rawRssi: result.rssi,
        smoothedRssi: smoothed,
        estimatedDistance: distance,
        zone: zone,
        lastSeen: result.timeStamp,
        firstSeen: existing?.firstSeen ?? result.timeStamp,
        txPower: result.advertisementData.txPowerLevel,
      );

      _devices[id] = model;

      // Debounced SQLite upsert: write at most once per second per device
      final lastWrite = _lastDbWriteTimes[id];
      if (lastWrite == null || now.difference(lastWrite) >= const Duration(seconds: 1)) {
        _lastDbWriteTimes[id] = now;
        unawaited(historyRepository.upsertDevice(model));
      }
    }

    notifyListeners();
  }

  /// Testing hook: manually adds or updates a device model in the in-memory registry.
  @visibleForTesting
  void addDeviceForTesting(BleDeviceModel device) {
    _devices[device.id] = device;
    notifyListeners();
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _adapterStateSubscription?.cancel();
    _isScanningSubscription?.cancel();
    super.dispose();
  }
}
