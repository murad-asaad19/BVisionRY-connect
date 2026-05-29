import 'package:connect_mobile/core/errors/app_exception.dart';
import 'package:connect_mobile/features/intros/data/intros_service.dart';
import 'package:connect_mobile/features/intros/domain/intro_enums.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../helpers/intros_fixtures.dart';

class _FakeIntrosGateway extends Mock implements IntrosGateway {}

void main() {
  setUpAll(() => registerFallbackValue(<String, dynamic>{}));

  group('IntrosService.sendIntro', () {
    late _FakeIntrosGateway gateway;
    late IntrosService service;

    setUp(() {
      gateway = _FakeIntrosGateway();
      service = IntrosService(gateway);
    });

    test('happy path calls send_intro with trimmed note and returns Intro',
        () async {
      final fixture = buildIntro();
      when(
        () => gateway.rpc('send_intro', params: any(named: 'params')),
      ).thenAnswer((_) async => fixture.toJson());

      final result = await service.sendIntro(
        recipientId: 'recipient-1',
        note: '  ${'a' * 100}  ',
      );

      expect(result.id, fixture.id);
      expect(result.state, IntroState.delivered);
      final captured = verify(
        () => gateway.rpc('send_intro', params: captureAny(named: 'params')),
      ).captured.single as Map<String, dynamic>;
      expect(captured['p_recipient_id'], 'recipient-1');
      expect((captured['p_note'] as String).length, 100);
    });

    void stubError(PostgrestException ex) {
      when(
        () => gateway.rpc('send_intro', params: any(named: 'params')),
      ).thenThrow(ex);
    }

    test('maps 28000 -> UnauthenticatedException', () async {
      stubError(const PostgrestException(message: '', code: '28000'));
      expect(
        () => service.sendIntro(recipientId: 'r', note: 'x' * 100),
        throwsA(isA<UnauthenticatedException>()),
      );
    });

    test('maps P0001 cooldown -> IntroCooldownException', () async {
      stubError(
        const PostgrestException(message: '', code: 'P0001', hint: 'cooldown'),
      );
      expect(
        () => service.sendIntro(recipientId: 'r', note: 'x' * 100),
        throwsA(isA<IntroCooldownException>()),
      );
    });

    test('maps P0001 daily_cap -> DailyCapException', () async {
      stubError(
        const PostgrestException(
          message: '',
          code: 'P0001',
          hint: 'daily_cap',
        ),
      );
      expect(
        () => service.sendIntro(recipientId: 'r', note: 'x' * 100),
        throwsA(isA<DailyCapException>()),
      );
    });

    test('maps 23505 -> DuplicateException', () async {
      stubError(const PostgrestException(message: '', code: '23505'));
      expect(
        () => service.sendIntro(recipientId: 'r', note: 'x' * 100),
        throwsA(isA<DuplicateException>()),
      );
    });

    test('maps P0002 -> NotOnboardedException', () async {
      stubError(const PostgrestException(message: '', code: 'P0002'));
      expect(
        () => service.sendIntro(recipientId: 'r', note: 'x' * 100),
        throwsA(isA<NotOnboardedException>()),
      );
    });

    test('maps 22023 note-range -> IntroNoteRangeException', () async {
      stubError(
        const PostgrestException(
          message: 'char_length(btrim(note))',
          code: '22023',
        ),
      );
      expect(
        () => service.sendIntro(recipientId: 'r', note: 'short'),
        throwsA(isA<IntroNoteRangeException>()),
      );
    });
  });

  group('IntrosService.acceptIntro', () {
    late _FakeIntrosGateway gateway;
    late IntrosService service;

    setUp(() {
      gateway = _FakeIntrosGateway();
      service = IntrosService(gateway);
    });

    test('returns Intro with conversation_id on success', () async {
      final fixture = buildIntro(
        state: IntroState.connected,
        conversationId: 'conv-1',
      );
      when(
        () => gateway.rpc('accept_intro', params: any(named: 'params')),
      ).thenAnswer((_) async => fixture.toJson());

      final result = await service.acceptIntro('intro-1');
      expect(result.conversationId, 'conv-1');
      expect(result.state, IntroState.connected);
      final captured = verify(
        () => gateway.rpc('accept_intro', params: captureAny(named: 'params')),
      ).captured.single as Map<String, dynamic>;
      expect(captured['p_intro_id'], 'intro-1');
    });

    test('maps 22023 wrong-kind -> WrongIntroKindException', () async {
      when(
        () => gateway.rpc('accept_intro', params: any(named: 'params')),
      ).thenThrow(
        const PostgrestException(message: 'wrong intro kind', code: '22023'),
      );
      expect(
        () => service.acceptIntro('warm-1'),
        throwsA(isA<WrongIntroKindException>()),
      );
    });
  });

  group('IntrosService.declineIntro', () {
    test('returns Intro with state=declined', () async {
      final gateway = _FakeIntrosGateway();
      final service = IntrosService(gateway);
      final fixture = buildIntro(state: IntroState.declined);
      when(
        () => gateway.rpc('decline_intro', params: any(named: 'params')),
      ).thenAnswer((_) async => fixture.toJson());

      final result = await service.declineIntro('intro-1');
      expect(result.state, IntroState.declined);
    });
  });

  group('IntrosService.introsTodayCount', () {
    test('returns int from RPC', () async {
      final gateway = _FakeIntrosGateway();
      final service = IntrosService(gateway);
      when(
        () => gateway.rpc('intros_today_count'),
      ).thenAnswer((_) async => 7);
      expect(await service.introsTodayCount(), 7);
    });

    test('maps PostgrestException through error_map', () async {
      final gateway = _FakeIntrosGateway();
      final service = IntrosService(gateway);
      when(
        () => gateway.rpc('intros_today_count'),
      ).thenThrow(const PostgrestException(message: '', code: '28000'));
      expect(
        () => service.introsTodayCount(),
        throwsA(isA<UnauthenticatedException>()),
      );
    });
  });

  group('IntrosService.introsSentTodayCount', () {
    test('returns (used, cap) from a bare-map RPC row', () async {
      final gateway = _FakeIntrosGateway();
      final service = IntrosService(gateway);
      when(
        () => gateway.rpc('intros_sent_today_count'),
      ).thenAnswer((_) async => <String, dynamic>{'used': 3, 'cap': 5});
      final result = await service.introsSentTodayCount();
      expect(result.used, 3);
      expect(result.cap, 5);
    });

    test('normalises a one-element list RPC row', () async {
      final gateway = _FakeIntrosGateway();
      final service = IntrosService(gateway);
      when(() => gateway.rpc('intros_sent_today_count')).thenAnswer(
        (_) async => <Map<String, dynamic>>[
          <String, dynamic>{'used': 12, 'cap': 15},
        ],
      );
      final result = await service.introsSentTodayCount();
      expect(result.used, 12);
      expect(result.cap, 15);
    });

    test('maps PostgrestException through error_map', () async {
      final gateway = _FakeIntrosGateway();
      final service = IntrosService(gateway);
      when(
        () => gateway.rpc('intros_sent_today_count'),
      ).thenThrow(const PostgrestException(message: '', code: '28000'));
      expect(
        () => service.introsSentTodayCount(),
        throwsA(isA<UnauthenticatedException>()),
      );
    });
  });

  group('IntrosService.listReceivedIntros', () {
    test('parses rows from the gateway', () async {
      final gateway = _FakeIntrosGateway();
      final service = IntrosService(gateway);
      final fixture = buildIntro();
      when(
        () => gateway.selectReceivedIntros(any()),
      ).thenAnswer((_) async => <Map<String, dynamic>>[fixture.toJson()]);

      final result = await service.listReceivedIntros(viewerId: 'me');
      expect(result, hasLength(1));
      expect(result.single.id, fixture.id);
      verify(() => gateway.selectReceivedIntros('me')).called(1);
    });

    test('maps PostgrestException through error_map', () async {
      final gateway = _FakeIntrosGateway();
      final service = IntrosService(gateway);
      when(
        () => gateway.selectReceivedIntros(any()),
      ).thenThrow(const PostgrestException(message: '', code: '28000'));
      expect(
        () => service.listReceivedIntros(viewerId: 'me'),
        throwsA(isA<UnauthenticatedException>()),
      );
    });
  });

  group('IntrosService.listSentIntros', () {
    test('parses rows from the gateway', () async {
      final gateway = _FakeIntrosGateway();
      final service = IntrosService(gateway);
      final fixture = buildIntro(senderId: 'me');
      when(
        () => gateway.selectSentIntros(any()),
      ).thenAnswer((_) async => <Map<String, dynamic>>[fixture.toJson()]);

      final result = await service.listSentIntros(viewerId: 'me');
      expect(result, hasLength(1));
      verify(() => gateway.selectSentIntros('me')).called(1);
    });
  });
}
