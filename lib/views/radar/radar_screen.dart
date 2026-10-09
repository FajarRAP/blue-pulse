import 'package:material_ui/material_ui.dart';

import 'package:blue_pulse/core/di/injection.dart';
import 'package:blue_pulse/core/utils/extensions.dart';
import 'package:blue_pulse/core/utils/preview_annotations.dart';
import 'package:blue_pulse/data/models/ble_device_model.dart';
import 'package:blue_pulse/viewmodels/radar_viewmodel.dart';
import 'package:blue_pulse/views/radar/widgets/radar_canvas.dart';
import 'package:blue_pulse/views/radar/widgets/telemetry_card.dart';
import 'package:blue_pulse/views/scanner/widgets/bluetooth_warning_banner.dart';

/// Screen 2: Detail Pelacakan (Radar View).
///
/// Stateful Screen Wrapper that coordinates the lifecycle of [RadarViewModel]
/// and binds state to the presentation dumb view [_RadarView].
class const RadarScreen({
  super.key,
  required final BleDeviceModel targetDevice,
  final RadarViewModel? viewModel,
}) extends StatefulWidget {
  @override
  State<RadarScreen> createState() => _RadarScreenState();
}

class _RadarScreenState extends State<RadarScreen> {
  late final RadarViewModel _viewModel;
  late final bool _isInternalViewModel;

  @override
  void initState() {
    super.initState();
    _isInternalViewModel = widget.viewModel == null;
    _viewModel = widget.viewModel ??
        locator<RadarViewModel>(param1: widget.targetDevice);
  }

  @override
  void dispose() {
    if (_isInternalViewModel) {
      _viewModel.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        return _RadarView(
          device: _viewModel.targetDevice,
          isLost: _viewModel.isLost,
          isBluetoothDisabled: _viewModel.isBluetoothDisabled,
          packetRate: _viewModel.packetRate,
          stabilityScore: _viewModel.stabilityScore,
          timeSinceLastPacket: _viewModel.timeSinceLastPacket,
          onBack: () => Navigator.of(context).pop(),
          onRetryScan: _viewModel.retryScan,
        );
      },
    );
  }
}

/// Dumb View presenting the Radar Canvas, Telemetry Card, and tracking status.
///
/// Pure presentation component: receives all data via parameters and invokes [onBack] callback.
class const _RadarView({
  required final BleDeviceModel device,
  required final bool isLost,
  final bool isBluetoothDisabled = false,
  required final double packetRate,
  required final String stabilityScore,
  required final Duration timeSinceLastPacket,
  required final VoidCallback onBack,
  final VoidCallback? onRetryScan,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final text = context.text;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: onBack,
          tooltip: 'Kembali',
        ),
        title: Column(
          crossAxisAlignment: .start,
          mainAxisSize: .min,
          children: [
            Text(
              device.name,
              style: text.titleMedium?.copyWith(fontWeight: .bold),
              maxLines: 1,
              overflow: .ellipsis,
            ),
            Text(
              device.id,
              style: text.bodySmall?.copyWith(
                fontFamily: 'monospace',
                color: scheme.onSurfaceVariant,
                letterSpacing: 0.5,
              ),
              maxLines: 1,
              overflow: .ellipsis,
            ),
          ],
        ),
        actions: [
          Padding(
            padding: 12.rPadding,
            child: Center(
              child: Container(
                padding: 10.hPadding + 6.vPadding,
                decoration: BoxDecoration(
                  color: isLost
                      ? scheme.errorContainer.withValues(alpha: 0.8)
                      : scheme.primaryContainer,
                  borderRadius: 20.radius,
                ),
                child: Row(
                  mainAxisSize: .min,
                  children: [
                    if (!isLost) ...[
                      SizedBox.square(
                        dimension: 8,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: scheme.onPrimaryContainer,
                        ),
                      ),
                      6.wGap,
                      Text(
                        'Melacak...',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: .w700,
                          color: scheme.onPrimaryContainer,
                        ),
                      ),
                    ] else ...[
                      Icon(
                        isBluetoothDisabled
                            ? Icons.bluetooth_disabled_rounded
                            : Icons
                                .signal_cellular_connected_no_internet_0_bar_rounded,
                        size: 14,
                        color: scheme.onErrorContainer,
                      ),
                      6.wGap,
                      Text(
                        isBluetoothDisabled
                            ? 'Bluetooth Dinonaktifkan'
                            : 'Sinyal Terputus',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: .w700,
                          color: scheme.onErrorContainer,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: 16.allPadding,
          child: Column(
            children: [
              if (isBluetoothDisabled) ...[
                BluetoothWarningBanner(
                  message:
                      'Bluetooth dinonaktifkan. Silakan aktifkan Bluetooth untuk melanjutkan pelacakan radar.',
                  actionLabel: 'Coba Lagi',
                  margin: .zero,
                  onAction: onRetryScan,
                ),
                16.hGap,
              ],
              // Responsive Radar Canvas Area
              ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: 280,
                  maxHeight: 380,
                ),
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: RadarCanvas(
                    device: device,
                    isLost: isLost,
                  ),
                ),
              ),
              16.hGap,
              // Structured Telemetry Card Area
              TelemetryCard(
                device: device,
                isLost: isLost,
                packetRate: packetRate,
                stabilityScore: stabilityScore,
                timeSinceLastPacket: timeSinceLastPacket,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

@BluePulsePreview(name: 'Tracking Active', group: 'RadarScreen')
Widget previewTrackingActive() {
  return _RadarView(
    device: .new(
      id: 'F4:84:4C:12:34:56',
      name: 'Pulse Tracker Alpha',
      rawRssi: -54,
      smoothedRssi: -52.8,
      estimatedDistance: 1.8,
      zone: .strong,
      lastSeen: .now(),
    ),
    isLost: false,
    packetRate: 5.2,
    stabilityScore: 'Sangat Stabil',
    timeSinceLastPacket: 1.seconds,
    onBack: () {},
  );
}

@BluePulsePreview(name: 'Signal Lost', group: 'RadarScreen')
Widget previewSignalLost() {
  return _RadarView(
    device: .new(
      id: 'F4:84:4C:12:34:56',
      name: 'Pulse Tracker Alpha',
      rawRssi: -94,
      smoothedRssi: -92.0,
      estimatedDistance: -1.0,
      zone: .lost,
      lastSeen: .now(),
    ),
    isLost: true,
    packetRate: 0.0,
    stabilityScore: 'Terputus',
    timeSinceLastPacket: 12.seconds,
    onBack: () {},
  );
}

@BluePulsePreview(name: 'Bluetooth Disabled', group: 'RadarScreen')
Widget previewBluetoothDisabled() {
  return _RadarView(
    device: .new(
      id: 'F4:84:4C:12:34:56',
      name: 'Pulse Tracker Alpha',
      rawRssi: -94,
      smoothedRssi: -92.0,
      estimatedDistance: -1.0,
      zone: .lost,
      lastSeen: .now(),
    ),
    isLost: true,
    isBluetoothDisabled: true,
    packetRate: 0.0,
    stabilityScore: 'Terputus',
    timeSinceLastPacket: 15.seconds,
    onBack: () {},
    onRetryScan: () {},
  );
}
