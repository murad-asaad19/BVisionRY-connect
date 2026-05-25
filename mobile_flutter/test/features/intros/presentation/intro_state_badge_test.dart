import 'package:connect_mobile/features/intros/domain/intro_enums.dart';
import 'package:connect_mobile/features/intros/presentation/intro_state_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump.dart';

void main() {
  testWidgets('renders a tagged badge for every IntroState value', (
    tester,
  ) async {
    for (final s in IntroState.values) {
      final widget = await wrapWithTheme(child: IntroStateBadge(state: s));
      await pumpWithI18n(tester, widget);
      expect(
        find.byKey(ValueKey<String>('intro-badge-${s.name}')),
        findsOneWidget,
      );
    }
  });

  testWidgets('delivered badge shows the localized Pending label', (
    tester,
  ) async {
    final widget = await wrapWithTheme(
      child: const IntroStateBadge(state: IntroState.delivered),
    );
    await pumpWithI18n(tester, widget);
    expect(find.text('Pending'), findsOneWidget);
  });

  testWidgets('connected badge shows the localized Connected label', (
    tester,
  ) async {
    final widget = await wrapWithTheme(
      child: const IntroStateBadge(state: IntroState.connected),
    );
    await pumpWithI18n(tester, widget);
    expect(find.text('Connected'), findsOneWidget);
  });
}
