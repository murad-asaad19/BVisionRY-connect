import 'package:connect_mobile/features/connections/data/connections_service.dart';
import 'package:connect_mobile/features/connections/domain/connection.dart';
import 'package:connect_mobile/features/intros/data/intros_service.dart';
import 'package:connect_mobile/features/intros/domain/intro.dart';
import 'package:connect_mobile/features/intros/presentation/inbox_screen.dart';
import 'package:connect_mobile/features/intros/providers/intros_providers.dart';
import 'package:connect_mobile/features/profile/data/peer_profile_service.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/intros_fixtures.dart';
import '../../../helpers/pump.dart';

class _FakeIntrosService extends Mock implements IntrosService {}

class _FakeConnectionsService extends Mock implements ConnectionsService {}

class _FakePeerProfileService extends Mock implements PeerProfileService {}

void main() {
  setUpAll(() => registerFallbackValue(<String, dynamic>{}));

  _FakeIntrosService stubIntros({
    List<Intro> received = const <Intro>[],
    List<Intro> sent = const <Intro>[],
    int today = 0,
  }) {
    final fake = _FakeIntrosService();
    when(
      () => fake.listReceivedIntros(viewerId: any(named: 'viewerId')),
    ).thenAnswer((_) async => received);
    when(
      () => fake.listSentIntros(viewerId: any(named: 'viewerId')),
    ).thenAnswer((_) async => sent);
    when(() => fake.introsTodayCount()).thenAnswer((_) async => today);
    return fake;
  }

  _FakeConnectionsService stubConnections([List<Connection> rows = const []]) {
    final fake = _FakeConnectionsService();
    when(() => fake.listConnections()).thenAnswer((_) async => rows);
    return fake;
  }

  _FakePeerProfileService stubPeer() {
    final fake = _FakePeerProfileService();
    when(() => fake.fetchById(any())).thenAnswer((_) async => null);
    return fake;
  }

  testWidgets('empty received tab shows EmptyState body', (tester) async {
    final widget = await wrapWithTheme(
      child: const InboxScreen(),
      overrides: <Override>[
        introsServiceProvider.overrideWithValue(stubIntros()),
        connectionsServiceProvider.overrideWithValue(stubConnections()),
        peerProfileServiceProvider.overrideWithValue(stubPeer()),
        currentUserIdProvider.overrideWithValue('me'),
      ],
    );
    await pumpWithI18n(tester, widget);
    expect(find.text('No intros yet'), findsOneWidget);
  });

  testWidgets('received with items renders an intro badge', (tester) async {
    final widget = await wrapWithTheme(
      child: const InboxScreen(),
      overrides: <Override>[
        introsServiceProvider.overrideWithValue(
          stubIntros(received: <Intro>[buildIntro()]),
        ),
        connectionsServiceProvider.overrideWithValue(stubConnections()),
        peerProfileServiceProvider.overrideWithValue(stubPeer()),
        currentUserIdProvider.overrideWithValue('me'),
      ],
    );
    await pumpWithI18n(tester, widget);
    expect(find.byKey(const ValueKey('intro-badge-delivered')), findsOneWidget);
  });

  testWidgets('today >= 20 shows daily-cap banner on Received tab', (
    tester,
  ) async {
    final widget = await wrapWithTheme(
      child: const InboxScreen(),
      overrides: <Override>[
        introsServiceProvider.overrideWithValue(stubIntros(today: 22)),
        connectionsServiceProvider.overrideWithValue(stubConnections()),
        peerProfileServiceProvider.overrideWithValue(stubPeer()),
        currentUserIdProvider.overrideWithValue('me'),
      ],
    );
    await pumpWithI18n(tester, widget);
    expect(find.text('Daily limit reached'), findsOneWidget);
  });

  testWidgets('daily-cap banner hides when switching to Sent', (tester) async {
    final widget = await wrapWithTheme(
      child: const InboxScreen(),
      overrides: <Override>[
        introsServiceProvider.overrideWithValue(stubIntros(today: 22)),
        connectionsServiceProvider.overrideWithValue(stubConnections()),
        peerProfileServiceProvider.overrideWithValue(stubPeer()),
        currentUserIdProvider.overrideWithValue('me'),
      ],
    );
    await pumpWithI18n(tester, widget);
    expect(find.text('Daily limit reached'), findsOneWidget);

    await tester.tap(find.text('Sent'));
    await tester.pumpAndSettle();
    expect(find.text('Daily limit reached'), findsNothing);
  });

  testWidgets('connections tab shows empty state when no connections', (
    tester,
  ) async {
    final widget = await wrapWithTheme(
      child: const InboxScreen(),
      overrides: <Override>[
        introsServiceProvider.overrideWithValue(stubIntros()),
        connectionsServiceProvider.overrideWithValue(stubConnections()),
        peerProfileServiceProvider.overrideWithValue(stubPeer()),
        currentUserIdProvider.overrideWithValue('me'),
      ],
    );
    await pumpWithI18n(tester, widget);
    await tester.tap(find.text('Connections'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('No connections yet'),
      findsOneWidget,
    );
  });

  testWidgets('connections tab lists connection rows', (tester) async {
    final widget = await wrapWithTheme(
      child: const InboxScreen(),
      overrides: <Override>[
        introsServiceProvider.overrideWithValue(stubIntros()),
        connectionsServiceProvider.overrideWithValue(
          stubConnections(<Connection>[buildConnection(name: 'Alice')]),
        ),
        peerProfileServiceProvider.overrideWithValue(stubPeer()),
        currentUserIdProvider.overrideWithValue('me'),
      ],
    );
    await pumpWithI18n(tester, widget);
    await tester.tap(find.text('Connections'));
    await tester.pumpAndSettle();
    expect(find.text('Alice'), findsOneWidget);
  });
}
