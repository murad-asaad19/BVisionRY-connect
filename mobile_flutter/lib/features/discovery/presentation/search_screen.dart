import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/i18n.dart';
import '../../../core/routing/routes.dart';
import '../../../core/widgets/app_input.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/top_bar.dart';
import '../providers/search_provider.dart';
import 'widgets/feed_filter_bar.dart';
import 'widgets/search_result_row.dart';

/// Discoverable-profile search screen. Backed by the keyset-paginated
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

  @override
  Widget build(BuildContext context) {
    final searchAsync = ref.watch(searchProvider);
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: TopBar(title: context.t('discovery.openSearch'), back: true),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: AppInput(
              value: _query,
              placeholder: context.t('discovery.searchPlaceholder'),
              onChanged: (v) {
                setState(() => _query = v);
                ref.read(searchProvider.notifier).setQuery(v);
              },
            ),
          ),
          const FeedFilterBar(),
          Expanded(
            child: searchAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text(e.toString())),
              data: (state) {
                if (state.items.isEmpty) {
                  return EmptyState(
                    icon: Icons.search_off,
                    title: context.t('discovery.searchEmptyTitle'),
                    body: context.t('discovery.searchEmptyBody'),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(searchProvider.notifier).setQuery(_query),
                  child: ListView.separated(
                    controller: _scroll,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: state.items.length + (state.hasMore ? 1 : 0),
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      if (i >= state.items.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: CircularProgressIndicator()),
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
