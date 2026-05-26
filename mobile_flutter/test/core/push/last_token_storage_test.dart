import 'package:connect_mobile/core/push/last_token_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  test('LastTokenStorage round-trips a token', () async {
    const LastTokenStorage storage = LastTokenStorage();
    expect(await storage.get(), isNull);
    await storage.set('fcm-token-abc');
    expect(await storage.get(), equals('fcm-token-abc'));
  });

  test('LastTokenStorage.clear removes the persisted token', () async {
    const LastTokenStorage storage = LastTokenStorage();
    await storage.set('fcm-token-abc');
    await storage.clear();
    expect(await storage.get(), isNull);
  });

  test('LastTokenStorage uses the documented key', () async {
    const LastTokenStorage storage = LastTokenStorage();
    await storage.set('fcm-token-xyz');
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('connect.fcm_last_token'), equals('fcm-token-xyz'));
  });
}
