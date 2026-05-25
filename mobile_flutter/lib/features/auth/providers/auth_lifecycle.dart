import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_service.dart' show AuthGateway;
import 'auth_service_provider.dart';

/// Bridges Flutter's app-lifecycle signals to the Supabase auto-refresh
/// token loop. On Android/iOS, `startAutoRefresh` schedules a timer that
/// silently rotates the access token while the app is foreground — leaving
/// it ticking while the app is paused wastes battery and burns through the
/// refresh-token rate budget, so we toggle it on every transition.
///
/// On web the underlying client owns its own timer and the call is a no-op;
/// we still guard with [kIsWeb] for clarity.
class AuthLifecycle with WidgetsBindingObserver {
  AuthLifecycle(this._auth);

  final AuthGateway _auth;
  bool _installed = false;

  /// Registers this instance with the [WidgetsBinding] and kicks off the
  /// initial auto-refresh tick (we assume the app is foreground when this
  /// is created — the very next lifecycle event will correct any race).
  void init() {
    if (_installed) return;
    _installed = true;
    WidgetsBinding.instance.addObserver(this);
    if (!kIsWeb) {
      _auth.startAutoRefresh();
    }
  }

  /// Removes the observer and stops auto-refresh. Idempotent.
  void dispose() {
    if (!_installed) return;
    _installed = false;
    WidgetsBinding.instance.removeObserver(this);
    if (!kIsWeb) {
      _auth.stopAutoRefresh();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    handleState(state);
  }

  /// Exposed for tests so they can drive lifecycle transitions without
  /// pumping the binding.
  @visibleForTesting
  void handleState(AppLifecycleState state) {
    if (kIsWeb) return;
    switch (state) {
      case AppLifecycleState.resumed:
        _auth.startAutoRefresh();
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _auth.stopAutoRefresh();
    }
  }
}

/// Owns the single [AuthLifecycle] instance for the app's lifetime. Reading
/// this provider in `main.dart` (or the root `ConsumerWidget`) installs the
/// observer; container disposal tears it back down.
final Provider<AuthLifecycle> authLifecycleProvider = Provider<AuthLifecycle>((
  Ref<AuthLifecycle> ref,
) {
  final AuthLifecycle lc = AuthLifecycle(ref.watch(authGatewayProvider));
  lc.init();
  ref.onDispose(lc.dispose);
  return lc;
});
