import 'dart:ui';

/// App color tokens and semantic telemetry colors for BluePulse.
///
/// Follows Material Design 3 Dynamic Theming using a single [primarySeed]
/// and fixed semantic telemetry colors according to the study case specification.
abstract final class AppColors {
  // --- Material 3 Primary Seed ---
  /// Electric Bluetooth Blue seed color for Material 3 ColorScheme generation.
  static const primarySeed = Color(0xFF0066FF);

  // --- 6 Semantic Telemetry Colors (Study Case Specification) ---
  /// Sangat Kuat (< 1m, -10 s/d -30 dBm) -> Green
  static const signalVeryStrong = Color(0xFF00C853);

  /// Kuat (1 - 3m, -30 s/d -50 dBm) -> Cyan / Light Blue
  static const signalStrong = Color(0xFF00B0FF);

  /// Cukup / Baik (3 - 10m, -50 s/d -70 dBm) -> Yellow / Amber
  static const signalFair = Color(0xFFFFD600);

  /// Lemah (10 - 20m, -70 s/d -80 dBm) -> Orange
  static const signalWeak = Color(0xFFFF9100);

  /// Sangat Lemah (> 20m, -80 s/d -90 dBm) -> Red
  static const signalVeryWeak = Color(0xFFFF1744);

  /// Sinyal Hilang / Lost (< -90 dBm atau timeout) -> Grey
  static const signalLost = Color(0xFF9E9E9E);
}
