import 'package:shared_preferences/shared_preferences.dart';

/// Persists the most-recently-registered FCM token so we can deregister it
/// on sign-out. Full lifecycle (refresh, permissions) is implemented in
/// Phase 12; here we expose the read/write/clear surface AuthService needs.
class FcmTokenStore {
  static const String _key = 'connect.fcm_last_token';

  /// Returns the persisted token, or `null` when no token has been stored.
  Future<String?> read() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_key);
  }

  /// Persists [token] so it can be retrieved on the next sign-out cycle.
  Future<void> write(String token) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, token);
  }

  /// Removes the persisted token (called immediately after deregistration
  /// during sign-out).
  Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_key);
  }
}
