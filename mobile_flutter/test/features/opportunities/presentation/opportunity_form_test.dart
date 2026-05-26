import 'package:connect_mobile/features/opportunities/domain/opportunity_kind.dart';
import 'package:connect_mobile/features/opportunities/presentation/opportunity_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump.dart';

void main() {
  testWidgets('OpportunityForm renders all three sections', (tester) async {
    tester.view.physicalSize = const Size(1080, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      await wrapWithTheme(
        child: Scaffold(
          body: OpportunityForm(
            onSubmit: (_) async {},
            submitLabel: 'Post opportunity',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('TITLE'), findsOneWidget);
    expect(find.text('DESCRIPTION'), findsOneWidget);
    expect(find.text('TAGS'), findsOneWidget);
    expect(find.text('Post opportunity'), findsOneWidget);
  });

  testWidgets('expiresAt default is today + 30d (UTC)', (tester) async {
    tester.view.physicalSize = const Size(1080, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    OpportunityFormValue? captured;
    final OpportunityFormValue empty = OpportunityFormValue.empty(
      now: DateTime.utc(2026, 5, 26),
    );
    expect(empty.expiresAt, DateTime.utc(2026, 6, 25));

    await tester.pumpWidget(
      await wrapWithTheme(
        child: Scaffold(
          body: OpportunityForm(
            initial: OpportunityFormValue.empty(now: DateTime.utc(2026, 5, 26))
                .copyWith(
              kind: OpportunityKind.hiring,
              title: 'A title of decent length',
              body: 'A body that is long enough to clear ten chars.',
            ),
            onSubmit: (OpportunityFormValue v) async => captured = v,
            submitLabel: 'Post',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Post'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Post'));
    await tester.pumpAndSettle();
    expect(captured, isNotNull);
    expect(captured!.expiresAt.month, 6);
    expect(captured!.expiresAt.day, 25);
  });

  test('OpportunityFormValue.isValid requires kind + ranges', () {
    final OpportunityFormValue empty = OpportunityFormValue.empty();
    expect(empty.isValid, isFalse);
    final OpportunityFormValue valid = empty.copyWith(
      kind: OpportunityKind.hiring,
      title: 'A title of decent length',
      body: 'A body that is long enough to clear ten chars.',
    );
    expect(valid.isValid, isTrue);
  });
}
