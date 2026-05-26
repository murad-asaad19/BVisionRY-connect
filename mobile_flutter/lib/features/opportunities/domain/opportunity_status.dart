/// The 3 `opportunity_status` enum values mirrored from the DB enum
/// (`open`, `closed`, `archived`).
enum OpportunityStatus {
  open('open'),
  closed('closed'),
  archived('archived');

  const OpportunityStatus(this.dbValue);

  /// Literal wire encoding — matches the SQL enum exactly.
  final String dbValue;

  /// Resolves a raw wire value to an enum instance. Throws [ArgumentError]
  /// on unknowns so callers don't silently coerce schema drift.
  static OpportunityStatus fromDb(String value) {
    for (final OpportunityStatus v in OpportunityStatus.values) {
      if (v.dbValue == value) return v;
    }
    throw ArgumentError.value(value, 'value', 'Unknown opportunity_status');
  }
}
