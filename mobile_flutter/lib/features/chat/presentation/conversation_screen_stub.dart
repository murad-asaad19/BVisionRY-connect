import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/widgets.dart';
import '../providers/active_conversation_provider.dart';

/// Phase-7 Chunk-A placeholder for `/chats/:id`. Chunk B replaces this
/// with the real ConversationScreen (bubbles, recorder sheet, image
/// viewer, message input, typing indicator).
///
/// Sets [activeConversationProvider] so the Phase-12 push handler can
/// already suppress in-thread toasts during integration testing.
class ConversationScreenStub extends ConsumerStatefulWidget {
  const ConversationScreenStub({super.key, required this.conversationId});

  final String conversationId;

  @override
  ConsumerState<ConversationScreenStub> createState() =>
      _ConversationScreenStubState();
}

class _ConversationScreenStubState
    extends ConsumerState<ConversationScreenStub> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(activeConversationProvider.notifier).state =
          widget.conversationId;
    });
  }

  @override
  void dispose() {
    Future.microtask(() {
      ref.read(activeConversationProvider.notifier).state = null;
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: TopBar(
          title: 'Chat ${widget.conversationId}',
          back: Navigator.of(context).canPop(),
        ),
      ),
      body: const EmptyState(
        icon: Icons.chat_bubble_outline,
        title: 'Conversation',
        body: 'Coming in Phase 7 Chunk B.',
      ),
    );
  }
}
