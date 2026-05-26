import 'package:connect_mobile/core/errors/app_exception.dart';
import 'package:connect_mobile/features/privacy/data/privacy_service.dart';
import 'package:connect_mobile/features/privacy/domain/blocked_user.dart';
import 'package:connect_mobile/features/privacy/domain/report_reason.dart';
import 'package:connect_mobile/features/privacy/domain/report_target_type.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakeGateway extends Mock implements PrivacyGateway {}

void main() {
  setUpAll(() => registerFallbackValue(<String, dynamic>{}));

  late _FakeGateway gateway;
  late PrivacyService service;

  setUp(() {
    gateway = _FakeGateway();
    service = PrivacyService(gateway);
  });

  group('blockUser', () {
    test('calls block_user RPC with p_target', () async {
      when(
        () => gateway.rpc('block_user', params: any(named: 'params')),
      ).thenAnswer((_) async => null);

      await service.blockUser('user-a');

      final Map<String, dynamic> captured = verify(
        () => gateway.rpc(
          'block_user',
          params: captureAny(named: 'params'),
        ),
      ).captured.single as Map<String, dynamic>;
      expect(captured['p_target'], 'user-a');
    });

    test('maps PostgrestException via error_map', () async {
      when(
        () => gateway.rpc('block_user', params: any(named: 'params')),
      ).thenThrow(const PostgrestException(message: 'denied', code: '42501'));
      expect(
        () => service.blockUser('user-a'),
        throwsA(isA<ForbiddenException>()),
      );
    });

    test('maps 28000 -> UnauthenticatedException', () async {
      when(
        () => gateway.rpc('block_user', params: any(named: 'params')),
      ).thenThrow(const PostgrestException(message: '', code: '28000'));
      expect(
        () => service.blockUser('user-a'),
        throwsA(isA<UnauthenticatedException>()),
      );
    });
  });

  group('unblockUser', () {
    test('calls unblock_user RPC with p_target', () async {
      when(
        () => gateway.rpc('unblock_user', params: any(named: 'params')),
      ).thenAnswer((_) async => null);

      await service.unblockUser('user-b');

      final Map<String, dynamic> captured = verify(
        () => gateway.rpc(
          'unblock_user',
          params: captureAny(named: 'params'),
        ),
      ).captured.single as Map<String, dynamic>;
      expect(captured['p_target'], 'user-b');
    });

    test('maps PostgrestException via error_map', () async {
      when(
        () => gateway.rpc('unblock_user', params: any(named: 'params')),
      ).thenThrow(const PostgrestException(message: '', code: '42501'));
      expect(
        () => service.unblockUser('user-b'),
        throwsA(isA<ForbiddenException>()),
      );
    });
  });

  group('listBlockedUsers', () {
    test('maps rpc rows to BlockedUser', () async {
      when(() => gateway.rpc('list_blocked_users')).thenAnswer(
        (_) async => <Map<String, dynamic>>[
          <String, dynamic>{
            'blocked_id': 'b1',
            'handle': 'h1',
            'name': 'N1',
            'photo_url': null,
            'created_at': '2026-05-20T10:00:00Z',
          },
          <String, dynamic>{
            'blocked_id': 'b2',
            'handle': 'h2',
            'name': 'N2',
            'photo_url': 'https://cdn.example/2.png',
            'created_at': '2026-05-21T10:00:00Z',
          },
        ],
      );

      final List<BlockedUser> list = await service.listBlockedUsers();

      expect(list, hasLength(2));
      expect(list.first.blockedId, 'b1');
      expect(list[1].photoUrl, 'https://cdn.example/2.png');
    });

    test('returns empty list when RPC returns null', () async {
      when(() => gateway.rpc('list_blocked_users'))
          .thenAnswer((_) async => null);
      final List<BlockedUser> list = await service.listBlockedUsers();
      expect(list, isEmpty);
    });

    test('maps PostgrestException via error_map', () async {
      when(() => gateway.rpc('list_blocked_users')).thenThrow(
        const PostgrestException(message: '', code: '28000'),
      );
      expect(
        () => service.listBlockedUsers(),
        throwsA(isA<UnauthenticatedException>()),
      );
    });
  });

  group('reportTarget', () {
    setUp(() {
      when(
        () => gateway.rpc('report_target', params: any(named: 'params')),
      ).thenAnswer((_) async => null);
    });

    // 5 reasons x 3 target types = 15 combinations
    for (final ReportReason reason in ReportReason.values) {
      for (final ReportTargetType type in ReportTargetType.values) {
        test('forwards reason=${reason.wire} type=${type.wire}', () async {
          await service.reportTarget(
            targetType: type,
            targetId: 'x',
            reason: reason,
          );
          final Map<String, dynamic> captured = verify(
            () => gateway.rpc(
              'report_target',
              params: captureAny(named: 'params'),
            ),
          ).captured.single as Map<String, dynamic>;
          expect(captured['p_target_type'], type.wire);
          expect(captured['p_target_id'], 'x');
          expect(captured['p_reason'], reason.wire);
          expect(captured['p_note'], isNull);
          expect(captured['p_quoted_message_id'], isNull);
        });
      }
    }

    test('forwards note and quoted_message_id for chat reports', () async {
      await service.reportTarget(
        targetType: ReportTargetType.message,
        targetId: 'msg-1',
        reason: ReportReason.harassment,
        note: 'see screenshot',
        quotedMessageId: 'msg-1',
      );
      final Map<String, dynamic> captured = verify(
        () => gateway.rpc(
          'report_target',
          params: captureAny(named: 'params'),
        ),
      ).captured.single as Map<String, dynamic>;
      expect(captured['p_target_type'], 'message');
      expect(captured['p_target_id'], 'msg-1');
      expect(captured['p_reason'], 'harassment');
      expect(captured['p_note'], 'see screenshot');
      expect(captured['p_quoted_message_id'], 'msg-1');
    });

    test('refuses note > 1000 chars client-side', () async {
      final String tooLong = 'x' * 1001;
      expect(
        () => service.reportTarget(
          targetType: ReportTargetType.profile,
          targetId: 'p',
          reason: ReportReason.other,
          note: tooLong,
        ),
        throwsA(
          isA<ValidationException>().having(
            (ValidationException e) => e.i18nKey,
            'i18nKey',
            'privacy.reportModal.noteTooLong',
          ),
        ),
      );
      // Should never reach the RPC.
      verifyNever(
        () => gateway.rpc('report_target', params: any(named: 'params')),
      );
    });

    test('accepts note at exactly 1000 chars', () async {
      final String atCap = 'x' * 1000;
      await service.reportTarget(
        targetType: ReportTargetType.profile,
        targetId: 'p',
        reason: ReportReason.other,
        note: atCap,
      );
      verify(
        () => gateway.rpc('report_target', params: any(named: 'params')),
      ).called(1);
    });

    test('maps PostgrestException via error_map', () async {
      when(
        () => gateway.rpc('report_target', params: any(named: 'params')),
      ).thenThrow(const PostgrestException(message: '', code: '42501'));
      expect(
        () => service.reportTarget(
          targetType: ReportTargetType.profile,
          targetId: 'p',
          reason: ReportReason.spam,
        ),
        throwsA(isA<ForbiddenException>()),
      );
    });
  });
}
