import 'dart:async';

import 'package:flutter/foundation.dart';

/// Adapts a [Stream] to a [Listenable] for GoRouter's `refreshListenable`
/// argument. Every event on the source stream is forwarded as a single
/// `notifyListeners()` call so the router re-evaluates its `redirect:`
/// callback. Subscribes via `asBroadcastStream()` so the same stream can
/// also be consumed by Riverpod elsewhere.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _sub = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

/// Plain [ChangeNotifier] with a public `bump()` so callers (e.g.
/// `appRouterProvider`'s `ref.listen` callbacks) can trigger GoRouter's
/// refresh without reaching into the protected `notifyListeners()` API.
class RouterRefreshNotifier extends ChangeNotifier {
  void bump() => notifyListeners();
}
