import 'package:connect_mobile/core/theme/app_theme.dart';
import 'package:connect_mobile/features/auth/data/auth_service.dart';
import 'package:connect_mobile/features/auth/data/social_auth_service.dart';
import 'package:connect_mobile/features/auth/presentation/sign_in_screen.dart';
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

  Future<void> pumpScreen(
    WidgetTester tester, {
    required FakeAuthGateway auth,
    required FakeFunctionsGateway fn,
  }) async {
    final AuthService svc = AuthService(
      auth: auth,
      functions: fn,
      tokens: FcmTokenStore(),
      stores: PersistedStores(),
    );
    final SocialAuthService social = SocialAuthService(auth);
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          authServiceProvider.overrideWithValue(svc),
          socialAuthServiceProvider.overrideWithValue(social),
        ],
        child: MaterialApp(
          theme: buildAppTheme(Brightness.light),
          home: const SignInScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('submits email + password via signInWithIdentifier', (
    WidgetTester tester,
  ) async {
    final FakeAuthGateway auth = FakeAuthGateway();
    String? capEmail;
    String? capPwd;
    auth.onSignIn = ({required String email, required String password}) async {
      capEmail = email;
      capPwd = password;
      return AuthResponse(session: fakeSession(), user: fakeSession().user);
    };
    await pumpScreen(tester, auth: auth, fn: FakeFunctionsGateway());
    await tester.enterText(
      find.byKey(const Key('identifier-input')),
      'user@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('password-input')),
      'pw345678',
    );
    await tester.tap(find.byKey(const Key('submit-button')));
    await tester.pumpAndSettle();
    expect(capEmail, 'user@example.com');
    expect(capPwd, 'pw345678');
  });

  testWidgets('forgot-password refuses non-email identifier', (
    WidgetTester tester,
  ) async {
    final FakeAuthGateway auth = FakeAuthGateway();
    bool called = false;
    auth.onOtp =
        ({required String email, required String emailRedirectTo}) async {
      called = true;
    };
    await pumpScreen(tester, auth: auth, fn: FakeFunctionsGateway());
    await tester.enterText(
      find.byKey(const Key('identifier-input')),
      '@murad',
    );
    await tester.tap(find.byKey(const Key('forgot-password-link')));
    await tester.pumpAndSettle();
    // Non-email input: dialog opens with instructions, magic link never fires.
    expect(called, isFalse);
    expect(find.text('OK'), findsOneWidget);
  });

  testWidgets('forgot-password sends magic link on real email identifier', (
    WidgetTester tester,
  ) async {
    final FakeAuthGateway auth = FakeAuthGateway();
    String? capEmail;
    auth.onOtp =
        ({required String email, required String emailRedirectTo}) async {
      capEmail = email;
    };
    await pumpScreen(tester, auth: auth, fn: FakeFunctionsGateway());
    await tester.enterText(
      find.byKey(const Key('identifier-input')),
      'a@b.com',
    );
    await tester.tap(find.byKey(const Key('forgot-password-link')));
    await tester.pumpAndSettle();
    expect(capEmail, 'a@b.com');
  });

  testWidgets('forgot password with empty identifier opens dialog', (
    WidgetTester tester,
  ) async {
    await pumpScreen(
      tester,
      auth: FakeAuthGateway(),
      fn: FakeFunctionsGateway(),
    );
    await tester.tap(find.byKey(const Key('forgot-password-link')));
    await tester.pumpAndSettle();
    expect(find.text('OK'), findsOneWidget);
  });
}
