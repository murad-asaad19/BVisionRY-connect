import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../env.dart';
import 'firebase_init.dart';
import 'last_token_storage.dart';

/// Coarse OS notification-permission state the UI cares about. Collapses the
/// platform-specific [PermissionStatus] values into the three branches the
/// permission banner switches on (spec section 10.5):
///   * [granted]           — already authorized (incl. provisional/limited);
///     never offer "Enable".
///   * [prompt]            — not yet decided; the OS dialog can still be
///     shown, so we run the priming step then [FcmService.registerToken].
///   * [permanentlyDenied] — the OS will no longer show its dialog; the only
///     recovery is the system settings app (`openAppSettings`).
enum PushPermissionStatus { granted, prompt, permanentlyDenied }

/// Thin testable seam around FirebaseMessaging. The real implementation
/// is [DefaultMessagingFacade]; tests inject a mocktail Mock / Fake.
abstract class FirebaseMessagingFacade {
  Future<bool> requestPermission();

  /// Reads the CURRENT OS notification-permission status WITHOUT prompting,
  /// so the UI can decide between offering "Enable", running the priming
  /// flow, or surfacing the denied-recovery (open-settings) affordance.
  Future<PushPermissionStatus> currentPermissionStatus();

  Future<String?> getToken();
  Stream<String> get onTokenRefresh;
  Stream<RemoteMessage> get onMessage;
  Stream<RemoteMessage> get onMessageOpenedApp;
  Future<RemoteMessage?> getInitialMessage();
  String get platformValue;
}

/// Test seam over the slice of Supabase the FCM lifecycle touches:
/// two RPCs (`register_device_token`, `unregister_device_token`).
/// Tests inject a fake; the production adapter delegates to
/// `SupabaseClient.rpc(...)`.
abstract class FcmRpcGateway {
  Future<void> rpc(String name, {required Map<String, dynamic> params});
}

class _SupabaseFcmRpcGateway implements FcmRpcGateway {
  _SupabaseFcmRpcGateway(this._client);
  final SupabaseClient _client;

  @override
  Future<void> rpc(String name, {required Map<String, dynamic> params}) async {
    await _client.rpc<dynamic>(name, params: params);
  }
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
  Future<PushPermissionStatus> currentPermissionStatus() async {
    final PermissionStatus status = await Permission.notification.status;
    if (status.isGranted || status.isProvisional || status.isLimited) {
      return PushPermissionStatus.granted;
    }
    // `restricted` (parental controls) and `permanentlyDenied` can no longer
    // surface the OS dialog — the only path forward is system settings.
    if (status.isPermanentlyDenied || status.isRestricted) {
      return PushPermissionStatus.permanentlyDenied;
    }
    return PushPermissionStatus.prompt;
  }

  @override
  Future<String?> getToken() => FirebaseMessaging.instance.getToken();

  @override
  Stream<String> get onTokenRefresh =>
      FirebaseMessaging.instance.onTokenRefresh;

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
  /// Production constructor - wraps the supplied [SupabaseClient] with the
  /// default RPC gateway.
  FcmService({
    FirebaseMessagingFacade? messaging,
    required SupabaseClient supabase,
    LastTokenStorage tokenStorage = const LastTokenStorage(),
  })  : _messaging = messaging ?? DefaultMessagingFacade(),
        _rpc = _SupabaseFcmRpcGateway(supabase),
        _tokenStorage = tokenStorage;

  /// Test constructor - inject a fake [FcmRpcGateway] directly.
  @visibleForTesting
  FcmService.withGateway({
    required FirebaseMessagingFacade messaging,
    required FcmRpcGateway gateway,
    LastTokenStorage tokenStorage = const LastTokenStorage(),
  })  : _messaging = messaging,
        _rpc = gateway,
        _tokenStorage = tokenStorage;

  final FirebaseMessagingFacade _messaging;
  final FcmRpcGateway _rpc;
  final LastTokenStorage _tokenStorage;

  StreamSubscription<String>? _refreshSub;
  bool _permissionDenied = false;

  FirebaseMessagingFacade get messaging => _messaging;

  /// `true` after a [registerToken] call landed on
  /// [FirebaseMessagingFacade.requestPermission] returning `false`. Surfaces
  /// the one-shot permission-denied banner (Task 15).
  bool get permissionDenied => _permissionDenied;

  /// Reads the current OS notification-permission status without prompting.
  /// Returns [PushPermissionStatus.granted] when Firebase is gated off so the
  /// permission banner stays hidden on dev rigs / Expo Go parity builds.
  Future<PushPermissionStatus> permissionStatus() {
    if (!Env.firebaseEnabled) {
      return Future<PushPermissionStatus>.value(PushPermissionStatus.granted);
    }
    return _messaging.currentPermissionStatus();
  }

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
      await _rpc.rpc(
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
    await unregisterTokenValue(token);
  }

  /// Server-side deregister for an explicit [token]. Used by [unregisterToken]
  /// after reading from [LastTokenStorage] AND by [AuthService.signOut] which
  /// owns its own `FcmTokenStore` (the two storages exist for back-compat with
  /// Phase 2's pre-FCM scaffold).
  ///
  /// Best-effort: errors are logged but never thrown so sign-out never
  /// blocks on a flaky push backend.
  Future<void> unregisterTokenValue(String token) async {
    try {
      await _rpc.rpc(
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
        await _rpc.rpc(
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
