import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:blue_pulse/core/constants/app_colors.dart';
import 'package:blue_pulse/core/constants/app_constants.dart';
import 'package:blue_pulse/core/utils/signal_math.dart';

void main() {
  group('SignalMath - ProximityZone Classification', () {
    test('classifies veryStrong zone (-10 to -30 dBm)', () {
      expect(SignalMath.classifyZone(-10), ProximityZone.veryStrong);
      expect(SignalMath.classifyZone(-20), ProximityZone.veryStrong);
      expect(SignalMath.classifyZone(-30), ProximityZone.veryStrong);
    });

    test('classifies strong zone (-30 to -50 dBm)', () {
      expect(SignalMath.classifyZone(-31), ProximityZone.strong);
      expect(SignalMath.classifyZone(-40), ProximityZone.strong);
      expect(SignalMath.classifyZone(-50), ProximityZone.strong);
    });

    test('classifies fair zone (-50 to -70 dBm)', () {
      expect(SignalMath.classifyZone(-51), ProximityZone.fair);
      expect(SignalMath.classifyZone(-60), ProximityZone.fair);
      expect(SignalMath.classifyZone(-70), ProximityZone.fair);
    });

    test('classifies weak zone (-70 to -80 dBm)', () {
      expect(SignalMath.classifyZone(-71), ProximityZone.weak);
      expect(SignalMath.classifyZone(-75), ProximityZone.weak);
      expect(SignalMath.classifyZone(-80), ProximityZone.weak);
    });

    test('classifies veryWeak zone (-80 to -90 dBm)', () {
      expect(SignalMath.classifyZone(-81), ProximityZone.veryWeak);
      expect(SignalMath.classifyZone(-85), ProximityZone.veryWeak);
      expect(SignalMath.classifyZone(-90), ProximityZone.veryWeak);
    });

    test('classifies lost zone (< -90 dBm or invalid >= 0)', () {
      expect(SignalMath.classifyZone(-91), ProximityZone.lost);
      expect(SignalMath.classifyZone(-95), ProximityZone.lost);
      expect(SignalMath.classifyZone(-100), ProximityZone.lost);
      expect(SignalMath.classifyZone(0), ProximityZone.lost);
      expect(SignalMath.classifyZone(5), ProximityZone.lost);
    });
  });

  group('SignalMath - ProximityZone Getters & Telemetry Tokens', () {
    test('verifies displayName tokens', () {
      expect(ProximityZone.veryStrong.displayName, 'Sangat Kuat');
      expect(ProximityZone.strong.displayName, 'Kuat');
      expect(ProximityZone.fair.displayName, 'Cukup');
      expect(ProximityZone.weak.displayName, 'Lemah');
      expect(ProximityZone.veryWeak.displayName, 'Sangat Lemah');
      expect(ProximityZone.lost.displayName, 'Sinyal Hilang');
    });

    test('verifies distanceRangeDescription tokens', () {
      expect(ProximityZone.veryStrong.distanceRangeDescription, '< 1 meter');
      expect(ProximityZone.strong.distanceRangeDescription, '1 – 3 meter');
      expect(ProximityZone.fair.distanceRangeDescription, '3 – 10 meter');
      expect(ProximityZone.weak.distanceRangeDescription, '10 – 20 meter');
      expect(ProximityZone.veryWeak.distanceRangeDescription, '> 20 meter');
      expect(ProximityZone.lost.distanceRangeDescription, 'Terputus / Di luar jangkauan');
    });

    test('verifies semantic telemetry colors', () {
      expect(ProximityZone.veryStrong.color, AppColors.signalVeryStrong);
      expect(ProximityZone.strong.color, AppColors.signalStrong);
      expect(ProximityZone.fair.color, AppColors.signalFair);
      expect(ProximityZone.weak.color, AppColors.signalWeak);
      expect(ProximityZone.veryWeak.color, AppColors.signalVeryWeak);
      expect(ProximityZone.lost.color, AppColors.signalLost);
      expect(ProximityZone.lost.color, const Color(0xFF9E9E9E));
    });
  });

  group('SignalMath - Log-Distance Path Loss Model', () {
    test('calculates exactly 1.0 meter when RSSI equals txPower', () {
      final distance = SignalMath.calculateDistance(
        AppConstants.defaultTxPower,
        txPower: AppConstants.defaultTxPower,
      );
      expect(distance, closeTo(1.0, 0.001));
    });

    test('calculates close distance (< 1m) when signal is stronger than txPower', () {
      // txPower = -59, rssi = -35 -> exponent = (-59 - (-35)) / 24 = -1.0 -> 10^-1 = 0.1m
      final distance = SignalMath.calculateDistance(-35, txPower: -59, n: 2.4);
      expect(distance, closeTo(0.1, 0.001));
    });

    test('calculates 10.0 meters when exponent evaluates to 1.0', () {
      // txPower = -59, rssi = -83 -> exponent = (-59 - (-83)) / 24 = 24 / 24 = 1.0 -> 10^1 = 10.0m
      final distance = SignalMath.calculateDistance(-83, txPower: -59, n: 2.4);
      expect(distance, closeTo(10.0, 0.001));
    });

    test('returns -1.0 for edge cases (rssi >= 0 or rssi < -95)', () {
      expect(SignalMath.calculateDistance(0), -1.0);
      expect(SignalMath.calculateDistance(10), -1.0);
      expect(SignalMath.calculateDistance(-96), -1.0);
      expect(SignalMath.calculateDistance(-105), -1.0);
    });
  });

  group('SignalMath - Exponential Moving Average (EMA)', () {
    test('initializes directly to currentRaw when prevSmoothed is 0', () {
      final smoothed = SignalMath.smoothRssi(0, -65);
      expect(smoothed, -65.0);
    });

    test('smooths RSSI value according to alpha parameter', () {
      // prevSmoothed = -50.0, currentRaw = -70, alpha = 0.35
      // Expected = 0.35 * -70 + (1 - 0.35) * -50 = -24.5 - 32.5 = -57.0
      final smoothed = SignalMath.smoothRssi(-50.0, -70, alpha: 0.35);
      expect(smoothed, closeTo(-57.0, 0.001));
    });

    test('smooths with custom alpha', () {
      // prevSmoothed = -60.0, currentRaw = -80, alpha = 0.5
      // Expected = 0.5 * -80 + 0.5 * -60 = -40 + -30 = -70.0
      final smoothed = SignalMath.smoothRssi(-60.0, -80, alpha: 0.5);
      expect(smoothed, closeTo(-70.0, 0.001));
    });
  });
}
