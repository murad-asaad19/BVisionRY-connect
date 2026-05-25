import 'package:connect_mobile/core/errors/app_exception.dart';
import 'package:connect_mobile/features/intros/data/warm_intros_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../helpers/intros_fixtures.dart';

class _FakeWarmGateway extends Mock implements WarmIntrosGateway {}

void main() {
  setUpAll(() => registerFallbackValue(<String, dynamic>{}));

  group('suggestWarmIntros', () {
    test('returns list of WarmSuggestion with passed limit', () async {
      final gateway = _FakeWarmGateway();
      final service = WarmIntrosService(gateway);
      final s = buildWarmSuggestion();
      when(
        () => gateway.rpc('suggest_warm_intros', params: any(named: 'params')),
      ).thenAnswer((_) async => <Map<String, dynamic>>[s.toJson()]);

      final result = await service.suggestWarmIntros(limit: 5);
      expect(result, hasLength(1));
      expect(result.single.targetId, s.targetId);
      final captured = verify(
        () => gateway.rpc(
          'suggest_warm_intros',
          params: captureAny(named: 'params'),
        ),
      ).captured.single as Map<String, dynamic>;
      expect(captured['p_limit'], 5);
    });

    test('default limit is 10', () async {
      final gateway = _FakeWarmGateway();
      final service = WarmIntrosService(gateway);
      when(
        () => gateway.rpc('suggest_warm_intros', params: any(named: 'params')),
      ).thenAnswer((_) async => <Map<String, dynamic>>[]);

      await service.suggestWarmIntros();
      final captured = verify(
        () => gateway.rpc(
          'suggest_warm_intros',
          params: captureAny(named: 'params'),
        ),
      ).captured.single as Map<String, dynamic>;
      expect(captured['p_limit'], 10);
    });

    test('maps 28000 -> UnauthenticatedException', () async {
      final gateway = _FakeWarmGateway();
      final service = WarmIntrosService(gateway);
      when(
        () => gateway.rpc('suggest_warm_intros', params: any(named: 'params')),
      ).thenThrow(const PostgrestException(message: '', code: '28000'));
      expect(
        () => service.suggestWarmIntros(),
        throwsA(isA<UnauthenticatedException>()),
      );
    });
  });

  group('sendWarmRequest', () {
    test('trims note and returns new intro id', () async {
      final gateway = _FakeWarmGateway();
      final service = WarmIntrosService(gateway);
      when(
        () => gateway.rpc('send_warm_request', params: any(named: 'params')),
      ).thenAnswer((_) async => 'new-intro-id');

      final id = await service.sendWarmRequest(
        mutualId: 'm',
        targetId: 't',
        note: '  ${'a' * 100}  ',
      );
      expect(id, 'new-intro-id');
      final captured = verify(
        () => gateway.rpc(
          'send_warm_request',
          params: captureAny(named: 'params'),
        ),
      ).captured.single as Map<String, dynamic>;
      expect(captured['p_mutual_id'], 'm');
      expect(captured['p_target_id'], 't');
      expect((captured['p_note'] as String).length, 100);
    });

    test('maps 23505 -> DuplicateException (anti-shotgun)', () async {
      final gateway = _FakeWarmGateway();
      final service = WarmIntrosService(gateway);
      when(
        () => gateway.rpc('send_warm_request', params: any(named: 'params')),
      ).thenThrow(const PostgrestException(message: '', code: '23505'));
      expect(
        () => service.sendWarmRequest(
          mutualId: 'm',
          targetId: 't',
          note: 'x' * 100,
        ),
        throwsA(isA<DuplicateException>()),
      );
    });
  });

  group('forwardWarmIntro', () {
    test('trims note and returns new forward id', () async {
      final gateway = _FakeWarmGateway();
      final service = WarmIntrosService(gateway);
      when(
        () => gateway.rpc('forward_warm_intro', params: any(named: 'params')),
      ).thenAnswer((_) async => 'forward-id');

      final id = await service.forwardWarmIntro(
        introId: 'wr-1',
        note: '  ${'b' * 90}  ',
      );
      expect(id, 'forward-id');
      final captured = verify(
        () => gateway.rpc(
          'forward_warm_intro',
          params: captureAny(named: 'params'),
        ),
      ).captured.single as Map<String, dynamic>;
      expect(captured['p_intro_id'], 'wr-1');
      expect((captured['p_note'] as String).length, 90);
    });

    test('maps 22023 note-range -> IntroNoteRangeException', () async {
      final gateway = _FakeWarmGateway();
      final service = WarmIntrosService(gateway);
      when(
        () => gateway.rpc('forward_warm_intro', params: any(named: 'params')),
      ).thenThrow(
        const PostgrestException(
          message: 'char_length(btrim(note))',
          code: '22023',
        ),
      );
      expect(
        () => service.forwardWarmIntro(introId: 'i', note: 'short'),
        throwsA(isA<IntroNoteRangeException>()),
      );
    });
  });
}
