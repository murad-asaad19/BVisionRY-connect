import 'package:connect_mobile/features/auth/data/social_auth_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../helpers/fake_supabase.dart';

void main() {
  test('signInWithApple invokes provider=apple with redirect', () async {
    final auth = FakeAuthGateway();
    OAuthProvider? prov;
    String? redirect;
    auth.onOAuth = (OAuthProvider p, {required String redirectTo}) async {
      prov = p;
      redirect = redirectTo;
      return true;
    };
    final svc = SocialAuthService(auth);
    await svc.signInWithApple();
    expect(prov, OAuthProvider.apple);
    expect(redirect, 'connect-mobile://auth');
  });

  test('signInWithGoogle invokes provider=google', () async {
    final auth = FakeAuthGateway();
    OAuthProvider? prov;
    auth.onOAuth = (OAuthProvider p, {required String redirectTo}) async {
      prov = p;
      return true;
    };
    final svc = SocialAuthService(auth);
    await svc.signInWithGoogle();
    expect(prov, OAuthProvider.google);
  });

  test('user-cancelled (returns false) yields AuthException', () async {
    final auth = FakeAuthGateway();
    auth.onOAuth = (OAuthProvider p, {required String redirectTo}) async =>
        false;
    final svc = SocialAuthService(auth);
    expect(() => svc.signInWithApple(), throwsA(isA<AuthException>()));
  });
}
