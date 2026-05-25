import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/profile.dart';
import 'auth_service_provider.dart';
import 'session_provider.dart';

/// Resolves the signed-in user's [Profile]. Returns `null` when there is no
/// session, or when the row hasn't been written yet (treated as "not
/// onboarded" by [routeGuardProvider]).
///
/// Auto-invalidates whenever the session changes — `ref.watch` of
/// [sessionProvider] is enough; Riverpod rebuilds this future whenever its
/// dependency emits a new value, including transitions between distinct
/// user ids on the same machine.
final FutureProvider<Profile?> profileProvider = FutureProvider<Profile?>((
  Ref<AsyncValue<Profile?>> ref,
) async {
  // Wait for the first session emission so a fresh container that hasn't yet
  // pumped the seed doesn't prematurely resolve to `null`.
  final Session? session = await ref.watch(sessionProvider.future);
  if (session == null) return null;
  return ref.watch(profileRepositoryProvider).fetchOwn(session.user.id);
});
