import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'package:blue_pulse/core/constants/app_constants.dart';
import 'package:blue_pulse/core/utils/extensions.dart';
import 'package:blue_pulse/core/utils/signal_math.dart';
import 'package:blue_pulse/data/models/ble_device_model.dart';
import 'package:blue_pulse/data/repositories/device_history_repository.dart';
import 'package:blue_pulse/services/ble_service.dart';

/// Type alias for backward and architectural compatibility.
typedef RadarTrackingViewModel = RadarViewModel;

/// ViewModel for Screen 2: Detail Pelacakan (Radar View).
///
/// Coordinates target-specific BLE packet filtering, real-time signal smoothing (EMA),
/// dynamic distance estimation, stability scoring, reception packet rate,
/// persistence to SQLite, and an active watchdog for lost signal detection.
class RadarViewModel({
  required final BleService _bleService,
  required final DeviceHistoryRepository _historyRepository,
  required final BleDeviceModel initialDevice,
  final ValueGetter<DateTime>? _nowProvider,
}) extends ChangeNotifier {
  this {
    _targetDevice = initialDevice;
    _lastPacketTime = initialDevice.lastSeen;
    _isLost = initialDevice.zone == .lost;
    _rssiHistory.add(initialDevice.rawRssi);
    _init();
  }

  late BleDeviceModel _targetDevice;
  late DateTime _lastPacketTime;
  late bool _isLost;

  StreamSubscription<List<ScanResult>>? _scanSubscription;
  Timer? _watchdogTimer;

  final List<int> _rssiHistory = [];
  final List<DateTime> _packetTimestamps = [];

  // --- Getters ---

  /// The active tracked target device model with latest telemetry.
  BleDeviceModel get targetDevice => _targetDevice;

  /// Whether the tracked target signal is lost (> 10s without packet or zone == lost).
  bool get isLost => _isLost;

  /// Elapsed duration since the last BLE advertising packet was received from the target.
  Duration get timeSinceLastPacket => _currentTime.difference(_lastPacketTime);

  /// Current time based on [nowProvider] (or [DateTime.now]).
  DateTime get _currentTime => (_nowProvider ?? DateTime.now)();

  /// Estimated packet reception rate (packets per second).
  double get packetRate {
    if (_isLost || _packetTimestamps.isEmpty) {
      return 0.0;
    }

    final now = _currentTime;
    final recent = _packetTimestamps
        .where((t) => now.difference(t) <= 5.seconds)
        .toList();

    if (recent.isEmpty) {
      return 0.0;
    }
    if (recent.length == 1) {
      return 1.0;
    }

    final durationSeconds =
        now.difference(recent.first).inMilliseconds / 1000.0;
    final effectiveDuration = math.max(1.0, durationSeconds);
    return .parse((recent.length / effectiveDuration).toStringAsFixed(1));
  }

  /// Categorical signal stability score based on the variance of delta RSSI.
  ///
  /// Returns "Sangat Stabil", "Stabil", or "Fluktuatif".
  String get stabilityScore {
    if (_isLost) {
      return 'Terputus';
    }
    if (_rssiHistory.length < 2) {
      return 'Stabil';
    }

    final deltas = <double>[];
    for (var i = 1; i < _rssiHistory.length; i++) {
      deltas.add((_rssiHistory[i] - _rssiHistory[i - 1]).abs().toDouble());
    }

    final meanDelta = deltas.reduce((a, b) => a + b) / deltas.length;
    final variance =
        deltas.fold<double>(0.0, (sum, d) => sum + math.pow(d - meanDelta, 2)) /
        deltas.length;

    if (variance <= 2.0 && meanDelta <= 3.0) {
      return 'Sangat Stabil';
    } else if (variance <= 8.0 && meanDelta <= 7.0) {
      return 'Stabil';
    } else {
      return 'Fluktuatif';
    }
  }

  // --- Initialization & Logic ---

  void _init() {
    if (!_bleService.isScanning) {
      try {
        _bleService.startScan();
      } catch (_) {}
    }

    _scanSubscription = _bleService.scanResultsStream.listen(_onScanResults);
    _watchdogTimer = Timer.periodic(1.seconds, (_) => checkWatchdog());
  }

  /// Listens to scan results and filters exclusively for [targetDevice.id].
  void _onScanResults(List<ScanResult> results) {
    for (final result in results) {
      if (result.device.remoteId.str != _targetDevice.id) {
        continue;
      }
      _processTargetPacket(result);
    }
  }

  /// Processes an advertising packet from the target device.
  void _processTargetPacket(ScanResult result) {
    final now = _currentTime;
    _lastPacketTime = now;
    _isLost = false;

    _packetTimestamps.add(now);
    _packetTimestamps.removeWhere((t) => now.difference(t) > 5.seconds);

    _rssiHistory.add(result.rssi);
    if (_rssiHistory.length > 20) {
      _rssiHistory.removeAt(0);
    }

    final prevSmoothed = _targetDevice.smoothedRssi;
    final smoothed = SignalMath.smoothRssi(prevSmoothed, result.rssi);
    final txPower =
        result.advertisementData.txPowerLevel ??
        _targetDevice.txPower ??
        AppConstants.defaultTxPower;
    final distance = SignalMath.calculateDistance(
      result.rssi,
      txPower: txPower,
    );
    final zone = SignalMath.classifyZone(result.rssi);

    final advName = result.advertisementData.advName;
    final platformName = result.device.platformName;
    final updatedName = advName.isNotEmpty
        ? advName
        : (platformName.isNotEmpty ? platformName : _targetDevice.name);

    _targetDevice = _targetDevice.copyWith(
      name: updatedName,
      rawRssi: result.rssi,
      smoothedRssi: smoothed,
      estimatedDistance: distance,
      zone: zone,
      lastSeen: result.timeStamp,
      txPower: result.advertisementData.txPowerLevel ?? _targetDevice.txPower,
    );

    unawaited(_historyRepository.upsertDevice(_targetDevice));
    notifyListeners();
  }

  /// Periodic signal lost watchdog check.
  ///
  /// Marks target as [ProximityZone.lost] and sets [isLost] to `true`
  /// if no packet is received for longer than [AppConstants.signalLostThreshold] (10s).
  void checkWatchdog() {
    final diff = _currentTime.difference(_lastPacketTime);
    if (diff > AppConstants.signalLostThreshold) {
      if (!_isLost || _targetDevice.zone != .lost) {
        _isLost = true;
        _targetDevice = _targetDevice.copyWith(zone: .lost);
        notifyListeners();
      }
    } else {
      notifyListeners();
    }
  }

  /// Testing helper: manually sets the last packet reception time.
  @visibleForTesting
  void setLastPacketTimeForTesting(DateTime time) {
    _lastPacketTime = time;
  }

  /// Testing helper: manually adds an RSSI reading to history.
  @visibleForTesting
  void addRssiForTesting(int rssi) {
    _rssiHistory.add(rssi);
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _watchdogTimer?.cancel();
    super.dispose();
  }
}
