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

import '../../helpers/fake_supabase.dart';

class _Q implements ProfileQueryRunner {
  _Q(this.row);
  final Map<String, dynamic>? row;
  @override
  Future<Map<String, dynamic>?> selectById(String id) async => row;
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

  testWidgets('with no session, app shows the SignIn screen', (
    WidgetTester tester,
  ) async {
    final FakeAuthGateway auth = FakeAuthGateway();
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          authGatewayProvider.overrideWithValue(auth),
          profileRepositoryProvider.overrideWithValue(
            ProfileRepository(_Q(null)),
          ),
        ],
        child: Builder(
          builder: (BuildContext ctx) {
            return MaterialApp.router(
              theme: buildAppTheme(Brightness.light),
              routerConfig: ProviderScope.containerOf(ctx).read(
                appRouterProvider,
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    // SignInScreen renders the BVisionRY wordmark from AuthShell.
    expect(find.text('BVisionRY'), findsOneWidget);
  });

  testWidgets('session + onboarded → routes to /home', (
    WidgetTester tester,
  ) async {
    final FakeAuthGateway auth = FakeAuthGateway();
    auth.pushAuthState(
      AuthChangeEvent.initialSession,
      fakeSession(id: 'u'),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          authGatewayProvider.overrideWithValue(auth),
          profileRepositoryProvider.overrideWithValue(
            ProfileRepository(
              _Q(<String, dynamic>{
                'id': 'u',
                'onboarded': true,
                'suspended_at': null,
              }),
            ),
          ),
        ],
        child: Builder(
          builder: (BuildContext ctx) {
            return MaterialApp.router(
              theme: buildAppTheme(Brightness.light),
              routerConfig: ProviderScope.containerOf(ctx).read(
                appRouterProvider,
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Home'), findsWidgets);
  });

  testWidgets('session + suspended → routes to /suspended', (
    WidgetTester tester,
  ) async {
    final FakeAuthGateway auth = FakeAuthGateway();
    auth.pushAuthState(
      AuthChangeEvent.initialSession,
      fakeSession(id: 'u'),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          authGatewayProvider.overrideWithValue(auth),
          profileRepositoryProvider.overrideWithValue(
            ProfileRepository(
              _Q(<String, dynamic>{
                'id': 'u',
                'onboarded': true,
                'suspended_at': DateTime.now().toIso8601String(),
              }),
            ),
          ),
        ],
        child: Builder(
          builder: (BuildContext ctx) {
            return MaterialApp.router(
              theme: buildAppTheme(Brightness.light),
              routerConfig: ProviderScope.containerOf(ctx).read(
                appRouterProvider,
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('sign-out')), findsOneWidget);
  });
}
