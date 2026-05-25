import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/routing/route_guard.dart';
import '../domain/profile.dart';
import 'profile_provider.dart';
import 'session_provider.dart';

/// Routes the navigator should target based on the current session +
/// profile state. Mirrors spec §5.3 by funneling its inputs through the
/// pure [resolveNextRoute] state machine.
///
/// Returns `null` while either dependency is still loading — consumers
/// (typically a `GoRouter.redirect`) treat that as "keep the splash up."
final Provider<String?> routeGuardProvider = Provider<String?>((
  Ref<String?> ref,
) {
  final AsyncValue<Session?> session = ref.watch(sessionProvider);
  final AsyncValue<Profile?> profile = ref.watch(profileProvider);

  final bool sessionLoading = session.isLoading;
  final bool hasSession = session.valueOrNull != null;
  final bool profileLoading = hasSession && profile.isLoading;
  final Profile? p = profile.valueOrNull;
  final bool suspended = p?.isSuspended ?? false;
  final bool onboarded = p?.onboarded ?? false;

  return resolveNextRoute(
    sessionLoading: sessionLoading,
    hasSession: hasSession,
    profileLoading: profileLoading,
    suspended: suspended,
    onboarded: onboarded,
  );
});
