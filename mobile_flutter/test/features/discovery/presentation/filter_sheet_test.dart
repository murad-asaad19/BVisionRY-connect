import 'package:connect_mobile/features/discovery/domain/feed_filters.dart';
import 'package:connect_mobile/features/discovery/presentation/filter_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Apply returns the selected filters', (tester) async {
    FeedFilters? returned;
    final w = await wrapWithTheme(
      child: Builder(
        builder: (ctx) {
          return Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  returned = await showFilterSheet(
                    ctx,
                    initial: const FeedFilters(),
                  );
                },
                child: const Text('open'),
              ),
            ),
          );
        },
      ),
    );
    await pumpWithI18n(tester, w);
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Founder'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hire'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    expect(returned, isNotNull);
    expect(returned!.roles, contains('founder'));
    expect(returned!.goalTypes, contains('hire'));
  });

  testWidgets('Reset clears all selections', (tester) async {
    FeedFilters? returned;
    final w = await wrapWithTheme(
      child: Builder(
        builder: (ctx) {
          return Scaffold(
            body: ElevatedButton(
              onPressed: () async => returned = await showFilterSheet(
                ctx,
                initial: const FeedFilters(
                  roles: <String>['founder'],
                  country: 'UK',
                ),
              ),
              child: const Text('open'),
            ),
          );
        },
      ),
    );
    await pumpWithI18n(tester, w);
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();
    expect(returned!.roles, isEmpty);
    expect(returned!.country, isNull);
  });
}
