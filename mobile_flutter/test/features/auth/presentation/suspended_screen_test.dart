import 'package:connect_mobile/core/theme/app_theme.dart';
import 'package:connect_mobile/features/auth/data/auth_service.dart';
import 'package:connect_mobile/features/auth/presentation/suspended_screen.dart';
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

  testWidgets('renders title, body, appeal and sign-out buttons', (
    WidgetTester tester,
  ) async {
    final FakeAuthGateway auth = FakeAuthGateway();
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
          home: const SuspendedScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('appeal')), findsOneWidget);
    expect(find.byKey(const Key('sign-out')), findsOneWidget);
  });

  testWidgets('signOut tap calls authService.signOut', (
    WidgetTester tester,
  ) async {
    final FakeAuthGateway auth = FakeAuthGateway();
    bool called = false;
    auth.onSignOut = ({SignOutScope scope = SignOutScope.local}) async {
      called = true;
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
          home: const SuspendedScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('sign-out')));
    await tester.pumpAndSettle();
    expect(called, isTrue);
  });
}
