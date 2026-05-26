import 'package:connect_mobile/core/env.dart';
import 'package:connect_mobile/core/push/fcm_service.dart';
import 'package:connect_mobile/features/auth/providers/session_provider.dart';
import 'package:connect_mobile/features/push/providers/fcm_lifecycle_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockFcm extends Mock implements FcmService {}

void main() {
  // The lifecycle is gated on `Env.firebaseEnabled`; in unit tests the
  // dart-define defaults that bool to false, so we only exercise the
  // short-circuit path here. The full happy-path is covered by the
  // integration test in test/app_push_integration_test.dart.

  test('lifecycle is a no-op when Env.firebaseEnabled is false', () async {
    expect(
      Env.firebaseEnabled,
      isFalse,
      reason: 'test runs without FIREBASE_ENABLED=true dart-define',
    );
    final _MockFcm fcm = _MockFcm();
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        fcmServiceProvider.overrideWithValue(fcm),
        currentSessionProvider.overrideWith((Ref<Session?> ref) => null),
      ],
    );
    addTearDown(container.dispose);
    await container.read(fcmLifecycleProvider.future);
    verifyNever(() => fcm.initialize());
    verifyNever(() => fcm.registerToken());
    verifyNever(() => fcm.subscribeTokenRefresh());
  });
}
