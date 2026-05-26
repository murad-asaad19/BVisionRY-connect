import 'package:connect_mobile/core/i18n/locale_loader.dart';
import 'package:connect_mobile/core/i18n/locale_notifier.dart';
import 'package:connect_mobile/core/routing/app_router.dart';
import 'package:connect_mobile/core/theme/app_theme.dart';
import 'package:connect_mobile/features/auth/data/profile_repository.dart';
import 'package:connect_mobile/features/auth/providers/auth_service_provider.dart';
import 'package:connect_mobile/features/connections/data/connections_service.dart';
import 'package:connect_mobile/features/connections/domain/connection.dart';
import 'package:connect_mobile/features/discovery/data/discovery_service.dart';
import 'package:connect_mobile/features/discovery/domain/daily_match.dart';
import 'package:connect_mobile/features/discovery/providers/midnight_invalidator.dart';
import 'package:connect_mobile/features/intros/data/intros_service.dart';
import 'package:connect_mobile/features/intros/data/warm_intros_service.dart';
import 'package:connect_mobile/features/intros/domain/intro.dart';
import 'package:connect_mobile/features/intros/domain/intro_enums.dart';
import 'package:connect_mobile/features/intros/domain/warm_suggestion.dart';
import 'package:connect_mobile/features/profile/data/peer_profile_service.dart';
import 'package:connect_mobile/features/profile/domain/profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../helpers/fake_discovery_service.dart';
import '../helpers/fake_supabase.dart';
import '../helpers/intros_fixtures.dart';
import '../helpers/pump.dart';

class _Q implements ProfileQueryRunner {
  _Q(this.row);
  final Map<String, dynamic>? row;
  @override
  Future<Map<String, dynamic>?> selectById(String id) async => row;
}

class _NoOpMidnightInvalidator extends MidnightInvalidator {
  @override
  void build() {
    // intentionally empty: skip Timer + lifecycle listener registration.
  }
}

class _FakeIntrosService extends Mock implements IntrosService {}

class _FakeWarmIntrosService extends Mock implements WarmIntrosService {}

class _FakeConnectionsService extends Mock implements ConnectionsService {}

class _FakePeerProfileService extends Mock implements PeerProfileService {}

