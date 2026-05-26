/// Mirrors the Postgres enum `public.notification_kind` (spec §2.16):
///
///   intro_received, intro_accepted, message_received, voice_received,
///   meeting_reminder, daily_matches_ready, goal_staleness,
///   meeting_proposal, meeting_confirmed, opportunity_interest.
///
/// Each value carries:
///   * `dbValue`     — wire string sent to / read from the database.
///   * `i18nLabelKey` — translation key under `settings.notif.kind.*`.
///   * `hasEmitter`   — whether a server-side emitter is currently wired
///     (spec §17.4). Four kinds (`intro_accepted`, `meeting_reminder`,
///     `daily_matches_ready`, `goal_staleness`) currently have no emitter
///     in `send-push` and surface a "coming soon" chip in the matrix UI.
enum NotificationKind {
  introReceived('intro_received', hasEmitter: true),
  introAccepted('intro_accepted', hasEmitter: false),
  messageReceived('message_received', hasEmitter: true),
  voiceReceived('voice_received', hasEmitter: true),
  meetingReminder('meeting_reminder', hasEmitter: false),
  dailyMatchesReady('daily_matches_ready', hasEmitter: false),
  goalStaleness('goal_staleness', hasEmitter: false),
  meetingProposal('meeting_proposal', hasEmitter: true),
  meetingConfirmed('meeting_confirmed', hasEmitter: true),
  opportunityInterest('opportunity_interest', hasEmitter: true);

  const NotificationKind(this.dbValue, {required this.hasEmitter});
  final String dbValue;

  /// Whether the server currently emits push for this kind. The four
  /// no-emitter kinds (§17.4) still appear in the matrix so the user can
  /// configure preferences ahead of the server work, but a "coming soon"
  /// chip is rendered next to the row.
  final bool hasEmitter;

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

  /// UI matrix row order. Matches the RN reference and keeps the visual
  /// grouping (receive → respond → meeting lifecycle → discovery → ops).
  static const List<NotificationKind> uiMatrixOrder = <NotificationKind>[
    introReceived,
    introAccepted,
    messageReceived,
    voiceReceived,
    meetingProposal,
    meetingConfirmed,
    meetingReminder,
    dailyMatchesReady,
    goalStaleness,
    opportunityInterest,
  ];
}
