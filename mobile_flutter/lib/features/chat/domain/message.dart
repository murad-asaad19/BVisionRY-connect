import 'package:freezed_annotation/freezed_annotation.dart';

import 'message_kind.dart';
import 'transcript_status.dart';

part 'message.freezed.dart';

/// One row from `public.messages` (spec §2.6).
///
/// Carries every column on the table so the same model serves the
/// conversation thread, the chats list preview, and edit/delete flows.
/// Wire conversion is hand-rolled via [Message.fromRow] because the table
/// is read directly (RLS protected) — there's no RPC envelope to wrap.
///
/// The [isTombstone] / [isEdited] / [canEditBy] / [canDeleteBy] helpers
/// centralise the rules so message bubbles can render without re-deriving
/// them from raw columns. Edit window is 15 minutes per spec §3.4.
@freezed
class Message with _$Message {
  const Message._();

  const factory Message({
    required String id,
    required String conversationId,
    required String senderId,
    required MessageKind kind,
    required DateTime createdAt,
    String? body,
    String? meetingProposalId,
    String? mediaPath,
    int? mediaDurationMs,
    int? mediaSizeBytes,
    DateTime? editedAt,
    DateTime? deletedAt,
    String? transcript,
    TranscriptStatus? transcriptStatus,
  }) = _Message;

  factory Message.fromRow(Map<String, dynamic> row) {
    return Message(
      id: row['id'] as String,
      conversationId: row['conversation_id'] as String,
      senderId: row['sender_id'] as String,
      kind: MessageKind.fromDb(row['kind'] as String?),
      createdAt: DateTime.parse(row['created_at'] as String).toUtc(),
      body: row['body'] as String?,
      meetingProposalId: row['meeting_proposal_id'] as String?,
      mediaPath: row['media_path'] as String?,
      mediaDurationMs: (row['media_duration_ms'] as num?)?.toInt(),
      mediaSizeBytes: (row['media_size_bytes'] as num?)?.toInt(),
      editedAt: _parseUtc(row['edited_at']),
      deletedAt: _parseUtc(row['deleted_at']),
      transcript: row['transcript'] as String?,
      transcriptStatus: TranscriptStatus.fromDb(
        row['transcript_status'] as String?,
      ),
    );
  }

  /// `true` when the message has been soft-deleted (server stamps
  /// `deleted_at` and nulls `body`). The UI should render a tombstone.
  bool get isTombstone => deletedAt != null;

  /// `true` when the message has been edited at least once.
  bool get isEdited => editedAt != null;

  /// Per spec §3.4: a user can edit their OWN text message within 15
  /// minutes of creation, and only if it hasn't been deleted.
  bool canEditBy({required String userId, DateTime? at}) {
    if (isTombstone) return false;
    if (kind != MessageKind.text) return false;
    if (senderId != userId) return false;
    final now = (at ?? DateTime.now()).toUtc();
    return now.difference(createdAt).inMinutes < 15;
  }

  /// Per spec §3.4: a user can soft-delete their OWN message (any kind)
  /// at any time, as long as it isn't already a tombstone.
  bool canDeleteBy({required String userId}) =>
      !isTombstone && senderId == userId;
}

DateTime? _parseUtc(Object? raw) {
  if (raw == null) return null;
  return DateTime.parse(raw as String).toUtc();
}
