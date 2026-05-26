import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/i18n/i18n.dart';
import '../../../core/routing/routes.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/top_bar.dart';
import '../../discovery/presentation/widgets/daily_matches_section.dart';
import '../../discovery/providers/daily_matches_provider.dart';
import '../../intros/presentation/warm_intro_suggestions_strip.dart';
import '../../push/presentation/push_permission_banner.dart';
import 'widgets/home_skeleton.dart';
import 'widgets/thin_pool_banner.dart';
import 'widgets/todays_matches_header.dart';

/// Home tab. Renders today's daily matches, optionally a thin-pool banner
/// (when fewer than 3 picks were returned), and a search affordance in the
/// top bar. Replaces the Phase 1 stub.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncMatches = ref.watch(dailyMatchesProvider);
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: TopBar(
          title: context.t('home.title'),
          actions: <TopBarAction>[
            TopBarAction(
              key: const Key('home.openSettings'),
              icon: LucideIcons.settings,
              label: context.t('settings.title'),
              onPressed: () => context.push(Routes.settings),
            ),
            TopBarAction(
              icon: Icons.search,
              label: context.t('discovery.openSearch'),
              onPressed: () => context.push(Routes.search),
            ),
          ],
        ),
      ),
      body: asyncMatches.when(
        loading: HomeSkeleton.new,
        error: (e, _) => Center(child: Text(e.toString())),
        data: (matches) {
          if (matches.isEmpty) {
            return EmptyState(
              icon: Icons.calendar_today_outlined,
              title: context.t('home.matchesEmptyTitle'),
              body: context.t('home.matchesEmptyBody'),
              action: EmptyStateAction(
                label: context.t('discovery.openSearch'),
                onPressed: () => context.push(Routes.search),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(dailyMatchesProvider.notifier).refresh(),
            child: ListView(
              children: <Widget>[
                const PushPermissionBannerWidget(),
                if (matches.length < 3) ThinPoolBanner(count: matches.length),
                TodaysMatchesHeader(
                  count: matches.length,
                  date: matches.first.forDateLocal,
                ),
                DailyMatchesSection(matches: matches),
                const WarmIntroSuggestionsStrip(),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }
}
