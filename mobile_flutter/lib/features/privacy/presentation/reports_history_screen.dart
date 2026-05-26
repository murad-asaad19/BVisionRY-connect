import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/i18n/i18n.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/top_bar.dart';

/// `/settings/reports` — history of reports the current user has filed.
///
/// Gallery H5 forward-intent surface: the back end RPC that lists prior
/// `report_target(...)` submissions is not in this release, so we render
/// the EmptyState today. When the server-side endpoint ships, this screen
/// flips to a list (drop a FutureProvider in and pass it to QueryState).
///
/// The screen is reachable from the SAFETY section of `/settings/privacy`
/// and the route is exposed as `Routes.reportsHistory` so deep-links and
/// notification taps can land here.
class ReportsHistoryScreen extends ConsumerWidget {
  const ReportsHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: TopBar(
          title: context.t('settings.reportedByYou.title'),
          back: true,
        ),
      ),
      body: EmptyState(
        icon: LucideIcons.flag,
        title: context.t('settings.reportedByYou.empty.title'),
        body: context.t('settings.reportedByYou.empty.body'),
      ),
    );
  }
}
