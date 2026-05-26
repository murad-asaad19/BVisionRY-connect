import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/i18n/i18n.dart';
import '../../../core/routing/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_filter_chip.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/query_state.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/top_bar.dart';
import '../domain/opportunity_kind.dart';
import '../providers/opportunities_feed_provider.dart';
import 'opportunity_card.dart';

/// Public opportunities feed.
///
/// Layout: TopBar (with `+` to compose and a kebab to My Opportunities) →
/// sticky horizontal filter strip → paginated list of [OpportunityCard]s.
/// Pull-to-refresh re-fetches page 1; scrolling near the bottom triggers
/// `loadMore` while `hasMore` is set.
class OpportunitiesFeedScreen extends ConsumerStatefulWidget {
  const OpportunitiesFeedScreen({super.key});

  @override
  ConsumerState<OpportunitiesFeedScreen> createState() =>
      _OpportunitiesFeedScreenState();
}

class _OpportunitiesFeedScreenState
    extends ConsumerState<OpportunitiesFeedScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final double pos = _scrollController.position.pixels;
    final double max = _scrollController.position.maxScrollExtent;
    if (max - pos < 400) {
      ref.read(opportunitiesFeedProvider.notifier).loadMore();
    }
  }

  void _toggleKind(OpportunityKind k) {
    final state = ref.read(opportunitiesFeedProvider).valueOrNull;
    if (state == null) return;
    final bool active = state.kinds.contains(k);
    final List<OpportunityKind> next = active
        ? state.kinds.where((OpportunityKind v) => v != k).toList()
        : <OpportunityKind>[...state.kinds, k];
    ref.read(opportunitiesFeedProvider.notifier).setFilters(
          kinds: next,
          remoteOnly: state.remoteOnly,
          search: state.search,
        );
  }

  void _toggleRemote() {
    final state = ref.read(opportunitiesFeedProvider).valueOrNull;
    if (state == null) return;
    ref.read(opportunitiesFeedProvider.notifier).setFilters(
          kinds: state.kinds,
          remoteOnly: !state.remoteOnly,
          search: state.search,
        );
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = Theme.of(context).extension<AppColors>()!;
    final AsyncValue<OpportunitiesFeedState> async =
        ref.watch(opportunitiesFeedProvider);

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: <Widget>[
            TopBar(
              title: context.t('opportunities.feed.title'),
              actions: <TopBarAction>[
                TopBarAction(
                  icon: LucideIcons.plus,
                  label: context.t('opportunities.feed.newCta'),
                  onPressed: () => context.push(Routes.opportunityNew),
                ),
                TopBarAction(
                  icon: LucideIcons.ellipsisVertical,
                  label: 'Menu',
                  onPressed: () => _showKebab(context),
                ),
              ],
            ),
            _FilterRow(
              kinds: async.valueOrNull?.kinds ?? const <OpportunityKind>[],
              remoteOnly: async.valueOrNull?.remoteOnly ?? false,
              onToggleKind: _toggleKind,
              onToggleRemote: _toggleRemote,
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () =>
                    ref.read(opportunitiesFeedProvider.notifier).refresh(),
                child: QueryState<OpportunitiesFeedState>(
                  value: async,
                  loading: const _FeedSkeleton(),
                  data: (OpportunitiesFeedState state) {
                    if (state.items.isEmpty) {
                      return _EmptyFeed();
                    }
                    return ListView.separated(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: state.items.length +
                          (state.isLoadingMore ? 1 : 0),
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 12),
                      itemBuilder: (BuildContext c, int i) {
                        if (i == state.items.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Center(
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          );
                        }
                        final item = state.items[i];
                        return OpportunityCard(
                          data: item,
                          onTap: () => context.push(
                            Routes.opportunity(item.opportunity.id),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showKebab(BuildContext context) async {
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    final Offset offset =
        box?.localToGlobal(Offset.zero) ?? Offset.zero;
    final int? selected = await showMenu<int>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx + (box?.size.width ?? 0) - 200,
        offset.dy + 56,
        12,
        offset.dy + 200,
      ),
      items: <PopupMenuEntry<int>>[
        PopupMenuItem<int>(
          value: 0,
          child: Text(context.t('opportunities.feed.myOpportunities')),
        ),
      ],
    );
    if (!context.mounted) return;
    if (selected == 0) unawaited(context.push(Routes.myOpportunities));
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.kinds,
    required this.remoteOnly,
    required this.onToggleKind,
    required this.onToggleRemote,
  });

  final List<OpportunityKind> kinds;
  final bool remoteOnly;
  final ValueChanged<OpportunityKind> onToggleKind;
  final VoidCallback onToggleRemote;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = Theme.of(context).extension<AppColors>()!;
    return Container(
      decoration: BoxDecoration(
        color: colors.white,
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: <Widget>[
            AppFilterChip(
              label: context.t('opportunities.filter.remoteOnly'),
              icon: LucideIcons.globe,
              active: remoteOnly,
              onTap: onToggleRemote,
            ),
            const SizedBox(width: 8),
            for (final OpportunityKind k in OpportunityKind.values) ...<Widget>[
              AppFilterChip(
                label: context.t(k.i18nKey),
                active: kinds.contains(k),
                onTap: () => onToggleKind(k),
              ),
              const SizedBox(width: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyFeed extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: <Widget>[
        EmptyState(
          icon: LucideIcons.briefcaseBusiness,
          title: context.t('opportunities.feed.emptyTitle'),
          body: context.t('opportunities.feed.empty'),
          action: EmptyStateAction(
            label: context.t('opportunities.feed.newCta'),
            onPressed: () => context.push(Routes.opportunityNew),
          ),
        ),
      ],
    );
  }
}

class _FeedSkeleton extends StatelessWidget {
  const _FeedSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(12),
      children: <Widget>[
        for (int i = 0; i < 5; i++) ...<Widget>[
          const SkeletonListRow(),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}
