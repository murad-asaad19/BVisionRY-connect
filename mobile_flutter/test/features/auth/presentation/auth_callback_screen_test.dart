import 'package:connect_mobile/core/theme/app_theme.dart';
import 'package:connect_mobile/features/auth/data/auth_service.dart';
import 'package:connect_mobile/features/auth/presentation/auth_callback_screen.dart';
import 'package:connect_mobile/features/auth/providers/auth_service_provider.dart';
import 'package:connect_mobile/features/push/data/fcm_token_store.dart';
import 'package:connect_mobile/features/settings/data/persisted_stores.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../helpers/fake_supabase.dart';

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

  testWidgets('shows spinner then settles when exchange succeeds', (
    WidgetTester tester,
  ) async {
    final FakeAuthGateway auth = FakeAuthGateway();
    auth.onExchange = (String code) async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      return AuthSessionUrlResponse(
        session: fakeSession(),
        redirectType: 'recovery',
      );
    };
    final AuthService svc = AuthService(
      auth: auth,
      functions: FakeFunctionsGateway(),
      tokens: FcmTokenStore(),
      stores: PersistedStores(),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[authServiceProvider.overrideWithValue(svc)],
        child: MaterialApp(
          theme: buildAppTheme(Brightness.light),
          home: AuthCallbackScreen(
            uri: Uri.parse('connect-mobile://auth?code=abc'),
          ),
        ),
      ),
    );
    await tester.pump(); // initial frame
    await tester.pump(); // post-frame
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 200));
    // success is silent — the route guard performs the redirect; spinner
    // stays up until the navigator pushes us elsewhere.
    expect(find.byKey(const Key('callback-retry')), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows error retry + back-to-signin on failure', (
    WidgetTester tester,
  ) async {
    final FakeAuthGateway auth = FakeAuthGateway();
    auth.onExchange =
        (String code) async => throw const AuthException('expired');
    final AuthService svc = AuthService(
      auth: auth,
      functions: FakeFunctionsGateway(),
      tokens: FcmTokenStore(),
      stores: PersistedStores(),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[authServiceProvider.overrideWithValue(svc)],
        child: MaterialApp(
          theme: buildAppTheme(Brightness.light),
          home: AuthCallbackScreen(
            uri: Uri.parse('connect-mobile://auth?code=abc'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('callback-retry')), findsOneWidget);
    expect(find.byKey(const Key('callback-back-to-signin')), findsOneWidget);
  });
}
