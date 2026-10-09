import 'package:material_ui/material_ui.dart';

import 'package:blue_pulse/core/constants/app_colors.dart';
import 'package:blue_pulse/core/utils/extensions.dart';
import 'package:blue_pulse/core/utils/preview_annotations.dart';
import 'package:blue_pulse/data/models/ble_device_model.dart';

/// Telemetry Card displaying structured real-time metrics for a tracked BLE device.
///
/// Shows Raw vs Smoothed RSSI, numerical distance estimation, signal stability indicator,
/// packet heartbeat rate, and relative time since last packet.
///
/// Follows the Dumb Component Pattern: receives data via properties and has no service locator calls.
class const TelemetryCard({
  super.key,
  required final BleDeviceModel device,
  required final bool isLost,
  required final double packetRate,
  required final String stabilityScore,
  required final Duration timeSinceLastPacket,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final text = context.text;
    final zoneColor = isLost ? AppColors.signalLost : device.zone.color;

    final distanceStr = (isLost || device.estimatedDistance < 0)
        ? 'N/A'
        : device.estimatedDistance.toStringAsFixed(1);

    final lastSeenStr = isLost
        ? 'Hilang (> 10 dtk)'
        : timeSinceLastPacket.inSeconds < 1
        ? 'Baru saja'
        : '${timeSinceLastPacket.inSeconds} dtk lalu';

    final stabilityColor = switch (stabilityScore) {
      'Sangat Stabil' => AppColors.signalVeryStrong,
      'Stabil' => AppColors.signalStrong,
      'Fluktuatif' => AppColors.signalWeak,
      _ => AppColors.signalLost,
    };

    return Card(
      elevation: 0,
      margin: .zero,
      shape: RoundedRectangleBorder(
        borderRadius: 20.radius,
        side: BorderSide(
          color: scheme.outlineVariant.withValues(alpha: 0.6),
          width: 1,
        ),
      ),
      clipBehavior: .antiAlias,
      child: Padding(
        padding: 20.allPadding,
        child: Column(
          crossAxisAlignment: .start,
          children: [
            // 1. Header: Numerical Distance & Zone Badge
            Row(
              crossAxisAlignment: .start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: .start,
                    children: [
                      Text(
                        'ESTIMASI JARAK',
                        style: text.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: .w700,
                          letterSpacing: 1.1,
                        ),
                      ),
                      4.hGap,
                      Row(
                        crossAxisAlignment: .baseline,
                        textBaseline: .alphabetic,
                        children: [
                          Text(
                            distanceStr,
                            style: text.headlineLarge?.copyWith(
                              fontWeight: .bold,
                              color: isLost ? scheme.outline : scheme.onSurface,
                            ),
                          ),
                          if (!isLost && device.estimatedDistance >= 0) ...[
                            6.wGap,
                            Text(
                              'meter',
                              style: text.titleMedium?.copyWith(
                                color: scheme.onSurfaceVariant,
                                fontWeight: .w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Proximity Zone Pill
                Container(
                  padding: 10.hPadding + 6.vPadding,
                  decoration: BoxDecoration(
                    color: zoneColor.withValues(alpha: 0.12),
                    borderRadius: 20.radius,
                    border: .all(
                      color: zoneColor.withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: .min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: .circle,
                          color: zoneColor,
                        ),
                      ),
                      6.wGap,
                      Text(
                        isLost ? 'Sinyal Hilang' : device.zone.displayName,
                        style: text.labelMedium?.copyWith(
                          fontWeight: .bold,
                          color: zoneColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Warning Banner when signal is lost
            if (isLost) ...[
              14.hGap,
              Container(
                padding: 12.allPadding,
                decoration: BoxDecoration(
                  color: scheme.errorContainer.withValues(alpha: 0.4),
                  borderRadius: 12.radius,
                  border: .all(
                    color: scheme.error.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: scheme.error,
                      size: 20,
                    ),
                    10.wGap,
                    Expanded(
                      child: Text(
                        'Watchdog: Tidak ada sinyal diterima dalam 10 detik terakhir.',
                        style: text.bodySmall?.copyWith(
                          color: scheme.onErrorContainer,
                          fontWeight: .w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            16.hGap,
            Divider(color: scheme.outlineVariant.withValues(alpha: 0.5)),
            16.hGap,

            // 2. Metrics 2x2 Layout
            Row(
              children: [
                // RSSI Metric Tile
                Expanded(
                  child: _MetricTile(
                    icon: Icons.sensors_rounded,
                    label: 'Sinyal (Raw / Smooth)',
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '${device.rawRssi} ',
                            style: text.bodyMedium?.copyWith(
                              fontWeight: .bold,
                              color: scheme.onSurface,
                            ),
                          ),
                          TextSpan(
                            text: 'dBm',
                            style: text.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          TextSpan(
                            text: ' / ',
                            style: text.bodySmall?.copyWith(
                              color: scheme.outline,
                            ),
                          ),
                          TextSpan(
                            text: device.smoothedRssi.toStringAsFixed(1),
                            style: text.bodyMedium?.copyWith(
                              fontWeight: .bold,
                              color: zoneColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                12.wGap,
                // Stability Metric Tile
                Expanded(
                  child: _MetricTile(
                    icon: Icons.show_chart_rounded,
                    label: 'Stabilitas Sinyal',
                    child: Row(
                      mainAxisSize: .min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: .circle,
                            color: stabilityColor,
                          ),
                        ),
                        6.wGap,
                        Text(
                          stabilityScore,
                          style: text.bodyMedium?.copyWith(
                            fontWeight: .bold,
                            color: stabilityColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            12.hGap,

            Row(
              children: [
                // Packet Rate Tile
                Expanded(
                  child: _MetricTile(
                    icon: Icons.speed_rounded,
                    label: 'Reception Rate',
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '${packetRate.toStringAsFixed(1)} ',
                            style: text.bodyMedium?.copyWith(
                              fontWeight: .bold,
                              color: scheme.onSurface,
                            ),
                          ),
                          TextSpan(
                            text: 'pkt/s',
                            style: text.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                12.wGap,
                // Last Detected Tile
                Expanded(
                  child: _MetricTile(
                    icon: Icons.access_time_rounded,
                    label: 'Terakhir Terdeteksi',
                    child: Text(
                      lastSeenStr,
                      style: text.bodyMedium?.copyWith(
                        fontWeight: .bold,
                        color: isLost ? scheme.error : scheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: .ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class const _MetricTile({
  required final IconData icon,
  required final String label,
  required final Widget child,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final text = context.text;

    return Container(
      padding: 12.allPadding,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: 12.radius,
        border: .all(
          color: scheme.outlineVariant.withValues(alpha: 0.4),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: scheme.onSurfaceVariant),
              6.wGap,
              Expanded(
                child: Text(
                  label,
                  style: text.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontSize: 10.5,
                  ),
                  maxLines: 1,
                  overflow: .ellipsis,
                ),
              ),
            ],
          ),
          6.hGap,
          child,
        ],
      ),
    );
  }
}

@BluePulsePreview(name: 'Telemetry Card')
Widget previewTelemetryCard() {
  return Column(
    children: [
      TelemetryCard(
        device: .new(
          id: 'AA:BB:CC:DD:EE:FF',
          name: 'Pulse Beacon Pro',
          rawRssi: -58,
          smoothedRssi: -57.4,
          estimatedDistance: 2.1,
          zone: .strong,
          lastSeen: .now(),
        ),
        isLost: false,
        packetRate: 4.5,
        stabilityScore: 'Sangat Stabil',
        timeSinceLastPacket: 1.seconds,
      ),
    ],
  );
}
