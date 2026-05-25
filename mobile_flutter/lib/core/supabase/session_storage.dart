import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// [LocalStorage] backed by `flutter_secure_storage`.
///
/// Sessions are persisted in the Keychain on iOS and EncryptedSharedPreferences
/// on Android (default `aOptions`). This keeps refresh tokens off the device's
/// plain-text shared prefs, which is required for the security review in
/// Phase 14.
class SecureSessionStorage extends LocalStorage {
  SecureSessionStorage([
    this._secure = const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    ),
  ]);

  final FlutterSecureStorage _secure;
  static const String _key = 'connect.session';

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() async =>
      (await _secure.read(key: _key)) != null;

  @override
  Future<String?> accessToken() => _secure.read(key: _key);

  @override
  Future<void> persistSession(String persistSessionString) =>
      _secure.write(key: _key, value: persistSessionString);

  @override
  Future<void> removePersistedSession() => _secure.delete(key: _key);
}
