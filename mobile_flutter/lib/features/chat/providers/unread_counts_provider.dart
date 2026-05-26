import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/chat_service.dart';

/// Per-conversation unread counts keyed by conversation id.
///
/// Backed by `list_conversation_unread()` (spec §3.4). Refreshed:
/// - on `ref.invalidate(...)` from the conversation overview Realtime
///   stream (Task 15)
/// - on app foreground (Phase 12 lifecycle listener)
/// - after mark-as-read calls.
///
/// The chats-tab badge consumes `.values.fold(0, (a,b) => a + b)`.
final FutureProvider<Map<String, int>> unreadCountsProvider =
    FutureProvider<Map<String, int>>((ref) async {
  final svc = ref.watch(chatServiceProvider);
  final rows = await svc.listConversationUnread();
  return <String, int>{
    for (final r in rows) r.conversationId: r.unreadCount,
  };
});
