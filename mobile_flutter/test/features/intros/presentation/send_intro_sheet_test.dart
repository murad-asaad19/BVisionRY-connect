import 'package:connect_mobile/core/errors/app_exception.dart';
import 'package:connect_mobile/features/intros/data/intros_service.dart';
import 'package:connect_mobile/features/intros/domain/intro.dart';
import 'package:connect_mobile/features/intros/presentation/send_intro_sheet.dart';
import 'package:connect_mobile/features/intros/providers/intros_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/pump.dart';

class _FakeIntrosService extends Mock implements IntrosService {}

class _ThrowingIntrosService implements IntrosService {
  _ThrowingIntrosService(this._error);
  final AppException _error;
  @override
  Future<Intro> sendIntro({
    required String recipientId,
    required String note,
  }) async =>
      throw _error;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() => registerFallbackValue(<String, dynamic>{}));

  Future<void> pumpSheet(
    WidgetTester tester, {
    required IntrosService introsService,
  }) async {
    final widget = await wrapWithTheme(
      child: const Scaffold(
        body: SendIntroSheet(
          recipient: SendIntroRecipient(id: 'r-1', name: 'Rachel'),
        ),
      ),
      overrides: <Override>[
        introsServiceProvider.overrideWithValue(introsService),
        currentUserIdProvider.overrideWithValue('me'),
        // Bypass the profileProvider → sessionProvider → Supabase chain — the
        // cap value is irrelevant for these tests.
        dailyIntroCapProvider.overrideWith((_) => 5),
      ],
    );
    await pumpWithI18n(tester, widget);
  }

  testWidgets('Send button disabled until 80-400 chars typed', (tester) async {
    await pumpSheet(tester, introsService: _FakeIntrosService());
    final sendKey = find.byKey(const ValueKey('send-intro-sheet-send'));
    expect(sendKey, findsOneWidget);
    final InkWell inkWell = tester.widget(
      find.descendant(of: sendKey, matching: find.byType(InkWell)).first,
    );
    expect(inkWell.onTap, isNull);
  });

  testWidgets('cooldown error renders intros.compose.errorCooldown', (
    tester,
  ) async {
    await pumpSheet(
      tester,
      introsService: _ThrowingIntrosService(IntroCooldownException()),
    );
    await tester.enterText(find.byType(TextField), 'a' * 100);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('send-intro-sheet-send')));
    await tester.pumpAndSettle();
    expect(find.textContaining('30 days'), findsOneWidget);
  });

  testWidgets('daily-cap error renders intros.compose.errorRateLimit', (
    tester,
  ) async {
    await pumpSheet(
      tester,
      introsService: _ThrowingIntrosService(DailyCapException()),
    );
    await tester.enterText(find.byType(TextField), 'b' * 100);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('send-intro-sheet-send')));
    await tester.pumpAndSettle();
    expect(find.textContaining("today's send limit"), findsOneWidget);
  });

  testWidgets('duplicate error renders intros.compose.errorDuplicate', (
    tester,
  ) async {
    await pumpSheet(
      tester,
      introsService: _ThrowingIntrosService(DuplicateException()),
    );
    await tester.enterText(find.byType(TextField), 'c' * 100);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('send-intro-sheet-send')));
    await tester.pumpAndSettle();
    expect(find.textContaining('already have a pending'), findsOneWidget);
  });

  testWidgets('range error renders intros.compose.errorRange', (tester) async {
    await pumpSheet(
      tester,
      introsService: _ThrowingIntrosService(IntroNoteRangeException()),
    );
    await tester.enterText(find.byType(TextField), 'd' * 100);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('send-intro-sheet-send')));
    await tester.pumpAndSettle();
    expect(find.textContaining('80-400 characters'), findsOneWidget);
  });

  testWidgets('generic error renders intros.compose.errorGeneric', (
    tester,
  ) async {
    await pumpSheet(
      tester,
      introsService: _ThrowingIntrosService(GenericAppException()),
    );
    await tester.enterText(find.byType(TextField), 'e' * 100);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('send-intro-sheet-send')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Send failed'), findsOneWidget);
  });
}
