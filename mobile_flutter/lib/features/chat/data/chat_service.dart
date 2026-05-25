import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/error_map.dart';
import '../../../core/supabase/supabase_client.dart';
import '../domain/conversation_overview.dart';
import '../domain/message.dart';

/// One row from `list_conversation_unread()` — kept as a typed record so
/// providers can map it into a `Map<String,int>` without re-parsing.
typedef UnreadRow = ({String conversationId, int unreadCount});

/// Test-seam abstraction over the Supabase surface ChatService touches.
/// Concrete adapter binds to the live [SupabaseClient]; unit tests inject
/// a `mocktail`-driven [Mock] implementation.
abstract class ChatGateway {
  Future<Object?> rpc(String name, {Map<String, dynamic>? params});
}

class SupabaseChatGateway implements ChatGateway {
  SupabaseChatGateway(this._client);
  final SupabaseClient _client;

  @override
  Future<Object?> rpc(String name, {Map<String, dynamic>? params}) =>
      _client.rpc(name, params: params);
}

/// Thin wrapper over the chat-related RPCs (spec §3.4 + §17.8).
///
/// All RPC failures normalise through [mapPostgrestError] so the UI layer
/// always receives typed [AppException]s.
class ChatService {
  ChatService(this._gateway);

  final ChatGateway _gateway;

  /// `list_conversation_overview()` — called with NO arguments per spec
  /// §17.8 (uses `auth.uid()` default). Returns the rows the chats list
  /// needs to render in a single hop.
  Future<List<ConversationOverview>> listConversationOverview() async {
    try {
      final raw = await _gateway.rpc('list_conversation_overview');
      return _rows(raw)
          .map(ConversationOverview.fromRow)
          .toList(growable: false);
    } on PostgrestException catch (e) {
      throw mapPostgrestError(e);
    }
  }

  /// `list_conversation_unread()` — returns per-conversation unread
  /// counts. Sum across conversations powers the chats tab badge.
  Future<List<UnreadRow>> listConversationUnread() async {
    try {
      final raw = await _gateway.rpc('list_conversation_unread');
      return _rows(raw)
          .map(
            (r) => (
              conversationId: r['conversation_id'] as String,
              unreadCount: (r['unread_count'] as num).toInt(),
            ),
          )
          .toList(growable: false);
    } on PostgrestException catch (e) {
      throw mapPostgrestError(e);
    }
  }

  /// `mark_conversation_read(p_conversation_id)` — stamps a row in
  /// `conversation_reads` (spec §2.13). Called when the user opens a
  /// thread, scrolls to bottom, or the app foregrounds with that thread
  /// already on screen.
  Future<void> markConversationRead(String conversationId) async {
    try {
      await _gateway.rpc(
        'mark_conversation_read',
        params: <String, dynamic>{'p_conversation_id': conversationId},
      );
    } on PostgrestException catch (e) {
      throw mapPostgrestError(e);
    }
  }

  /// `mute_conversation(p_conversation_id)` — inserts/updates a row in
  /// `conversation_mutes` (spec §2.14). Suppresses push notifications for
  /// the muting user; the other side is unaffected.
  Future<void> muteConversation(String conversationId) async {
    try {
      await _gateway.rpc(
        'mute_conversation',
        params: <String, dynamic>{'p_conversation_id': conversationId},
      );
    } on PostgrestException catch (e) {
      throw mapPostgrestError(e);
    }
  }

  /// `unmute_conversation(p_conversation_id)` — removes the mute row.
  Future<void> unmuteConversation(String conversationId) async {
    try {
      await _gateway.rpc(
        'unmute_conversation',
        params: <String, dynamic>{'p_conversation_id': conversationId},
      );
    } on PostgrestException catch (e) {
      throw mapPostgrestError(e);
    }
  }

  /// `edit_message(p_id, p_body)` — server enforces sender-only + text-
  /// only + 15-minute window. Returns the updated row.
  Future<Message> editMessage(String id, String body) async {
    try {
      final raw = await _gateway.rpc(
        'edit_message',
        params: <String, dynamic>{'p_id': id, 'p_body': body},
      );
      return Message.fromRow(_singleRow(raw));
    } on PostgrestException catch (e) {
      throw mapPostgrestError(e);
    }
  }

  /// `delete_message(p_id)` — server stamps `deleted_at`, nulls `body`,
  /// and clears `media_path`. Returns the tombstoned row.
  Future<Message> deleteMessage(String id) async {
    try {
      final raw = await _gateway.rpc(
        'delete_message',
        params: <String, dynamic>{'p_id': id},
      );
      return Message.fromRow(_singleRow(raw));
    } on PostgrestException catch (e) {
      throw mapPostgrestError(e);
    }
  }

  /// Coerces a SETOF / table-return into `List<Map<String,dynamic>>`.
  List<Map<String, dynamic>> _rows(Object? raw) {
    if (raw == null) return const <Map<String, dynamic>>[];
    if (raw is List) {
      return raw
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(growable: false);
    }
    return <Map<String, dynamic>>[Map<String, dynamic>.from(raw as Map)];
  }

  /// Coerces a single-row RPC response (sometimes a one-element list,
  /// sometimes a bare map) into a typed `Map<String, dynamic>`.
  Map<String, dynamic> _singleRow(Object? raw) {
    if (raw is List && raw.isNotEmpty) {
      return Map<String, dynamic>.from(raw.first as Map);
    }
    return Map<String, dynamic>.from(raw as Map);
  }
}

/// Provider that exposes the configured [ChatService] singleton.
final Provider<ChatService> chatServiceProvider = Provider<ChatService>((ref) {
  return ChatService(SupabaseChatGateway(ref.watch(supabaseClientProvider)));
});
