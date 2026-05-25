import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/public_profile_service.dart';

/// Family-keyed lookup of a public profile by handle. The underlying RPC
/// (`get_public_profile`) is granted to PUBLIC so this works without an
/// authenticated session — anon visitors at `/p/:handle` resolve through
/// this provider.
///
/// Riverpod's family identity dedupes equivalent reads automatically, so
/// rendering the same handle from multiple consumers only fires one round
/// trip.
final AutoDisposeFutureProviderFamily<PublicProfile?, String>
    publicProfileProvider =
    FutureProvider.family.autoDispose<PublicProfile?, String>(
  (Ref<AsyncValue<PublicProfile?>> ref, String handle) {
    return ref.watch(publicProfileServiceProvider).getPublicProfile(handle);
  },
);
