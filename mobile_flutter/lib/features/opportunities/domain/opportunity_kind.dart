/// The 8 `opportunity_kind` enum values mirrored from the DB enum
/// (`hiring`, `seeking_role`, `fundraising`, `investing`, `cofounder`,
/// `advising`, `seeking_advisor`, `collaboration`).
///
/// Each value carries a `dbValue` (the literal wire / DB encoding) and an
/// `i18nKey` resolvable via `context.t(...)` against the
/// `opportunities.kind.*` namespace in `en.json` / `es.json`.
enum OpportunityKind {
  hiring('hiring'),
  seekingRole('seeking_role'),
  fundraising('fundraising'),
  investing('investing'),
  cofounder('cofounder'),
  advising('advising'),
  seekingAdvisor('seeking_advisor'),
  collaboration('collaboration');

  const OpportunityKind(this.dbValue);

  /// Literal wire encoding — matches the SQL enum exactly. Use this when
  /// serialising RPC params or comparing against raw row payloads.
  final String dbValue;

  /// Translation key consumed by `context.t(...)`. Keys live under
  /// `opportunities.kind.<dbValue>` in the locale JSON.
  String get i18nKey => 'opportunities.kind.$dbValue';

  /// Resolves a raw wire value to an enum instance. Throws [ArgumentError]
  /// on unknowns so callers don't silently treat a new server enum as a
  /// known one (would mask schema drift).
  static OpportunityKind fromDb(String value) {
    for (final OpportunityKind v in OpportunityKind.values) {
      if (v.dbValue == value) return v;
    }
    throw ArgumentError.value(value, 'value', 'Unknown opportunity_kind');
  }
}
