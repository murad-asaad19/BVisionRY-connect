import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/i18n.dart';
import '../../../core/routing/routes.dart';
import '../../../core/widgets/avatar.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/query_state.dart';
import '../../../core/widgets/top_bar.dart';
import '../../auth/providers/profile_provider.dart';
import '../../discovery/domain/daily_match.dart';
import '../../discovery/presentation/widgets/browse_all_section.dart';
import '../../discovery/presentation/widgets/daily_matches_section.dart';
import '../../discovery/providers/daily_matches_provider.dart';
import '../../intros/presentation/warm_intro_suggestions_strip.dart';
import '../../profile/presentation/goal_refresh_card.dart';
import '../../profile/providers/own_profile_controller.dart';
import '../../push/presentation/push_permission_banner.dart';
import 'widgets/email_verify_banner.dart';
import 'widgets/first_action_nudge.dart';
import 'widgets/home_skeleton.dart';
import 'widgets/thin_pool_banner.dart';
import 'widgets/todays_matches_header.dart';

/// Home tab. Renders today's daily matches, optionally a thin-pool banner
/// (when fewer than 3 picks were returned), and surfaces the viewer's
/// avatar (taps → /profile) alongside the search affordance in the top
/// bar.
///
/// The push-permission banner is lifted above the [QueryState] so it renders
/// in every state (loading / empty / error) — it self-collapses when not
/// applicable, so new users with an empty match list still get the nudge.
/// Pull-to-refresh wraps the whole query so it fires on empty + error too.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncMatches = ref.watch(dailyMatchesProvider);
    final viewer = ref.watch(profileProvider).asData?.value;
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: TopBar(
          title: context.t('home.title'),
          leading: viewer == null
              ? null
              : Semantics(
                  label: context.t('profile.openOwn'),
                  button: true,
                  child: InkResponse(
                    key: const Key('home.openProfile'),
                    // Profile is a bottom-nav tab now; switch to its branch
                    // (go, not push) so we don't stack a second profile route
                    // over the home tab.
                    onTap: () => context.go(Routes.profile),
                    radius: 22,
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: Avatar(
                        name: viewer.name ?? viewer.handle ?? '',
                        photoUrl: viewer.photoUrl,
                        size: 32,
                        tone: AvatarTone.muted,
                      ),
                    ),
                  ),
                ),
          actions: <TopBarAction>[
            TopBarAction(
              icon: Icons.search,
              label: context.t('discovery.openSearch'),
              onPressed: () => context.push(Routes.search),
            ),
          ],
        ),
      ),
      body: Column(
        children: <Widget>[
          // Lifted above the query so they show in loading / empty / error
          // states too — each self-collapses when not applicable.
          const EmailVerifyBanner(),
          const PushPermissionBannerWidget(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () =>
                  ref.read(dailyMatchesProvider.notifier).refresh(),
              child: QueryState<List<DailyMatch>>(
                value: asyncMatches,
                loading: const HomeSkeleton(),
                onRetry: () => ref.invalidate(dailyMatchesProvider),
                data: (matches) {
                  if (matches.isEmpty) {
                    return _ScrollableFill(
                      child: EmptyState(
                        icon: Icons.calendar_today_outlined,
                        title: context.t('home.matchesEmptyTitle'),
                        body: context.t('home.matchesEmptyBody'),
                        action: EmptyStateAction(
                          label: context.t('discovery.openSearch'),
                          onPressed: () => context.push(Routes.search),
                        ),
                      ),
                    );
                  }
                  return ListView(
                    children: <Widget>[
                      if (matches.length < 3)
                        ThinPoolBanner(count: matches.length),
                      // I1: goal-staleness nudge above the picks, quoting the
                      // user's goal (gallery I1, lines 2293-2299). Reuses the
                      // profile GoalRefreshCard widget unchanged.
                      if (viewer != null && viewer.isGoalStale)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                          child: GoalRefreshCard(
                            profile: viewer,
                            onUpdate: () => context.push(Routes.profileEdit),
                            onDismiss: () => ref
                                .read(ownProfileControllerProvider.notifier)
                                .confirmGoalFreshness(),
                          ),
                        ),
                      TodaysMatchesHeader(
                        count: matches.length,
                        date: matches.first.forDateLocal,
                      ),
                      DailyMatchesSection(matches: matches),
                      // B5: first-run nudge prompting the first intro (with a
                      // "verify email first" qualifier when unverified).
                      const FirstActionNudge(),
                      // C1: BROWSE ALL hybrid feed below the daily picks.
                      const BrowseAllSection(),
                      const WarmIntroSuggestionsStrip(),
                      const SizedBox(height: 16),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Makes a non-scrolling child (e.g. [EmptyState]) fill the viewport and
/// scroll, so a surrounding [RefreshIndicator] can fire pull-to-refresh on
/// the empty state. Mirrors the always-scrollable treatment [QueryState]
/// applies to its default error UI.
class _ScrollableFill extends StatelessWidget {
  const _ScrollableFill({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(child: child),
          ),
        );
      },
    );
  }
}
