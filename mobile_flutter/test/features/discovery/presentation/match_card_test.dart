import 'package:connect_mobile/features/discovery/domain/daily_match.dart';
import 'package:connect_mobile/features/discovery/domain/discovery_profile.dart';
import 'package:connect_mobile/features/discovery/presentation/match_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../helpers/pump.dart';

DailyMatch _m({DateTime? viewedAt}) => DailyMatch(
      id: 'm1',
      pickUserId: 'u',
      matchReason: 'Daily pick',
      forDateLocal: DateTime.utc(2026, 5, 25),
      viewedAt: viewedAt,
      createdAt: DateTime.utc(2026, 5, 25, 4),
      profile: const DiscoveryProfile(
        id: 'u',
        handle: 'omar',
        name: 'Omar Daher',
        primaryRole: 'builder',
      ),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
  });

  testWidgets('renders user name + handle and dispatches onTap',
      (tester) async {
    var tapped = false;
    final w = await wrapWithTheme(
      child: Scaffold(
        body: MatchCard(match: _m(), onTap: () => tapped = true),
      ),
    );
    await pumpWithI18n(tester, w);
    expect(find.text('Omar Daher'), findsOneWidget);
    await tester.tap(find.text('Omar Daher'));
    expect(tapped, isTrue);
  });

  testWidgets('fires onSeen exactly once when visible', (tester) async {
    var seen = 0;
    final w = await wrapWithTheme(
      child: Scaffold(
        body: MatchCard(match: _m(), onTap: () {}, onSeen: () => seen++),
      ),
    );
    await pumpWithI18n(tester, w);
    await tester.pumpAndSettle(const Duration(milliseconds: 50));
    expect(seen, 1);
  });

  testWidgets('does NOT fire onSeen when match already viewedAt set',
      (tester) async {
    var seen = 0;
    final w = await wrapWithTheme(
      child: Scaffold(
        body: MatchCard(
          match: _m(viewedAt: DateTime.utc(2026, 5, 25, 5)),
          onTap: () {},
          onSeen: () => seen++,
        ),
      ),
    );
    await pumpWithI18n(tester, w);
    expect(seen, 0);
  });
}
