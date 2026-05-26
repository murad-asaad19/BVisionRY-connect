/// Mirrors the Postgres enum `public.notification_kind` (spec §2.16):
///
///   intro_received, intro_accepted, message_received, voice_received,
///   meeting_reminder, daily_matches_ready, goal_staleness,
///   meeting_proposal, meeting_confirmed, opportunity_interest.
///
/// Each value carries:
///   * `dbValue`     — wire string sent to / read from the database.
///   * `i18nLabelKey` — translation key under `settings.notif.kind.*`.
enum NotificationKind {
  introReceived('intro_received'),
  introAccepted('intro_accepted'),
  messageReceived('message_received'),
  voiceReceived('voice_received'),
  meetingReminder('meeting_reminder'),
  dailyMatchesReady('daily_matches_ready'),
  goalStaleness('goal_staleness'),
  meetingProposal('meeting_proposal'),
  meetingConfirmed('meeting_confirmed'),
  opportunityInterest('opportunity_interest');

  const NotificationKind(this.dbValue);
  final String dbValue;

  /// Translation key consumed by `context.t(...)`. Keys live under
  /// `settings.notif.kind.<dbValue>` in the locale JSON.
  String get i18nLabelKey => 'settings.notif.kind.$dbValue';

  /// Round-trip safe lookup. Returns `null` for unknown wire values so the
  /// caller can surface a friendly error or fall back to the legacy URL.
  static NotificationKind? fromDb(String? value) {
    if (value == null) return null;
    for (final NotificationKind k in NotificationKind.values) {
      if (k.dbValue == value) return k;
    }
    return null;
  }
}
