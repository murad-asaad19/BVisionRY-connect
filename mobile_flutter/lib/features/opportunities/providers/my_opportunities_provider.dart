import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/profile_provider.dart';
import '../data/opportunities_service.dart';
import '../domain/opportunity_with_author.dart';

/// `list_my_opportunities()` — the caller's posts in any status.
///
/// The RPC omits the `author_*` columns (the caller IS the author, so
/// the server doesn't bother projecting them). This provider enriches
/// every row with the viewer's own profile metadata so the shared
/// [OpportunityCard] can render the author hero block consistently.
///
/// Auto-invalidated by the composer / edit / close mutations.
final FutureProvider<List<OpportunityWithAuthor>> myOpportunitiesProvider =
    FutureProvider<List<OpportunityWithAuthor>>(
  (Ref<AsyncValue<List<OpportunityWithAuthor>>> ref) async {
    final List<OpportunityWithAuthor> rows =
        await ref.watch(opportunitiesServiceProvider).listMyOpportunities();
    final viewer = ref.watch(profileProvider).valueOrNull;
    if (viewer == null) return rows;
    return rows
        .map(
          (OpportunityWithAuthor r) => r.copyWith(
            authorHandle:
                r.authorHandle.isEmpty ? (viewer.handle ?? '') : r.authorHandle,
            authorName: r.authorName.isEmpty
                ? (viewer.name ?? viewer.handle ?? '')
                : r.authorName,
            authorPhotoUrl: r.authorPhotoUrl ?? viewer.photoUrl,
            authorPrimaryRole: r.authorPrimaryRole ?? viewer.primaryRole,
            authorVerifiedGithubUsername:
                r.authorVerifiedGithubUsername ?? viewer.verifiedGithubUsername,
          ),
        )
        .toList(growable: false);
  },
);
