import 'package:connect_mobile/core/routing/route_guard.dart';
import 'package:connect_mobile/core/routing/routes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('no session -> sign-in', () {
    expect(
      resolveNextRoute(sessionLoading: false, hasSession: false),
      Routes.signIn,
    );
  });

  test('loading session -> null (caller shows spinner)', () {
    expect(
      resolveNextRoute(sessionLoading: true, hasSession: false),
      isNull,
    );
  });

  test('session but profile loading -> null (spinner)', () {
    expect(
      resolveNextRoute(
        sessionLoading: false,
        hasSession: true,
        profileLoading: true,
      ),
      isNull,
    );
  });

  test('suspended profile -> /suspended', () {
    expect(
      resolveNextRoute(
        sessionLoading: false,
        hasSession: true,
        profileLoading: false,
        suspended: true,
      ),
      Routes.suspended,
    );
  });

  test('not onboarded -> /onboarding/goal', () {
    expect(
      resolveNextRoute(
        sessionLoading: false,
        hasSession: true,
        profileLoading: false,
        suspended: false,
        onboarded: false,
      ),
      Routes.onboardingGoal,
    );
  });

  test('fully ready -> /home', () {
    expect(
      resolveNextRoute(
        sessionLoading: false,
        hasSession: true,
        profileLoading: false,
        suspended: false,
        onboarded: true,
      ),
      Routes.home,
    );
  });

  group('anon-allowed paths', () {
    test('isAnonAllowed matches /p/:handle prefix', () {
      expect(isAnonAllowed('/p/omar-d'), isTrue);
      expect(isAnonAllowed('/p/some-other-handle'), isTrue);
      expect(isAnonAllowed('/profile'), isFalse);
      expect(isAnonAllowed('/home'), isFalse);
    });

    test(
        'resolveNextRoute returns null for anon-allowed paths even when '
        'there is no session', () {
      expect(
        resolveNextRoute(
          sessionLoading: false,
          hasSession: false,
          currentLocation: '/p/omar-d',
        ),
        isNull,
      );
    });

    test('resolveNextRoute keeps standard behaviour for non-anon paths', () {
      expect(
        resolveNextRoute(
          sessionLoading: false,
          hasSession: false,
          currentLocation: '/profile',
        ),
        Routes.signIn,
      );
    });
  });
}
