import 'package:material_ui/material_ui.dart';

/// Representation of an RSSI threshold selection option.
class const RssiThresholdOption({
  required final int? threshold,
  required final String label,
});

/// Horizontal filter bar containing a live search field and RSSI threshold chips.
class const FilterBar({
  super.key,
  required final TextEditingController searchController,
  required final ValueChanged<String> onSearchChanged,
  required final VoidCallback onClearSearch,
  required final int? selectedThreshold,
  required final ValueChanged<int?> onThresholdSelected,
}) extends StatelessWidget {
  static const thresholdOptions = [
    RssiThresholdOption(threshold: null, label: 'Semua'),
    RssiThresholdOption(threshold: -80, label: '≥ -80 dBm'),
    RssiThresholdOption(threshold: -70, label: '≥ -70 dBm'),
    RssiThresholdOption(threshold: -60, label: '≥ -60 dBm'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          // Search TextField
          TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Cari nama atau MAC...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: onClearSearch,
                      tooltip: 'Hapus Pencarian',
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: colorScheme.primary,
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Horizontal Filter Chips
          SingleChildScrollView(
            scrollDirection: .horizontal,
            child: Row(
              children: [
                for (final option in thresholdOptions) ...[
                  FilterChip(
                    selected: selectedThreshold == option.threshold,
                    label: Text(option.label),
                    onSelected: (_) {
                      onThresholdSelected(option.threshold);
                    },
                    showCheckmark: false,
                    avatar: selectedThreshold == option.threshold
                        ? Icon(
                            Icons.check_rounded,
                            size: 16,
                            color: colorScheme.onPrimaryContainer,
                          )
                        : null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
