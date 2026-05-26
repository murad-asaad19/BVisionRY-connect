import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/opportunities_service.dart';
import '../domain/interested_user.dart';

/// `list_interested(p_opportunity_id)` family — keyed by opportunity id,
/// returns the author-only view of users who expressed interest. Non-authors
/// get a [ForbiddenException] from the service (mapped from Postgrest 42501).
final AutoDisposeFutureProviderFamily<List<InterestedUser>, String>
    interestedProvider =
    FutureProvider.autoDispose.family<List<InterestedUser>, String>(
  (Ref<AsyncValue<List<InterestedUser>>> ref, String opportunityId) async {
    return ref
        .watch(opportunitiesServiceProvider)
        .listInterested(opportunityId);
  },
);
