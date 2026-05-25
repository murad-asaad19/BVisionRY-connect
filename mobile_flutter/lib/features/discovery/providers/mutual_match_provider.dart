import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/discovery_service.dart';

/// `family` provider that resolves whether the caller and the supplied
/// user id are mutually connected. Consumed by profile screens (Phase 4)
/// to surface a "Mutual" pill.
final FutureProviderFamily<bool, String> mutualMatchProvider =
    FutureProvider.family<bool, String>((ref, otherUserId) async {
  return ref.watch(discoveryServiceProvider).isMutualMatch(otherUserId);
});
