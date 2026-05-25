import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_client.dart';
import '../data/messages_service.dart';
import '../domain/message.dart';

/// Realtime event delivered by [messagesRealtimeProvider] for a single
/// conversation. Sealed so [MessagesNotifier._apply] can exhaustively
/// pattern-match on the variants.
@immutable
sealed class MessageRealtimeEvent {
  const MessageRealtimeEvent();
  const factory MessageRealtimeEvent.insert(Message msg) = MessageInsert;
  const factory MessageRealtimeEvent.update(Message msg) = MessageUpdate;
  const factory MessageRealtimeEvent.delete(String id) = MessageDelete;
}

class MessageInsert extends MessageRealtimeEvent {
  const MessageInsert(this.msg);
  final Message msg;
}

class MessageUpdate extends MessageRealtimeEvent {
  const MessageUpdate(this.msg);
  final Message msg;
}

class MessageDelete extends MessageRealtimeEvent {
  const MessageDelete(this.id);
  final String id;
}

/// Per-conversation Realtime stream that emits [MessageRealtimeEvent]
/// values for INSERT / UPDATE / DELETE on `public.messages` filtered to
/// `conversation_id = :convId`.
///
/// Production: opens a Supabase Realtime channel. Tests override this
/// provider with a controlled stream.
final StreamProviderFamily<MessageRealtimeEvent, String> messagesRealtimeProvider =
    StreamProvider.family<MessageRealtimeEvent, String>((ref, convId) {
      final client = ref.watch(supabaseClientProvider);
      final controller = StreamController<MessageRealtimeEvent>();
      final ch = client.channel('messages:conv:$convId');
      final filter = PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'conversation_id',
        value: convId,
      );
      ch
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'messages',
            filter: filter,
            callback: (p) => controller.add(
              MessageRealtimeEvent.insert(Message.fromRow(p.newRecord)),
            ),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'messages',
            filter: filter,
            callback: (p) => controller.add(
              MessageRealtimeEvent.update(Message.fromRow(p.newRecord)),
            ),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.delete,
            schema: 'public',
            table: 'messages',
            filter: filter,
            callback: (p) => controller.add(
              MessageRealtimeEvent.delete(p.oldRecord['id'] as String),
            ),
          )
          .subscribe();
      ref.onDispose(() async {
        await client.removeChannel(ch);
        await controller.close();
      });
      return controller.stream;
    });

/// Paginated, Realtime-driven list of [Message]s for a single
/// conversation.
///
/// On `build(convId)`:
/// - Fetch first 30 newest rows via [MessagesService.listMessages]
/// - Subscribe to [messagesRealtimeProvider] and merge events into state
///
/// Insert prepends (newest first). Update replaces in place. Delete
/// removes by id. [loadMore] uses the oldest row's `created_at` as the
/// cursor.
///
/// AutoDispose so leaving a thread releases its Realtime channel.
class MessagesNotifier
    extends AutoDisposeFamilyAsyncNotifier<List<Message>, String> {
  static const int _pageSize = 30;
  bool _hasMore = true;

  bool get hasMore => _hasMore;

  @override
  Future<List<Message>> build(String arg) async {
    ref.listen<AsyncValue<MessageRealtimeEvent>>(
      messagesRealtimeProvider(arg),
      (_, next) {
        next.whenData(_apply);
      },
    );
    final svc = ref.watch(messagesServiceProvider);
    final rows = await svc.listMessages(arg, limit: _pageSize);
    _hasMore = rows.length == _pageSize;
    return rows;
  }

  void _apply(MessageRealtimeEvent event) {
    final current = state.valueOrNull ?? const <Message>[];
    switch (event) {
      case MessageInsert(:final msg):
        if (current.any((m) => m.id == msg.id)) return;
        state = AsyncData<List<Message>>(<Message>[msg, ...current]);
      case MessageUpdate(:final msg):
        state = AsyncData<List<Message>>(<Message>[
          for (final m in current) if (m.id == msg.id) msg else m,
        ]);
      case MessageDelete(:final id):
        state = AsyncData<List<Message>>(
          current.where((m) => m.id != id).toList(growable: false),
        );
    }
  }

  /// Fetches the next page (older messages). No-op when already at the
  /// end of history.
  Future<void> loadMore() async {
    if (!_hasMore) return;
    final current = state.valueOrNull ?? const <Message>[];
    if (current.isEmpty) return;
    final cursor = current.last.createdAt;
    final svc = ref.read(messagesServiceProvider);
    final older = await svc.listMessages(
      arg,
      beforeCursor: cursor,
      limit: _pageSize,
    );
    _hasMore = older.length == _pageSize;
    state = AsyncData<List<Message>>(<Message>[...current, ...older]);
  }

  /// Sends a text message and merges the inserted row into state. The
  /// Realtime channel will also fire INSERT for the same row; [_apply]
  /// dedupes by id.
  Future<Message> sendText(String body) async {
    final svc = ref.read(messagesServiceProvider);
    final result = await svc.sendTextMessage(conversationId: arg, body: body);
    _apply(MessageRealtimeEvent.insert(result));
    return result;
  }

  /// Replaces a row in-place — used by message-actions edits/deletes
  /// before the Realtime UPDATE confirms.
  void mergeUpdated(Message msg) => _apply(MessageRealtimeEvent.update(msg));
}

final AutoDisposeAsyncNotifierProviderFamily<
  MessagesNotifier,
  List<Message>,
  String
>
messagesProvider =
    AsyncNotifierProvider.autoDispose
        .family<MessagesNotifier, List<Message>, String>(MessagesNotifier.new);
