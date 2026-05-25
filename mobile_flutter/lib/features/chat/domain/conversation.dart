import 'package:freezed_annotation/freezed_annotation.dart';

part 'conversation.freezed.dart';

/// One row from `public.conversations` (spec §2.5).
///
/// Participants are stored in canonical order (`participant_a_id <
/// participant_b_id`) so the unique constraint on `(a, b)` collapses both
/// directions to a single row. [peerIdFor] returns the OTHER participant
/// for a given viewer — used everywhere we need to resolve "who is the
/// other side of this chat".
@freezed
class Conversation with _$Conversation {
  const Conversation._();

  const factory Conversation({
    required String id,
    required String participantAId,
    required String participantBId,
    required DateTime createdAt,
    DateTime? lastMessageAt,
  }) = _Conversation;

  factory Conversation.fromRow(Map<String, dynamic> row) => Conversation(
    id: row['id'] as String,
    participantAId: row['participant_a_id'] as String,
    participantBId: row['participant_b_id'] as String,
    createdAt: DateTime.parse(row['created_at'] as String).toUtc(),
    lastMessageAt: row['last_message_at'] != null
        ? DateTime.parse(row['last_message_at'] as String).toUtc()
        : null,
  );

  /// Returns the other participant's id. Throws [ArgumentError] if
  /// [userId] isn't a participant — that's a programmer error worth
  /// surfacing loudly.
  String peerIdFor(String userId) {
    if (userId == participantAId) return participantBId;
    if (userId == participantBId) return participantAId;
    throw ArgumentError('user $userId is not a participant of $id');
  }
}
