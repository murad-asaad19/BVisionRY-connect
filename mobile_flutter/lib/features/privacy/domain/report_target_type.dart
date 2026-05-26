/// Mirrors the Postgres enum `public.report_target_type` (spec §2.12):
///   `('profile', 'message', 'intro')`.
///
/// The lowercase `name` of each value is the literal wire encoding sent to
/// `report_target(p_target_type text, ...)`. Callers should pass `.wire`
/// rather than constructing the literal so a refactor of the enum is
/// caught by the compiler.
enum ReportTargetType {
  profile,
  message,
  intro;

  /// Literal wire encoding — matches the SQL enum exactly.
  String get wire => name;
}
