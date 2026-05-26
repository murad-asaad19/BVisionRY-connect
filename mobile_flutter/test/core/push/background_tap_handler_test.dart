import 'dart:async';

import 'package:connect_mobile/core/push/background_tap_handler.dart';
import 'package:connect_mobile/core/push/fcm_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeMessaging extends Fake implements FirebaseMessagingFacade {
  final StreamController<RemoteMessage> controller =
      StreamController<RemoteMessage>.broadcast();
  RemoteMessage? initial;

  @override
  Stream<RemoteMessage> get onMessageOpenedApp => controller.stream;

  @override
  Future<RemoteMessage?> getInitialMessage() async => initial;
}

void main() {
  late _FakeMessaging messaging;
  late List<String> routes;

  setUp(() {
    messaging = _FakeMessaging();
    routes = <String>[];
  });

  tearDown(() => messaging.controller.close());

  test('warm-start tap routes to the resolved path', () async {
    final BackgroundTapHandler handler = BackgroundTapHandler(
      messaging: messaging,
      navigate: routes.add,
    );
    handler.subscribe();
    messaging.controller.add(
      const RemoteMessage(
        data: <String, String>{
          'kind': 'intro_received',
          'entity_id': 'intro-warm',
        },
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 1));
    expect(routes, equals(<String>['/intros/intro-warm']));
    await handler.dispose();
  });

  test('cold-start (getInitialMessage) routes once', () async {
    messaging.initial = const RemoteMessage(
      data: <String, String>{
        'kind': 'opportunity_interest',
        'entity_id': 'opp-cold',
      },
    );
    final BackgroundTapHandler handler = BackgroundTapHandler(
      messaging: messaging,
      navigate: routes.add,
    );
    await handler.consumeInitialMessage();
    expect(routes, equals(<String>['/opportunities/opp-cold']));
  });

  test('cold-start handler is idempotent (second call is a no-op)', () async {
    messaging.initial = const RemoteMessage(
      data: <String, String>{
        'kind': 'opportunity_interest',
        'entity_id': 'opp-cold',
      },
    );
    final BackgroundTapHandler handler = BackgroundTapHandler(
      messaging: messaging,
      navigate: routes.add,
    );
    await handler.consumeInitialMessage();
    await handler.consumeInitialMessage();
    expect(routes.length, equals(1));
  });

  test('cold-start with no initial message -> no route', () async {
    final BackgroundTapHandler handler = BackgroundTapHandler(
      messaging: messaging,
      navigate: routes.add,
    );
    await handler.consumeInitialMessage();
    expect(routes, isEmpty);
  });

  test('warm-start tap with payload.url for unknown kind -> uses url',
      () async {
    final BackgroundTapHandler handler = BackgroundTapHandler(
      messaging: messaging,
      navigate: routes.add,
    );
    handler.subscribe();
    messaging.controller.add(
      const RemoteMessage(
        data: <String, String>{
          'kind': 'experimental',
          'url': '/profile/edit',
        },
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 1));
    expect(routes, equals(<String>['/profile/edit']));
    await handler.dispose();
  });
}
