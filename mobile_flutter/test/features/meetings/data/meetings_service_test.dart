import 'package:connect_mobile/core/errors/app_exception.dart';
import 'package:connect_mobile/features/meetings/data/meetings_service.dart';
import 'package:connect_mobile/features/meetings/domain/meeting_review.dart';
import 'package:connect_mobile/features/meetings/domain/meeting_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockGateway extends Mock implements MeetingsGateway {}

void main() {
  late _MockGateway gateway;
  late MeetingsService svc;

  setUp(() {
    gateway = _MockGateway();
    svc = MeetingsService(gateway);
  });

  group('proposeMeeting validation', () {
    test('rejects empty slots', () async {
      await expectLater(
        svc.proposeMeeting(
          conversationId: 'c',
          slots: const [],
          durationMinutes: 30,
          meetingUrl: null,
          timezone: 'UTC',
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects > 3 slots', () async {
      final now = DateTime.now().toUtc().add(const Duration(days: 1));
      await expectLater(
        svc.proposeMeeting(
          conversationId: 'c',
          slots: [
            now,
            now.add(const Duration(hours: 1)),
            now.add(const Duration(hours: 2)),
            now.add(const Duration(hours: 3)),
          ],
          durationMinutes: 30,
          meetingUrl: null,
          timezone: 'UTC',
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects past slots', () async {
      final past = DateTime.now().toUtc().subtract(const Duration(hours: 1));
      await expectLater(
        svc.proposeMeeting(
          conversationId: 'c',
          slots: [past],
          durationMinutes: 30,
          meetingUrl: null,
          timezone: 'UTC',
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects duration out of 15-240 range', () async {
      final now = DateTime.now().toUtc().add(const Duration(hours: 1));
      await expectLater(
        svc.proposeMeeting(
          conversationId: 'c',
          slots: [now],
          durationMinutes: 10,
          meetingUrl: null,
          timezone: 'UTC',
        ),
        throwsA(isA<ValidationException>()),
      );
      await expectLater(
        svc.proposeMeeting(
          conversationId: 'c',
          slots: [now],
          durationMinutes: 300,
          meetingUrl: null,
          timezone: 'UTC',
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects non-https meeting URL', () async {
      final now = DateTime.now().toUtc().add(const Duration(hours: 1));
      await expectLater(
        svc.proposeMeeting(
          conversationId: 'c',
          slots: [now],
          durationMinutes: 30,
          meetingUrl: 'http://meet.example.com',
          timezone: 'UTC',
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('accepts valid input and forwards to gateway', () async {
      final now = DateTime.now().toUtc().add(const Duration(days: 1));
      when(() => gateway.rpc('propose_meeting', params: any(named: 'params')))
          .thenAnswer((_) async => _proposalRow(state: 'proposed'));
      final result = await svc.proposeMeeting(
        conversationId: 'c',
        slots: [now],
        durationMinutes: 30,
        meetingUrl: 'https://meet.google.com/abc',
        timezone: 'UTC',
      );
      expect(result.state, MeetingState.proposed);
      verify(
        () => gateway.rpc('propose_meeting', params: any(named: 'params')),
      ).called(1);
    });
  });

  test('confirmMeeting forwards meeting_id + slot', () async {
    when(() => gateway.rpc('confirm_meeting', params: any(named: 'params')))
        .thenAnswer((_) async => _proposalRow(state: 'confirmed'));
    final slot = DateTime.now().toUtc().add(const Duration(days: 1));
    final result = await svc.confirmMeeting('mid', slot);
    expect(result.state, MeetingState.confirmed);
  });

  test('declineMeeting calls decline_meeting RPC', () async {
    when(() => gateway.rpc('decline_meeting', params: any(named: 'params')))
        .thenAnswer((_) async => _proposalRow(state: 'declined'));
    final result = await svc.declineMeeting('mid');
    expect(result.state, MeetingState.declined);
  });

  test('cancelMeeting calls cancel_meeting RPC', () async {
    when(() => gateway.rpc('cancel_meeting', params: any(named: 'params')))
        .thenAnswer((_) async => _proposalRow(state: 'cancelled'));
    final result = await svc.cancelMeeting('mid');
    expect(result.state, MeetingState.cancelled);
  });

  test('submitMeetingReview forwards outcome + note', () async {
    when(
      () => gateway.rpc('submit_meeting_review', params: any(named: 'params')),
    ).thenAnswer((_) async => _reviewRow());
    final result = await svc.submitMeetingReview(
      meetingId: 'mid',
      outcome: MeetingReviewOutcome.useful,
      note: 'great',
    );
    expect(result.outcome, MeetingReviewOutcome.useful);
  });

  test('pendingMeetingReviews returns a list of proposals', () async {
    when(
      () =>
          gateway.rpc('pending_meeting_reviews', params: any(named: 'params')),
    ).thenAnswer((_) async => [_proposalRow(state: 'confirmed')]);
    final result = await svc.pendingMeetingReviews();
    expect(result, hasLength(1));
    expect(result.first.state, MeetingState.confirmed);
  });
}

Map<String, dynamic> _proposalRow({required String state}) => {
      'id': 'mid',
      'conversation_id': 'cid',
      'proposed_by_id': 'p',
      'slots': [
        DateTime.now()
            .toUtc()
            .add(const Duration(days: 1))
            .toIso8601String(),
      ],
      'duration_minutes': 30,
      'timezone': 'UTC',
      'state': state,
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

Map<String, dynamic> _reviewRow() => {
      'id': 'rid',
      'meeting_id': 'mid',
      'reviewer_id': 'uid',
      'outcome': 'useful',
      'note': 'great',
      'created_at': DateTime.now().toUtc().toIso8601String(),
    };
