import 'package:material_ui/material_ui.dart';

import 'package:blue_pulse/core/utils/extensions.dart';
import 'package:blue_pulse/core/utils/preview_annotations.dart';

/// Informative dialog displayed when Bluetooth or Location permissions are denied or permanently denied.
///
/// Follows the Dumb Component pattern: purely driven by input callbacks and properties.
class const BlePermissionDialog({
  super.key,
  required final VoidCallback onOpenSettings,
  final VoidCallback? onDismiss,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final text = context.text;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: 20.radius),
      icon: Icon(
        Icons.bluetooth_disabled_rounded,
        color: scheme.error,
        size: 40,
      ),
      title: const Text(
        'Izin Bluetooth Diperlukan',
        textAlign: .center,
        style: TextStyle(fontWeight: .bold),
      ),
      content: Text(
        'BluePulse memerlukan izin Bluetooth dan Lokasi untuk mendeteksi '
        'serta memperkirakan jarak perangkat BLE di sekitar Anda. '
        'Silakan buka Pengaturan aplikasi untuk memberikan izin.',
        textAlign: .center,
        style: text.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
      actionsAlignment: .spaceBetween,
      actions: [
        TextButton(
          onPressed: onDismiss,
          child: const Text('Batal'),
        ),
        FilledButton.icon(
          onPressed: onOpenSettings,
          icon: const Icon(Icons.settings_rounded, size: 18),
          label: const Text('Buka Pengaturan'),
        ),
      ],
    );
  }
}

@BluePulsePreview(name: 'BLE Permission Dialog', group: 'Scanner Dialogs')
Widget previewBlePermissionDialog() {
  return BlePermissionDialog(
    onOpenSettings: () {},
    onDismiss: () {},
  );
}
