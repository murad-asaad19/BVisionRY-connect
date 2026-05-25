import 'package:connect_mobile/core/i18n/locale_notifier.dart';
import 'package:connect_mobile/core/theme/app_theme.dart';
import 'package:connect_mobile/features/profile/domain/profile_signals.dart';
import 'package:connect_mobile/features/profile/presentation/profile_signals_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

import '../../../helpers/pump.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpSignals(WidgetTester tester, Widget child) async {
    final loader = await primedLocaleLoader();
    await tester.pumpWidgetBuilder(
      ProviderScope(
        overrides: <Override>[localeLoaderProvider.overrideWithValue(loader)],
        child: Material(
          child: Padding(padding: const EdgeInsets.all(12), child: child),
        ),
      ),
      wrapper: materialAppWrapper(theme: buildAppTheme(Brightness.light)),
      surfaceSize: const Size(390, 80),
    );
    await tester.pumpAndSettle();
  }

  testGoldens('ProfileSignalsRow — hidden state (<3 reviews, no mutuals)', (
    WidgetTester tester,
  ) async {
    await pumpSignals(
      tester,
      const ProfileSignalsRow(
        signals: ProfileSignals(
          mutualConnectionCount: 0,
          mutualTopUserIds: <String>[],
          avgMeetingRating: 4.5,
          totalMeetingReviews: 2,
        ),
      ),
    );
    await screenMatchesGolden(tester, 'profile_signals_row_hidden');
  });

  testGoldens('ProfileSignalsRow — count only (mutuals + rating hidden)', (
    WidgetTester tester,
  ) async {
    await pumpSignals(
      tester,
      const ProfileSignalsRow(
        signals: ProfileSignals(
          mutualConnectionCount: 5,
          mutualTopUserIds: <String>['a', 'b', 'c', 'd', 'e'],
          avgMeetingRating: null,
          totalMeetingReviews: 0,
        ),
      ),
    );
    await screenMatchesGolden(tester, 'profile_signals_row_count_only');
  });

  testGoldens('ProfileSignalsRow — count + rating both visible', (
    WidgetTester tester,
  ) async {
    await pumpSignals(
      tester,
      const ProfileSignalsRow(
        signals: ProfileSignals(
          mutualConnectionCount: 3,
          mutualTopUserIds: <String>['a', 'b', 'c'],
          avgMeetingRating: 4.7,
          totalMeetingReviews: 8,
        ),
      ),
    );
    await screenMatchesGolden(tester, 'profile_signals_row_both');
  });
}
