import 'package:connect_mobile/features/intros/data/warm_intros_service.dart';
import 'package:connect_mobile/features/intros/domain/intro_enums.dart';
import 'package:connect_mobile/features/intros/presentation/warm_intro_forward_sheet.dart';
import 'package:connect_mobile/features/profile/data/peer_profile_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/intros_fixtures.dart';
import '../../../helpers/pump.dart';

class _FakeWarmIntrosService extends Mock implements WarmIntrosService {}

class _FakePeerProfileService extends Mock implements PeerProfileService {}

void main() {
  setUpAll(() => registerFallbackValue(<String, dynamic>{}));

  _FakePeerProfileService stubPeer() {
    final fake = _FakePeerProfileService();
    when(() => fake.fetchById(any())).thenAnswer((_) async => null);
    return fake;
  }

  testWidgets('debug build asserts when intro.kind != warm_request', (
    tester,
  ) async {
    final intro = buildIntro(); // default direct
    expect(
      () => WarmIntroForwardSheet(intro: intro),
      throwsAssertionError,
    );
  });

  testWidgets('Forward CTA disabled below 80 chars', (tester) async {
    final intro = buildIntro(
      kind: IntroKind.warmRequest,
      warmTargetId: 'target-x',
    );
    final widget = await wrapWithTheme(
      child: Scaffold(body: WarmIntroForwardSheet(intro: intro)),
      overrides: <Override>[
        warmIntrosServiceProvider.overrideWithValue(_FakeWarmIntrosService()),
        peerProfileServiceProvider.overrideWithValue(stubPeer()),
      ],
    );
    await pumpWithI18n(tester, widget);
    final sendKey = find.byKey(const ValueKey('warm-forward-send'));
    final InkWell inkWell = tester.widget(
      find.descendant(of: sendKey, matching: find.byType(InkWell)).first,
    );
    expect(inkWell.onTap, isNull);
  });

  testWidgets('renders original asker note in the gold banner', (
    tester,
  ) async {
    final intro = buildIntro(
      kind: IntroKind.warmRequest,
      warmTargetId: 'target-x',
      note: 'Please introduce me to your friend ' * 4,
    );
    final widget = await wrapWithTheme(
      child: Scaffold(body: WarmIntroForwardSheet(intro: intro)),
      overrides: <Override>[
        warmIntrosServiceProvider.overrideWithValue(_FakeWarmIntrosService()),
        peerProfileServiceProvider.overrideWithValue(stubPeer()),
      ],
    );
    await pumpWithI18n(tester, widget);
    expect(find.textContaining('Please introduce me'), findsOneWidget);
  });
}
