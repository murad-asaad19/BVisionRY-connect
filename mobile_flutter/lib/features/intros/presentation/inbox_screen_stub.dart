import 'package:flutter/material.dart';

import '../../../core/i18n/i18n.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/top_bar.dart';

/// Phase-5 placeholder for the intros inbox tab. Replaced by the real
/// [InboxScreen] in Phase 6.
class InboxScreenStub extends StatelessWidget {
  const InboxScreenStub({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: TopBar(title: context.t('common.tabs.inbox')),
      ),
      body: EmptyState(
        icon: Icons.inbox_outlined,
        title: context.t('common.tabs.inbox'),
        body: 'Coming in Phase 6.',
      ),
    );
  }
}
