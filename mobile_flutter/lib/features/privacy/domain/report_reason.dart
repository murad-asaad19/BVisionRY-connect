/// Mirrors the Postgres enum `public.report_reason` (spec §2.12):
///   `('spam', 'harassment', 'impersonation', 'inappropriate', 'other')`.
///
/// Each value carries a `wire` string (the literal sent to `report_target`)
/// and an `i18nKey` resolvable via `context.t(...)` against the
/// `privacy.reportModal.reasons.*` namespace in `en.json` / `es.json`.
enum ReportReason {
  spam,
  harassment,
  impersonation,
  inappropriate,
  other;

  /// Literal wire encoding — matches the SQL enum exactly.
  String get wire => name;

  /// Translation key consumed by `context.t(...)`. Keys live under
  /// `privacy.reportModal.reasons.<wire>` in the locale JSON.
  String get i18nKey => 'privacy.reportModal.reasons.$name';
}
