import 'package:connect_mobile/features/auth/providers/session_provider.dart';
import 'package:connect_mobile/features/opportunities/data/opportunities_service.dart';
import 'package:connect_mobile/features/opportunities/presentation/express_interest_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../helpers/pump.dart';

class _FakeService extends Mock implements OpportunitiesService {}

Future<void> _openSheet(
  WidgetTester tester,
  _FakeService fake,
) async {
  await tester.pumpWidget(
    await wrapWithTheme(
      child: Scaffold(
        body: Builder(
          builder: (BuildContext c) {
            return ElevatedButton(
              onPressed: () {
                showExpressInterestSheet(c, opportunityId: 'oid');
              },
              child: const Text('Open'),
            );
          },
        ),
      ),
      overrides: <Override>[
        opportunitiesServiceProvider.overrideWithValue(fake),
        sessionProvider.overrideWith((_) => const Stream<Session?>.empty()),
      ],
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => registerFallbackValue(<String, dynamic>{}));

  testWidgets('submit with empty note calls expressInterest with note=null',
      (tester) async {
    final _FakeService fake = _FakeService();
    when(
      () => fake.expressInterest(
        opportunityId: any(named: 'opportunityId'),
        note: any(named: 'note'),
      ),
    ).thenAnswer((_) async {});
    await _openSheet(tester, fake);
    await tester.tap(find.text('Send interest'));
    await tester.pumpAndSettle();
    verify(
      () => fake.expressInterest(
        opportunityId: 'oid',
        note: null,
      ),
    ).called(1);
  });

  testWidgets('submit with 5-char note shows error and does not call service',
      (tester) async {
    final _FakeService fake = _FakeService();
    await _openSheet(tester, fake);
    await tester.enterText(find.byType(TextField), 'short');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send interest'));
    await tester.pumpAndSettle();
    expect(
      find.text('Note must be at least 10 characters.'),
      findsOneWidget,
    );
    verifyNever(
      () => fake.expressInterest(
        opportunityId: any(named: 'opportunityId'),
        note: any(named: 'note'),
      ),
    );
  });

  testWidgets('submit with 12-char note calls expressInterest', (tester) async {
    final _FakeService fake = _FakeService();
    when(
      () => fake.expressInterest(
        opportunityId: any(named: 'opportunityId'),
        note: any(named: 'note'),
      ),
    ).thenAnswer((_) async {});
    await _openSheet(tester, fake);
    await tester.enterText(find.byType(TextField), 'I love this');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send interest'));
    await tester.pumpAndSettle();
    verify(
      () => fake.expressInterest(
        opportunityId: 'oid',
        note: 'I love this',
      ),
    ).called(1);
  });
}
