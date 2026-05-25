import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/profile_signals_service.dart';
import '../domain/profile_signals.dart';

/// Family-keyed signals lookup for a third-party profile id. Returns
/// [ProfileSignals.empty] when no row matches (self-view, blocked pair, or
/// brand-new account) so the UI never has to branch on null.
///
/// Spec §3.1 / §17.6.
final AutoDisposeFutureProviderFamily<ProfileSignals, String>
    profileSignalsProvider =
    FutureProvider.family.autoDispose<ProfileSignals, String>(
  (Ref<AsyncValue<ProfileSignals>> ref, String targetUserId) {
    return ref.watch(profileSignalsServiceProvider).fetchSignals(targetUserId);
  },
);
