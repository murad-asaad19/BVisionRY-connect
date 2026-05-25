// Phase 2 import shim — the canonical Profile model lives at
// `lib/features/profile/domain/profile.dart` (freezed, full schema).
//
// Phase 2 code (ProfileRepository, profileProvider, routeGuardProvider) and
// its tests import this path. Re-export from here so we don't have to touch
// Phase 2 imports until a deliberate sweep — Profile.fromMap remains the
// open-shaped-Map factory the auth gate's minimal-row reads rely on.
export '../../profile/domain/profile.dart';
