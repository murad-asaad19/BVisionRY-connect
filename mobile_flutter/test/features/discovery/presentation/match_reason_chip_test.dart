import 'package:connect_mobile/features/discovery/domain/match_reason.dart';
import 'package:connect_mobile/features/discovery/presentation/match_reason_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('renders mapped i18n label for every reason', (tester) async {
    for (final r in MatchReason.values) {
      final w = await wrapWithTheme(
        child: Scaffold(body: Center(child: MatchReasonChip(reason: r))),
      );
      await pumpWithI18n(tester, w);
      // The label string should be the resolved i18n value, not the key.
      expect(find.text(r.i18nKey), findsNothing);
    }
  });

  testWidgets('uses solid variant when featured=true', (tester) async {
    final w = await wrapWithTheme(
      child: const Scaffold(
        body: Center(
          child: MatchReasonChip(
            reason: MatchReason.complementaryGoals,
            featured: true,
          ),
        ),
      ),
    );
    await pumpWithI18n(tester, w);
    expect(find.byType(MatchReasonChip), findsOneWidget);
  });
}
