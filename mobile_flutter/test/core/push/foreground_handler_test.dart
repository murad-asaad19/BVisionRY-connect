import 'dart:async';

import 'package:connect_mobile/core/push/fcm_service.dart';
import 'package:connect_mobile/core/push/foreground_handler.dart';
import 'package:connect_mobile/features/chat/providers/active_conversation_provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeMessaging extends Fake implements FirebaseMessagingFacade {
  final StreamController<RemoteMessage> controller =
      StreamController<RemoteMessage>.broadcast();
  @override
  Stream<RemoteMessage> get onMessage => controller.stream;
}

typedef ToastRecord = ({String title, String body, String route});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeMessaging messaging;
  late List<ToastRecord> toasts;

  setUp(() {
    messaging = _FakeMessaging();
    toasts = <ToastRecord>[];
  });

  tearDown(() async {
    await messaging.controller.close();
  });

  ProviderContainer makeContainer({String? activeConv}) {
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        activeConversationProvider.overrideWith((Ref<String?> ref) => activeConv),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('non-conversation push shows a toast', () async {
    final ProviderContainer container = makeContainer();
    final ForegroundHandler handler = ForegroundHandler(
      messaging: messaging,
      container: container,
      showToast: (String title, String body, String route) =>
          toasts.add((title: title, body: body, route: route)),
    );
    handler.subscribe();

    messaging.controller.add(
      RemoteMessage(
        data: const <String, String>{
          'kind': 'intro_received',
          'entity_id': 'intro-1',
        },
        notification: const RemoteNotification(
          title: 'New intro',
          body: 'From Ada',
        ),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 1));
    expect(toasts, hasLength(1));
    expect(toasts.first.route, equals('/intros/intro-1'));
    expect(toasts.first.title, equals('New intro'));
    expect(toasts.first.body, equals('From Ada'));

    await handler.dispose();
  });

  test(
      'suppression: active conversation matches data.conversation_id -> no toast',
      () async {
    final ProviderContainer container = makeContainer(activeConv: 'conv-1');
    final ForegroundHandler handler = ForegroundHandler(
      messaging: messaging,
      container: container,
      showToast: (String title, String body, String route) =>
          toasts.add((title: title, body: body, route: route)),
    );
    handler.subscribe();
    messaging.controller.add(
      RemoteMessage(
        data: const <String, String>{
          'kind': 'message_received',
          'conversation_id': 'conv-1',
        },
        notification: const RemoteNotification(title: 't', body: 'b'),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 1));
    expect(toasts, isEmpty);

    await handler.dispose();
  });

  test('different active conversation -> toast still shown', () async {
    final ProviderContainer container =
        makeContainer(activeConv: 'conv-OTHER');
    final ForegroundHandler handler = ForegroundHandler(
      messaging: messaging,
      container: container,
      showToast: (String title, String body, String route) =>
          toasts.add((title: title, body: body, route: route)),
    );
    handler.subscribe();
    messaging.controller.add(
      RemoteMessage(
        data: const <String, String>{
          'kind': 'message_received',
          'conversation_id': 'conv-1',
        },
        notification: const RemoteNotification(title: 't', body: 'b'),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 1));
    expect(toasts, hasLength(1));
    expect(toasts.first.route, equals('/chats/conv-1'));

    await handler.dispose();
  });

  test('missing notification title/body -> uses payload.title/body fallback',
      () async {
    final ProviderContainer container = makeContainer();
    final ForegroundHandler handler = ForegroundHandler(
      messaging: messaging,
      container: container,
      showToast: (String title, String body, String route) =>
          toasts.add((title: title, body: body, route: route)),
    );
    handler.subscribe();
    messaging.controller.add(
      RemoteMessage(
        data: const <String, String>{
          'kind': 'message_received',
          'conversation_id': 'conv-2',
          'title': 'From payload',
          'body': 'Body from payload',
        },
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 1));
    expect(toasts.first.title, equals('From payload'));
    expect(toasts.first.body, equals('Body from payload'));

    await handler.dispose();
  });

  test('completely empty payload -> no toast', () async {
    final ProviderContainer container = makeContainer();
    final ForegroundHandler handler = ForegroundHandler(
      messaging: messaging,
      container: container,
      showToast: (String title, String body, String route) =>
          toasts.add((title: title, body: body, route: route)),
    );
    handler.subscribe();
    messaging.controller.add(RemoteMessage(data: const <String, String>{}));
    await Future<void>.delayed(const Duration(milliseconds: 1));
    expect(toasts, isEmpty);

    await handler.dispose();
  });

  test('unknown kind with payload.url -> uses payload.url route', () async {
    final ProviderContainer container = makeContainer();
    final ForegroundHandler handler = ForegroundHandler(
      messaging: messaging,
      container: container,
      showToast: (String title, String body, String route) =>
          toasts.add((title: title, body: body, route: route)),
    );
    handler.subscribe();
    messaging.controller.add(
      RemoteMessage(
        data: const <String, String>{
          'kind': 'experimental',
          'url': '/profile/edit',
        },
        notification: const RemoteNotification(title: 't', body: 'b'),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 1));
    expect(toasts.single.route, equals('/profile/edit'));

    await handler.dispose();
  });
}
