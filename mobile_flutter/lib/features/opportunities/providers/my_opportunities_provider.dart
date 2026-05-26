import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/opportunities_service.dart';
import '../domain/opportunity_with_author.dart';

/// `list_my_opportunities()` — the caller's posts in any status. Auto-
/// invalidated by composer / edit / close mutations so the My Opportunities
/// screen mirrors server-side state.
final FutureProvider<List<OpportunityWithAuthor>> myOpportunitiesProvider =
    FutureProvider<List<OpportunityWithAuthor>>(
  (Ref<AsyncValue<List<OpportunityWithAuthor>>> ref) async {
    return ref.watch(opportunitiesServiceProvider).listMyOpportunities();
  },
);
