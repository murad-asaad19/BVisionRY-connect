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
}
