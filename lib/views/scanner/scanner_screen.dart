import 'package:material_ui/material_ui.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'package:blue_pulse/core/di/injection.dart';
import 'package:blue_pulse/data/models/ble_device_model.dart';
import 'package:blue_pulse/viewmodels/scanner_viewmodel.dart';
import 'package:blue_pulse/views/scanner/widgets/device_card.dart';
import 'package:blue_pulse/views/scanner/widgets/filter_bar.dart';

/// Screen 1: Dashboard Utama (Scanner View).
///
/// Features real-time BLE scanning, auto-sorting by RSSI descending,
/// multi-criteria search and signal threshold filtering, and responsive device cards.
class ScannerScreen extends StatefulWidget {
  final ValueChanged<BleDeviceModel>? onDeviceSelected;
  final ScannerViewModel? viewModel;

  const ScannerScreen({
    super.key,
    this.onDeviceSelected,
    this.viewModel,
  });

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  late final ScannerViewModel _viewModel;
  late final TextEditingController _searchController;
  late final bool _isInternalViewModel;

  @override
  void initState() {
    super.initState();
    _isInternalViewModel = widget.viewModel == null;
    _viewModel = widget.viewModel ?? locator<ScannerViewModel>();
    _searchController = TextEditingController(text: _viewModel.searchQuery);

    // Automatically trigger initial BLE scan upon dashboard launch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_viewModel.isScanning) {
        _viewModel.startScan();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    if (_isInternalViewModel) {
      _viewModel.dispose();
    }
    super.dispose();
  }

  void _handleDeviceTap(BleDeviceModel device) {
    if (widget.onDeviceSelected != null) {
      widget.onDeviceSelected!(device);
      return;
    }

    // Default placeholder action for Milestone 3 (Milestone 4 connects to RadarScreen)
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.radar_rounded, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Perangkat dipilih: ${device.name} (${device.id})'),
            ),
          ],
        ),
        behavior: .floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final devices = _viewModel.filteredAndSortedDevices;
        final isScanning = _viewModel.isScanning;
        final hasWarning = _viewModel.adapterState == BluetoothAdapterState.off ||
            _viewModel.errorMessage != null;

        return Scaffold(
          appBar: AppBar(
            elevation: 0,
            title: Row(
              mainAxisSize: .min,
              children: [
                const Text(
                  'BluePulse',
                  style: TextStyle(fontWeight: .bold),
                ),
                const SizedBox(width: 10),
                // Scanning Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isScanning
                        ? colorScheme.primaryContainer
                        : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: .min,
                    children: [
                      if (isScanning) ...[
                        SizedBox(
                          width: 8,
                          height: 8,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Memindai...',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: .w600,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ] else ...[
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Siap',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: .w600,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              // Prominent Start/Stop Scan Toggle Button
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: isScanning
                    ? FilledButton.tonalIcon(
                        onPressed: _viewModel.stopScan,
                        icon: const Icon(Icons.stop_rounded, size: 18),
                        label: const Text('Hentikan'),
                        style: FilledButton.styleFrom(
                          visualDensity: .compact,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                      )
                    : FilledButton.icon(
                        onPressed: _viewModel.startScan,
                        icon: const Icon(Icons.play_arrow_rounded, size: 18),
                        label: const Text('Pindai'),
                        style: FilledButton.styleFrom(
                          visualDensity: .compact,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                      ),
              ),
            ],
          ),
          body: Column(
            crossAxisAlignment: .start,
            children: [
              // Warning Banner (Bluetooth OFF or Error Message)
              if (hasWarning)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.bluetooth_disabled_rounded,
                        color: colorScheme.onErrorContainer,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _viewModel.errorMessage ??
                              'Bluetooth tidak aktif. Silakan nyalakan Bluetooth untuk memindai.',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onErrorContainer,
                            fontWeight: .w500,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _viewModel.startScan,
                        style: TextButton.styleFrom(
                          visualDensity: .compact,
                          foregroundColor: colorScheme.onErrorContainer,
                        ),
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                ),

              // Multi-Filter Bar: Search TextField & Threshold Chips
              FilterBar(
                searchController: _searchController,
                onSearchChanged: _viewModel.setSearchQuery,
                onClearSearch: () {
                  _searchController.clear();
                  _viewModel.setSearchQuery('');
                },
                selectedThreshold: _viewModel.rssiThreshold,
                onThresholdSelected: _viewModel.setRssiThreshold,
              ),

              // Summary Bar: Device Count & Filter Reset
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
                child: Row(
                  children: [
                    Text(
                      _viewModel.hasActiveFilters
                          ? 'Ditemukan ${devices.length} dari ${_viewModel.totalDevicesCount} perangkat'
                          : 'Ditemukan ${devices.length} perangkat',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: .w600,
                      ),
                    ),
                    const Spacer(),
                    if (_viewModel.hasActiveFilters)
                      GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          _viewModel.clearFilters();
                        },
                        child: Text(
                          'Reset Filter',
                          style: textTheme.labelSmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: .bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Device List or Informative Empty State
              Expanded(
                child: devices.isEmpty
                    ? _buildEmptyState(context, colorScheme, textTheme)
                    : ListView.builder(
                        itemCount: devices.length,
                        padding: const EdgeInsets.only(top: 4, bottom: 20),
                        itemBuilder: (context, index) {
                          final device = devices[index];
                          return DeviceCard(
                            key: ValueKey(device.id),
                            device: device,
                            onTap: () => _handleDeviceTap(device),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    if (_viewModel.isScanning) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: .center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text(
                'Memindai perangkat BLE di sekitar...',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: .bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Pastikan perangkat Bluetooth berada dalam jangkauan dan mode advertising aktif.',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (_viewModel.hasActiveFilters) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: .center,
            children: [
              Icon(
                Icons.filter_alt_off_rounded,
                size: 56,
                color: colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                'Tidak Ada Perangkat yang Cocok',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: .bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Coba ubah kata kunci pencarian atau longgarkan filter ambang batas RSSI.',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {
                  _searchController.clear();
                  _viewModel.clearFilters();
                },
                child: const Text('Reset Filter'),
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: .center,
          children: [
            Icon(
              Icons.bluetooth_searching_rounded,
              size: 56,
              color: colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Belum Ada Perangkat Ditemukan',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: .bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Tekan tombol "Pindai" di atas untuk mencari perangkat Bluetooth di sekitar.',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _viewModel.startScan,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Mulai Pindai'),
            ),
          ],
        ),
      ),
    );
  }
}
