// Verifies that `ToastHost` is mounted in `ConnectApp`'s widget tree so
// toasts surfaced via `toastServiceProvider` from any screen are visible
// and auto-dismiss after the configured duration.
import 'package:connect_mobile/app.dart';
import 'package:connect_mobile/core/supabase/supabase_client.dart';
import 'package:connect_mobile/core/widgets/toast.dart';
import 'package:connect_mobile/core/widgets/variants.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
      if (call.method == 'read') return null;
      if (call.method == 'readAll') return <String, String>{};
      if (call.method == 'containsKey') return false;
      return null;
    });
  });

  testWidgets(
    'ConnectApp overlays ToastHost so toasts render and auto-dismiss',
    (WidgetTester tester) async {
      final ProviderContainer container = ProviderContainer();
      await container.read(supabaseInitProvider.future);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const ConnectApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Surface a toast through the global provider the same way feature
      // screens (SignInScreen / SignUpScreen) do.
      container.read(toastServiceProvider.notifier).showToast(
            title: 'Magic link sent',
            body: 'Check your inbox.',
            intent: AppIntent.success,
          );
      await tester.pump();

      expect(find.text('Magic link sent'), findsOneWidget);
      expect(find.text('Check your inbox.'), findsOneWidget);

      // Auto-dismiss is 3.5s — pump past the timer and confirm the toast
      // disappears from the tree.
      await tester.pump(const Duration(milliseconds: 3600));
      expect(find.text('Magic link sent'), findsNothing);

      // Tear down Supabase's auto-refresh Timer.periodic so the framework
      // does not flag a pending timer after the test completes.
      Supabase.instance.client.auth.stopAutoRefresh();
      container.dispose();
      await Supabase.instance.dispose();
    },
  );
}
