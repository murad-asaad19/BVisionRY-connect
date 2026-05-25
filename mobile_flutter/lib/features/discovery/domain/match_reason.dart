/// The five canonical match-reason strings returned by `get_daily_matches`
/// (spec §3.2 `match_reason_for`) mapped to typed Dart enum values + their
/// localization key.
///
/// Use [MatchReason.fromServer] when parsing a row from the database; unknown
/// strings fall back to [MatchReason.dailyPick] so the UI never crashes if
/// the server adds a new reason.
enum MatchReason {
  complementaryGoals('Complementary goals', 'discovery.reason.complementaryGoals'),
  sharedRole('Shared role', 'discovery.reason.sharedRole'),
  sameCity('Same city', 'discovery.reason.sameCity'),
  newOnConnect('New on Connect', 'discovery.reason.newOnConnect'),
  dailyPick('Daily pick', 'discovery.reason.dailyPick');

  const MatchReason(this.serverValue, this.i18nKey);

  /// The exact string returned by the RPC.
  final String serverValue;

  /// The dotted i18n key — passed to [BuildContext.t] for display.
  final String i18nKey;

  /// Parses the RPC string. Unknown values map to [dailyPick] so the UI
  /// always has something to render.
  static MatchReason fromServer(String value) {
    for (final r in MatchReason.values) {
      if (r.serverValue == value) return r;
    }
    return MatchReason.dailyPick;
  }
}
