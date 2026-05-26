import 'package:connect_mobile/core/errors/app_exception.dart';
import 'package:connect_mobile/features/auth/providers/session_provider.dart';
import 'package:connect_mobile/features/opportunities/data/opportunities_service.dart';
import 'package:connect_mobile/features/opportunities/domain/interested_user.dart';
import 'package:connect_mobile/features/opportunities/presentation/interested_list_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../helpers/pump.dart';

class _FakeService extends Mock implements OpportunitiesService {}

InterestedUser _u(String id, {String? note}) => InterestedUser(
      userId: id,
      handle: 'sam',
      name: 'Sam',
      primaryRole: 'engineer',
      note: note,
      createdAt: DateTime.utc(2026, 5, 25, 10),
    );

void main() {
  testWidgets('renders one row per user', (tester) async {
    final _FakeService fake = _FakeService();
    when(() => fake.listInterested('oid')).thenAnswer(
      (_) async => <InterestedUser>[_u('a'), _u('b')],
    );
    await tester.pumpWidget(
      await wrapWithTheme(
        child: const InterestedListScreen(opportunityId: 'oid'),
        overrides: <Override>[
          opportunitiesServiceProvider.overrideWithValue(fake),
          sessionProvider.overrideWith((_) => const Stream<Session?>.empty()),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Sam'), findsNWidgets(2));
  });

  testWidgets('row note is shown when non-null', (tester) async {
    final _FakeService fake = _FakeService();
    when(() => fake.listInterested('oid')).thenAnswer(
      (_) async => <InterestedUser>[_u('a', note: 'Loved your stack.')],
    );
    await tester.pumpWidget(
      await wrapWithTheme(
        child: const InterestedListScreen(opportunityId: 'oid'),
        overrides: <Override>[
          opportunitiesServiceProvider.overrideWithValue(fake),
          sessionProvider.overrideWith((_) => const Stream<Session?>.empty()),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Loved your stack.'), findsOneWidget);
  });

  testWidgets('forbidden error shows guarded empty state', (tester) async {
    final _FakeService fake = _FakeService();
    when(() => fake.listInterested('oid')).thenThrow(ForbiddenException());
    await tester.pumpWidget(
      await wrapWithTheme(
        child: const InterestedListScreen(opportunityId: 'oid'),
        overrides: <Override>[
          opportunitiesServiceProvider.overrideWithValue(fake),
          sessionProvider.overrideWith((_) => const Stream<Session?>.empty()),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Not allowed'), findsOneWidget);
  });

  testWidgets('empty state for empty list', (tester) async {
    final _FakeService fake = _FakeService();
    when(() => fake.listInterested('oid'))
        .thenAnswer((_) async => const <InterestedUser>[]);
    await tester.pumpWidget(
      await wrapWithTheme(
        child: const InterestedListScreen(opportunityId: 'oid'),
        overrides: <Override>[
          opportunitiesServiceProvider.overrideWithValue(fake),
          sessionProvider.overrideWith((_) => const Stream<Session?>.empty()),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No one has expressed interest yet.'), findsOneWidget);
  });
}
