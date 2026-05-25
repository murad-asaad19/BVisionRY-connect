import 'package:flutter/material.dart';

import '../../../core/i18n/i18n.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/top_bar.dart';

/// Phase-5 placeholder for the opportunities tab. Replaced by the real
/// opportunities feed in Phase 9/10.
class OpportunitiesScreenStub extends StatelessWidget {
  const OpportunitiesScreenStub({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: TopBar(title: context.t('common.tabs.opportunities')),
      ),
      body: EmptyState(
        icon: Icons.work_outline,
        title: context.t('common.tabs.opportunities'),
        body: 'Coming in Phase 9.',
      ),
    );
  }
}
