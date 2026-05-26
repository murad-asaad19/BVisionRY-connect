import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/chat/providers/active_conversation_provider.dart';
import '../analytics/telemetry.dart';
import 'fcm_service.dart';
import 'notification_route.dart';

/// Callback shape implemented by the runtime toast-emitter (the wired
/// implementation in `app.dart` delegates to `ToastService.showToast` and
/// captures the route in the tap handler).
typedef ShowPushToast = void Function(
  String title,
  String body,
  String route,
);

/// Subscribes to FCM onMessage (foreground) and emits a push toast via
/// the injected [showToast] callback. Suppresses the toast when the
/// active conversation (Phase 7's [activeConversationProvider]) matches
/// the message's `data.conversation_id` - the user is already viewing
/// that thread.
class ForegroundHandler {
  ForegroundHandler({
    required FirebaseMessagingFacade messaging,
    required ProviderContainer container,
    required ShowPushToast showToast,
  })  : _messaging = messaging,
        _container = container,
        _showToast = showToast;

  final FirebaseMessagingFacade _messaging;
  final ProviderContainer _container;
  final ShowPushToast _showToast;
  StreamSubscription<RemoteMessage>? _sub;

  void subscribe() {
    _sub?.cancel();
    _sub = _messaging.onMessage.listen(_onMessage);
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
  }

  void _onMessage(RemoteMessage message) {
    final Map<String, dynamic> data = Map<String, dynamic>.from(message.data);
    final String? convId =
        (data['conversation_id'] as Object?)?.toString();
    final String? activeConv = _container.read(activeConversationProvider);
    if (convId != null && convId.isNotEmpty && convId == activeConv) {
      // Suppressed - the user is already in this chat.
      Telemetry.recordBreadcrumb(
        category: 'push',
        message: 'foreground.suppressed conversation_id=$convId',
      );
      return;
    }

    final String title = message.notification?.title ??
        (data['title'] as Object?)?.toString() ??
        '';
    final String body = message.notification?.body ??
        (data['body'] as Object?)?.toString() ??
        '';
    if (title.isEmpty && body.isEmpty) return;

    final String route = resolvePushRoute(data, _payloadFrom(data));
    Telemetry.recordBreadcrumb(
      category: 'push',
      message: 'foreground.shown kind=${data['kind']} route=$route',
    );
    try {
      _showToast(title, body, route);
    } catch (e, st) {
      debugPrint('[push] foreground showToast failed: $e\n$st');
    }
  }

  /// FCM `data` includes the flattened payload. We synthesise a payload
  /// map (containing `url` if present) so [resolvePushRoute] can fall
  /// through to the legacy server-rendered path on unknown kinds.
  Map<String, dynamic>? _payloadFrom(Map<String, dynamic> data) {
    final String? url = (data['url'] as Object?)?.toString();
    if (url == null || url.isEmpty) return null;
    return <String, dynamic>{'url': url};
  }
}
