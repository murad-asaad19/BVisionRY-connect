import 'package:connect_mobile/features/profile/domain/profile_signals.dart';
import 'package:connect_mobile/features/profile/presentation/profile_signals_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump.dart';

void main() {
  group('ProfileSignalsRow', () {
    testWidgets('hides rating row when total_meeting_reviews < 3', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        await wrapWithTheme(
          child: const ProfileSignalsRow(
            signals: ProfileSignals(
              mutualConnectionCount: 3,
              mutualTopUserIds: <String>['a', 'b', 'c'],
              avgMeetingRating: 4.2,
              totalMeetingReviews: 2, // < 3 → hide rating
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('profileSignals.rating')), findsNothing);
      expect(find.byKey(const Key('profileSignals.mutuals')), findsOneWidget);
    });

    testWidgets('shows rating row when total_meeting_reviews >= 3', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        await wrapWithTheme(
          child: const ProfileSignalsRow(
            signals: ProfileSignals(
              mutualConnectionCount: 2,
              mutualTopUserIds: <String>['a', 'b'],
              avgMeetingRating: 4.7,
              totalMeetingReviews: 6,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('profileSignals.rating')), findsOneWidget);
      expect(find.text('4.7'), findsOneWidget);
    });

    testWidgets('empty signals → collapses to a SizedBox.shrink', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        await wrapWithTheme(
          // ignore: prefer_const_constructors
          child: ProfileSignalsRow(signals: ProfileSignals.empty),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('profileSignals.rating')), findsNothing);
      expect(find.byKey(const Key('profileSignals.mutuals')), findsNothing);
      expect(
        find.byKey(const ValueKey<String>('profile-signals-empty')),
        findsOneWidget,
      );
    });
  });
}
