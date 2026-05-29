import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/supabase/supabase_client.dart';
import '../data/messages_service.dart';
import '../domain/message.dart';
import '../domain/message_kind.dart';

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
///
/// AutoDispose so the channel is torn down when the listening
/// [MessagesNotifier] (also autoDispose) is released — without it, every
/// conversation visited would keep its Supabase Realtime subscription
/// open for the rest of the session.
final AutoDisposeStreamProviderFamily<MessageRealtimeEvent, String>
    messagesRealtimeProvider = StreamProvider.autoDispose
        .family<MessageRealtimeEvent, String>((ref, convId) {
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
  bool _loadingMore = false;

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
        // Image/voice optimistic bubbles share the server row's id (the
        // client UUID is embedded in the storage path and reused as the
        // row id), so a plain id match reconciles them in place.
        final byId = current.indexWhere((m) => m.id == msg.id);
        if (byId != -1) {
          state = AsyncData<List<Message>>(<Message>[
            for (var i = 0; i < current.length; i++)
              if (i == byId) msg else current[i],
          ]);
          return;
        }
        // Text optimistic bubbles carry a client UUID the server never sees,
        // so the Realtime echo arrives with a fresh server id. Reconcile by
        // replacing the matching `sending` placeholder (own message, same
        // body) instead of appending a duplicate.
        final pendingIdx = _matchPendingText(current, msg);
        if (pendingIdx != -1) {
          state = AsyncData<List<Message>>(<Message>[
            for (var i = 0; i < current.length; i++)
              if (i == pendingIdx) msg else current[i],
          ]);
          return;
        }
        state = AsyncData<List<Message>>(<Message>[msg, ...current]);
      case MessageUpdate(:final msg):
        state = AsyncData<List<Message>>(<Message>[
          for (final m in current)
            if (m.id == msg.id) msg else m,
        ]);
      case MessageDelete(:final id):
        state = AsyncData<List<Message>>(
          current.where((m) => m.id != id).toList(growable: false),
        );
    }
  }

  /// Finds the index of a `sending` optimistic TEXT placeholder that the
  /// incoming server row [msg] confirms — matched by sender + body so the
  /// Realtime echo (server id) replaces the right pending bubble. Returns
  /// -1 when none matches.
  int _matchPendingText(List<Message> current, Message msg) {
    if (msg.kind != MessageKind.text) return -1;
    return current.indexWhere(
      (m) =>
          m.isOptimistic &&
          m.kind == MessageKind.text &&
          m.senderId == msg.senderId &&
          m.body == msg.body,
    );
  }

  /// Fetches the next page (older messages). No-op when already at the
  /// end of history or while a previous loadMore is still in flight — the
  /// caller (scroll-listener in ConversationScreen) fires this on every
  /// scroll tick past the threshold, and without the gate a single fling
  /// would spawn N parallel fetches that all share the same cursor and
  /// concatenate the same page N times into state.
  Future<void> loadMore() async {
    if (!_hasMore || _loadingMore) return;
    final current = state.valueOrNull ?? const <Message>[];
    if (current.isEmpty) return;
    _loadingMore = true;
    try {
      final cursor = current.last.createdAt;
      final svc = ref.read(messagesServiceProvider);
      final older = await svc.listMessages(
        arg,
        beforeCursor: cursor,
        limit: _pageSize,
      );
      _hasMore = older.length == _pageSize;
      state = AsyncData<List<Message>>(<Message>[...current, ...older]);
    } finally {
      _loadingMore = false;
    }
  }

  /// Prepends an optimistic placeholder bubble so the user sees their
  /// message the instant they hit send.
  void _prepend(Message optimistic) {
    final current = state.valueOrNull ?? const <Message>[];
    state = AsyncData<List<Message>>(<Message>[optimistic, ...current]);
  }

  /// Replaces the optimistic placeholder identified by [clientId] with the
  /// confirmed [server] row. If the Realtime echo already reconciled it
  /// (image/voice share the id), the server row is simply updated in place.
  void _reconcile({required String clientId, required Message server}) {
    final current = state.valueOrNull ?? const <Message>[];
    final hasServer = current.any((m) => m.id == server.id && !m.isOptimistic);
    state = AsyncData<List<Message>>(<Message>[
      for (final m in current)
        if (m.id == clientId)
          // Drop the placeholder if the confirmed row is already present
          // (Realtime won the race), otherwise swap placeholder → server.
          if (hasServer && clientId != server.id)
            ...const <Message>[]
          else
            server
        else
          m,
    ]);
  }

  /// Flags the optimistic placeholder [clientId] as failed so the bubble can
  /// render an inline retry affordance instead of a transient toast.
  void _markFailed(String clientId) {
    final current = state.valueOrNull ?? const <Message>[];
    state = AsyncData<List<Message>>(<Message>[
      for (final m in current)
        if (m.id == clientId)
          m.copyWith(sendStatus: MessageSendStatus.failed)
        else
          m,
    ]);
  }

  /// Removes the optimistic placeholder [clientId] outright — used when a
  /// failed bubble is dismissed.
  void discardPending(String clientId) {
    final current = state.valueOrNull ?? const <Message>[];
    state = AsyncData<List<Message>>(
      current.where((m) => m.id != clientId).toList(growable: false),
    );
  }

  /// Optimistically sends a TEXT message: prepends a `sending` bubble keyed
  /// by a fresh client UUID, then inserts via the service. On success the
  /// placeholder reconciles to the server row (by RPC return or Realtime
  /// echo, whichever arrives first); on failure it flips to `failed`.
  Future<void> sendText(String body) async {
    final senderId = ref.read(supabaseClientProvider).auth.currentUser?.id;
    final clientId = const Uuid().v4();
    _prepend(
      Message.optimisticText(
        clientId: clientId,
        conversationId: arg,
        senderId: senderId ?? '',
        body: body,
        createdAt: DateTime.now().toUtc(),
      ),
    );
    await _runSend(
      clientId: clientId,
      send: () async {
        final svc = ref.read(messagesServiceProvider);
        return svc.sendTextMessage(conversationId: arg, body: body);
      },
    );
  }

  /// Retries a previously [failed] text bubble in place (keeps its slot).
  Future<void> retryText({required String clientId, required String body}) {
    _markSending(clientId);
    return _runSend(
      clientId: clientId,
      send: () async {
        final svc = ref.read(messagesServiceProvider);
        return svc.sendTextMessage(conversationId: arg, body: body);
      },
    );
  }

  /// Optimistically sends an IMAGE/VOICE message. The caller supplies the
  /// client UUID ([messageId], also the storage-path segment so the server
  /// row reuses it), the local placeholder, and a [send] closure that does
  /// the upload + RPC and returns the confirmed server [Message].
  Future<void> sendMedia({
    required String messageId,
    required Message optimistic,
    required Future<Message> Function() send,
  }) async {
    _prepend(optimistic);
    await _runSend(clientId: messageId, send: send);
  }

  /// Retries a failed media bubble in place.
  Future<void> retryMedia({
    required String messageId,
    required Future<Message> Function() send,
  }) {
    _markSending(messageId);
    return _runSend(clientId: messageId, send: send);
  }

  void _markSending(String clientId) {
    final current = state.valueOrNull ?? const <Message>[];
    state = AsyncData<List<Message>>(<Message>[
      for (final m in current)
        if (m.id == clientId)
          m.copyWith(sendStatus: MessageSendStatus.sending)
        else
          m,
    ]);
  }

  Future<void> _runSend({
    required String clientId,
    required Future<Message> Function() send,
  }) async {
    try {
      final server = await send();
      _reconcile(clientId: clientId, server: server);
    } catch (_) {
      _markFailed(clientId);
      rethrow;
    }
  }

  /// Replaces a row in-place — used by message-actions edits/deletes
  /// before the Realtime UPDATE confirms.
  void mergeUpdated(Message msg) => _apply(MessageRealtimeEvent.update(msg));
}

final AutoDisposeAsyncNotifierProviderFamily<MessagesNotifier, List<Message>,
        String> messagesProvider =
    AsyncNotifierProvider.autoDispose
        .family<MessagesNotifier, List<Message>, String>(MessagesNotifier.new);
