import 'dart:async';

import 'package:connect_mobile/features/chat/data/messages_service.dart';
import 'package:connect_mobile/features/chat/domain/message.dart';
import 'package:connect_mobile/features/chat/domain/message_kind.dart';
import 'package:connect_mobile/features/chat/providers/messages_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSvc extends Mock implements MessagesService {}

Message _msg(String id, DateTime at, {String? body}) => Message(
  id: id,
  conversationId: 'c1',
  senderId: 'u1',
  kind: MessageKind.text,
  createdAt: at,
  body: body ?? 'hi',
);

void main() {
  setUpAll(() {
    registerFallbackValue(DateTime.utc(2026));
  });

  test('initial fetch returns DESC list', () async {
    final svc = _MockSvc();
    final initial = [
      _msg('m3', DateTime.utc(2026, 5, 25, 10, 2)),
      _msg('m2', DateTime.utc(2026, 5, 25, 10, 1)),
      _msg('m1', DateTime.utc(2026, 5, 25, 10, 0)),
    ];
    when(
      () => svc.listMessages('c1', beforeCursor: null, limit: 30),
    ).thenAnswer((_) async => initial);
    final ctrl = StreamController<MessageRealtimeEvent>.broadcast();
    final container = ProviderContainer(
      overrides: [
        messagesServiceProvider.overrideWithValue(svc),
        messagesRealtimeProvider('c1').overrideWith((_) => ctrl.stream),
      ],
    );
    addTearDown(() async {
      await ctrl.close();
      container.dispose();
    });
    final first = await container.read(messagesProvider('c1').future);
    expect(first.map((m) => m.id), ['m3', 'm2', 'm1']);
  });

  test('INSERT prepends new message at index 0', () async {
    final svc = _MockSvc();
    when(
      () => svc.listMessages('c1', beforeCursor: null, limit: 30),
    ).thenAnswer((_) async => [_msg('m1', DateTime.utc(2026, 5, 25, 10, 0))]);
    final ctrl = StreamController<MessageRealtimeEvent>.broadcast();
    final container = ProviderContainer(
      overrides: [
        messagesServiceProvider.overrideWithValue(svc),
        messagesRealtimeProvider('c1').overrideWith((_) => ctrl.stream),
      ],
    );
    addTearDown(() async {
      await ctrl.close();
      container.dispose();
    });
    await container.read(messagesProvider('c1').future);
    // Keep the provider alive so ref.listen runs on subsequent events.
    final sub = container.listen(messagesProvider('c1'), (_, __) {});
    ctrl.add(
      MessageRealtimeEvent.insert(
        _msg('m4', DateTime.utc(2026, 5, 25, 10, 3)),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 20));
    final after = await container.read(messagesProvider('c1').future);
    expect(after.first.id, 'm4');
    expect(after, hasLength(2));
    sub.close();
  });

  test('INSERT dedupes by id', () async {
    final svc = _MockSvc();
    final m1 = _msg('m1', DateTime.utc(2026, 5, 25, 10, 0));
    when(
      () => svc.listMessages('c1', beforeCursor: null, limit: 30),
    ).thenAnswer((_) async => [m1]);
    final ctrl = StreamController<MessageRealtimeEvent>.broadcast();
    final container = ProviderContainer(
      overrides: [
        messagesServiceProvider.overrideWithValue(svc),
        messagesRealtimeProvider('c1').overrideWith((_) => ctrl.stream),
      ],
    );
    addTearDown(() async {
      await ctrl.close();
      container.dispose();
    });
    await container.read(messagesProvider('c1').future);
    final sub = container.listen(messagesProvider('c1'), (_, __) {});
    ctrl.add(MessageRealtimeEvent.insert(m1));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    final after = await container.read(messagesProvider('c1').future);
    expect(after, hasLength(1));
    sub.close();
  });

  test('UPDATE replaces row by id', () async {
    final svc = _MockSvc();
    final m1 = _msg('m1', DateTime.utc(2026, 5, 25, 10, 0));
    when(
      () => svc.listMessages('c1', beforeCursor: null, limit: 30),
    ).thenAnswer((_) async => [m1]);
    final ctrl = StreamController<MessageRealtimeEvent>.broadcast();
    final container = ProviderContainer(
      overrides: [
        messagesServiceProvider.overrideWithValue(svc),
        messagesRealtimeProvider('c1').overrideWith((_) => ctrl.stream),
      ],
    );
    addTearDown(() async {
      await ctrl.close();
      container.dispose();
    });
    await container.read(messagesProvider('c1').future);
    final sub = container.listen(messagesProvider('c1'), (_, __) {});
    ctrl.add(
      MessageRealtimeEvent.update(
        m1.copyWith(
          body: 'edited',
          editedAt: DateTime.utc(2026, 5, 25, 10, 1),
        ),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 20));
    final after = await container.read(messagesProvider('c1').future);
    expect(after.first.body, 'edited');
    expect(after.first.isEdited, isTrue);
    sub.close();
  });

  test('DELETE removes row by id', () async {
    final svc = _MockSvc();
    when(
      () => svc.listMessages('c1', beforeCursor: null, limit: 30),
    ).thenAnswer(
      (_) async => [
        _msg('m1', DateTime.utc(2026, 5, 25, 10, 0)),
        _msg('m2', DateTime.utc(2026, 5, 25, 9, 0)),
      ],
    );
    final ctrl = StreamController<MessageRealtimeEvent>.broadcast();
    final container = ProviderContainer(
      overrides: [
        messagesServiceProvider.overrideWithValue(svc),
        messagesRealtimeProvider('c1').overrideWith((_) => ctrl.stream),
      ],
    );
    addTearDown(() async {
      await ctrl.close();
      container.dispose();
    });
    await container.read(messagesProvider('c1').future);
    final sub = container.listen(messagesProvider('c1'), (_, __) {});
    ctrl.add(const MessageRealtimeEvent.delete('m1'));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    final after = await container.read(messagesProvider('c1').future);
    expect(after, hasLength(1));
    expect(after.first.id, 'm2');
    sub.close();
  });

  test('sendText inserts the returned message', () async {
    final svc = _MockSvc();
    when(
      () => svc.listMessages('c1', beforeCursor: null, limit: 30),
    ).thenAnswer((_) async => <Message>[]);
    final sent = _msg('m1', DateTime.utc(2026, 5, 25, 10), body: 'hi');
    when(
      () => svc.sendTextMessage(conversationId: 'c1', body: 'hi'),
    ).thenAnswer((_) async => sent);
    final ctrl = StreamController<MessageRealtimeEvent>.broadcast();
    final container = ProviderContainer(
      overrides: [
        messagesServiceProvider.overrideWithValue(svc),
        messagesRealtimeProvider('c1').overrideWith((_) => ctrl.stream),
      ],
    );
    addTearDown(() async {
      await ctrl.close();
      container.dispose();
    });
    await container.read(messagesProvider('c1').future);
    final notifier = container.read(messagesProvider('c1').notifier);
    await notifier.sendText('hi');
    final after = await container.read(messagesProvider('c1').future);
    expect(after.first.id, 'm1');
  });

  test('loadMore appends older page', () async {
    final svc = _MockSvc();
    final initial = List<Message>.generate(
      30,
      (i) => _msg(
        'm$i',
        DateTime.utc(2026, 5, 25, 10).subtract(Duration(minutes: i)),
      ),
    );
    when(
      () => svc.listMessages('c1', beforeCursor: null, limit: 30),
    ).thenAnswer((_) async => initial);
    when(
      () => svc.listMessages(
        'c1',
        beforeCursor: any(named: 'beforeCursor'),
        limit: 30,
      ),
    ).thenAnswer(
      (_) async => [_msg('older', DateTime.utc(2026, 5, 25, 9))],
    );
    final ctrl = StreamController<MessageRealtimeEvent>.broadcast();
    final container = ProviderContainer(
      overrides: [
        messagesServiceProvider.overrideWithValue(svc),
        messagesRealtimeProvider('c1').overrideWith((_) => ctrl.stream),
      ],
    );
    addTearDown(() async {
      await ctrl.close();
      container.dispose();
    });
    await container.read(messagesProvider('c1').future);
    final notifier = container.read(messagesProvider('c1').notifier);
    await notifier.loadMore();
    final after = await container.read(messagesProvider('c1').future);
    expect(after.last.id, 'older');
    expect(notifier.hasMore, isFalse);
  });
}
