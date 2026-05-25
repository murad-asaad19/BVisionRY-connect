import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/i18n.dart';
import '../../../../core/widgets/app_filter_chip.dart';
import '../../providers/feed_filters_provider.dart';
import '../../providers/search_provider.dart';
import '../filter_sheet.dart';

/// Inline horizontal-scroller above the search results showing each active
/// filter as a removable chip + a trailing "+ Filters" affordance that
/// opens [showFilterSheet].
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
            AppFilterChip(
              label: '+ ${context.t('discovery.filtersTitle')}',
              active: false,
              onTap: () async {
                final next = await showFilterSheet(context, initial: f);
                if (next != null) {
                  await ref.read(searchProvider.notifier).applyFilters(
                        roles: next.roles,
                        goalTypes: next.goalTypes,
                        country: next.country,
                      );
                }
              },
            ),
          ],
        ),
      ),
      orElse: () => const SizedBox(height: 48),
    );
  }
}
