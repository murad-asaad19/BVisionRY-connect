/// Transcript pipeline status for a voice message (spec §2.6 + §13).
///
/// Server-side states map 1:1 to the worker pipeline:
/// - `pending`: enqueued, no work yet
/// - `processing`: worker has picked it up
/// - `ready`: `transcript` column populated
/// - `unsupported`: codec/language outside the pipeline's capability
/// - `failed`: terminal error (network, ASR rejection, etc.)
enum TranscriptStatus {
  pending,
  processing,
  ready,
  unsupported,
  failed;

  /// Wire value persisted to the DB column.
  String get dbValue => name;

  /// Parses a nullable column value. Returns `null` when the column itself
  /// is null (typical for non-voice messages). Unknown strings fall back to
  /// [failed] so the UI can still render a stable "transcript unavailable"
  /// state.
  static TranscriptStatus? fromDb(String? raw) {
    if (raw == null) return null;
    return TranscriptStatus.values.firstWhere(
      (t) => t.name == raw,
      orElse: () => TranscriptStatus.failed,
    );
  }
}
