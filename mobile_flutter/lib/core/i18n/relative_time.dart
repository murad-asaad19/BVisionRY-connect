import 'package:flutter/widgets.dart';

import 'i18n.dart';

/// Localized "time ago" / "time until" formatting backed by the `time.*`
/// i18n keys. Replaces the three bespoke English-only formatters that used
/// to live in `opportunities/_relative_time.dart`,
/// `chat/conversation_overview_tile.dart` and `intros/intro_state_badge.dart`.
///
/// Pass [now] for deterministic tests / golden snapshots.
String relativeTimeAgo(BuildContext context, DateTime time, {DateTime? now}) {
  final DateTime reference = now ?? DateTime.now();
  final Duration d = reference.difference(time);
  if (d.inSeconds < 45) return context.t('time.justNow');
  if (d.inMinutes < 60) {
    return context
        .t('time.minutesAgo', vars: <String, Object>{'count': d.inMinutes});
  }
  if (d.inHours < 24) {
    return context
        .t('time.hoursAgo', vars: <String, Object>{'count': d.inHours});
  }
  if (d.inDays < 7) {
    return context.t('time.daysAgo', vars: <String, Object>{'count': d.inDays});
  }
  return context.t(
    'time.weeksAgo',
    vars: <String, Object>{'count': (d.inDays / 7).floor()},
  );
}

/// Localized future relative time, e.g. "in 3d" / "expired" for an expiry
/// timestamp. Returns the `time.expired` copy once [time] is in the past.
String relativeTimeUntil(BuildContext context, DateTime time, {DateTime? now}) {
  final DateTime reference = now ?? DateTime.now();
  final Duration d = time.difference(reference);
  if (d.isNegative || d.inSeconds <= 0) return context.t('time.expired');
  if (d.inMinutes < 60) {
    return context
        .t('time.inMinutes', vars: <String, Object>{'count': d.inMinutes});
  }
  if (d.inHours < 24) {
    return context
        .t('time.inHours', vars: <String, Object>{'count': d.inHours});
  }
  return context.t('time.inDays', vars: <String, Object>{'count': d.inDays});
}
