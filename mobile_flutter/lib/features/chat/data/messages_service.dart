import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_map.dart';
import '../../../core/supabase/supabase_client.dart';
import '../domain/message.dart';

/// Test-seam abstraction over the Supabase surface MessagesService touches.
///
/// Direct table reads/writes go through this gateway so unit tests can
/// drive the service without needing to mock Supabase's fluent
/// `from(...).select().eq(...)` chain.
abstract class MessagesGateway {
  /// SELECT messages WHERE conversation_id = :id (and optional cursor),
  /// ORDER BY created_at DESC, LIMIT :limit.
  Future<List<Map<String, dynamic>>> selectMessages(
    String conversationId, {
    DateTime? beforeCursor,
    required int limit,
  });

  /// INSERT a text message and RETURN the inserted row.
  Future<Map<String, dynamic>> insertTextMessage({
    required String conversationId,
    required String senderId,
    required String body,
  });

  /// SELECT a single message by id (used by Realtime fallback / refetch).
  Future<Map<String, dynamic>?> selectMessage(String id);

  /// Current authenticated user id (mirrors `_client.auth.currentUser?.id`).
  String? get currentUserId;
}

class SupabaseMessagesGateway implements MessagesGateway {
  SupabaseMessagesGateway(this._client);
  final SupabaseClient _client;

  @override
  String? get currentUserId => _client.auth.currentUser?.id;

  @override
  Future<List<Map<String, dynamic>>> selectMessages(
    String conversationId, {
    DateTime? beforeCursor,
    required int limit,
  }) async {
    var query = _client
        .from('messages')
        .select()
        .eq('conversation_id', conversationId);
    if (beforeCursor != null) {
      query = query.lt('created_at', beforeCursor.toUtc().toIso8601String());
    }
    final rows = await query.order('created_at', ascending: false).limit(limit);
    return (rows as List<dynamic>)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList(growable: false);
  }

  @override
  Future<Map<String, dynamic>> insertTextMessage({
    required String conversationId,
    required String senderId,
    required String body,
  }) async {
    final row = await _client
        .from('messages')
        .insert(<String, dynamic>{
          'conversation_id': conversationId,
          'sender_id': senderId,
          'body': body,
          'kind': 'text',
        })
        .select()
        .single();
    return Map<String, dynamic>.from(row as Map);
  }

  @override
  Future<Map<String, dynamic>?> selectMessage(String id) async {
    final row = await _client
        .from('messages')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (row == null) return null;
    return Map<String, dynamic>.from(row as Map);
  }
}

/// Direct-table CRUD for messages (spec §2.6). RLS limits SELECTs and
/// INSERTs to participants; non-text inserts are server-side only via
/// `send_image_message` / `send_voice_message` RPCs in [MediaService].
///
/// All Postgrest errors normalise through [mapPostgrestError] so the UI
/// always receives typed [AppException]s.
class MessagesService {
  MessagesService(this._gateway);

  final MessagesGateway _gateway;

  static const int defaultPageSize = 30;

  /// Lists messages newest-first, paginated by `created_at` cursor.
  /// When [beforeCursor] is null, returns the most recent [limit] rows.
  Future<List<Message>> listMessages(
    String conversationId, {
    DateTime? beforeCursor,
    int limit = defaultPageSize,
  }) async {
    try {
      final rows = await _gateway.selectMessages(
        conversationId,
        beforeCursor: beforeCursor,
        limit: limit,
      );
      return rows.map(Message.fromRow).toList(growable: false);
    } on PostgrestException catch (e) {
      throw mapPostgrestError(e);
    }
  }

  /// Direct INSERT of a text message (RLS allows kind=text only). The
  /// SQL trigger updates `conversations.last_message_at`. Throws
  /// [UnauthenticatedException] when the session is gone.
  Future<Message> sendTextMessage({
    required String conversationId,
    required String body,
  }) async {
    final senderId = _gateway.currentUserId;
    if (senderId == null) throw UnauthenticatedException();
    try {
      final row = await _gateway.insertTextMessage(
        conversationId: conversationId,
        senderId: senderId,
        body: body,
      );
      return Message.fromRow(row);
    } on PostgrestException catch (e) {
      throw mapPostgrestError(e);
    }
  }

  /// Single-row fetch by id — used by the Realtime stream when an
  /// UPDATE arrives with mismatched cache (forward-compat with replica
  /// identity changes).
  Future<Message?> fetchMessage(String id) async {
    try {
      final row = await _gateway.selectMessage(id);
      if (row == null) return null;
      return Message.fromRow(row);
    } on PostgrestException catch (e) {
      throw mapPostgrestError(e);
    }
  }
}

/// Provider that exposes the configured [MessagesService] singleton.
final Provider<MessagesService> messagesServiceProvider =
    Provider<MessagesService>((ref) {
      return MessagesService(
        SupabaseMessagesGateway(ref.watch(supabaseClientProvider)),
      );
    });
