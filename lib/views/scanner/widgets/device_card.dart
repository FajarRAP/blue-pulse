import 'package:material_ui/material_ui.dart';

import 'package:blue_pulse/data/models/ble_device_model.dart';

/// Material 3 Card displaying real-time telemetry and metadata for a discovered BLE device.
class const DeviceCard({
  super.key,
  required final BleDeviceModel device,
  required final VoidCallback onTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final zoneColor = device.zone.color;

    final distanceText = device.estimatedDistance >= 0
        ? '${device.estimatedDistance.toStringAsFixed(1)} m'
        : 'N/A';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.6),
          width: 1,
        ),
      ),
      clipBehavior: .antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: .start,
            children: [
              Row(
                crossAxisAlignment: .start,
                children: [
                  // Signal Icon with dynamic zone glow
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: zoneColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: .center,
                    child: Icon(
                      Icons.bluetooth_searching_rounded,
                      color: zoneColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Device Name & MAC Address
                  Expanded(
                    child: Column(
                      crossAxisAlignment: .start,
                      children: [
                        Text(
                          device.name,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: .bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          device.id,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Raw RSSI Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: .min,
                      children: [
                        Icon(
                          Icons.signal_cellular_alt_rounded,
                          size: 14,
                          color: zoneColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${device.rawRssi} dBm',
                          style: textTheme.labelMedium?.copyWith(
                            fontWeight: .bold,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Bottom Telemetry Row: Proximity Zone Pill, Distance Badge, Navigation Chevron
              Row(
                children: [
                  // Proximity Zone Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: zoneColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: zoneColor.withValues(alpha: 0.6),
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
                            shape: BoxShape.circle,
                            color: zoneColor,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          device.zone.displayName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: .w600,
                            color: zoneColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Estimated Distance Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: .min,
                      children: [
                        Icon(
                          Icons.straighten_rounded,
                          size: 13,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          distanceText,
                          style: textTheme.bodySmall?.copyWith(
                            fontWeight: .w600,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Chevron Indicator
                  Icon(
                    Icons.chevron_right_rounded,
                    color: colorScheme.outline,
                    size: 20,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
