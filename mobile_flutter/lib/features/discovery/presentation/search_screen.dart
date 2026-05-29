import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/i18n.dart';
import '../../../core/routing/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_icon_button.dart';
import '../../../core/widgets/app_input.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/gap.dart';
import '../../../core/widgets/query_state.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/top_bar.dart';
import '../domain/search_state.dart';
import '../providers/feed_filters_provider.dart';
import '../providers/search_provider.dart';
import 'widgets/feed_filter_bar.dart';
import 'widgets/search_result_row.dart';

/// Structured Browse surface (gallery C3). Primarily driven by the
/// [FeedFilterBar] facet pills; the free-text field is retained as a
/// secondary affordance below the title. Backed by the keyset-paginated
/// `searchProvider`; debounce + filter persistence are handled inside the
/// controller. Tap a row → push `/p/:handle`.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final ScrollController _scroll = ScrollController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
      ref.read(searchProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _scroll
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _setQuery(String v) {
    setState(() => _query = v);
    ref.read(searchProvider.notifier).setQuery(v);
  }

  void _clearQuery() {
    setState(() => _query = '');
    ref.read(searchProvider.notifier).setQuery('');
  }

  @override
  Widget build(BuildContext context) {
    final searchAsync = ref.watch(searchProvider);
    final spacing = Theme.of(context).extension<AppSpacing>()!;
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: TopBar(title: context.t('discovery.browseTitle'), back: true),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.fromLTRB(spacing.lg, spacing.sm, spacing.lg, 0),
            child: AppInput(
              value: _query,
              placeholder: context.t('discovery.searchPlaceholder'),
              textInputAction: TextInputAction.search,
              onChanged: _setQuery,
              // Submitting from the keyboard runs the query immediately
              // rather than waiting out the keystroke debounce.
              onSubmitted: (v) =>
                  ref.read(searchProvider.notifier).applyFilters(),
              trailing: _query.isEmpty
                  ? null
                  : AppIconButton(
                      key: const Key('search.clearQuery'),
                      icon: Icons.close,
                      label: context.t('common.clear'),
                      size: AppIconButtonSize.sm,
                      onPressed: _clearQuery,
                    ),
            ),
          ),
          const FeedFilterBar(),
          Expanded(
            child: QueryState<SearchState>(
              value: searchAsync,
              loading: const _SearchLoading(),
              onRetry: () => ref.read(searchProvider.notifier).applyFilters(),
              data: (state) {
                if (state.items.isEmpty) {
                  final filtersActive =
                      ref.watch(feedFiltersProvider).asData?.value.isActive ??
                          false;
                  return EmptyState(
                    icon: Icons.search_off,
                    title: context.t('discovery.searchEmptyTitle'),
                    body: context.t('discovery.searchEmptyBody'),
                    action: filtersActive
                        ? EmptyStateAction(
                            label: context.t('discovery.filter.clear'),
                            onPressed: () {
                              _clearQuery();
                              ref.read(searchProvider.notifier).resetFilters();
                            },
                          )
                        : null,
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _ResultCountLine(count: state.items.length),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () =>
                            ref.read(searchProvider.notifier).applyFilters(),
                        child: ListView.separated(
                          controller: _scroll,
                          padding: EdgeInsets.fromLTRB(
                            spacing.lg,
                            0,
                            spacing.lg,
                            spacing.sm,
                          ),
                          itemCount:
                              state.items.length + (state.hasMore ? 1 : 0),
                          separatorBuilder: (_, __) => Gap(spacing.sm),
                          itemBuilder: (_, i) {
                            if (i >= state.items.length) {
                              return Padding(
                                padding:
                                    EdgeInsets.symmetric(vertical: spacing.lg),
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            final p = state.items[i];
                            return SearchResultRow(
                              profile: p,
                              onTap: () =>
                                  context.push(Routes.publicProfile(p.handle)),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Dosis-bold muted eyebrow above the results (gallery C3 line 1549):
/// `{n} RESULTS · SORTED BY RELEVANCE`. Pluralized result count + a fixed
/// "sorted by relevance" suffix (the feed is relevance-ranked server-side).
class _ResultCountLine extends StatelessWidget {
  const _ResultCountLine({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    final t = Theme.of(context).extension<AppTypography>()!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(
        context.t(
          'discovery.resultCount',
          vars: <String, Object>{'count': count},
        ).toUpperCase(),
        style: t.displayXs.copyWith(color: c.muted, letterSpacing: 0.8),
      ),
    );
  }
}

/// Row-shaped loading placeholder for the search list — mirrors the real
/// [SearchResultRow] geometry so the layout doesn't jump when data lands.
class _SearchLoading extends StatelessWidget {
  const _SearchLoading();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: const <Widget>[
        SkeletonListRow(),
        SkeletonListRow(),
        SkeletonListRow(),
        SkeletonListRow(),
        SkeletonListRow(),
      ],
    );
  }
}
