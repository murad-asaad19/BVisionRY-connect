import 'package:flutter/material.dart';

import '../../../core/i18n/i18n.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/top_bar.dart';

/// Phase-5 placeholder for the connections tab. Replaced by the real
/// network screen in Phase 13 (if not already populated earlier).
class NetworkScreenStub extends StatelessWidget {
  const NetworkScreenStub({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: TopBar(title: context.t('common.tabs.network')),
      ),
      body: EmptyState(
        icon: Icons.people_outline,
        title: context.t('common.tabs.network'),
        body: 'Coming in a later phase.',
      ),
    );
  }
}
