import 'package:connect_mobile/core/i18n/locale_notifier.dart';
import 'package:connect_mobile/core/theme/app_theme.dart';
import 'package:connect_mobile/features/intros/data/intros_service.dart';
import 'package:connect_mobile/features/intros/domain/intro.dart';
import 'package:connect_mobile/features/intros/domain/intro_enums.dart';
import 'package:connect_mobile/features/intros/presentation/intro_detail_screen.dart';
import 'package:connect_mobile/features/intros/providers/intros_providers.dart';
import 'package:connect_mobile/features/profile/data/peer_profile_service.dart';
import 'package:connect_mobile/features/profile/data/profile_signals_service.dart';
import 'package:connect_mobile/features/profile/domain/profile.dart';
import 'package:connect_mobile/features/profile/domain/profile_signals.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/intros_fixtures.dart';
import '../../../../helpers/pump.dart';

class _FakeIntrosService extends Mock implements IntrosService {}

class _FakePeerProfileService extends Mock implements PeerProfileService {}

class _EmptySignalsService implements ProfileSignalsService {
  @override
  Future<ProfileSignals> fetchSignals(String targetUserId) async =>
      ProfileSignals.empty;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => registerFallbackValue(<String, dynamic>{}));

  _FakeIntrosService stub({List<Intro> received = const <Intro>[]}) {
    final fake = _FakeIntrosService();
    when(
      () => fake.listReceivedIntros(viewerId: any(named: 'viewerId')),
    ).thenAnswer((_) async => received);
    when(
      () => fake.listSentIntros(viewerId: any(named: 'viewerId')),
    ).thenAnswer((_) async => const <Intro>[]);
    when(() => fake.introsTodayCount()).thenAnswer((_) async => 0);
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

  Future<void> pump(WidgetTester tester, Intro intro) async {
    final loader = await primedLocaleLoader();
    await tester.pumpWidgetBuilder(
      ProviderScope(
        overrides: <Override>[
          localeLoaderProvider.overrideWithValue(loader),
          introsServiceProvider
              .overrideWithValue(stub(received: <Intro>[intro])),
          peerProfileServiceProvider.overrideWithValue(stubPeer()),
          profileSignalsServiceProvider.overrideWithValue(
            _EmptySignalsService(),
          ),
          currentUserIdProvider.overrideWithValue('me'),
        ],
        child: const IntroDetailScreen(introId: 'intro-1'),
      ),
      wrapper: materialAppWrapper(theme: buildAppTheme(Brightness.light)),
      surfaceSize: const Size(390, 844),
    );
    await tester.pumpAndSettle();
  }

  testGoldens('IntroDetailScreen — direct, delivered', (tester) async {
    await pump(
      tester,
      buildIntro(
        note: "Hello Alice, I'm working on a fintech startup and I'd love to "
            "trade notes. Your background in payments would be incredibly "
            "valuable to where we're heading.",
      ),
    );
    await screenMatchesGolden(tester, 'intro_detail_direct_delivered');
  });

  testGoldens('IntroDetailScreen — warm_request shows Forward CTA', (
    tester,
  ) async {
    await pump(
      tester,
      buildIntro(
        kind: IntroKind.warmRequest,
        warmTargetId: 'target-x',
        note: 'Asking your help to reach Bob about an investor intro. '
            'We met at the founder dinner last quarter — context matters.',
      ),
    );
    await screenMatchesGolden(tester, 'intro_detail_warm_request');
  });

  testGoldens('IntroDetailScreen — declined hides action row', (tester) async {
    await pump(tester, buildIntro(state: IntroState.declined));
    await screenMatchesGolden(tester, 'intro_detail_declined');
  });
}
