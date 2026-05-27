import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/opportunity_status.dart';
import 'my_opportunities_provider.dart';

/// Aggregate interest count across the caller's *open* opportunities —
/// drives the Opportunities tab badge so the author sees at a glance
/// when someone has expressed interest in their posts.
///
/// MVP semantic: total interested-count (not "unread since last view").
/// Once a server-side `last_viewed_at_per_opportunity` is in place, this
/// provider should diff against it; until then total count is the best
/// signal we have without a second round-trip.
final FutureProvider<int> opportunitiesInterestBadgeProvider =
    FutureProvider<int>((Ref<AsyncValue<int>> ref) async {
  final rows = await ref.watch(myOpportunitiesProvider.future);
  int total = 0;
  for (final r in rows) {
    if (r.opportunity.status != OpportunityStatus.open) continue;
    total += r.interestedCount ?? 0;
  }
  return total;
});
