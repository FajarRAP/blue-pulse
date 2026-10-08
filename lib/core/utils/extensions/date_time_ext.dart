/// Extensions on [DateTime] for human-readable relative time formatting.
extension DateTimeExt on DateTime {
  /// Formats the difference between [DateTime.now()] and this instance
  /// into a human-friendly relative string (e.g. "Baru saja", "15 dtk lalu", "2 mnt lalu").
  String toRelativeTime() {
    final now = DateTime.now();
    final difference = now.difference(this);

    if (difference.inSeconds < 5) return 'Baru saja';
    if (difference.inSeconds < 60) return '${difference.inSeconds} dtk lalu';
    if (difference.inMinutes < 60) return '${difference.inMinutes} mnt lalu';
    if (difference.inHours < 24) return '${difference.inHours} jam lalu';
    if (difference.inDays < 7) return '${difference.inDays} hari lalu';
    return '${day.toString().padLeft(2, '0')}/${month.toString().padLeft(2, '0')}/$year';
  }
}
