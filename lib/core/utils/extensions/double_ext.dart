/// Extensions on [double] for distance telemetry formatting.
extension DoubleExt on double {
  /// Formats distance in meters to a clean readable string (e.g. "< 1 m", "1.5 m", "> 50 m").
  String toDistanceString() {
    if (this < 0 || isInfinite || isNaN) return 'N/A';
    if (this < 1.0) return '< 1 m';
    if (this > 50.0) return '> 50 m';
    return '${toStringAsFixed(1)} m';
  }
}
