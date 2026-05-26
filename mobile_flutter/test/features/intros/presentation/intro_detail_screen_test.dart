import 'package:connect_mobile/features/intros/data/intros_service.dart';
import 'package:connect_mobile/features/intros/domain/intro.dart';
import 'package:connect_mobile/features/intros/domain/intro_enums.dart';
import 'package:connect_mobile/features/intros/presentation/intro_detail_screen.dart';
import 'package:connect_mobile/features/intros/providers/intros_providers.dart';
import 'package:connect_mobile/features/profile/data/peer_profile_service.dart';
import 'package:connect_mobile/features/profile/data/profile_signals_service.dart';
import 'package:connect_mobile/features/profile/domain/profile_signals.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/intros_fixtures.dart';
import '../../../helpers/pump.dart';

class _FakeIntrosService extends Mock implements IntrosService {}

class _FakePeerProfileService extends Mock implements PeerProfileService {}

/// Returns [ProfileSignals.empty] so the mutual-connections footer collapses
/// to a zero-height box and the detail screen test stays focused on the
/// intro body itself.
class _EmptySignalsService implements ProfileSignalsService {
  @override
  Future<ProfileSignals> fetchSignals(String targetUserId) async =>
      ProfileSignals.empty;
}

void main() {
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
    when(() => fake.fetchById(any())).thenAnswer((_) async => null);
    return fake;
  }

  /// Common provider override list — every test uses these so the surface
  /// renders without touching Supabase.
  List<Override> commonOverrides({
    required IntrosService intros,
    required PeerProfileService peer,
  }) =>
      <Override>[
        introsServiceProvider.overrideWithValue(intros),
        peerProfileServiceProvider.overrideWithValue(peer),
        profileSignalsServiceProvider.overrideWithValue(_EmptySignalsService()),
        currentUserIdProvider.overrideWithValue('me'),
      ];

  testWidgets('shows note text + delivered badge for a direct intro', (
    tester,
  ) async {
    final intro = buildIntro(note: 'Hello world ' * 8);
    final widget = await wrapWithTheme(
      child: const IntroDetailScreen(introId: 'intro-1'),
      overrides: commonOverrides(
        intros: stub(received: <Intro>[intro]),
        peer: stubPeer(),
      ),
    );
    await pumpWithI18n(tester, widget);
    expect(find.textContaining('Hello world'), findsOneWidget);
    expect(find.byKey(const ValueKey('intro-badge-delivered')), findsOneWidget);
    expect(find.text('Accept'), findsOneWidget);
    expect(find.text('Decline'), findsOneWidget);
  });

  testWidgets('warm_request renders Forward CTA instead of Accept', (
    tester,
  ) async {
    final intro = buildIntro(
      kind: IntroKind.warmRequest,
      warmTargetId: 'target-x',
    );
    final widget = await wrapWithTheme(
      child: const IntroDetailScreen(introId: 'intro-1'),
      overrides: commonOverrides(
        intros: stub(received: <Intro>[intro]),
        peer: stubPeer(),
      ),
    );
    await pumpWithI18n(tester, widget);
    expect(find.text('Forward warm intro'), findsOneWidget);
    expect(find.text('Accept'), findsNothing);
  });

  testWidgets('declined intro hides Accept + Decline buttons', (tester) async {
    final intro = buildIntro(state: IntroState.declined);
    final widget = await wrapWithTheme(
      child: const IntroDetailScreen(introId: 'intro-1'),
      overrides: commonOverrides(
        intros: stub(received: <Intro>[intro]),
        peer: stubPeer(),
      ),
    );
    await pumpWithI18n(tester, widget);
    expect(find.text('Accept'), findsNothing);
    expect(find.text('Decline'), findsNothing);
    expect(find.byKey(const ValueKey('intro-badge-declined')), findsOneWidget);
  });

  testWidgets('expired intro shows expired hint and hides actions', (
    tester,
  ) async {
    final intro = buildIntro(state: IntroState.expired);
    final widget = await wrapWithTheme(
      child: const IntroDetailScreen(introId: 'intro-1'),
      overrides: commonOverrides(
        intros: stub(received: <Intro>[intro]),
        peer: stubPeer(),
      ),
    );
    await pumpWithI18n(tester, widget);
    expect(find.textContaining('expired'), findsOneWidget);
    expect(find.text('Accept'), findsNothing);
  });

  testWidgets('missing intro shows notFound copy', (tester) async {
    final widget = await wrapWithTheme(
      child: const IntroDetailScreen(introId: 'unknown'),
      overrides: commonOverrides(
        intros: stub(),
        peer: stubPeer(),
      ),
    );
    await pumpWithI18n(tester, widget);
    expect(find.text('Intro not found'), findsOneWidget);
  });
}
