import 'package:material_ui/material_ui.dart';

import 'package:blue_pulse/core/di/injection.dart';
import 'package:blue_pulse/core/utils/extensions.dart';
import 'package:blue_pulse/core/utils/preview_annotations.dart';
import 'package:blue_pulse/data/models/ble_device_model.dart';
import 'package:blue_pulse/viewmodels/history_viewmodel.dart';
import 'package:blue_pulse/views/history/widgets/history_card.dart';
import 'package:blue_pulse/views/radar/radar_screen.dart';

/// Screen 3: Riwayat Perangkat (History Log View).
///
/// Stateful Screen Wrapper that coordinates the lifecycle of [HistoryViewModel]
/// and binds state to the pure presentation component [_HistoryView].
class const HistoryScreen({
  super.key,
  final HistoryViewModel? viewModel,
}) extends StatefulWidget {
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late final HistoryViewModel _viewModel;
  late final bool _isInternalViewModel;

  @override
  void initState() {
    super.initState();
    _isInternalViewModel = widget.viewModel == null;
    _viewModel = widget.viewModel ?? locator<HistoryViewModel>();

    // Load persisted history from SQLite on screen launch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _viewModel.loadHistory();
      }
    });
  }

  @override
  void dispose() {
    if (_isInternalViewModel) {
      _viewModel.dispose();
    }
    super.dispose();
  }

  void _navigateToRadar(BleDeviceModel device) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RadarScreen(targetDevice: device),
      ),
    );
  }

  Future<void> _confirmDeleteDevice(BleDeviceModel device) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Perangkat?'),
        content: Text(
          'Apakah Anda yakin ingin menghapus "${device.name}" (${device.id}) dari riwayat?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _viewModel.deleteDevice(device.id);
      if (mounted) {
        context.showSnackBar(
          message: '${device.name} berhasil dihapus dari riwayat',
        );
      }
    }
  }

  Future<void> _confirmClearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Semua Riwayat?'),
        content: const Text(
          'Seluruh data riwayat perangkat yang tersimpan akan dihapus permanen. Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Hapus Semua'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _viewModel.clearAllHistory();
      if (mounted) {
        context.showSnackBar(message: 'Riwayat perangkat berhasil dibersihkan');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        return _HistoryView(
          devices: _viewModel.devices,
          isLoading: _viewModel.isLoading,
          errorMessage: _viewModel.errorMessage,
          onRefresh: _viewModel.loadHistory,
          onDeviceTap: _navigateToRadar,
          onDeleteDevice: _confirmDeleteDevice,
          onClearAll: _confirmClearAll,
          onBack: () => Navigator.of(context).pop(),
        );
      },
    );
  }
}

/// Pure presentation component displaying the history log list, empty state, and actions.
class const _HistoryView({
  required final List<BleDeviceModel> devices,
  required final bool isLoading,
  required final String? errorMessage,
  required final Future<void> Function() onRefresh,
  required final ValueChanged<BleDeviceModel> onDeviceTap,
  required final ValueChanged<BleDeviceModel> onDeleteDevice,
  required final VoidCallback onClearAll,
  required final VoidCallback onBack,
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
        title: const Text(
          'Riwayat Perangkat',
          style: TextStyle(fontWeight: .bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded),
            tooltip: 'Hapus Semua Riwayat',
            onPressed: devices.isNotEmpty ? onClearAll : null,
          ),
        ],
        actionsPadding: 8.rPadding,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: onRefresh,
          child: _buildContent(context, scheme, text),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ColorScheme scheme,
    TextTheme text,
  ) {
    if (isLoading && devices.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null && devices.isEmpty) {
      return LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: 24.allPadding,
                child: Column(
                  mainAxisSize: .min,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 48,
                      color: scheme.error,
                    ),
                    12.hGap,
                    Text(
                      'Gagal Memuat Riwayat',
                      style: text.titleMedium?.copyWith(fontWeight: .bold),
                    ),
                    6.hGap,
                    Text(
                      errorMessage!,
                      textAlign: .center,
                      style: text.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    16.hGap,
                    FilledButton.tonalIcon(
                      onPressed: onRefresh,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (devices.isEmpty) {
      return LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: 32.allPadding,
                child: Column(
                  mainAxisSize: .min,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest.withValues(
                          alpha: 0.5,
                        ),
                        shape: .circle,
                      ),
                      alignment: .center,
                      child: Icon(
                        Icons.history_rounded,
                        size: 40,
                        color: scheme.primary,
                      ),
                    ),
                    20.hGap,
                    Text(
                      'Belum Ada Riwayat',
                      style: text.titleMedium?.copyWith(fontWeight: .bold),
                    ),
                    8.hGap,
                    Text(
                      'Perangkat BLE yang terdeteksi saat pemindaian akan otomatis tercatat di sini.',
                      textAlign: .center,
                      style: text.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: 16.allPadding,
      itemCount: devices.length,
      separatorBuilder: (_, _) => 12.hGap,
      itemBuilder: (context, index) {
        final device = devices[index];
        return HistoryCard(
          key: ValueKey(device.id),
          device: device,
          onTap: () => onDeviceTap(device),
          onDelete: () => onDeleteDevice(device),
        );
      },
    );
  }
}

@BluePulsePreview(name: 'History Populated', group: 'HistoryScreen')
Widget previewHistoryPopulated() {
  return _HistoryView(
    devices: [
      .new(
        id: 'F4:84:4C:12:34:56',
        name: 'Pulse Tracker Alpha',
        rawRssi: -54,
        smoothedRssi: -52.8,
        estimatedDistance: 1.8,
        zone: .strong,
        lastSeen: .now().subtract(2.seconds),
      ),
      .new(
        id: 'D0:56:B2:78:9A:BC',
        name: 'Beacon Nord-01',
        rawRssi: -72,
        smoothedRssi: -71.5,
        estimatedDistance: 11.2,
        zone: .weak,
        lastSeen: .now().subtract(15.seconds),
      ),
      .new(
        id: 'C1:A2:E3:44:55:66',
        name: 'Smart Tag Pro',
        rawRssi: -35,
        smoothedRssi: -36.0,
        estimatedDistance: 0.8,
        zone: .veryStrong,
        lastSeen: .now().subtract(3.seconds),
      ),
    ],
    isLoading: false,
    errorMessage: null,
    onRefresh: () async {},
    onDeviceTap: (_) {},
    onDeleteDevice: (_) {},
    onClearAll: () {},
    onBack: () {},
  );
}

@BluePulsePreview(name: 'History Empty', group: 'HistoryScreen')
Widget previewHistoryEmpty() {
  return _HistoryView(
    devices: const [],
    isLoading: false,
    errorMessage: null,
    onRefresh: () async {},
    onDeviceTap: (_) {},
    onDeleteDevice: (_) {},
    onClearAll: () {},
    onBack: () {},
  );
}
