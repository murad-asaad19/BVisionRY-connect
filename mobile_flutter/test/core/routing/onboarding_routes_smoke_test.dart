import 'package:connect_mobile/core/routing/app_router.dart';
import 'package:connect_mobile/core/routing/routes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  test('router resolves all four onboarding step routes', () {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);
    final GoRouter router = container.read(appRouterProvider);
    for (final String path in <String>[
      Routes.onboardingGoal,
      Routes.onboardingIdentity,
      Routes.onboardingRoles,
      Routes.onboardingAbout,
    ]) {
      final RouteMatchList match =
          router.configuration.findMatch(Uri.parse(path));
      expect(
        match.matches,
        isNotEmpty,
        reason: '$path should resolve to a route in appRouterProvider',
      );
    }
  });
}
