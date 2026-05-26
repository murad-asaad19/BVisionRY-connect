import 'package:shared_preferences/shared_preferences.dart';

/// Persists the most-recently-registered FCM token so that the sign-out
/// path can call `unregister_device_token` even after the in-memory
/// FirebaseMessaging instance has rotated.
///
/// Key matches the spec §10.3 contract: `last_fcm_token`.
class LastTokenStorage {
  const LastTokenStorage();
  static const String _key = 'last_fcm_token';

  Future<String?> get() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }

  Future<void> set(String token) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, token);
  }

  Future<void> clear() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
