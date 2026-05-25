import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/session_provider.dart';
import '../data/intros_service.dart';
import '../domain/intro.dart';
import '../domain/intro_enums.dart';

/// Convenience accessor that flattens [currentSessionProvider] to the
/// caller's user id. Returns `null` for signed-out users so list /
/// count providers can fast-fail without an explicit guard.
///
/// Overridable in tests via `currentUserIdProvider.overrideWithValue(...)`
/// so widget tests don't need to plumb a `Session`.
final Provider<String?> currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(currentSessionProvider)?.user.id;
});

/// All intros the caller has received, newest-first. Refreshes on:
/// - pull-to-refresh (`ref.invalidate(receivedIntrosProvider)`)
/// - app foreground transitions (Phase 2 lifecycle listener)
/// - any successful accept/decline (called by the action handler).
///
/// Intros are NOT in `supabase_realtime`, so we use refresh-on-event
/// rather than a Stream subscription.
final FutureProvider<List<Intro>> receivedIntrosProvider =
    FutureProvider<List<Intro>>((ref) async {
  final String? me = ref.watch(currentUserIdProvider);
  if (me == null) return const <Intro>[];
  return ref.watch(introsServiceProvider).listReceivedIntros(viewerId: me);
});

/// All intros the caller has sent, newest-first.
final FutureProvider<List<Intro>> sentIntrosProvider =
    FutureProvider<List<Intro>>((ref) async {
  final String? me = ref.watch(currentUserIdProvider);
  if (me == null) return const <Intro>[];
  return ref.watch(introsServiceProvider).listSentIntros(viewerId: me);
});

/// Caller's intros-sent-today count (sender-side daily cap helper).
final FutureProvider<int> todayCountProvider = FutureProvider<int>((
  ref,
) async {
  final String? me = ref.watch(currentUserIdProvider);
  if (me == null) return 0;
  return ref.watch(introsServiceProvider).introsTodayCount();
});

/// Count of received intros in the `delivered` state — drives the Inbox
/// tab badge on the bottom nav and the unread dot inside Inbox.
///
/// Derived from [receivedIntrosProvider] so a single fetch satisfies both
/// the list rendering AND the badge — and pull-to-refresh on the list
/// also refreshes the badge.
final FutureProvider<int> unreadIntrosCountProvider = FutureProvider<int>((
  ref,
) async {
  final list = await ref.watch(receivedIntrosProvider.future);
  return list.where((Intro i) => i.state == IntroState.delivered).length;
});
