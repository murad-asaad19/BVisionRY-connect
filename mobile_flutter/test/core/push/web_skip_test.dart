@TestOn('browser')
library;

import 'package:connect_mobile/core/push/firebase_init.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ensureFirebaseInitialized returns false on web even when env enabled',
      () async {
    // kIsWeb short-circuit applies even if dart-define overrides
    // FIREBASE_ENABLED to true. firebase_messaging is mobile-only in this
    // build per spec section 10.7.
    final bool ok = await ensureFirebaseInitialized();
    expect(ok, isFalse);
  });
}
