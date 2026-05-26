import 'package:connect_mobile/core/errors/app_exception.dart';
import 'package:connect_mobile/core/errors/error_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('maps intros.send P0001 hint=cooldown to IntroCooldownException', () {
    const PostgrestException ex = PostgrestException(
      message: 'recipient declined within 30 days',
      code: 'P0001',
      hint: 'cooldown',
    );
    final AppException mapped = mapPostgrestError(ex);
    expect(mapped, isA<IntroCooldownException>());
    expect(mapped.i18nKey, equals('intros.compose.errorCooldown'));
  });

  test('maps intros daily_cap hint to rate-limit exception', () {
    const PostgrestException ex = PostgrestException(
      message: 'daily cap',
      code: 'P0001',
      hint: 'daily_cap',
    );
    final AppException mapped = mapPostgrestError(ex);
    expect(mapped, isA<DailyCapException>());
    expect(mapped.i18nKey, equals('intros.compose.errorRateLimit'));
  });

  test('falls back to GenericException with i18n key auth.errors.generic', () {
    const PostgrestException ex = PostgrestException(
      message: 'something else',
      code: 'XX999',
    );
    final AppException mapped = mapPostgrestError(ex);
    expect(mapped, isA<GenericAppException>());
    expect(mapped.i18nKey, equals('auth.errors.generic'));
  });

  test(
    'maps 22023 with "wrong intro kind" message to WrongIntroKindException',
    () {
      const PostgrestException ex = PostgrestException(
        message: 'wrong intro kind',
        code: '22023',
      );
      final AppException mapped = mapPostgrestError(ex);
      expect(mapped, isA<WrongIntroKindException>());
      expect(mapped.i18nKey, equals('intros.detail.acceptFailed'));
    },
  );

  test('maps 22023 with note-range message to IntroNoteRangeException', () {
    const PostgrestException ex = PostgrestException(
      message: 'char_length(btrim(note))',
      code: '22023',
    );
    final AppException mapped = mapPostgrestError(ex);
    expect(mapped, isA<IntroNoteRangeException>());
    expect(mapped.i18nKey, equals('intros.compose.errorRange'));
  });

  test('maps 22023 without specific message to IntroNoteRangeException', () {
    // Catch-all for any other 22023 (e.g. sender_id <> recipient_id) —
    // compose UI excludes self-intro, so this branch should never reach
    // the user, but the mapping must not return `Generic`.
    const PostgrestException ex = PostgrestException(
      message: 'sender_id <> recipient_id',
      code: '22023',
    );
    final AppException mapped = mapPostgrestError(ex);
    expect(mapped, isA<IntroNoteRangeException>());
  });

  test('maps 22023 with "duration" detail to meetings.propose.errors.duration',
      () {
    const PostgrestException ex = PostgrestException(
      message: 'duration must be 15-240',
      code: '22023',
    );
    final AppException mapped = mapPostgrestError(ex);
    expect(mapped, isA<ValidationException>());
    expect(mapped.i18nKey, 'meetings.propose.errors.duration');
  });

  test('maps 22023 with "slots" detail to meetings.propose.errors.slotsRange',
      () {
    const PostgrestException ex = PostgrestException(
      message: 'slots: 1-3 future timestamps required',
      code: '22023',
    );
    final AppException mapped = mapPostgrestError(ex);
    expect(mapped, isA<ValidationException>());
    expect(mapped.i18nKey, 'meetings.propose.errors.slotsRange');
  });

  test('maps 22023 with "https" detail to meetings.propose.errors.url', () {
    const PostgrestException ex = PostgrestException(
      message: 'meeting_url must start with https://',
      code: '22023',
    );
    final AppException mapped = mapPostgrestError(ex);
    expect(mapped, isA<ValidationException>());
    expect(mapped.i18nKey, 'meetings.propose.errors.url');
  });

  group('office-hours error mapping', () {
    test('hint=slot_unavailable to SlotUnavailableException', () {
      const ex = PostgrestException(
        message: 'slot unavailable',
        code: 'P0001',
        hint: 'slot_unavailable',
      );
      final mapped = mapPostgrestError(ex);
      expect(mapped, isA<SlotUnavailableException>());
      expect(mapped.i18nKey, 'officeHours.book.errorSlotUnavailable');
    });

    test('hint=slot_too_soon to SlotTooSoonException', () {
      const ex = PostgrestException(
        message: 'too soon',
        code: 'P0001',
        hint: 'slot_too_soon',
      );
      final mapped = mapPostgrestError(ex);
      expect(mapped, isA<SlotTooSoonException>());
      expect(mapped.i18nKey, 'officeHours.book.errorTooSoon');
    });

    test('hint=host_self to HostSelfException', () {
      const ex = PostgrestException(
        message: 'self',
        code: 'P0001',
        hint: 'host_self',
      );
      expect(mapPostgrestError(ex), isA<HostSelfException>());
    });

    test('hint=oh_disabled to OhDisabledException', () {
      const ex = PostgrestException(
        message: 'off',
        code: 'P0001',
        hint: 'oh_disabled',
      );
      expect(mapPostgrestError(ex), isA<OhDisabledException>());
    });

    test('hint=weekly_cap to WeeklyCapException', () {
      const ex = PostgrestException(
        message: 'cap',
        code: 'P0001',
        hint: 'weekly_cap',
      );
      expect(mapPostgrestError(ex), isA<WeeklyCapException>());
    });

    test('hint=blocked to BlockedException', () {
      const ex = PostgrestException(
        message: 'blocked',
        code: 'P0001',
        hint: 'blocked',
      );
      expect(mapPostgrestError(ex), isA<BlockedException>());
    });

    test('hint=topic_invalid to ValidationException(topicInvalid)', () {
      const ex = PostgrestException(
        message: 'topic',
        code: 'P0001',
        hint: 'topic_invalid',
      );
      final mapped = mapPostgrestError(ex);
      expect(mapped, isA<ValidationException>());
      expect(mapped.i18nKey, 'officeHours.book.errorTopicInvalid');
    });

    test('hint=bad_meeting_url to BadMeetingUrlException', () {
      const ex = PostgrestException(
        message: 'bad url',
        code: 'P0001',
        hint: 'bad_meeting_url',
      );
      expect(mapPostgrestError(ex), isA<BadMeetingUrlException>());
    });

    test('hint=not_booked to ValidationException(notBooked)', () {
      const ex = PostgrestException(
        message: 'nb',
        code: 'P0001',
        hint: 'not_booked',
      );
      final mapped = mapPostgrestError(ex);
      expect(mapped, isA<ValidationException>());
      expect(mapped.i18nKey, 'officeHours.bookings.errorNotBooked');
    });

    test('hint=not_authorised to ForbiddenException', () {
      const ex = PostgrestException(
        message: 'na',
        code: 'P0001',
        hint: 'not_authorised',
      );
      expect(mapPostgrestError(ex), isA<ForbiddenException>());
    });
  });
}
