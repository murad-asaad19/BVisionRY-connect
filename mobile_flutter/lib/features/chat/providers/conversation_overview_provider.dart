import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_client.dart';
import '../data/chat_service.dart';
import '../domain/conversation_overview.dart';

/// Global stream that fires whenever ANY row in `public.messages` changes
/// (INSERT / UPDATE / DELETE). Used to invalidate the chats list +
/// unread counts so cross-conversation activity refreshes the badge and
/// preview rows without manual pull-to-refresh.
///
/// Production: opens a Realtime channel on the `messages` table with no
/// filter. Tests override this provider with a controlled `Stream<void>`.
final StreamProvider<void> messageStreamProvider = StreamProvider<void>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final controller = StreamController<void>();
  final ch = client.channel('messages:global');
  ch
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'messages',
        callback: (_) => controller.add(null),
      )
      .subscribe();
  ref.onDispose(() async {
    await client.removeChannel(ch);
    await controller.close();
  });
  return controller.stream;
});

/// Conversation list rows powering the Inbox → Chats segment.
///
/// Backed by `list_conversation_overview()` (RPC, NO args — see spec
/// §17.8). Self-invalidates on every emission of [messageStreamProvider] so
/// the chats list refreshes live while it's open. (The bottom-nav unread
/// badge no longer depends on this provider being alive — `unreadCountsProvider`
/// now carries its own [messageStreamProvider] listener.)
final FutureProvider<List<ConversationOverview>> conversationOverviewProvider =
    FutureProvider<List<ConversationOverview>>((ref) async {
  ref.listen(messageStreamProvider, (_, __) => ref.invalidateSelf());
  return ref.watch(chatServiceProvider).listConversationOverview();
});

/// Resolves the existing 1:1 conversation id with [peerId], or null when the
/// two users have never connected (no conversation row yet).
///
/// Derived from [conversationOverviewProvider] so it rides the same
/// Realtime-backed cache — no extra round-trip — and updates the instant a new
/// conversation appears (e.g. right after an intro is accepted). Discovery,
/// public-profile and opportunity surfaces watch this to choose between a
/// "Send intro" CTA and an "Open chat" CTA: offering to introduce yourself to
/// someone you already chat with makes no sense.
final AutoDisposeProviderFamily<String?, String> conversationIdForPeerProvider =
    Provider.autoDispose.family<String?, String>((ref, String peerId) {
  final List<ConversationOverview>? overviews =
      ref.watch(conversationOverviewProvider).valueOrNull;
  if (overviews == null) return null;
  for (final ConversationOverview o in overviews) {
    if (o.peerId == peerId) return o.conversationId;
  }
  return null;
});
