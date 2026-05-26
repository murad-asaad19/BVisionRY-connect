import 'package:freezed_annotation/freezed_annotation.dart';

import 'message_kind.dart';

part 'conversation_overview.freezed.dart';

/// One row from `list_conversation_overview()` (spec §3.4 / §17.8).
///
/// The RPC joins `conversations` against `messages` and `profiles` to
/// produce everything the chats-list row needs in a single hop — peer
/// identity, the last message preview, unread count, and the mute flag.
///
/// `last_message_*` fields are nullable because a brand-new conversation
/// (created by `accept_intro`) starts with no messages.
@freezed
class ConversationOverview with _$ConversationOverview {
  const factory ConversationOverview({
    required String conversationId,
    required String peerId,
    required String peerName,
    required String peerHandle,
    required MessageKind? lastMessageKind,
    required DateTime? lastMessageAt,
    required int unreadCount,
    required bool isMuted,
    String? peerPhotoUrl,
    String? lastMessageBody,
    int? lastMessageDurationMs,
  }) = _ConversationOverview;

  factory ConversationOverview.fromRow(Map<String, dynamic> row) =>
      ConversationOverview(
        conversationId: row['conversation_id'] as String,
        peerId: row['peer_id'] as String,
        peerName: row['peer_name'] as String,
        peerHandle: row['peer_handle'] as String,
        peerPhotoUrl: row['peer_photo_url'] as String?,
        lastMessageBody: row['last_message_body'] as String?,
        lastMessageKind: row['last_message_kind'] != null
            ? MessageKind.fromDb(row['last_message_kind'] as String?)
            : null,
        lastMessageAt: row['last_message_at'] != null
            ? DateTime.parse(row['last_message_at'] as String).toUtc()
            : null,
        unreadCount: (row['unread_count'] as num?)?.toInt() ?? 0,
        isMuted: (row['is_muted'] as bool?) ?? false,
        lastMessageDurationMs:
            (row['last_message_duration_ms'] as num?)?.toInt(),
      );
}
