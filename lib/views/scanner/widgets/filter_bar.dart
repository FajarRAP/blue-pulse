import 'package:material_ui/material_ui.dart';

import '../../../core/utils/extensions.dart';
import '../../../core/utils/preview_annotations.dart';

/// Representation of an RSSI threshold selection option.
class const RssiThresholdOption({
  required final int? threshold,
  required final String label,
});

/// Horizontal filter bar containing a live search field and RSSI threshold chips.
class const FilterBar({
  super.key,
  final TextEditingController? searchController,
  final ValueChanged<String>? onSearchChanged,
  final VoidCallback? onClearSearch,
  final int? selectedThreshold,
  final ValueChanged<int?>? onThresholdSelected,
}) extends StatelessWidget {
  static const thresholdOptions = [
    RssiThresholdOption(threshold: null, label: 'Semua'),
    RssiThresholdOption(threshold: -80, label: '≥ -80 dBm'),
    RssiThresholdOption(threshold: -70, label: '≥ -70 dBm'),
    RssiThresholdOption(threshold: -60, label: '≥ -60 dBm'),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;

    return Column(
      crossAxisAlignment: .start,
      children: [
        // Search TextField
        Padding(
          padding: 16.hPadding,
          child: TextFormField(
            controller: searchController,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Cari nama atau MAC...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: searchController?.text.isNotEmpty ?? false
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: onClearSearch,
                      tooltip: 'Hapus Pencarian',
                    )
                  : null,
              contentPadding: 16.hPadding + 12.vPadding,
              filled: true,
              fillColor: scheme.surfaceContainerHigh,
              border: OutlineInputBorder(
                borderRadius: 14.radius,
                borderSide: .none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: 14.radius,
                borderSide: .none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: 14.radius,
                borderSide: BorderSide(color: scheme.primary, width: 1.5),
              ),
            ),
          ),
        ),
        10.hGap,
        // Horizontal Filter Chips
        SingleChildScrollView(
          scrollDirection: .horizontal,
          padding: 16.hPadding,
          child: Row(
            spacing: 8,
            children: [
              ...thresholdOptions.map(
                (option) => FilterChip(
                  selected: selectedThreshold == option.threshold,
                  label: Text(option.label),
                  onSelected: (_) {
                    onThresholdSelected?.call(option.threshold);
                  },
                  showCheckmark: false,
                  avatar: selectedThreshold == option.threshold
                      ? Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: scheme.onPrimaryContainer,
                        )
                      : null,
                  shape: RoundedRectangleBorder(borderRadius: 20.radius),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

@BluePulsePreview(name: 'Filter Bar')
Widget preview() {
  return FilterBar();
}
