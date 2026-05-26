import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_client.dart';
import '../data/chat_service.dart';
import '../domain/conversation_overview.dart';
import 'unread_counts_provider.dart';

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

/// Conversation list rows powering the Chats tab.
///
/// Backed by `list_conversation_overview()` (RPC, NO args — see spec
/// §17.8). On every emission of [messageStreamProvider] this provider
/// invalidates itself AND `unreadCountsProvider`, so a single channel
/// drives the entire chats-tab data layer.
final FutureProvider<List<ConversationOverview>> conversationOverviewProvider =
    FutureProvider<List<ConversationOverview>>((ref) async {
  ref.listen(messageStreamProvider, (_, __) {
    ref.invalidate(unreadCountsProvider);
    ref.invalidateSelf();
  });
  return ref.watch(chatServiceProvider).listConversationOverview();
});
