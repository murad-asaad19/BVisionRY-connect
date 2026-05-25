import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_redirect.dart';
import 'auth_service.dart' show AuthGateway;

/// Apple + Google OAuth entry points. Delegates the browser flow launch to
/// [AuthGateway.signInWithOAuth]; cancellation (the gateway returning
/// `false`) is mapped to an [AuthException] tagged `oauth_cancelled` so the
/// shared `mapAuthError` can render the standard cancelled-OAuth toast.
class SocialAuthService {
  SocialAuthService(this._auth);
  final AuthGateway _auth;

  Future<void> signInWithApple() => _start(OAuthProvider.apple);
  Future<void> signInWithGoogle() => _start(OAuthProvider.google);

  Future<void> _start(OAuthProvider provider) async {
    final launched = await _auth.signInWithOAuth(
      provider,
      redirectTo: authRedirectUri(),
    );
    if (!launched) {
      throw const AuthException('oauth_cancelled');
    }
  }
}
