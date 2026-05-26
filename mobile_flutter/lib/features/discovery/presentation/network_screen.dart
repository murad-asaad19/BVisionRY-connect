import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/i18n/i18n.dart';
import '../../../core/routing/routes.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/top_bar.dart';
import '../../../core/widgets/user_card.dart';
import '../../intros/presentation/warm_intro_suggestions_strip.dart';
import '../data/discovery_service.dart';
import '../domain/discovery_profile.dart';

/// Recently-active discoverable profiles for the Network tab carousel.
/// Calls `search_discoverable_profiles(p_query: '', limit: 10)` — the
/// same RPC the search screen uses, but with empty filters so we just get
/// the freshest profiles back.
final AutoDisposeFutureProvider<List<DiscoveryProfile>>
    _recentlyActiveProvider =
    FutureProvider.autoDispose<List<DiscoveryProfile>>(
        (Ref<AsyncValue<List<DiscoveryProfile>>> ref) {
  return ref
      .watch(discoveryServiceProvider)
      .searchDiscoverableProfiles(limit: 10);
});

/// Network tab — replaces the Phase 5 stub.
///
/// Composition (matches gallery section C1):
///   1. `TopBar` with a search icon that pushes `/search`.
///   2. `WarmIntroSuggestionsStrip` — Phase 6's warm-intro carousel.
///      Hidden when there are no suggestions.
///   3. `SectionCard(title: 'Recently active')` — horizontal carousel of
///      [UserCard]s built from `_recentlyActiveProvider`.
///   4. `EmptyState` when both lists are empty.
class NetworkScreen extends ConsumerWidget {
  const NetworkScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<DiscoveryProfile>> recent =
        ref.watch(_recentlyActiveProvider);
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: TopBar(
          title: context.t('common.tabs.network'),
          actions: <TopBarAction>[
            TopBarAction(
              key: const Key('network.searchAction'),
              icon: LucideIcons.search,
              label: context.t('discovery.openSearch'),
              onPressed: () => context.push(Routes.search),
            ),
          ],
        ),
      ),
      body: ListView(
        children: <Widget>[
          const WarmIntroSuggestionsStrip(),
          recent.when(
            loading: () => const SizedBox(
              height: 220,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => const SizedBox.shrink(),
            data: (List<DiscoveryProfile> rows) {
              if (rows.isEmpty) {
                return EmptyState(
                  icon: LucideIcons.users,
                  title: context.t('settings.tabs.networkEmptyTitle'),
                  body: context.t('settings.tabs.networkEmptyBody'),
                  action: EmptyStateAction(
                    label: context.t('discovery.openSearch'),
                    onPressed: () => context.push(Routes.search),
                  ),
                );
              }
              return Padding(
                padding: const EdgeInsets.all(12),
                child: SectionCard(
                  title: context.t('settings.tabs.networkRecentlyActive'),
                  padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
                  child: SizedBox(
                    height: 220,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      itemCount: rows.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (BuildContext _, int i) {
                        final DiscoveryProfile p = rows[i];
                        return SizedBox(
                          width: 240,
                          child: UserCard(
                            name: p.name ?? p.handle,
                            primaryRole: p.primaryRole ?? '',
                            photoUrl: p.photoUrl,
                            headline: p.headline,
                            city: p.city,
                            country: p.country,
                            onTap: () =>
                                context.push(Routes.publicProfile(p.handle)),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
