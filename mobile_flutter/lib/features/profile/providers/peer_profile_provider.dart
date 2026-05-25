import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/peer_profile_service.dart';
import '../domain/profile.dart';

/// Family-keyed lookup of a peer profile by user id. Used by Intros and
/// Connections to resolve a stable Avatar + name + role without forcing the
/// caller to thread the lookup through the underlying RPCs.
///
/// Returns `null` when the row is missing (suspended user, deleted account,
/// or a yet-uncreated row) — UI layers fall back to rendering the user id.
///
/// AutoDispose so opening many detail screens doesn't pile up subscriptions.
final AutoDisposeFutureProviderFamily<Profile?, String> peerProfileProvider =
    FutureProvider.family.autoDispose<Profile?, String>(
  (Ref<AsyncValue<Profile?>> ref, String userId) {
    return ref.watch(peerProfileServiceProvider).fetchById(userId);
  },
);
