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
    // flutter_secure_storage's method channel isn't backed by a platform impl
    // in tests; stub it so initialise() and any later session writes succeed.
    const MethodChannel secureStorageChannel =
        MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, (MethodCall call) async {
      if (call.method == 'read') return null;
      if (call.method == 'readAll') return <String, String>{};
      if (call.method == 'containsKey') return false;
      return null;
    });
  });

  test('supabaseClientProvider returns a configured SupabaseClient', () async {
    final ProviderContainer container = ProviderContainer();
    await container.read(supabaseInitProvider.future);
    final SupabaseClient client = container.read(supabaseClientProvider);
    // The Supabase singleton is the same instance the rest of the app uses,
    // its auth subsystem is wired, and the default client info header is set.
    expect(client, same(Supabase.instance.client));
    expect(client.auth, isA<GoTrueClient>());
    expect(client.headers, containsPair('X-Client-Info', isNotEmpty));
    container.dispose();
  });
}
