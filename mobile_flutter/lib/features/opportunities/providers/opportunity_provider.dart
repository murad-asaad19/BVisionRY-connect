import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/opportunities_service.dart';
import '../domain/opportunity_with_counts.dart';

/// `get_opportunity(p_id)` family — keyed by opportunity id, returns the
/// detail-shape row. Invalidated by `expressInterest`, `updateOpportunity`,
/// `closeOpportunity` so the detail screen reflects fresh counts and state.
final AutoDisposeFutureProviderFamily<OpportunityWithCounts, String>
    opportunityProvider =
    FutureProvider.autoDispose.family<OpportunityWithCounts, String>(
  (Ref<AsyncValue<OpportunityWithCounts>> ref, String id) async {
    return ref.watch(opportunitiesServiceProvider).getOpportunity(id);
  },
);
