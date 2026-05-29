import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/i18n/i18n.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_filter_chip.dart';
import '../../../../core/widgets/gap.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../domain/discovery_profile.dart';
import '../../domain/feed_filters.dart';
import '../../providers/feed_filters_provider.dart';
import '../../providers/search_provider.dart';
import '../filter_sheet.dart';
import 'search_result_row.dart';

/// The "BROWSE ALL" hybrid feed rendered below the daily picks on Home
/// (gallery C1, lines 1447-1469): an eyebrow, a horizontal filter-pill row
/// (All roles / region / Verified / Active), then a short list of plain
/// (non-featured) discoverable profiles.
///
/// Data reuses the existing keyset-paginated [searchProvider] — the same
/// discoverable feed the full Browse screen renders — and the first
/// [_kPreviewCount] rows are shown here as a teaser. Role / region filters
/// write through to the shared [searchProvider] (so Home and Browse stay in
/// sync); the Verified / Active pills are client-side display filters over
/// the loaded preview (the backend feed does not yet expose those facets).
///
/// Collapses to [SizedBox.shrink] while loading-with-no-data or when the
/// feed is empty so Home never shows an orphan "BROWSE ALL" header.
class BrowseAllSection extends ConsumerStatefulWidget {
  const BrowseAllSection({super.key});

  @override
  ConsumerState<BrowseAllSection> createState() => _BrowseAllSectionState();
}

class _BrowseAllSectionState extends ConsumerState<BrowseAllSection> {
  static const int _kPreviewCount = 3;

  bool _verifiedOnly = false;
  bool _activeOnly = false;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    final t = Theme.of(context).extension<AppTypography>()!;
    final searchAsync = ref.watch(searchProvider);
    final FeedFilters filters =
        ref.watch(feedFiltersProvider).asData?.value ?? const FeedFilters();

    final rows = searchAsync.asData?.value.items ?? const <DiscoveryProfile>[];
    final filtered = rows
        .where((p) => !_verifiedOnly || p.verified)
        .where((p) => !_activeOnly || p.isActiveThisWeek)
        .take(_kPreviewCount)
        .toList(growable: false);

    final bool loading = searchAsync.isLoading && rows.isEmpty;
    // Nothing to show: no data and not loading → don't render an orphan header.
    if (!loading && rows.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                context.t('discovery.browse.allTitle').toUpperCase(),
                style: t.displayXs.copyWith(color: c.navy, letterSpacing: 1.2),
              ),
              GestureDetector(
                key: const Key('browseAll.seeAll'),
                onTap: () => context.push(Routes.search),
                child: Text(
                  context.t('discovery.browse.seeAll'),
                  style: t.bodySm.copyWith(color: c.navy),
                ),
              ),
            ],
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: <Widget>[
              AppFilterChip(
                key: const Key('browseAll.allRoles'),
                label: context.t('discovery.browse.allRoles'),
                active: filters.roles.isEmpty,
                onTap: () async {
                  await ref
                      .read(searchProvider.notifier)
                      .applyFilters(roles: const <String>[]);
                },
              ),
              const Gap(8),
              AppFilterChip(
                key: const Key('browseAll.region'),
                label: filters.country ??
                    '+ ${context.t('discovery.facet.region')}',
                active: filters.country != null,
                onTap: () async {
                  final next = await showFilterSheet(context, initial: filters);
                  if (next != null) {
                    await ref.read(searchProvider.notifier).applyFilters(
                          roles: next.roles,
                          goalTypes: next.goalTypes,
                          country: next.country,
                        );
                  }
                },
              ),
              const Gap(8),
              AppFilterChip(
                key: const Key('browseAll.verified'),
                label: '${context.t('discovery.facet.verified')} ✓',
                active: _verifiedOnly,
                onTap: () => setState(() => _verifiedOnly = !_verifiedOnly),
              ),
              const Gap(8),
              AppFilterChip(
                key: const Key('browseAll.active'),
                label: context.t('discovery.facet.active'),
                active: _activeOnly,
                onTap: () => setState(() => _activeOnly = !_activeOnly),
              ),
            ],
          ),
        ),
        const Gap(4),
        if (loading)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Column(
              children: <Widget>[
                SkeletonListRow(),
                SkeletonListRow(),
              ],
            ),
          )
        else
          for (final p in filtered)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: SearchResultRow(
                profile: p,
                onTap: () => context.push(Routes.publicProfile(p.handle)),
              ),
            ),
      ],
    );
  }
}
