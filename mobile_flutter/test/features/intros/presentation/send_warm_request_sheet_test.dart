import 'package:connect_mobile/core/errors/app_exception.dart';
import 'package:connect_mobile/features/intros/data/warm_intros_service.dart';
import 'package:connect_mobile/features/intros/domain/warm_suggestion.dart';
import 'package:connect_mobile/features/intros/presentation/send_warm_request_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/intros_fixtures.dart';
import '../../../helpers/pump.dart';

class _FakeWarmIntrosService extends Mock implements WarmIntrosService {}

class _ThrowingWarmIntrosService implements WarmIntrosService {
  _ThrowingWarmIntrosService(this._error);
  final AppException _error;
  @override
  Future<String> sendWarmRequest({
    required String mutualId,
    required String targetId,
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
    required WarmIntrosService service,
    WarmSuggestion? suggestion,
  }) async {
    final widget = await wrapWithTheme(
      child: Scaffold(
        body: SendWarmRequestSheet(
          suggestion: suggestion ?? buildWarmSuggestion(),
        ),
      ),
      overrides: <Override>[
        warmIntrosServiceProvider.overrideWithValue(service),
      ],
    );
    await pumpWithI18n(tester, widget);
  }

  testWidgets('renders target name + mutual via pill', (tester) async {
    await pumpSheet(tester, service: _FakeWarmIntrosService());
    expect(find.textContaining('Alice'), findsAtLeastNWidgets(1));
    expect(find.textContaining('Mia'), findsAtLeastNWidgets(1));
  });

  testWidgets('duplicate error renders intros.compose.errorDuplicate', (
    tester,
  ) async {
    await pumpSheet(
      tester,
      service: _ThrowingWarmIntrosService(DuplicateException()),
    );
    await tester.enterText(find.byType(TextField), 'a' * 100);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('send-warm-request-send')));
    await tester.pumpAndSettle();
    expect(find.textContaining('already have a pending'), findsOneWidget);
  });

  testWidgets('Send disabled below 80 chars', (tester) async {
    await pumpSheet(tester, service: _FakeWarmIntrosService());
    final sendKey = find.byKey(const ValueKey('send-warm-request-send'));
    await tester.enterText(find.byType(TextField), 'short note');
    await tester.pumpAndSettle();
    final InkWell inkWell = tester.widget(
      find.descendant(of: sendKey, matching: find.byType(InkWell)).first,
    );
    expect(inkWell.onTap, isNull);
  });
}
