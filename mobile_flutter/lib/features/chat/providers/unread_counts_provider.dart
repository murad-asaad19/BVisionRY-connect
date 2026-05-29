import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/chat_service.dart';
import 'conversation_overview_provider.dart';

/// Per-conversation unread counts keyed by conversation id.
///
/// Backed by `list_conversation_unread()` (spec §3.4). Refreshed:
/// - LIVE on every `messages` Realtime change via [messageStreamProvider]
///   (self-invalidate below). This is what keeps the bottom-nav Inbox badge
///   current on ANY tab — [AppShell] watches this provider unconditionally, so
///   the `messages:global` channel stays subscribed for the shell's lifetime.
///   (Previously the only Realtime refresher lived inside
///   `conversationOverviewProvider`, so the badge went stale unless the Chats
///   list happened to be open.)
/// - on app foreground (Phase 12 lifecycle listener)
/// - after mark-as-read calls.
///
/// The Inbox-tab badge consumes `.values.fold(0, (a,b) => a + b)`.
final FutureProvider<Map<String, int>> unreadCountsProvider =
    FutureProvider<Map<String, int>>((ref) async {
  ref.listen(messageStreamProvider, (_, __) => ref.invalidateSelf());
  final svc = ref.watch(chatServiceProvider);
  final rows = await svc.listConversationUnread();
  return <String, int>{
    for (final r in rows) r.conversationId: r.unreadCount,
  };
});
