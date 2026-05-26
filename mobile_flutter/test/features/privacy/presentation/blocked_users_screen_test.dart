import 'package:connect_mobile/features/privacy/data/privacy_service.dart';
import 'package:connect_mobile/features/privacy/domain/blocked_user.dart';
import 'package:connect_mobile/features/privacy/presentation/blocked_users_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/pump.dart';

class _FakeService extends Mock implements PrivacyService {}

BlockedUser _block(
  String id, {
  String handle = 'alice',
  String name = 'Alice',
  DateTime? createdAt,
}) {
  return BlockedUser(
    blockedId: id,
    handle: handle,
    name: name,
    createdAt: createdAt ?? DateTime.utc(2026, 5, 20),
  );
}

Future<void> _pump(
  WidgetTester tester, {
  required _FakeService service,
}) async {
  await tester.pumpWidget(
    await wrapWithTheme(
      child: const BlockedUsersScreen(),
      overrides: <Override>[
        privacyServiceProvider.overrideWithValue(service),
      ],
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => registerFallbackValue(<String, dynamic>{}));

  testWidgets('shows empty state when no blocks', (tester) async {
    final _FakeService svc = _FakeService();
    when(svc.listBlockedUsers)
        .thenAnswer((_) async => const <BlockedUser>[]);
    await _pump(tester, service: svc);
    expect(find.textContaining("haven't blocked"), findsOneWidget);
    // The forward-intent hint also appears as the EmptyState body.
    expect(find.textContaining('never re-request'), findsOneWidget);
  });

  testWidgets('renders one row per blocked user with handle and name',
      (tester) async {
    final _FakeService svc = _FakeService();
    when(svc.listBlockedUsers).thenAnswer(
      (_) async => <BlockedUser>[
        _block('b1', handle: 'alice', name: 'Alice'),
        _block('b2', handle: 'bob', name: 'Bob'),
      ],
    );
    await _pump(tester, service: svc);

    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('@alice'), findsOneWidget);
    expect(find.text('Bob'), findsOneWidget);
    expect(find.text('@bob'), findsOneWidget);
    // Hint banner above the list is always rendered.
    expect(find.textContaining('never re-request'), findsOneWidget);
  });

  testWidgets('shows blocked-on date for each row', (tester) async {
    final _FakeService svc = _FakeService();
    when(svc.listBlockedUsers).thenAnswer(
      (_) async => <BlockedUser>[
        _block(
          'b1',
          createdAt: DateTime.utc(2026, 1, 7),
        ),
      ],
    );
    await _pump(tester, service: svc);
    expect(find.textContaining('2026-01-07'), findsOneWidget);
  });

  testWidgets('tapping Unblock + confirming calls service.unblockUser',
      (tester) async {
    final _FakeService svc = _FakeService();
    when(svc.listBlockedUsers).thenAnswer(
      (_) async => <BlockedUser>[_block('b1', name: 'Alice')],
    );
    when(() => svc.unblockUser('b1')).thenAnswer((_) async {});
    await _pump(tester, service: svc);

    // There may be more than one "Unblock" string on screen (row CTA +
    // confirm button on the dialog). Tap the FIRST occurrence — the row.
    await tester.tap(find.text('Unblock').first);
    await tester.pumpAndSettle();

    // ConfirmDialog renders both Cancel + Unblock (confirm) buttons. Tap the
    // last occurrence, which is the confirmation button.
    await tester.tap(find.text('Unblock').last);
    await tester.pumpAndSettle();

    verify(() => svc.unblockUser('b1')).called(1);
  });

  testWidgets('cancelling Unblock does NOT call service', (tester) async {
    final _FakeService svc = _FakeService();
    when(svc.listBlockedUsers).thenAnswer(
      (_) async => <BlockedUser>[_block('b1')],
    );
    await _pump(tester, service: svc);

    await tester.tap(find.text('Unblock').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    verifyNever(() => svc.unblockUser(any()));
  });
}
