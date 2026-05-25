import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/profile_provider.dart';
import '../../auth/providers/session_provider.dart';
import '../data/profile_service.dart';
import '../domain/profile.dart';

/// Riverpod controller that wraps the Phase 2 [profileProvider] read with the
/// Phase 4 mutation surface (update / togglePrivateMode / refresh).
///
/// `build()` simply pipes through the underlying provider's value so any
/// listener sees the same source of truth — mutations call into
/// [ProfileService] then `ref.invalidate(profileProvider)` so a fresh fetch
/// fires automatically on the next read.
class OwnProfileController extends AsyncNotifier<Profile?> {
  @override
  Future<Profile?> build() async {
    return ref.watch(profileProvider.future);
  }

  /// Patches the caller's profile via [ProfileService.updateProfile] and
  /// invalidates the underlying provider so the next read re-fetches. The
  /// patch flows through the same column-allowlist guard the service
  /// enforces — sensitive columns surface as `ForbiddenColumnException`.
  Future<Profile?> updateOwnProfile(Map<String, dynamic> patch) async {
    final String? userId =
        (await ref.read(sessionProvider.future))?.user.id;
    if (userId == null) return null;
    final ProfileService svc = ref.read(profileServiceProvider);
    state = const AsyncValue<Profile?>.loading();
    state = await AsyncValue.guard<Profile?>(() async {
      final Profile next = await svc.updateProfile(
        userId: userId,
        patch: patch,
      );
      ref.invalidate(profileProvider);
      return next;
    });
    return state.value;
  }

  /// Toggles `profiles.private_mode` via the dedicated RPC then invalidates
  /// the underlying profileProvider.
  Future<void> togglePrivateMode(bool value) async {
    final ProfileService svc = ref.read(profileServiceProvider);
    await svc.setPrivateMode(value);
    ref.invalidate(profileProvider);
  }

  /// Forces a re-fetch of the underlying profileProvider. Used after avatar
  /// upload + other out-of-band mutations the UI initiates directly.
  Future<void> refresh() async {
    ref.invalidate(profileProvider);
    await ref.read(profileProvider.future);
  }
}

final AsyncNotifierProvider<OwnProfileController, Profile?>
    ownProfileControllerProvider =
    AsyncNotifierProvider<OwnProfileController, Profile?>(
  OwnProfileController.new,
);
