/// Compact relative-time formatter shared by the Opportunities surfaces.
///
/// Returns a short, deterministic string (`"now"`, `"5m"`, `"3h"`, `"2d"`,
/// `"5w"`). Deterministic so goldens stay stable; locale-aware formatting
/// (with i18next plural rules) lands in Phase 13.
String relativeShort(DateTime past, {DateTime? now}) {
  final DateTime ref = now ?? DateTime.now().toUtc();
  final Duration diff = ref.difference(past.toUtc());
  if (diff.inMinutes < 1) return 'now';
  if (diff.inHours < 1) return '${diff.inMinutes}m';
  if (diff.inDays < 1) return '${diff.inHours}h';
  if (diff.inDays < 7) return '${diff.inDays}d';
  return '${(diff.inDays / 7).floor()}w';
}

/// `"in 5d"`-style countdown for [future] relative to [now]. Returns
/// `"expired"` when the date is in the past.
String relativeFuture(DateTime future, {DateTime? now}) {
  final DateTime ref = now ?? DateTime.now().toUtc();
  final Duration diff = future.toUtc().difference(ref);
  if (diff.isNegative) return 'expired';
  if (diff.inHours < 1) return 'in ${diff.inMinutes}m';
  if (diff.inDays < 1) return 'in ${diff.inHours}h';
  return 'in ${diff.inDays}d';
}
