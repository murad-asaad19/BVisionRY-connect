import 'package:connect_mobile/features/intros/data/intros_service.dart';
import 'package:connect_mobile/features/intros/domain/intro.dart';
import 'package:connect_mobile/features/intros/providers/intros_providers.dart';
import 'package:connect_mobile/features/privacy/data/privacy_service.dart';
import 'package:connect_mobile/features/privacy/domain/blocked_user.dart';
import 'package:connect_mobile/features/privacy/presentation/block_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/intros_fixtures.dart';
import '../../../helpers/pump.dart';

class _FakePrivacyService extends Mock implements PrivacyService {}

class _FakeIntrosService extends Mock implements IntrosService {}

Future<void> _pump(
  WidgetTester tester, {
  required _FakePrivacyService privacy,
  _FakeIntrosService? intros,
  String userId = 'u1',
  String name = 'Alice',
  String? handle,
}) async {
  await tester.pumpWidget(
    await wrapWithTheme(
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: BlockButton(userId: userId, name: name, handle: handle),
        ),
      ),
      overrides: <Override>[
        privacyServiceProvider.overrideWithValue(privacy),
        if (intros != null) introsServiceProvider.overrideWithValue(intros),
        currentUserIdProvider.overrideWithValue('me'),
      ],
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => registerFallbackValue(<String, dynamic>{}));

  testWidgets('renders "Block {name}" when not blocked', (tester) async {
    final svc = _FakePrivacyService();
    when(svc.listBlockedUsers).thenAnswer((_) async => const <BlockedUser>[]);
    await _pump(tester, privacy: svc);
    expect(find.text('Block Alice'), findsOneWidget);
  });

  testWidgets('renders "Unblock {name}" when already blocked', (tester) async {
    final svc = _FakePrivacyService();
    when(svc.listBlockedUsers).thenAnswer(
      (_) async => <BlockedUser>[
        BlockedUser(
          blockedId: 'u1',
          handle: 'a',
          name: 'A',
          createdAt: DateTime.utc(2026),
        ),
      ],
    );
    await _pump(tester, privacy: svc);
    expect(find.text('Unblock Alice'), findsOneWidget);
  });

  testWidgets(
      'block flow opens destructive confirm + calls blockUser on accept',
      (tester) async {
    final svc = _FakePrivacyService();
    when(svc.listBlockedUsers).thenAnswer((_) async => const <BlockedUser>[]);
    when(() => svc.blockUser('u1')).thenAnswer((_) async {});

    final intros = _FakeIntrosService();
    when(() => intros.listReceivedIntros(viewerId: any(named: 'viewerId')))
        .thenAnswer((_) async => const <Intro>[]);
    when(() => intros.listSentIntros(viewerId: any(named: 'viewerId')))
        .thenAnswer((_) async => const <Intro>[]);

    await _pump(
      tester,
      privacy: svc,
      intros: intros,
      handle: 'alice',
    );

    await tester.tap(find.text('Block Alice'));
    await tester.pumpAndSettle();
    // ConfirmDialog title interpolates the handle.
    expect(find.text('Block @alice?'), findsOneWidget);
    await tester.tap(find.text('Block User'));
    await tester.pumpAndSettle();
    verify(() => svc.blockUser('u1')).called(1);
  });

  testWidgets('cancelling the block confirm does NOT call blockUser',
      (tester) async {
    final svc = _FakePrivacyService();
    when(svc.listBlockedUsers).thenAnswer((_) async => const <BlockedUser>[]);
    await _pump(tester, privacy: svc);

    await tester.tap(find.text('Block Alice'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    verifyNever(() => svc.blockUser(any()));
  });

  testWidgets(
      'unblock flow opens (non-destructive) confirm + calls unblockUser',
      (tester) async {
    final svc = _FakePrivacyService();
    when(svc.listBlockedUsers).thenAnswer(
      (_) async => <BlockedUser>[
        BlockedUser(
          blockedId: 'u1',
          handle: 'a',
          name: 'A',
          createdAt: DateTime.utc(2026),
        ),
      ],
    );
    when(() => svc.unblockUser('u1')).thenAnswer((_) async {});
    await _pump(tester, privacy: svc);

    await tester.tap(find.text('Unblock Alice'));
    await tester.pumpAndSettle();
    // Tap the confirm sheet's "Unblock" button (the last "Unblock" on screen).
    await tester.tap(find.text('Unblock').last);
    await tester.pumpAndSettle();
    verify(() => svc.unblockUser('u1')).called(1);
  });

  testWidgets('successful block invalidates received + sent intros providers',
      (tester) async {
    final svc = _FakePrivacyService();
    when(svc.listBlockedUsers).thenAnswer((_) async => const <BlockedUser>[]);
    when(() => svc.blockUser('u1')).thenAnswer((_) async {});

    int receivedCalls = 0;
    int sentCalls = 0;
    final intros = _FakeIntrosService();
    when(() => intros.listReceivedIntros(viewerId: any(named: 'viewerId')))
        .thenAnswer((_) async {
      receivedCalls++;
      return const <Intro>[];
    });
    when(() => intros.listSentIntros(viewerId: any(named: 'viewerId')))
        .thenAnswer((_) async {
      sentCalls++;
      return const <Intro>[];
    });

    await tester.pumpWidget(
      await wrapWithTheme(
        child: Scaffold(
          body: Consumer(
            builder: (BuildContext ctx, WidgetRef ref, _) {
              // Subscribe to both providers so they materialize before tap.
              ref.watch(receivedIntrosProvider);
              ref.watch(sentIntrosProvider);
              return const Padding(
                padding: EdgeInsets.all(16),
                child: BlockButton(
                  userId: 'u1',
                  name: 'Alice',
                  handle: 'alice',
                ),
              );
            },
          ),
        ),
        overrides: <Override>[
          privacyServiceProvider.overrideWithValue(svc),
          introsServiceProvider.overrideWithValue(intros),
          currentUserIdProvider.overrideWithValue('me'),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(receivedCalls, 1);
    expect(sentCalls, 1);

    await tester.tap(find.text('Block Alice'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Block User'));
    await tester.pumpAndSettle();

    expect(receivedCalls, greaterThanOrEqualTo(2));
    expect(sentCalls, greaterThanOrEqualTo(2));
  });
}

// Keep intros_fixtures.dart referenced so the import isn't lint-pruned in
// a future change.
// ignore: unused_element
Intro _ref() => buildIntro();
