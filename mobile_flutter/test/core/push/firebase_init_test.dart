import 'package:connect_mobile/core/env.dart';
import 'package:connect_mobile/core/push/firebase_init.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(resetFirebaseInitForTest);

  test('ensureFirebaseInitialized is a no-op when Env.firebaseEnabled is false',
      () async {
    // Default test dart-defines have FIREBASE_ENABLED=false.
    expect(Env.firebaseEnabled, isFalse);
    final bool ok = await ensureFirebaseInitialized();
    expect(ok, isFalse, reason: 'must short-circuit when gated off');
  });

  test('ensureFirebaseInitialized is safe to call multiple times', () async {
    final bool a = await ensureFirebaseInitialized();
    final bool b = await ensureFirebaseInitialized();
    expect(a, equals(b));
  });
}
