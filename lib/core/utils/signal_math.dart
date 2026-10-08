import 'dart:math' as math;
import 'dart:ui';

import 'package:blue_pulse/core/constants/app_colors.dart';
import 'package:blue_pulse/core/constants/app_constants.dart';

/// 6 Proximity Zones based on BLE RSSI signal ranges defined in the study case specification.
///
/// For full theoretical derivations, signal propagation physics, and boundary rationale,
/// please refer to `docs/SIGNAL_MATHEMATICS.md`.
enum ProximityZone {
  /// -10 to -30 dBm (< 1 meter)
  veryStrong,

  /// -30 to -50 dBm (1 - 3 meter)
  strong,

  /// -50 to -70 dBm (3 - 10 meter)
  fair,

  /// -70 to -80 dBm (10 - 20 meter)
  weak,

  /// -80 to -90 dBm (> 20 meter / range limit)
  veryWeak,

  /// < -90 dBm (Signal lost / disconnected)
  lost;

  /// Human-readable label for UI telemetry presentation.
  String get displayName => switch (this) {
    .veryStrong => 'Sangat Kuat',
    .strong => 'Kuat',
    .fair => 'Cukup',
    .weak => 'Lemah',
    .veryWeak => 'Sangat Lemah',
    .lost => 'Sinyal Hilang',
  };

  /// Estimated distance range description in meters.
  String get distanceRangeDescription => switch (this) {
    .veryStrong => '< 1 meter',
    .strong => '1 \u002d 3 meter',
    .fair => '3 \u002d 10 meter',
    .weak => '10 \u002d 20 meter',
    .veryWeak => '> 20 meter',
    .lost => 'Terputus / Di luar jangkauan',
  };

  /// Semantic telemetry color token (pure dart:ui Color, decoupled from material).
  Color get color => switch (this) {
    .veryStrong => AppColors.signalVeryStrong,
    .strong => AppColors.signalStrong,
    .fair => AppColors.signalFair,
    .weak => AppColors.signalWeak,
    .veryWeak => AppColors.signalVeryWeak,
    .lost => AppColors.signalLost,
  };
}

/// Signal Mathematics Engine for BluePulse BLE Tracker.
///
/// Implements the Log-Distance Path Loss model for physical distance estimation,
/// Exponential Moving Average (EMA) for signal jitter smoothing, and 6-zone
/// proximity classification.
///
/// NOTE: Due to Dart doc comments lacking native LaTeX formatting, full mathematical
/// proofs, physics derivations, and parameter trade-off analyses are documented
/// in `docs/SIGNAL_MATHEMATICS.md`. Developers are strongly encouraged to consult that document.
abstract final class SignalMath {
  /// Classifies raw RSSI in dBm into one of 6 [ProximityZone]s.
  ///
  /// Boundary specifications:
  /// - >= -30 dBm: [ProximityZone.veryStrong] (< 1m)
  /// - -30 to -50 dBm: [ProximityZone.strong] (1 - 3m)
  /// - -50 to -70 dBm: [ProximityZone.fair] (3 - 10m)
  /// - -70 to -80 dBm: [ProximityZone.weak] (10 - 20m)
  /// - -80 to -90 dBm: [ProximityZone.veryWeak] (> 20m)
  /// - < -90 dBm or invalid (>= 0): [ProximityZone.lost]
  ///
  /// See `docs/SIGNAL_MATHEMATICS.md` Section 3 for the detailed classification matrix.
  static ProximityZone classifyZone(int rssi) {
    return switch (rssi) {
      >= 0 || < -90 => .lost,
      >= -30 => .veryStrong,
      >= -50 => .strong,
      >= -70 => .fair,
      >= -80 => .weak,
      _ => .veryWeak,
    };
  }

  /// Calculates approximate physical distance in meters using the Log-Distance Path Loss Model.
  ///
  /// - [rssi]: Measured Received Signal Strength Indicator in dBm.
  /// - [txPower]: Calibrated RSSI at 1 meter distance (defaults to [AppConstants.defaultTxPower] = -59 dBm).
  /// - [n]: Environmental Path Loss Exponent (defaults to [AppConstants.defaultPathLossExponent] = 2.4).
  ///
  /// Returns `-1.0` for edge cases where `rssi >= 0` or `rssi < -95` (signal lost / invalid).
  ///
  /// Detailed formula derivation and environmental parameter tables are available in `docs/SIGNAL_MATHEMATICS.md` Section 1.
  static double calculateDistance(
    int rssi, {
    int txPower = AppConstants.defaultTxPower,
    double n = AppConstants.defaultPathLossExponent,
  }) {
    if (rssi >= 0 || rssi < -95) {
      return -1.0;
    }
    final exponent = (txPower - rssi) / (10.0 * n);
    return math.pow(10.0, exponent).toDouble();
  }

  /// Applies Exponential Moving Average (EMA) to smooth out raw RSSI fluctuations.
  ///
  /// If [prevSmoothed] is `0` (initial state / cold start), initializes directly with [currentRaw].
  ///
  /// See `docs/SIGNAL_MATHEMATICS.md` Section 2 for alpha factor selection and anti-jitter rationale.
  static double smoothRssi(
    double prevSmoothed,
    int currentRaw, {
    double alpha = AppConstants.defaultEmaAlpha,
  }) {
    if (prevSmoothed == 0) {
      return currentRaw.toDouble();
    }
    return (alpha * currentRaw) + ((1.0 - alpha) * prevSmoothed);
  }
}
