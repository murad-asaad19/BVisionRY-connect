import 'package:flutter/material.dart';

import '../../../core/i18n/i18n.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/top_bar.dart';

/// Phase-5 placeholder for the chats tab. Replaced by the real chats list
/// in Phase 7.
class ChatsScreenStub extends StatelessWidget {
  const ChatsScreenStub({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: TopBar(title: context.t('common.tabs.chats')),
      ),
      body: EmptyState(
        icon: Icons.chat_bubble_outline,
        title: context.t('common.tabs.chats'),
        body: 'Coming in Phase 7.',
      ),
    );
  }
}
