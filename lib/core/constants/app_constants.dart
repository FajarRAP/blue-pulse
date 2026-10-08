/// Application-wide constants for BluePulse BLE Tracker.
abstract final class AppConstants {
  // --- BLE Scanning & Telemetry Parameters ---
  /// Default BLE scan duration before stopping automatically.
  static const scanTimeout = Duration(seconds: 15);

  /// Default Measured RSSI at 1 meter distance (TxPower calibration constant).
  static const defaultTxPower = -59;

  /// Default Path-Loss Exponent (n) for indoor office/home environments.
  static const defaultPathLossExponent = 2.4;

  /// Smoothing factor (alpha) for Exponential Moving Average (EMA).
  /// Balances responsiveness with signal jitter reduction.
  static const defaultEmaAlpha = 0.35;

  /// Watchdog duration to mark a tracked target as Lost when no advertising packet is received.
  static const signalLostThreshold = Duration(seconds: 10);

  // --- Persistence Constants ---
  /// SQLite database filename.
  static const databaseName = 'devices.db';

  /// SQLite database schema version.
  static const databaseVersion = 1;

  /// Table name for discovered BLE devices history log.
  static const historyTableName = 'device_history';
}
