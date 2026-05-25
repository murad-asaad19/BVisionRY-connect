import 'package:connect_mobile/core/routing/app_router.dart';
import 'package:connect_mobile/core/theme/app_theme.dart';
import 'package:connect_mobile/features/auth/data/profile_repository.dart';
import 'package:connect_mobile/features/auth/providers/auth_service_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../helpers/fake_supabase.dart';

class _Q implements ProfileQueryRunner {
  _Q(this.row);
  final Map<String, dynamic>? row;
  @override
  Future<Map<String, dynamic>?> selectById(String id) async => row;
}

Future<void> _pumpApp(
  WidgetTester tester, {
  required FakeAuthGateway auth,
  required _Q query,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        authGatewayProvider.overrideWithValue(auth),
        profileRepositoryProvider.overrideWithValue(
          ProfileRepository(query),
        ),
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
    // HomeScreen is the Phase 1 stub rendering "Home (stub)".
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
