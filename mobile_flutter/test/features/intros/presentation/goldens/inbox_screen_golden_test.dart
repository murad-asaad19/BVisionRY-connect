import 'package:connect_mobile/core/i18n/locale_notifier.dart';
import 'package:connect_mobile/core/theme/app_theme.dart';
import 'package:connect_mobile/features/connections/data/connections_service.dart';
import 'package:connect_mobile/features/connections/domain/connection.dart';
import 'package:connect_mobile/features/intros/data/intros_service.dart';
import 'package:connect_mobile/features/intros/domain/intro.dart';
import 'package:connect_mobile/features/intros/domain/intro_enums.dart';
import 'package:connect_mobile/features/intros/presentation/inbox_screen.dart';
import 'package:connect_mobile/features/intros/providers/intros_providers.dart';
import 'package:connect_mobile/features/profile/data/peer_profile_service.dart';
import 'package:connect_mobile/features/profile/domain/profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/intros_fixtures.dart';
import '../../../../helpers/pump.dart';

class _FakeIntrosService extends Mock implements IntrosService {}

class _FakeConnectionsService extends Mock implements ConnectionsService {}

class _FakePeerProfileService extends Mock implements PeerProfileService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
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

  _FakeConnectionsService stubConnections([
    List<Connection> rows = const <Connection>[],
  ]) {
    final fake = _FakeConnectionsService();
    when(() => fake.listConnections()).thenAnswer((_) async => rows);
    return fake;
  }

  _FakePeerProfileService stubPeer() {
    final fake = _FakePeerProfileService();
    when(() => fake.fetchById(any())).thenAnswer((_) async {
      return const Profile(
        id: 'peer',
        handle: 'alice',
        name: 'Alice',
        primaryRole: 'founder',
      );
    });
    return fake;
  }

  Future<void> pumpInbox(
    WidgetTester tester, {
    required IntrosService intros,
    required ConnectionsService connections,
  }) async {
    final loader = await primedLocaleLoader();
    await tester.pumpWidgetBuilder(
      ProviderScope(
        overrides: <Override>[
          localeLoaderProvider.overrideWithValue(loader),
          introsServiceProvider.overrideWithValue(intros),
          connectionsServiceProvider.overrideWithValue(connections),
          peerProfileServiceProvider.overrideWithValue(stubPeer()),
          currentUserIdProvider.overrideWithValue('me'),
        ],
        child: const InboxScreen(),
      ),
      wrapper: materialAppWrapper(theme: buildAppTheme(Brightness.light)),
      surfaceSize: const Size(390, 844),
    );
    await tester.pumpAndSettle();
  }

  testGoldens('InboxScreen — received with two pending intros', (tester) async {
    await pumpInbox(
      tester,
      intros: stubIntros(
        received: <Intro>[
          buildIntro(id: 'i-1', note: 'Hi Alice, ${'x' * 90}'),
          buildIntro(
            id: 'i-2',
            senderId: 'sender-2',
            state: IntroState.accepted,
          ),
        ],
      ),
      connections: stubConnections(),
    );
    await screenMatchesGolden(tester, 'inbox_screen_received');
  });

  testGoldens('InboxScreen — empty received tab', (tester) async {
    await pumpInbox(
      tester,
      intros: stubIntros(),
      connections: stubConnections(),
    );
    await screenMatchesGolden(tester, 'inbox_screen_empty_received');
  });

  testGoldens('InboxScreen — connections sub-tab populated', (tester) async {
    await pumpInbox(
      tester,
      intros: stubIntros(),
      connections: stubConnections(<Connection>[
        buildConnection(name: 'Alice', primaryRole: 'founder'),
        buildConnection(
          userId: 'peer-2',
          handle: 'bob',
          name: 'Bob',
          primaryRole: 'investor',
          conversationId: 'conv-2',
        ),
      ]),
    );
    await tester.tap(find.text('Connections'));
    await tester.pumpAndSettle();
    await screenMatchesGolden(tester, 'inbox_screen_connections');
  });
}
