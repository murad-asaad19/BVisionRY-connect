import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/i18n/i18n.dart';
import '../../../core/routing/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_filter_chip.dart';
import '../../../core/widgets/app_icon_button.dart';
import '../../../core/widgets/app_input.dart';
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

  void _setSearch(String raw) {
    final state = ref.read(opportunitiesFeedProvider).valueOrNull;
    if (state == null) return;
    final String trimmed = raw.trim();
    final String? next = trimmed.isEmpty ? null : trimmed;
    if (next == state.search) return;
    ref.read(opportunitiesFeedProvider.notifier).setFilters(
          kinds: state.kinds,
          remoteOnly: state.remoteOnly,
          search: next,
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
                  label: context.t('common.more'),
                  onPressed: () => _showKebab(context),
                ),
              ],
            ),
            _SearchBar(
              initial: async.valueOrNull?.search,
              onSubmit: _setSearch,
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
                  onRetry: () =>
                      ref.read(opportunitiesFeedProvider.notifier).refresh(),
                  data: (OpportunitiesFeedState state) {
                    if (state.items.isEmpty) {
                      final bool filtering = state.search != null ||
                          state.kinds.isNotEmpty ||
                          state.remoteOnly;
                      return _EmptyFeed(filtering: filtering);
                    }
                    // Footer slot when a page is loading OR the last loadMore
                    // failed (non-destructive: the loaded feed stays intact
                    // and the user gets a retry affordance).
                    final bool hasFooter =
                        state.isLoadingMore || state.loadMoreError;
                    return ListView.separated(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: state.items.length + (hasFooter ? 1 : 0),
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (BuildContext c, int i) {
                        if (i == state.items.length) {
                          if (state.loadMoreError) {
                            return _LoadMoreError(
                              onRetry: () => ref
                                  .read(opportunitiesFeedProvider.notifier)
                                  .loadMore(force: true),
                            );
                          }
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
    // Anchor to the top-right corner (where the kebab action sits in the
    // TopBar) rather than off a stale ancestor render box — the previous
    // anchoring used the whole-screen context box and mis-positioned the
    // popup.
    final Size screen = MediaQuery.of(context).size;
    final double top = MediaQuery.of(context).padding.top + 52;
    final int? selected = await showMenu<int>(
      context: context,
      position: RelativeRect.fromLTRB(screen.width - 12, top, 12, 0),
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
  const _EmptyFeed({this.filtering = false});

  /// When the empty result is the product of an active search / filter, we
  /// show "no matches" copy instead of the first-run "post one" CTA.
  final bool filtering;

  @override
  Widget build(BuildContext context) {
    if (filtering) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: <Widget>[
          EmptyState(
            icon: LucideIcons.searchX,
            title: context.t('opportunities.feed.noResultsTitle'),
            body: context.t('opportunities.feed.noResults'),
          ),
        ],
      );
    }
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

/// Free-text search affordance for the feed. Debounces input so each
/// keystroke doesn't fire a round-trip, and exposes a clear button.
class _SearchBar extends StatefulWidget {
  const _SearchBar({required this.initial, required this.onSubmit});

  final String? initial;
  final ValueChanged<String> onSubmit;

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  late String _text;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _text = widget.initial ?? '';
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String v) {
    setState(() => _text = v);
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 400),
      () => widget.onSubmit(v),
    );
  }

  void _clear() {
    _debounce?.cancel();
    setState(() => _text = '');
    widget.onSubmit('');
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = Theme.of(context).extension<AppColors>()!;
    final AppSpacing spacing = Theme.of(context).extension<AppSpacing>()!;
    return Container(
      color: colors.white,
      padding: EdgeInsets.fromLTRB(spacing.md, spacing.sm, spacing.md, 0),
      child: AppInput(
        value: _text,
        placeholder: context.t('opportunities.feed.searchPlaceholder'),
        keyboardType: TextInputType.text,
        textInputAction: TextInputAction.search,
        onChanged: _onChanged,
        onSubmitted: (String v) {
          _debounce?.cancel();
          widget.onSubmit(v);
        },
        trailing: _text.isEmpty
            ? Icon(LucideIcons.search, size: 18, color: colors.muted)
            : AppIconButton(
                icon: LucideIcons.x,
                label: context.t('common.clear'),
                size: AppIconButtonSize.sm,
                onPressed: _clear,
              ),
      ),
    );
  }
}

/// Footer row shown when `loadMore` failed — keeps the loaded feed intact
/// and offers an explicit retry instead of nuking the whole list.
class _LoadMoreError extends StatelessWidget {
  const _LoadMoreError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = Theme.of(context).extension<AppColors>()!;
    final AppTypography typo = Theme.of(context).extension<AppTypography>()!;
    final AppSpacing spacing = Theme.of(context).extension<AppSpacing>()!;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: spacing.md),
      child: Column(
        children: <Widget>[
          Text(
            context.t('opportunities.feed.loadMoreError'),
            textAlign: TextAlign.center,
            style: typo.bodySm.copyWith(color: colors.muted),
          ),
          SizedBox(height: spacing.sm),
          AppButton(
            label: context.t('common.retry'),
            variant: AppButtonVariant.outline,
            fullWidth: false,
            size: AppButtonSize.small,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}
