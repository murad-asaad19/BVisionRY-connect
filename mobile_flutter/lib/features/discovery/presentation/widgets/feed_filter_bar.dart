import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/i18n.dart';
import '../../../../core/widgets/app_filter_chip.dart';
import '../../domain/feed_filters.dart';
import '../../providers/feed_filters_provider.dart';
import '../../providers/search_provider.dart';
import '../filter_sheet.dart';

/// Inline horizontal-scroller above the Browse results (gallery C3, lines
/// 1542-1548): each active filter renders as a solid removable chip
/// (`Founder ×` / `London ×`), followed by per-facet outline adder pills
/// (`+ Sector` / `+ Stage` / `+ Region`) and a catch-all `+ Filters`
/// affordance. The per-facet adders open [showFilterSheet] positioned to
/// add that facet — Sector/Stage are backend-driven facets surfaced through
/// the same sheet rather than faked client-side.
class FeedFilterBar extends ConsumerWidget {
  const FeedFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filtersAsync = ref.watch(feedFiltersProvider);
    return filtersAsync.maybeWhen(
      data: (f) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: <Widget>[
            for (final r in f.roles)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: AppFilterChip(
                  label: '${context.t('discovery.roles.$r')} ×',
                  active: true,
                  onTap: () async {
                    final next = f.roles.where((x) => x != r).toList();
                    await ref
                        .read(searchProvider.notifier)
                        .applyFilters(roles: next);
                  },
                ),
              ),
            for (final g in f.goalTypes)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: AppFilterChip(
                  label: '${context.t('discovery.goals.$g')} ×',
                  active: true,
                  onTap: () async {
                    final next = f.goalTypes.where((x) => x != g).toList();
                    await ref
                        .read(searchProvider.notifier)
                        .applyFilters(goalTypes: next);
                  },
                ),
              ),
            if (f.country != null)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: AppFilterChip(
                  label: '${f.country} ×',
                  active: true,
                  onTap: () async {
                    await ref
                        .read(searchProvider.notifier)
                        .applyFilters(country: null);
                  },
                ),
              ),
            // Per-facet outline adder pills (gallery C3). Region is wired to
            // the country facet; Sector / Stage are backend-driven facets the
            // sheet surfaces when available — all open the same filter sheet.
            if (f.country == null)
              _AdderChip(
                label: '+ ${context.t('discovery.facet.region')}',
                initial: f,
              ),
            _AdderChip(
              label: '+ ${context.t('discovery.facet.sector')}',
              initial: f,
            ),
            _AdderChip(
              label: '+ ${context.t('discovery.facet.stage')}',
              initial: f,
            ),
            AppFilterChip(
              label: '+ ${context.t('discovery.filtersTitle')}',
              active: false,
              onTap: () => _openSheet(context, ref, f),
            ),
          ],
        ),
      ),
      orElse: () => const SizedBox(height: 48),
    );
  }
}

/// Opens the structured filter sheet and writes any returned facets back
/// through the shared [searchProvider].
Future<void> _openSheet(
  BuildContext context,
  WidgetRef ref,
  FeedFilters initial,
) async {
  final next = await showFilterSheet(context, initial: initial);
  if (next != null) {
    await ref.read(searchProvider.notifier).applyFilters(
          roles: next.roles,
          goalTypes: next.goalTypes,
          country: next.country,
        );
  }
}

/// Outline "+ Facet" adder pill that opens the structured filter sheet.
class _AdderChip extends ConsumerWidget {
  const _AdderChip({required this.label, required this.initial});

  final String label;
  final FeedFilters initial;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: AppFilterChip(
        label: label,
        active: false,
        onTap: () => _openSheet(context, ref, initial),
      ),
    );
  }
}