Future<void> _pumpApp(
  WidgetTester tester, {
  required IntrosService intros,
  required WarmIntrosService warm,
  required ConnectionsService connections,
  required PeerProfileService peerProfile,
}) async {
  final LocaleLoader loader = await primedLocaleLoader();
  final FakeDiscoveryService fakeDiscovery = FakeDiscoveryService();
  when(() => fakeDiscovery.fetchDailyMatches(date: any(named: 'date')))
      .thenAnswer((_) async => const <DailyMatch>[]);

  final FakeAuthGateway auth = FakeAuthGateway();
  auth.pushAuthState(
    AuthChangeEvent.initialSession,
    fakeSession(id: 'me'),
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        authGatewayProvider.overrideWithValue(auth),
        profileRepositoryProvider.overrideWithValue(
          ProfileRepository(
            _Q(<String, dynamic>{
              'id': 'me',
              'onboarded': true,
              'suspended_at': null,
            }),
          ),
        ),
        localeLoaderProvider.overrideWithValue(loader),
        discoveryServiceProvider.overrideWithValue(fakeDiscovery),
        midnightInvalidatorProvider.overrideWith(_NoOpMidnightInvalidator.new),
        introsServiceProvider.overrideWithValue(intros),
        warmIntrosServiceProvider.overrideWithValue(warm),
        connectionsServiceProvider.overrideWithValue(connections),
        peerProfileServiceProvider.overrideWithValue(peerProfile),
      ],
      child: Builder(
        builder: (BuildContext ctx) {
          return MaterialApp.router(
            theme: buildAppTheme(Brightness.light),
            routerConfig:
                ProviderScope.containerOf(ctx).read(appRouterProvider),
          );
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    registerDiscoveryFallbacks();
    registerFallbackValue(<String, dynamic>{});
  });
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    const MethodChannel secureStorageChannel = MethodChannel(
      'plugins.it_nomads.com/flutter_secure_storage',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, (MethodCall _) async {
      return null;
    });
  });

  _FakeIntrosService stubIntros({
    List<Intro> received = const <Intro>[],
    List<Intro> sent = const <Intro>[],
    Intro? acceptResult,
  }) {
    final fake = _FakeIntrosService();
    when(() => fake.listReceivedIntros(viewerId: any(named: 'viewerId')))
        .thenAnswer((_) async => received);
    when(() => fake.listSentIntros(viewerId: any(named: 'viewerId')))
        .thenAnswer((_) async => sent);
    when(() => fake.introsTodayCount()).thenAnswer((_) async => 0);
    if (acceptResult != null) {
      when(() => fake.acceptIntro(any())).thenAnswer((_) async => acceptResult);
    }
    when(
      () => fake.sendIntro(
        recipientId: any(named: 'recipientId'),
        note: any(named: 'note'),
      ),
    ).thenAnswer((_) async => acceptResult ?? buildIntro());
    return fake;
  }

  _FakeWarmIntrosService stubWarm() {
    final fake = _FakeWarmIntrosService();
    when(() => fake.suggestWarmIntros(limit: any(named: 'limit')))
        .thenAnswer((_) async => const <WarmSuggestion>[]);
    return fake;
  }

  _FakeConnectionsService stubConnections() {
    final fake = _FakeConnectionsService();
    when(() => fake.listConnections())
        .thenAnswer((_) async => const <Connection>[]);
    return fake;
  }

  _FakePeerProfileService stubPeer() {
    final fake = _FakePeerProfileService();
    when(() => fake.fetchById(any())).thenAnswer((_) async {
      return const Profile(
        id: 'sender-1',
        handle: 'alice',
        name: 'Alice',
        primaryRole: 'founder',
      );
    });
    return fake;
  }

  testWidgets('Inbox tab → tapping an intro opens detail with Accept', (
    WidgetTester tester,
  ) async {
    final intro = buildIntro(
      id: 'intro-1',
      senderId: 'sender-1',
      note: 'Hi Alice, I would love to learn how you built your payments '
          'stack last quarter — happy to share notes from our infra side.',
    );
    final intros = stubIntros(received: <Intro>[intro]);

    await _pumpApp(
      tester,
      intros: intros,
      warm: stubWarm(),
      connections: stubConnections(),
      peerProfile: stubPeer(),
    );

    // Land on /home, then tap Inbox tab.
    await tester.tap(find.text('Inbox').first);
    await tester.pumpAndSettle();

    // The single intro renders the resolved peer name.
    expect(find.text('Alice'), findsOneWidget);

    // Tap the row to navigate to the detail screen.
    await tester.tap(find.text('Alice'));
    await tester.pumpAndSettle();

    // Detail screen surfaces Accept + Decline for a delivered direct intro.
    expect(find.text('Accept'), findsOneWidget);
    expect(find.text('Decline'), findsOneWidget);
    verify(() => intros.listReceivedIntros(viewerId: any(named: 'viewerId')))
        .called(greaterThanOrEqualTo(1));
  });

  testWidgets('Inbox tab badge reflects unread delivered count', (
    WidgetTester tester,
  ) async {
    final intros = stubIntros(
      received: <Intro>[
        buildIntro(id: 'i-1'),
        buildIntro(id: 'i-2'),
        buildIntro(id: 'i-3', state: IntroState.accepted),
      ],
    );

    await _pumpApp(
      tester,
      intros: intros,
      warm: stubWarm(),
      connections: stubConnections(),
      peerProfile: stubPeer(),
    );

    // Two delivered → Inbox badge shows "2".
    expect(find.text('2'), findsOneWidget);
  });
}
