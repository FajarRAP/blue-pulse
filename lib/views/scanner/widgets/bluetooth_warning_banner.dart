import 'package:material_ui/material_ui.dart';

import 'package:blue_pulse/core/utils/extensions.dart';
import 'package:blue_pulse/core/utils/preview_annotations.dart';

/// Persistent warning banner communicating Bluetooth or permission issues with a quick action button.
///
/// Follows the Dumb Component pattern: strictly driven by provided properties and callbacks.
class const BluetoothWarningBanner({
  super.key,
  required final String message,
  final String actionLabel = 'Coba Lagi',
  final IconData icon = Icons.bluetooth_disabled_rounded,
  final VoidCallback? onAction,
  final EdgeInsetsGeometry? margin,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final text = context.text;

    return Container(
      margin: margin ?? (16.hPadding + 8.vPadding),
      padding: 14.hPadding + 10.vPadding,
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: 12.radius,
      ),
      child: Row(
        crossAxisAlignment: .center,
        children: [
          Icon(
            icon,
            color: scheme.onErrorContainer,
            size: 22,
          ),
          10.wGap,
          Expanded(
            child: Text(
              message,
              style: text.bodySmall?.copyWith(
                color: scheme.onErrorContainer,
                fontWeight: .w500,
              ),
            ),
          ),
          if (onAction != null) ...[
            8.wGap,
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                visualDensity: .compact,
                foregroundColor: scheme.onErrorContainer,
                padding: 8.hPadding,
              ),
              child: Text(
                actionLabel,
                style: const TextStyle(fontWeight: .bold),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

@BluePulsePreview(name: 'Bluetooth Warning Banner', group: 'Scanner Banners')
Widget previewBluetoothWarningBanner() {
  return Column(
    children: [
      BluetoothWarningBanner(
        message: 'Bluetooth dalam keadaan mati. Silakan aktifkan Bluetooth.',
        onAction: () {},
      ),
    ],
  );
}
