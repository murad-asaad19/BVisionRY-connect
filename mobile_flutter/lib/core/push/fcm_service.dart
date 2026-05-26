import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../env.dart';
import 'firebase_init.dart';
import 'last_token_storage.dart';

/// Thin testable seam around FirebaseMessaging. The real implementation
/// is [DefaultMessagingFacade]; tests inject a mocktail Mock / Fake.
abstract class FirebaseMessagingFacade {
  Future<bool> requestPermission();
  Future<String?> getToken();
  Stream<String> get onTokenRefresh;
  Stream<RemoteMessage> get onMessage;
  Stream<RemoteMessage> get onMessageOpenedApp;
  Future<RemoteMessage?> getInitialMessage();
  String get platformValue;
}

class DefaultMessagingFacade implements FirebaseMessagingFacade {
  @override
  Future<bool> requestPermission() async {
    final NotificationSettings settings =
        await FirebaseMessaging.instance.requestPermission();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  @override
  Future<String?> getToken() => FirebaseMessaging.instance.getToken();

  @override
  Stream<String> get onTokenRefresh => FirebaseMessaging.instance.onTokenRefresh;

  @override
  Stream<RemoteMessage> get onMessage => FirebaseMessaging.onMessage;

  @override
  Stream<RemoteMessage> get onMessageOpenedApp =>
      FirebaseMessaging.onMessageOpenedApp;

  @override
  Future<RemoteMessage?> getInitialMessage() =>
      FirebaseMessaging.instance.getInitialMessage();

  @override
  String get platformValue {
    if (kIsWeb) return 'web';
    if (Platform.isIOS) return 'ios';
    return 'android';
  }
}

/// FCM lifecycle owner: token register/unregister against the Supabase RPCs,
/// permission prompt, and onTokenRefresh re-registration.
///
/// Spec section 10 + 3.9. Every method short-circuits gracefully when
/// [Env.firebaseEnabled] is false (Expo Go parity / dev rigs without a
/// google-services.json).
class FcmService {
  FcmService({
    FirebaseMessagingFacade? messaging,
    required SupabaseClient supabase,
    LastTokenStorage tokenStorage = const LastTokenStorage(),
  })  : _messaging = messaging ?? DefaultMessagingFacade(),
        _supabase = supabase,
        _tokenStorage = tokenStorage;

  final FirebaseMessagingFacade _messaging;
  final SupabaseClient _supabase;
  final LastTokenStorage _tokenStorage;

  StreamSubscription<String>? _refreshSub;
  bool _permissionDenied = false;

  FirebaseMessagingFacade get messaging => _messaging;

  /// `true` after a [registerToken] call landed on
  /// [FirebaseMessagingFacade.requestPermission] returning `false`. Surfaces
  /// the one-shot permission-denied banner (Task 15).
  bool get permissionDenied => _permissionDenied;

  /// Returns true once Firebase is ready, false when gated off.
  Future<bool> initialize() => ensureFirebaseInitialized();

  /// Asks for permission, fetches the FCM token, registers it server-side,
  /// and persists it for the sign-out path.
  ///
  /// Returns true on a successful register, false on:
  /// - Env.firebaseEnabled = false
  /// - permission denied
  /// - 28000 (token bound to another user - device-handoff race)
  /// - any other unexpected failure (logged via debugPrint)
  Future<bool> registerToken() async {
    if (!Env.firebaseEnabled) return false;
    final bool granted = await _messaging.requestPermission();
    if (!granted) {
      _permissionDenied = true;
      debugPrint('[fcm] permission denied');
      return false;
    }
    _permissionDenied = false;
    final String? token = await _messaging.getToken();
    if (token == null || token.isEmpty) return false;
    try {
      await _supabase.rpc<dynamic>(
        'register_device_token',
        params: <String, dynamic>{
          'p_token': token,
          'p_platform': _messaging.platformValue,
        },
      );
      await _tokenStorage.set(token);
      return true;
    } on PostgrestException catch (e) {
      if (e.code == '28000') {
        // Token bound to another live user - device handoff is expected.
        debugPrint(
          '[fcm] register_device_token 28000 (handoff): ${e.message}',
        );
        return false;
      }
      debugPrint(
        '[fcm] register_device_token failed: ${e.code} ${e.message}',
      );
      return false;
    } catch (e, st) {
      debugPrint('[fcm] register_device_token exception: $e\n$st');
      return false;
    }
  }

  /// Called from the auth sign-out path BEFORE `supabase.auth.signOut`.
  /// Reads the last persisted token; if absent, no-ops.
  Future<void> unregisterToken() async {
    final String? token = await _tokenStorage.get();
    if (token == null || token.isEmpty) return;
    try {
      await _supabase.rpc<dynamic>(
        'unregister_device_token',
        params: <String, dynamic>{'p_token': token},
      );
    } catch (e) {
      debugPrint('[fcm] unregister_device_token failed (best-effort): $e');
    } finally {
      await _tokenStorage.clear();
    }
  }

  /// Subscribes to onTokenRefresh and re-registers every rotated token.
  void subscribeTokenRefresh() {
    _refreshSub?.cancel();
    _refreshSub = _messaging.onTokenRefresh.listen((String token) async {
      try {
        await _supabase.rpc<dynamic>(
          'register_device_token',
          params: <String, dynamic>{
            'p_token': token,
            'p_platform': _messaging.platformValue,
          },
        );
        await _tokenStorage.set(token);
      } catch (e) {
        debugPrint('[fcm] token-refresh re-register failed: $e');
      }
    });
  }

  Future<void> dispose() async {
    await _refreshSub?.cancel();
    _refreshSub = null;
  }
}
