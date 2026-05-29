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

  // A failed profile fetch (vs. a deliberately-absent row) must NOT be read
  // as "not onboarded" — doing so silently dumps the user into onboarding on
  // a transient backend/RLS error. While the fetch is in error we keep the
  // guard pinned to the loading/splash state (return null) so the surface
  // can offer a retry instead of mis-routing. `valueOrNull` stays null on
  // error, so we check `hasError` explicitly.
  if (hasSession && profile.hasError) {
    return null;
  }

  final bool profileLoading = hasSession && profile.isLoading;
  final Profile? p = profile.valueOrNull;
  final bool suspended = p?.isSuspended ?? false;
  final bool onboarded = p?.onboarded ?? false;
  // Gate the consent interstitial only on a LOADED profile that has not yet
  // recorded consent. A missing row (theoretical — the on_auth_user_created
  // trigger always writes one) is left to the onboarding gate below, matching
  // prior behaviour and avoiding a dead-end on the consent RPC, which requires
  // an existing row to update.
  final bool consentRecorded = p == null ? true : p.consentRecorded;

  return resolveNextRoute(
    sessionLoading: sessionLoading,
    hasSession: hasSession,
    profileLoading: profileLoading,
    suspended: suspended,
    consentRecorded: consentRecorded,
    onboarded: onboarded,
  );
});
