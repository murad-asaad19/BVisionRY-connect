import 'dart:typed_data';

import 'package:freezed_annotation/freezed_annotation.dart';

import 'message_kind.dart';
import 'transcript_status.dart';

part 'message.freezed.dart';

/// Lifecycle of a locally-originated (optimistic) message bubble.
///
/// A bubble is [sending] the instant the user hits send (before the server
/// row exists), flips to [sent] once the Realtime INSERT / RPC result
/// reconciles it, and to [failed] if the round-trip throws — at which point
/// the bubble exposes a retry affordance. Server-sourced rows carry a null
/// status (they are, by definition, already confirmed).
enum MessageSendStatus { sending, sent, failed }

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
    // --- Transient, client-only optimistic-send fields ---
    // Never populated by [Message.fromRow]; carried only by locally-created
    // optimistic bubbles so they can render before the server row exists and
    // reconcile against it afterwards.
    /// Non-null while the bubble is a local optimistic placeholder.
    MessageSendStatus? sendStatus,

    /// Locally-picked image bytes shown under an upload overlay until the
    /// real (signed-URL) image is available. Optimistic image bubbles only.
    @Default(null) Uint8List? localImageBytes,
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

  /// `true` while this bubble is an unconfirmed local optimistic placeholder
  /// (mid-flight to the server).
  bool get isSending => sendStatus == MessageSendStatus.sending;

  /// `true` when the optimistic send failed and the bubble should offer a
  /// retry affordance.
  bool get isFailed => sendStatus == MessageSendStatus.failed;

  /// `true` for any locally-originated optimistic bubble (sending or failed)
  /// that has not yet been replaced by its confirmed server row.
  bool get isOptimistic =>
      sendStatus != null && sendStatus != MessageSendStatus.sent;

  /// Builds an optimistic TEXT bubble keyed by a client-generated [clientId]
  /// (the server assigns the real id, so this is reconciled by replacement).
  factory Message.optimisticText({
    required String clientId,
    required String conversationId,
    required String senderId,
    required String body,
    required DateTime createdAt,
  }) =>
      Message(
        id: clientId,
        conversationId: conversationId,
        senderId: senderId,
        kind: MessageKind.text,
        createdAt: createdAt,
        body: body,
        sendStatus: MessageSendStatus.sending,
      );

  /// Builds an optimistic IMAGE bubble. [messageId] is the client UUID that
  /// also forms the storage path, so the server row reuses the SAME id and
  /// reconciliation is a simple id match.
  factory Message.optimisticImage({
    required String messageId,
    required String conversationId,
    required String senderId,
    required DateTime createdAt,
    required Uint8List localBytes,
  }) =>
      Message(
        id: messageId,
        conversationId: conversationId,
        senderId: senderId,
        kind: MessageKind.image,
        createdAt: createdAt,
        localImageBytes: localBytes,
        sendStatus: MessageSendStatus.sending,
      );

  /// Builds an optimistic VOICE bubble. As with images the [messageId] is
  /// the client UUID embedded in the storage path, so the server row reuses
  /// it and reconciliation is a plain id match.
  factory Message.optimisticVoice({
    required String messageId,
    required String conversationId,
    required String senderId,
    required DateTime createdAt,
    required int durationMs,
  }) =>
      Message(
        id: messageId,
        conversationId: conversationId,
        senderId: senderId,
        kind: MessageKind.voice,
        createdAt: createdAt,
        mediaDurationMs: durationMs,
        sendStatus: MessageSendStatus.sending,
      );
}

DateTime? _parseUtc(Object? raw) {
  if (raw == null) return null;
  return DateTime.parse(raw as String).toUtc();
}
