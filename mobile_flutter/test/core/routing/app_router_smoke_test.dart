import 'package:connect_mobile/core/routing/app_router.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    const MethodChannel secureStorageChannel = MethodChannel(
      'plugins.it_nomads.com/flutter_secure_storage',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, (_) async => null);
  });

  test('router builds without throwing', () {
    final ProviderContainer container = ProviderContainer();
    final GoRouter router = container.read(appRouterProvider);
    expect(router, isNotNull);
    container.dispose();
  });

  test('router knows /settings/office-hours and /bookings', () {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);
    final GoRouter router = container.read(appRouterProvider);
    final ohMatch = router.configuration.findMatch(
      Uri.parse('/settings/office-hours'),
    );
    expect(ohMatch.fullPath, '/settings/office-hours');
    final bookingsMatch = router.configuration.findMatch(
      Uri.parse('/bookings'),
    );
    expect(bookingsMatch.fullPath, '/bookings');
  });

  test('router knows all 5 opportunities sub-routes', () {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);
    final GoRouter router = container.read(appRouterProvider);
    expect(
      router.configuration
          .findMatch(Uri.parse('/opportunities/new'))
          .fullPath,
      '/opportunities/new',
    );
    expect(
      router.configuration
          .findMatch(Uri.parse('/opportunities/mine'))
          .fullPath,
      '/opportunities/mine',
    );
    expect(
      router.configuration
          .findMatch(Uri.parse('/opportunities/oid'))
          .fullPath,
      '/opportunities/:id',
    );
    expect(
      router.configuration
          .findMatch(Uri.parse('/opportunities/oid/edit'))
          .fullPath,
      '/opportunities/:id/edit',
    );
    expect(
      router.configuration
          .findMatch(Uri.parse('/opportunities/oid/interested'))
          .fullPath,
      '/opportunities/:id/interested',
    );
  });
}
