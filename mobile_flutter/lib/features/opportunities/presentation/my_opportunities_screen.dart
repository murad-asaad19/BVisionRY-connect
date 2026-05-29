import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/i18n/i18n.dart';
import '../../../core/routing/routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/query_state.dart';
import '../../../core/widgets/segmented_control.dart';
import '../../../core/widgets/top_bar.dart';
import '../domain/opportunity_status.dart';
import '../domain/opportunity_with_author.dart';
import '../providers/my_opportunities_provider.dart';
import 'opportunity_card.dart';

/// The caller's own opportunities (any status), segmented into Open / Closed
/// / Archived buckets so the author isn't looking at one undifferentiated
/// list. Each segment label carries its count.
class MyOpportunitiesScreen extends ConsumerStatefulWidget {
  const MyOpportunitiesScreen({super.key});

  @override
  ConsumerState<MyOpportunitiesScreen> createState() =>
      _MyOpportunitiesScreenState();
}

class _MyOpportunitiesScreenState extends ConsumerState<MyOpportunitiesScreen> {
  OpportunityStatus _segment = OpportunityStatus.open;

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<OpportunityWithAuthor>> async =
        ref.watch(myOpportunitiesProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: <Widget>[
            TopBar(
              title: context.t('opportunities.mine.title'),
              back: true,
              actions: <TopBarAction>[
                TopBarAction(
                  icon: LucideIcons.plus,
                  label: context.t('opportunities.mine.newCta'),
                  onPressed: () => context.push(Routes.opportunityNew),
                ),
              ],
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(myOpportunitiesProvider);
                  await ref.read(myOpportunitiesProvider.future);
                },
                child: QueryState<List<OpportunityWithAuthor>>(
                  value: async,
                  onRetry: () => ref.invalidate(myOpportunitiesProvider),
                  data: (List<OpportunityWithAuthor> items) {
                    if (items.isEmpty) {
                      return _EmptyMine();
                    }
                    return _SegmentedList(
                      items: items,
                      segment: _segment,
                      onSegmentChange: (OpportunityStatus s) =>
                          setState(() => _segment = s),
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
}

class _SegmentedList extends StatelessWidget {
  const _SegmentedList({
    required this.items,
    required this.segment,
    required this.onSegmentChange,
  });

  final List<OpportunityWithAuthor> items;
  final OpportunityStatus segment;
  final ValueChanged<OpportunityStatus> onSegmentChange;

  int _countFor(OpportunityStatus s) => items
      .where((OpportunityWithAuthor o) => o.opportunity.status == s)
      .length;

  @override
  Widget build(BuildContext context) {
    final AppSpacing spacing = Theme.of(context).extension<AppSpacing>()!;
    final int openCount = _countFor(OpportunityStatus.open);
    final int closedCount = _countFor(OpportunityStatus.closed);
    final int archivedCount = _countFor(OpportunityStatus.archived);
    final List<OpportunityWithAuthor> visible = items
        .where((OpportunityWithAuthor o) => o.opportunity.status == segment)
        .toList(growable: false);

    return Column(
      children: <Widget>[
        Padding(
          padding: EdgeInsets.fromLTRB(
            spacing.md,
            spacing.md,
            spacing.md,
            spacing.sm,
          ),
          child: SegmentedControl<OpportunityStatus>(
            value: segment,
            onChange: onSegmentChange,
            options: <SegmentedOption<OpportunityStatus>>[
              SegmentedOption<OpportunityStatus>(
                value: OpportunityStatus.open,
                label: context.t(
                  'opportunities.mine.segmentOpen',
                  vars: <String, Object>{'count': openCount},
                ),
              ),
              SegmentedOption<OpportunityStatus>(
                value: OpportunityStatus.closed,
                label: context.t(
                  'opportunities.mine.segmentClosed',
                  vars: <String, Object>{'count': closedCount},
                ),
              ),
              SegmentedOption<OpportunityStatus>(
                value: OpportunityStatus.archived,
                label: context.t(
                  'opportunities.mine.segmentArchived',
                  vars: <String, Object>{'count': archivedCount},
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: visible.isEmpty
              ? _EmptySegment(segment: segment)
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 32),
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: visible.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (BuildContext c, int i) {
                    final OpportunityWithAuthor item = visible[i];
                    return OpportunityCard(
                      data: item,
                      statusOverlay: true,
                      onTap: () => context.push(
                        Routes.opportunity(item.opportunity.id),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _EmptySegment extends StatelessWidget {
  const _EmptySegment({required this.segment});

  final OpportunityStatus segment;

  @override
  Widget build(BuildContext context) {
    final String key = switch (segment) {
      OpportunityStatus.open => 'opportunities.mine.emptyOpen',
      OpportunityStatus.closed => 'opportunities.mine.emptyClosed',
      OpportunityStatus.archived => 'opportunities.mine.emptyArchived',
    };
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: <Widget>[
        EmptyState(
          icon: LucideIcons.briefcaseBusiness,
          title: context.t(key),
        ),
      ],
    );
  }
}

class _EmptyMine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: <Widget>[
        EmptyState(
          icon: LucideIcons.briefcaseBusiness,
          title: context.t('opportunities.mine.emptyTitle'),
          body: context.t('opportunities.mine.empty'),
          action: EmptyStateAction(
            label: context.t('opportunities.mine.newCta'),
            onPressed: () => context.push(Routes.opportunityNew),
          ),
        ),
      ],
    );
  }
}
