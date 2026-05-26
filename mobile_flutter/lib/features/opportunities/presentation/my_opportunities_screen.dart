import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/i18n/i18n.dart';
import '../../../core/routing/routes.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/query_state.dart';
import '../../../core/widgets/top_bar.dart';
import '../domain/opportunity_with_author.dart';
import '../providers/my_opportunities_provider.dart';
import 'opportunity_card.dart';

/// The caller's own opportunities (any status).
///
/// Renders an [OpportunityCard] per row; closed / archived posts surface a
/// muted status pill in the kind row.
class MyOpportunitiesScreen extends ConsumerWidget {
  const MyOpportunitiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  data: (List<OpportunityWithAuthor> items) {
                    if (items.isEmpty) {
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: <Widget>[
                          EmptyState(
                            icon: LucideIcons.briefcaseBusiness,
                            title: context.t('opportunities.mine.emptyTitle'),
                            body: context.t('opportunities.mine.empty'),
                            action: EmptyStateAction(
                              label: context.t('opportunities.mine.newCta'),
                              onPressed: () =>
                                  context.push(Routes.opportunityNew),
                            ),
                          ),
                        ],
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (BuildContext c, int i) {
                        final item = items[i];
                        return OpportunityCard(
                          data: item,
                          statusOverlay: true,
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
}
