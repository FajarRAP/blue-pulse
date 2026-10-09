import 'package:material_ui/material_ui.dart';

import 'package:blue_pulse/core/di/injection.dart';
import 'package:blue_pulse/core/utils/extensions.dart';
import 'package:blue_pulse/core/utils/preview_annotations.dart';
import 'package:blue_pulse/data/models/ble_device_model.dart';
import 'package:blue_pulse/viewmodels/scanner_viewmodel.dart';
import 'package:blue_pulse/views/history/history_screen.dart';
import 'package:blue_pulse/views/radar/radar_screen.dart';
import 'package:blue_pulse/views/scanner/widgets/device_card.dart';
import 'package:blue_pulse/views/scanner/widgets/filter_bar.dart';

/// Screen 1: Dashboard Utama (Scanner View).
///
/// Features real-time BLE scanning, auto-sorting by RSSI descending,
/// multi-criteria search and signal threshold filtering, and responsive device cards.
class const ScannerScreen({
  super.key,
  final ValueChanged<BleDeviceModel>? onDeviceSelected,
  final ScannerViewModel? viewModel,
}) extends StatefulWidget {
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

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => RadarScreen(targetDevice: device)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final text = context.text;
    final viewPadding = context.viewPadding;

    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final devices = _viewModel.filteredAndSortedDevices;
        final isScanning = _viewModel.isScanning;
        final hasWarning =
            _viewModel.adapterState == .off || _viewModel.errorMessage != null;

        return Scaffold(
          appBar: AppBar(
            // title: Row(
            //   mainAxisSize: .min,
            //   children: [
            //     const Text('BluePulse', style: TextStyle(fontWeight: .bold)),
            //     10.wGap,
            //     // Scanning Status Badge
            //     Container(
            //       padding: 8.hPadding + 4.vPadding,
            //       decoration: BoxDecoration(
            //         color: isScanning
            //             ? scheme.primaryContainer
            //             : scheme.surfaceContainer,
            //         borderRadius: 12.radius,
            //       ),
            //       child: Row(
            //         mainAxisSize: .min,
            //         children: [
            //           if (isScanning) ...[
            //             SizedBox.square(
            //               dimension: 8,
            //               child: CircularProgressIndicator(strokeWidth: 2),
            //             ),
            //             6.wGap,
            //             Text(
            //               'Memindai...',
            //               style: TextStyle(
            //                 fontSize: 11,
            //                 fontWeight: .w600,
            //                 color: scheme.onPrimaryContainer,
            //               ),
            //             ),
            //           ] else ...[
            //             SizedBox.square(
            //               dimension: 6,
            //               child: DecoratedBox(
            //                 decoration: BoxDecoration(
            //                   shape: .circle,
            //                   color: scheme.onSurfaceVariant,
            //                 ),
            //               ),
            //             ),
            //             6.wGap,
            //             Text(
            //               'Siap',
            //               style: TextStyle(
            //                 fontSize: 11,
            //                 fontWeight: .w600,
            //                 color: scheme.onSurfaceVariant,
            //               ),
            //             ),
            //           ],
            //         ],
            //       ),
            //     ),
            //   ],
            // ),
            title: Column(
              crossAxisAlignment: .start,
              mainAxisSize: .min,
              children: [
                const Text('BluePulse', style: TextStyle(fontWeight: .bold)),
                Row(
                  mainAxisSize: .min,
                  children: [
                    if (isScanning) ...[
                      SizedBox.square(
                        dimension: 8,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: scheme.primary,
                        ),
                      ),
                      6.wGap,
                      Text(
                        'Memindai...',
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.primary,
                          fontWeight: .w600,
                        ),
                      ),
                    ] else ...[
                      DecoratedBox(
                        decoration: BoxDecoration(
                          shape: .circle,
                          color: scheme.outline,
                        ),
                        child: const SizedBox.square(dimension: 6),
                      ),
                      6.wGap,
                      Text(
                        'Siap',
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.history_rounded),
                tooltip: 'Riwayat Perangkat',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const HistoryScreen()),
                ),
              ),
              // Prominent Start/Stop Scan Toggle Button
              if (isScanning)
                FilledButton.tonalIcon(
                  onPressed: _viewModel.stopScan,
                  icon: const Icon(Icons.stop_rounded, size: 18),
                  label: const Text('Hentikan'),
                  style: FilledButton.styleFrom(
                    visualDensity: .compact,
                    padding: 12.hPadding,
                  ),
                )
              else
                FilledButton.icon(
                  onPressed: _viewModel.startScan,
                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                  label: const Text('Pindai'),
                  style: FilledButton.styleFrom(
                    visualDensity: .compact,
                    padding: 12.hPadding,
                  ),
                ),
            ],
            actionsPadding: 16.rPadding,
            // Multi-Filter Bar: Search TextField & Threshold Chips
            bottom: PreferredSize(
              preferredSize: .fromHeight(114),
              child: Padding(
                padding: 8.bPadding,
                child: FilterBar(
                  searchController: _searchController,
                  onSearchChanged: _viewModel.setSearchQuery,
                  onClearSearch: () {
                    _searchController.clear();
                    _viewModel.setSearchQuery('');
                  },
                  selectedThreshold: _viewModel.rssiThreshold,
                  onThresholdSelected: _viewModel.setRssiThreshold,
                ),
              ),
            ),
          ),
          body: Column(
            crossAxisAlignment: .start,
            children: [
              // Warning Banner (Bluetooth OFF or Error Message)
              if (hasWarning)
                Container(
                  margin: 16.hPadding + 8.vPadding,
                  padding: 14.hPadding + 10.vPadding,
                  decoration: BoxDecoration(
                    color: scheme.errorContainer,
                    borderRadius: 12.radius,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.bluetooth_disabled_rounded,
                        color: scheme.onErrorContainer,
                        size: 22,
                      ),
                      10.wGap,
                      Expanded(
                        child: Text(
                          _viewModel.errorMessage ?? 'Bluetooth tidak aktif. Silakan nyalakan Bluetooth untuk memindai.',
                          style: text.bodySmall?.copyWith(
                            color: scheme.onErrorContainer,
                            fontWeight: .w500,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _viewModel.startScan,
                        style: TextButton.styleFrom(
                          visualDensity: .compact,
                          foregroundColor: scheme.onErrorContainer,
                        ),
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                ),

              // Summary Bar: Device Count & Filter Reset
              Padding(
                padding: 16.hPadding + 4.vPadding,
                child: Row(
                  children: [
                    Text(
                      _viewModel.hasActiveFilters
                          ? 'Ditemukan ${devices.length} dari ${_viewModel.totalDevicesCount} perangkat'
                          : 'Ditemukan ${devices.length} perangkat',
                      style: text.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
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
                          style: text.labelSmall?.copyWith(
                            color: scheme.primary,
                            fontWeight: .bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Device List or Informative Empty State
              Expanded(
                child: switch (devices.isEmpty) {
                  true =>
                    _viewModel.isScanning
                        ? _Scanning()
                        : _viewModel.hasActiveFilters
                        ? _HasActiveFilters(
                            onResetFilters: () {
                              _searchController.clear();
                              _viewModel.clearFilters();
                            },
                          )
                        : _Empty(
                            onStartScan: () {
                              _viewModel.startScan();
                            },
                          ),
                  false => ListView.separated(
                    itemBuilder: (context, index) {
                      final device = devices[index];

                      return DeviceCard(
                        key: ValueKey(device.id),
                        device: device,
                        onTap: () => _handleDeviceTap(device),
                      );
                    },
                    separatorBuilder: (context, index) => 8.hGap,
                    itemCount: devices.length,
                    padding: 16.allPadding + viewPadding.bottom.bPadding,
                  ),
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class const _Empty({final VoidCallback? onStartScan}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final text = context.text;

    return Center(
      child: Padding(
        padding: 32.allPadding,
        child: Column(
          mainAxisAlignment: .center,
          children: [
            Icon(
              Icons.bluetooth_searching_rounded,
              size: 56,
              color: scheme.outline,
            ),
            16.hGap,
            Text(
              'Belum Ada Perangkat Ditemukan',
              style: text.titleMedium?.copyWith(fontWeight: .bold),
              textAlign: .center,
            ),
            8.hGap,
            Text(
              'Tekan tombol "Pindai" di atas untuk mencari perangkat Bluetooth di sekitar.',
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              textAlign: .center,
            ),
            20.hGap,
            FilledButton.icon(
              onPressed: onStartScan,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Mulai Pindai'),
            ),
          ],
        ),
      ),
    );
  }
}

@BluePulsePreview(name: 'Empty', group: 'Scanner Screen')
Widget previewEmpty() {
  return _Empty(onStartScan: () {});
}

class const _HasActiveFilters({final VoidCallback? onResetFilters})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final text = context.text;

    return Center(
      child: Padding(
        padding: 32.allPadding,
        child: Column(
          mainAxisAlignment: .center,
          children: [
            Icon(Icons.filter_alt_off_rounded, size: 56, color: scheme.outline),
            16.hGap,
            Text(
              'Tidak Ada Perangkat yang Cocok',
              style: text.titleMedium?.copyWith(fontWeight: .bold),
              textAlign: .center,
            ),
            8.hGap,
            Text(
              'Coba ubah kata kunci pencarian atau longgarkan filter ambang batas RSSI.',
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              textAlign: .center,
            ),
            16.hGap,
            OutlinedButton(
              onPressed: onResetFilters,
              child: const Text('Reset Filter'),
            ),
          ],
        ),
      ),
    );
  }
}

@BluePulsePreview(name: 'Has Active Filters', group: 'Scanner Screen')
Widget previewHasActiveFilters() {
  return _HasActiveFilters(onResetFilters: () {});
}

class _Scanning extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final text = context.text;

    return Center(
      child: Padding(
        padding: 32.allPadding,
        child: Column(
          mainAxisAlignment: .center,
          children: [
            const CircularProgressIndicator(),
            20.hGap,
            Text(
              'Memindai perangkat BLE di sekitar...',
              style: text.titleMedium?.copyWith(fontWeight: .bold),
              textAlign: .center,
            ),
            8.hGap,
            Text(
              'Pastikan perangkat Bluetooth berada dalam jangkauan dan mode advertising aktif.',
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              textAlign: .center,
            ),
          ],
        ),
      ),
    );
  }
}
