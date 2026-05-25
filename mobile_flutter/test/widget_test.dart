import 'package:connect_mobile/app.dart';
import 'package:connect_mobile/core/supabase/supabase_client.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    const MethodChannel secureStorageChannel =
        MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel,
            (MethodCall call) async {
      if (call.method == 'read') return null;
      if (call.method == 'readAll') return <String, String>{};
      if (call.method == 'containsKey') return false;
      return null;
    });
  });

  testWidgets('App boots, routes to /sign-in, renders the stub',
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
    expect(find.text('SignIn (stub)'), findsOneWidget);
    // Stop the auto-refresh Timer.periodic GoTrue spins up on init —
    // otherwise the test framework flags a pending timer after teardown.
    Supabase.instance.client.auth.stopAutoRefresh();
    container.dispose();
    await Supabase.instance.dispose();
  });
}
