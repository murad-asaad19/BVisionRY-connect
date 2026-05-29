import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/verification_service.dart';
import '../domain/verification_request.dart';

/// The caller's verification submissions, keyed by [VerificationKind] for
/// O(1) per-row lookup in the verification screen.
///
/// `list_my_verifications()` returns at most one live row per kind (the
/// partial-unique index enforces it), and a rejected row may coexist only
/// until the user re-submits. When both a rejected and a fresh row exist for
/// the same kind, the newest wins — the RPC orders newest-first, so the first
/// row seen per kind is the authoritative one.
final FutureProvider<Map<VerificationKind, VerificationRequest>>
    myVerificationsProvider =
    FutureProvider<Map<VerificationKind, VerificationRequest>>((ref) async {
  final List<VerificationRequest> rows =
      await ref.watch(verificationServiceProvider).listMyVerifications();
  final Map<VerificationKind, VerificationRequest> byKind =
      <VerificationKind, VerificationRequest>{};
  for (final VerificationRequest r in rows) {
    // Newest-first order from the RPC: keep the first row seen per kind.
    byKind.putIfAbsent(r.kind, () => r);
  }
  return byKind;
});
