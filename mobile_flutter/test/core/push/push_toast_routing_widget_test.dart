import 'dart:async';

import 'package:connect_mobile/core/push/fcm_service.dart';
import 'package:connect_mobile/core/push/foreground_handler.dart';
import 'package:connect_mobile/features/chat/providers/active_conversation_provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeMessaging extends Fake implements FirebaseMessagingFacade {
  final StreamController<RemoteMessage> controller =
      StreamController<RemoteMessage>.broadcast();
  @override
  Stream<RemoteMessage> get onMessage => controller.stream;
}

/// End-to-end coverage of the foreground push pipeline: a fake messaging
/// facade dispatches a RemoteMessage; the ForegroundHandler resolves the
/// route via spec section 7.4 and emits via the injected showToast which
/// captures the route. Mirrors the production wiring in `_PushBootstrap`,
/// minus the ToastService queue (covered separately).
void main() {
  testWidgets('foreground message -> resolves route -> emits via showToast',
      (WidgetTester tester) async {
    final _FakeMessaging messaging = _FakeMessaging();
    String? navigated;

    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        activeConversationProvider.overrideWith((Ref<String?> ref) => null),
      ],
    );
    addTearDown(container.dispose);

    final ForegroundHandler handler = ForegroundHandler(
      messaging: messaging,
      container: container,
      showToast: (String title, String body, String route) {
        navigated = route;
      },
    )..subscribe();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold()),
      ),
    );

    messaging.controller.add(
      const RemoteMessage(
        data: <String, String>{
          'kind': 'intro_received',
          'entity_id': 'i-7',
        },
        notification: RemoteNotification(
          title: 'Ada Lovelace',
          body: 'wants to connect',
        ),
      ),
    );
    await tester.pump();
    expect(navigated, equals('/intros/i-7'));

    await handler.dispose();
    await messaging.controller.close();
  });

  testWidgets('foreground message suppressed when conversation is active',
      (WidgetTester tester) async {
    final _FakeMessaging messaging = _FakeMessaging();
    int toastCount = 0;

    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        activeConversationProvider.overrideWith(
          (Ref<String?> ref) => 'conv-active',
        ),
      ],
    );
    addTearDown(container.dispose);

    final ForegroundHandler handler = ForegroundHandler(
      messaging: messaging,
      container: container,
      showToast: (_, __, ___) => toastCount += 1,
    )..subscribe();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold()),
      ),
    );

    messaging.controller.add(
      const RemoteMessage(
        data: <String, String>{
          'kind': 'message_received',
          'conversation_id': 'conv-active',
        },
        notification: RemoteNotification(title: 't', body: 'b'),
      ),
    );
    await tester.pump();
    expect(toastCount, equals(0));

    await handler.dispose();
    await messaging.controller.close();
  });
}
