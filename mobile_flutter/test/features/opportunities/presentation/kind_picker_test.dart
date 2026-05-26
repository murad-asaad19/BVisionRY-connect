import 'package:connect_mobile/core/widgets/app_filter_chip.dart';
import 'package:connect_mobile/features/opportunities/domain/opportunity_kind.dart';
import 'package:connect_mobile/features/opportunities/presentation/kind_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump.dart';

void main() {
  testWidgets('KindPicker renders all 8 chips', (tester) async {
    await tester.pumpWidget(
      await wrapWithTheme(
        child: Scaffold(
          body: KindPicker(value: null, onChanged: (_) {}),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(AppFilterChip), findsNWidgets(8));
  });

  testWidgets('KindPicker calls onChanged with selected kind', (tester) async {
    OpportunityKind? selected;
    await tester.pumpWidget(
      await wrapWithTheme(
        child: Scaffold(
          body: KindPicker(
            value: null,
            onChanged: (OpportunityKind k) => selected = k,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hiring').first);
    await tester.pumpAndSettle();
    expect(selected, OpportunityKind.hiring);
  });
}
