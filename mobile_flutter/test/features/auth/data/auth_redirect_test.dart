import 'package:connect_mobile/features/auth/data/auth_redirect.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('authRedirectUri uses connect-mobile scheme + /auth path', () {
    expect(authRedirectUri(), equals('connect-mobile://auth'));
  });

  test('authRedirectUri respects override scheme', () {
    expect(authRedirectUri(scheme: 'myapp'), equals('myapp://auth'));
  });
}
