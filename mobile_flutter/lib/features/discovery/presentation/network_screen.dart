import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/i18n/i18n.dart';
import '../../../core/routing/routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/gap.dart';
import '../../../core/widgets/query_state.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/segmented_control.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/top_bar.dart';
import '../../../core/widgets/user_card.dart';
import '../../connections/presentation/connections_list_body.dart';
import '../../intros/presentation/warm_intro_suggestions_strip.dart';
import '../../intros/providers/warm_intros_provider.dart';
import '../data/discovery_service.dart';
import '../domain/discovery_profile.dart';
import '../domain/role_label.dart';

/// Recently-active discoverable profiles for the Network → Discover carousel.
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

/// Network tab — "your people" + grow-your-network, split into two segments:
///   * Connections — the user's established connections (primary; this is the
///     conventional "My Network" landing). Backed by [ConnectionsListBody].
///   * Discover — warm-intro suggestions + a "Recently active" carousel of
///     discoverable profiles.
///
/// Connections used to live as an Inbox segment; it moved here so the Inbox
/// stays focused on the intro→chat flow and the Network tab owns relationships.
class NetworkScreen extends ConsumerStatefulWidget {
  const NetworkScreen({super.key});

  @override
  ConsumerState<NetworkScreen> createState() => _NetworkScreenState();
}

enum _NetworkTab { connections, discover }

class _NetworkScreenState extends ConsumerState<NetworkScreen> {
  _NetworkTab _tab = _NetworkTab.connections;

  @override
  Widget build(BuildContext context) {
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
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: SegmentedControl<_NetworkTab>(
              value: _tab,
              onChange: (v) => setState(() => _tab = v),
              options: <SegmentedOption<_NetworkTab>>[
                SegmentedOption<_NetworkTab>(
                  value: _NetworkTab.connections,
                  label: context.t('network.tab.connections'),
                ),
                SegmentedOption<_NetworkTab>(
                  value: _NetworkTab.discover,
                  label: context.t('network.tab.discover'),
                ),
              ],
            ),
          ),
          Expanded(
            child: switch (_tab) {
              _NetworkTab.connections => const ConnectionsListBody(),
              _NetworkTab.discover => const _DiscoverBody(),
            },
          ),
        ],
      ),
    );
  }
}

/// Discover segment — warm-intro suggestions strip + "Recently active"
/// carousel. Mirrors the gallery section C1 discovery composition.
class _DiscoverBody extends ConsumerWidget {
  const _DiscoverBody();

  static const double _carouselHeight = 220;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<DiscoveryProfile>> recent =
        ref.watch(_recentlyActiveProvider);
    final spacing = Theme.of(context).extension<AppSpacing>()!;
    return RefreshIndicator(
      onRefresh: () async {
        ref
          ..invalidate(_recentlyActiveProvider)
          ..invalidate(warmSuggestionsProvider);
        await ref.read(_recentlyActiveProvider.future);
      },
      child: ListView(
        // Always-scrollable so the pull gesture works even when the
        // carousel is short or empty.
        physics: const AlwaysScrollableScrollPhysics(),
        children: <Widget>[
          const WarmIntroSuggestionsStrip(),
          QueryState<List<DiscoveryProfile>>(
            value: recent,
            loading: const SizedBox(
              height: _carouselHeight,
              child: Center(child: SkeletonListRow()),
            ),
            onRetry: () => ref.invalidate(_recentlyActiveProvider),
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
                padding: EdgeInsets.all(spacing.md),
                child: SectionCard(
                  title: context.t('settings.tabs.networkRecentlyActive'),
                  padding: EdgeInsets.fromLTRB(
                    spacing.sm,
                    spacing.md,
                    spacing.sm,
                    spacing.sm,
                  ),
                  child: SizedBox(
                    height: _carouselHeight,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(horizontal: spacing.xs),
                      itemCount: rows.length,
                      separatorBuilder: (_, __) => Gap(spacing.md),
                      itemBuilder: (BuildContext _, int i) {
                        final DiscoveryProfile p = rows[i];
                        final role = p.primaryRole;
                        return SizedBox(
                          width: 240,
                          child: UserCard(
                            name: p.name ?? p.handle,
                            primaryRole: (role == null || role.isEmpty)
                                ? ''
                                : roleLabel(context, role),
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
