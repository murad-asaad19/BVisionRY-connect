import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../analytics/telemetry.dart';
import 'fcm_service.dart';
import 'notification_route.dart';

typedef Navigate = void Function(String route);

/// Routes notification taps after the app is already running OR was launched
/// from a terminated state. Spec section 10.4.
///
/// - Warm start: `onMessageOpenedApp` stream is consumed continuously.
/// - Cold start: `getInitialMessage()` is awaited once after first frame.
class BackgroundTapHandler {
  BackgroundTapHandler({
    required FirebaseMessagingFacade messaging,
    required Navigate navigate,
  })  : _messaging = messaging,
        _navigate = navigate;

  final FirebaseMessagingFacade _messaging;
  final Navigate _navigate;
  StreamSubscription<RemoteMessage>? _sub;
  bool _initialConsumed = false;

  void subscribe() {
    _sub?.cancel();
    _sub = _messaging.onMessageOpenedApp.listen(_route);
  }

  Future<void> consumeInitialMessage() async {
    if (_initialConsumed) return;
    _initialConsumed = true;
    try {
      final RemoteMessage? initial = await _messaging.getInitialMessage();
      if (initial != null) _route(initial);
    } catch (e, st) {
      debugPrint('[push] getInitialMessage failed: $e\n$st');
    }
  }

  void _route(RemoteMessage message) {
    final Map<String, dynamic> data = Map<String, dynamic>.from(message.data);
    final String? url = (data['url'] as Object?)?.toString();
    final Map<String, dynamic>? payload =
        (url != null && url.isNotEmpty) ? <String, dynamic>{'url': url} : null;
    final String route = resolvePushRoute(data, payload);
    Telemetry.recordBreadcrumb(
      category: 'push',
      message: 'tap kind=${data['kind']} route=$route',
    );
    _navigate(route);
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
  }
}
