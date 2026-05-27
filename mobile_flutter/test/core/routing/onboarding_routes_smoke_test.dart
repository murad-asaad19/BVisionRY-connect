import 'package:connect_mobile/core/routing/app_router.dart';
import 'package:connect_mobile/core/routing/routes.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // appRouterProvider drags in supabaseInitProvider, which constructs a
    // SharedPreferencesGotrueAsyncStorage at boot. Stub the prefs + secure
    // storage channel so the router can resolve without a real platform.
    SharedPreferences.setMockInitialValues(<String, Object>{});
    const MethodChannel secureStorageChannel = MethodChannel(
      'plugins.it_nomads.com/flutter_secure_storage',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, (MethodCall _) async {
      return null;
    });
  });

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
