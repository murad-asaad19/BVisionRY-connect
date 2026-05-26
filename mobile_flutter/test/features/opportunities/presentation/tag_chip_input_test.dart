import 'package:connect_mobile/features/opportunities/domain/tag_input.dart';
import 'package:connect_mobile/features/opportunities/presentation/tag_chip_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump.dart';

Future<void> _pumpWithState(
  WidgetTester tester, {
  TagInput initial = const TagInput.pure(),
}) async {
  TagInput value = initial;
  await tester.pumpWidget(
    await wrapWithTheme(
      child: Scaffold(
        body: StatefulBuilder(
          builder: (BuildContext context, void Function(VoidCallback) setState) {
            return TagChipInput(
              value: value,
              onChanged: (TagInput v) => setState(() => value = v),
            );
          },
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows counter "n/8"', (tester) async {
    await _pumpWithState(
      tester,
      initial: const TagInput.dirty(<String>['a', 'b', 'c']),
    );
    expect(find.text('3/8'), findsOneWidget);
  });

  testWidgets('adds a tag when comma is typed', (tester) async {
    await _pumpWithState(tester);
    await tester.enterText(find.byType(TextField), 'pm,');
    await tester.pumpAndSettle();
    expect(find.text('pm'), findsOneWidget);
  });

  testWidgets('normalizes case + trims', (tester) async {
    await _pumpWithState(tester);
    await tester.enterText(find.byType(TextField), ' Fintech ,');
    await tester.pumpAndSettle();
    expect(find.text('fintech'), findsOneWidget);
  });

  testWidgets('does not add a 31-char tag', (tester) async {
    await _pumpWithState(tester);
    final String tooLong = 'a' * 31;
    await tester.enterText(find.byType(TextField), '$tooLong,');
    await tester.pumpAndSettle();
    expect(find.text(tooLong), findsNothing);
    expect(find.text('0/8'), findsOneWidget);
  });
}
