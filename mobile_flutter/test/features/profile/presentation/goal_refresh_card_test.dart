import 'package:connect_mobile/features/profile/domain/profile.dart';
import 'package:connect_mobile/features/profile/presentation/goal_refresh_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump.dart';

Profile _staleProfile() => Profile.empty('u-1').copyWith(
      goalUpdatedAt: DateTime.now().toUtc().subtract(const Duration(days: 70)),
    );

Profile _freshProfile() => Profile.empty('u-1').copyWith(
      goalUpdatedAt: DateTime.now().toUtc().subtract(const Duration(days: 10)),
    );

void main() {
  group('GoalRefreshCard', () {
    testWidgets('renders banner with warning copy when goal is stale', (
      WidgetTester tester,
    ) async {
      bool updateTapped = false;
      await tester.pumpWidget(
        await wrapWithTheme(
          child: GoalRefreshCard(
            profile: _staleProfile(),
            onUpdate: () => updateTapped = true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('goal-refresh-card')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('goalRefresh.update')));
      expect(updateTapped, isTrue);
    });

    testWidgets('collapses when goal is fresh (< 28 days)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        await wrapWithTheme(
          child: GoalRefreshCard(
            profile: _freshProfile(),
            onUpdate: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('goal-refresh-card')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('goal-refresh-card-fresh')),
        findsOneWidget,
      );
    });

    testWidgets('collapses when goalUpdatedAt is null', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        await wrapWithTheme(
          child: GoalRefreshCard(
            profile: Profile.empty('u-1'),
            onUpdate: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('goal-refresh-card')),
        findsNothing,
      );
    });
  });
}
