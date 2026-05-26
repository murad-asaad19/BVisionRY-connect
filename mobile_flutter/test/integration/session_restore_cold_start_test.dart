import 'package:connect_mobile/core/i18n/locale_loader.dart';
import 'package:connect_mobile/core/i18n/locale_notifier.dart';
import 'package:connect_mobile/core/routing/app_router.dart';
import 'package:connect_mobile/core/supabase/supabase_client.dart';
import 'package:connect_mobile/core/theme/app_theme.dart';
import 'package:connect_mobile/features/intros/providers/warm_intros_provider.dart';
import 'package:connect_mobile/features/auth/data/profile_repository.dart';
import 'package:connect_mobile/features/auth/providers/auth_service_provider.dart';
import 'package:connect_mobile/features/discovery/data/discovery_service.dart';
import 'package:connect_mobile/features/discovery/domain/daily_match.dart';
import 'package:connect_mobile/features/discovery/providers/midnight_invalidator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../helpers/fake_discovery_service.dart';
import '../helpers/fake_supabase.dart';
import '../helpers/pump.dart';

class _Q implements ProfileQueryRunner {
  _Q(this.row);
  final Map<String, dynamic>? row;
  @override
  Future<Map<String, dynamic>?> selectById(String id) async => row;
}

/// No-op stand-in for [MidnightInvalidator] used by the integration test.
/// The production class schedules a 24h-distant `Timer` + an
/// `AppLifecycleListener`, both of which would leak past the test's
/// `pumpAndSettle` and trip the `!timersPending` invariant on tear-down.
class _NoOpMidnightInvalidator extends MidnightInvalidator {
  @override
  void build() {
    // intentionally empty: skip Timer + lifecycle listener registration.
  }
}

Future<void> _pumpApp(
  WidgetTester tester, {
  required FakeAuthGateway auth,
  required _Q query,
}) async {
  // Pre-load the English locale bundle so screens that resolve `context.t`
  // synchronously on first frame (BottomNav labels, etc.) render real
  // English strings instead of raw keys.
  final LocaleLoader loader = await primedLocaleLoader();
  // Override `discoveryServiceProvider` with a no-op fake — the real
  // adapter pulls `supabaseClientProvider`, which boots GoTrue's auto-refresh
  // timer and leaves a periodic Timer pending past the test's lifecycle.
  // The Home screen reads `dailyMatchesProvider` as soon as it mounts, so
  // every test that lands on /home needs this in place.
  final FakeDiscoveryService fakeDiscovery = FakeDiscoveryService();
  when(
    () => fakeDiscovery.fetchDailyMatches(date: any(named: 'date')),
  ).thenAnswer((_) async => const <DailyMatch>[]);
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        supabaseInitProvider.overrideWith((_) async {}),
        authGatewayProvider.overrideWithValue(auth),
        profileRepositoryProvider.overrideWithValue(
          ProfileRepository(query),
        ),
        localeLoaderProvider.overrideWithValue(loader),
        discoveryServiceProvider.overrideWithValue(fakeDiscovery),
        warmSuggestionsProvider.overrideWith((_) async => const []),
        midnightInvalidatorProvider.overrideWith(_NoOpMidnightInvalidator.new),
      ],
      child: Builder(
        builder: (BuildContext ctx) {
          return MaterialApp.router(
            theme: buildAppTheme(Brightness.light),
            routerConfig: ProviderScope.containerOf(
              ctx,
            ).read(appRouterProvider),
          );
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(registerDiscoveryFallbacks);
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    const MethodChannel secureStorageChannel = MethodChannel(
      'plugins.it_nomads.com/flutter_secure_storage',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, (
      MethodCall call,
    ) async {
      return null;
    });
  });

  testWidgets('cold-start with restored session lands on /home', (
    WidgetTester tester,
  ) async {
    final FakeAuthGateway auth = FakeAuthGateway();
    auth.pushAuthState(
      AuthChangeEvent.initialSession,
      fakeSession(id: 'restored'),
    );
    await _pumpApp(
      tester,
      auth: auth,
      query: _Q(<String, dynamic>{
        'id': 'restored',
        'onboarded': true,
        'suspended_at': null,
      }),
    );
    // HomeScreen renders the localized "Home" label in the BottomNav and
    // in its TopBar title (`home.title`). With the locale loader primed
    // both resolve to the English string "Home".
    expect(find.textContaining('Home'), findsWidgets);
  });

  testWidgets('cold-start with suspended profile lands on /suspended', (
    WidgetTester tester,
  ) async {
    final FakeAuthGateway auth = FakeAuthGateway();
    auth.pushAuthState(
      AuthChangeEvent.initialSession,
      fakeSession(id: 's'),
    );
    await _pumpApp(
      tester,
      auth: auth,
      query: _Q(<String, dynamic>{
        'id': 's',
        'onboarded': true,
        'suspended_at': DateTime.now().toIso8601String(),
      }),
    );
    // SuspendedScreen has a `sign-out` keyed button.
    expect(find.byKey(const Key('sign-out')), findsOneWidget);
  });

  testWidgets('cold-start with session but no profile row lands on onboarding',
      (
    WidgetTester tester,
  ) async {
    final FakeAuthGateway auth = FakeAuthGateway();
    auth.pushAuthState(
      AuthChangeEvent.initialSession,
      fakeSession(id: 'new'),
    );
    await _pumpApp(tester, auth: auth, query: _Q(null));
    // GoalStep renders the goal text input — assert the AppInput frame is
    // present, which is unique to the Goal step shell.
    expect(find.byKey(const ValueKey<String>('app-input-frame')), findsWidgets);
  });

  testWidgets('cold-start with no session lands on /sign-in', (
    WidgetTester tester,
  ) async {
    final FakeAuthGateway auth = FakeAuthGateway();
    await _pumpApp(tester, auth: auth, query: _Q(null));
    expect(find.text('BVisionRY'), findsOneWidget);
  });
}
