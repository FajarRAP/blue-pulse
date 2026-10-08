import 'package:blue_pulse/core/utils/preview_annotations.dart';
import 'package:material_ui/material_ui.dart';

import 'package:blue_pulse/data/models/ble_device_model.dart';

import '../../../core/utils/extensions.dart';

/// Material 3 Card displaying real-time telemetry and metadata for a discovered BLE device.
class const DeviceCard({
  super.key,
  required final BleDeviceModel device,
  final VoidCallback? onTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final text = context.text;
    final zoneColor = device.zone.color;

    final distanceText = device.estimatedDistance >= 0
        ? '${device.estimatedDistance.toStringAsFixed(1)} m'
        : 'N/A';

    return Card(
      elevation: 0,
      margin: .zero,
      shape: RoundedRectangleBorder(
        borderRadius: 16.radius,
        side: BorderSide(
          color: scheme.outlineVariant.withValues(alpha: 0.6),
          width: 1,
        ),
      ),
      clipBehavior: .antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: 16.radius,
        child: Padding(
          padding: 16.allPadding,
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
                      borderRadius: 12.radius,
                    ),
                    alignment: .center,
                    child: Icon(
                      Icons.bluetooth_searching_rounded,
                      color: zoneColor,
                      size: 24,
                    ),
                  ),
                  12.wGap,
                  // Device Name & MAC Address
                  Expanded(
                    child: Column(
                      crossAxisAlignment: .start,
                      children: [
                        Text(
                          device.name,
                          style: text.titleMedium?.copyWith(fontWeight: .bold),
                          maxLines: 1,
                          overflow: .ellipsis,
                        ),
                        4.hGap,
                        Text(
                          device.id,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: scheme.onSurfaceVariant,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          overflow: .ellipsis,
                        ),
                      ],
                    ),
                  ),
                  8.wGap,
                  // Raw RSSI Badge
                  Container(
                    padding: 10.hPadding + 6.vPadding,
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainer,
                      borderRadius: 20.radius,
                    ),
                    child: Row(
                      mainAxisSize: .min,
                      children: [
                        Icon(
                          Icons.signal_cellular_alt_rounded,
                          size: 14,
                          color: zoneColor,
                        ),
                        4.wGap,
                        Text(
                          '${device.rawRssi} dBm',
                          style: text.labelMedium?.copyWith(
                            fontWeight: .bold,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              14.hGap,
              // Bottom Telemetry Row: Proximity Zone Pill, Distance Badge, Navigation Chevron
              Row(
                children: [
                  // Proximity Zone Pill
                  Container(
                    padding: 10.hPadding + 4.vPadding,
                    decoration: BoxDecoration(
                      color: zoneColor.withValues(alpha: 0.12),
                      borderRadius: 20.radius,
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
                            shape: .circle,
                            color: zoneColor,
                          ),
                        ),
                        6.wGap,
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
                  8.wGap,
                  // Estimated Distance Badge
                  Container(
                    padding: 10.hPadding + 4.vPadding,
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest.withValues(
                        alpha: 0.5,
                      ),
                      borderRadius: 20.radius,
                    ),
                    child: Row(
                      mainAxisSize: .min,
                      children: [
                        Icon(
                          Icons.straighten_rounded,
                          size: 13,
                          color: scheme.onSurfaceVariant,
                        ),
                        4.wGap,
                        Text(
                          distanceText,
                          style: text.bodySmall?.copyWith(
                            fontWeight: .w600,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Chevron Indicator
                  Icon(
                    Icons.chevron_right_rounded,
                    color: scheme.outline,
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

@BluePulsePreview(name: 'Device Card')
Widget preview() {
  return Column(
    children: [
      DeviceCard(
        device: .new(
          id: 'id',
          name: 'name',
          rawRssi: 100,
          smoothedRssi: 101,
          estimatedDistance: 50,
          zone: .fair,
          lastSeen: .now(),
        ),
        onTap: () {},
      ),
    ],
  );
}
