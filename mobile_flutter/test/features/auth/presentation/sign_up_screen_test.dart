import 'package:connect_mobile/core/theme/app_theme.dart';
import 'package:connect_mobile/features/auth/data/auth_service.dart';
import 'package:connect_mobile/features/auth/presentation/sign_up_screen.dart';
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

  Future<void> pump(WidgetTester tester, AuthService svc) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[authServiceProvider.overrideWithValue(svc)],
        child: MaterialApp(
          theme: buildAppTheme(Brightness.light),
          home: const SignUpScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('live 8-char hint flips state at 8+', (
    WidgetTester tester,
  ) async {
    final FakeAuthGateway auth = FakeAuthGateway();
    final AuthService svc = AuthService(
      auth: auth,
      functions: FakeFunctionsGateway(),
      tokens: FcmTokenStore(),
      stores: PersistedStores(),
    );
    await pump(tester, svc);
    await tester.enterText(find.byKey(const Key('password-input')), 'short');
    await tester.pump();
    expect(find.byKey(const Key('pwd-hint-bad')), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('password-input')),
      'longenough',
    );
    await tester.pump();
    expect(find.byKey(const Key('pwd-hint-ok')), findsOneWidget);
  });

  testWidgets('submits via authService.signUpWithPassword', (
    WidgetTester tester,
  ) async {
    final FakeAuthGateway auth = FakeAuthGateway();
    String? capEmail;
    auth.onSignUp =
        ({
          required String email,
          required String password,
          required String emailRedirectTo,
        }) async {
          capEmail = email;
          return AuthResponse(session: fakeSession(), user: fakeSession().user);
        };
    final AuthService svc = AuthService(
      auth: auth,
      functions: FakeFunctionsGateway(),
      tokens: FcmTokenStore(),
      stores: PersistedStores(),
    );
    await pump(tester, svc);
    await tester.enterText(find.byKey(const Key('email-input')), 'a@b.com');
    await tester.enterText(
      find.byKey(const Key('password-input')),
      'pw345678',
    );
    await tester.tap(find.byKey(const Key('signup-submit')));
    await tester.pumpAndSettle();
    expect(capEmail, 'a@b.com');
  });
}
