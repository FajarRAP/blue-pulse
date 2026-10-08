/// Extensions on [int] for RSSI signal telemetry formatting.
extension IntExt on int {
  /// Appends the standard 'dBm' unit to the RSSI integer value (e.g. "-45 dBm").
  String toDbmString() => '$this dBm';

  /// Estimates approximate signal strength percentage (0% to 100%)
  /// based on standard BLE RSSI range (-100 dBm to -30 dBm).
  int toSignalPercentage() {
    if (this >= -30) return 100;
    if (this <= -100) return 0;
    return (((this + 100) / 70) * 100).round().clamp(0, 100);
  }
}
