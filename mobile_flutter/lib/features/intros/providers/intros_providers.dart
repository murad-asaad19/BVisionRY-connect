import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/profile_provider.dart';
import '../../auth/providers/session_provider.dart';
import '../data/intros_service.dart';
import '../domain/intro.dart';
import '../domain/intro_enums.dart';

/// Account tier surfaced by the gallery's "free 5 / verified 15 / Pro 40"
/// note. Today we only have a verified flag (`Profile.isVerified`); Pro will
/// land when the subscription provider exists.
enum IntrosTier { free, verified, pro }

/// Lookup table the send sheet renders as `Today's intros: count / cap`.
/// Centralised so the send sheet, profile gating, and any future settings
/// surface all agree on the cap.
const Map<IntrosTier, int> introsDailyCapForTier = <IntrosTier, int>{
  IntrosTier.free: 5,
  IntrosTier.verified: 15,
  IntrosTier.pro: 40,
};

/// Resolves the caller's intro tier off the existing [profileProvider] read.
/// Falls back to [IntrosTier.free] while the profile is loading so we never
/// over-promise a verified cap to an unverified user.
///
/// Tests should override this with `accountTierProvider.overrideWith((_) => …)`
/// rather than stub the whole profile chain.
final AutoDisposeProvider<IntrosTier> accountTierProvider =
    Provider.autoDispose<IntrosTier>((ref) {
  final profile = ref.watch(profileProvider).asData?.value;
  if (profile == null) return IntrosTier.free;
  if (profile.isVerified) return IntrosTier.verified;
  return IntrosTier.free;
});

/// Convenience derivative — returns the int cap straight away, so widgets
/// don't need to know the [IntrosTier] enum.
final AutoDisposeProvider<int> dailyIntroCapProvider =
    Provider.autoDispose<int>((ref) {
  final tier = ref.watch(accountTierProvider);
  return introsDailyCapForTier[tier] ?? introsDailyCapForTier[IntrosTier.free]!;
});

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
