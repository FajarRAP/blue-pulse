import 'package:material_ui/material_ui.dart';

import 'package:blue_pulse/core/utils/extensions.dart';
import 'package:blue_pulse/core/utils/preview_annotations.dart';
import 'package:blue_pulse/data/models/ble_device_model.dart';

/// Pure Dumb Component representing an individual persisted BLE device in the History Log.
///
/// Displays device name, MAC identifier, last-seen relative timestamp,
/// raw signal badge, estimated distance, dynamic proximity zone pill, and a delete action.
class const HistoryCard({
  super.key,
  required final BleDeviceModel device,
  final VoidCallback? onTap,
  final VoidCallback? onDelete,
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
              // Header Row: Device Icon, Name & MAC, and Individual Delete Button
              Row(
                crossAxisAlignment: .start,
                children: [
                  // Bluetooth Device Icon with dynamic zone glow
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: zoneColor.withValues(alpha: 0.14),
                      borderRadius: 12.radius,
                    ),
                    alignment: .center,
                    child: Icon(
                      Icons.history_rounded,
                      color: zoneColor,
                      size: 24,
                    ),
                  ),
                  12.wGap,
                  // Device Name & MAC Address / UUID
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
                  // Individual Delete Action Button
                  if (onDelete != null)
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        size: 20,
                        color: scheme.error.withValues(alpha: 0.8),
                      ),
                      tooltip: 'Hapus dari Riwayat',
                      onPressed: onDelete,
                      visualDensity: .compact,
                    ),
                ],
              ),
              10.hGap,
              // Relative Timestamp Row
              Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 14,
                    color: scheme.onSurfaceVariant,
                  ),
                  6.wGap,
                  Text(
                    'Terakhir terlihat: ${device.lastSeen.toRelativeTime()}',
                    style: text.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              12.hGap,
              // Telemetry Row: Proximity Zone Pill, RSSI Badge, Distance Badge, Quick-Track Chevron
              Wrap(
                spacing: 8,
                children: [
                  // Proximity Zone Pill
                  Container(
                    padding: 8.hPadding + 4.vPadding,
                    decoration: BoxDecoration(
                      color: zoneColor.withValues(alpha: 0.12),
                      borderRadius: 20.radius,
                      border: .all(
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
                  // Raw RSSI Badge
                  Container(
                    padding: 8.hPadding + 4.vPadding,
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainer,
                      borderRadius: 20.radius,
                    ),
                    child: Row(
                      mainAxisSize: .min,
                      children: [
                        Icon(
                          Icons.signal_cellular_alt_rounded,
                          size: 13,
                          color: zoneColor,
                        ),
                        4.wGap,
                        Text(
                          '${device.rawRssi} dBm',
                          style: text.labelSmall?.copyWith(
                            fontWeight: .bold,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Estimated Distance Badge
                  Container(
                    padding: 8.hPadding + 4.vPadding,
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
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

@BluePulsePreview(name: 'History Card')
Widget previewHistoryCard() => HistoryCard(
  device: .new(
    id: 'D0:56:B2:1A:3C:4E',
    name: 'Pulse Tracker Beacon',
    rawRssi: -58,
    smoothedRssi: -57.2,
    estimatedDistance: 2.1,
    zone: .strong,
    lastSeen: .now().subtract(15.seconds),
  ),
  onTap: () {},
  onDelete: () {},
);
