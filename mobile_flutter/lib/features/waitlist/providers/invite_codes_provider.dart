import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/invite_service.dart';
import '../domain/invite_code.dart';

/// `ensure_invite_codes()` — the caller's shareable invite codes, generating
/// the default batch (3) on first read if they don't have enough unexpired
/// ones. Newest first.
///
/// Invalidate to re-fetch (e.g. after a pull-to-refresh on the Invite Friends
/// screen).
final FutureProvider<List<InviteCode>> inviteCodesProvider =
    FutureProvider<List<InviteCode>>((Ref<AsyncValue<List<InviteCode>>> ref) {
  return ref.watch(inviteServiceProvider).ensureInviteCodes();
});
