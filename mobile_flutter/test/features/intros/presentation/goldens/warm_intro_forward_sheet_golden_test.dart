import 'package:connect_mobile/core/i18n/locale_notifier.dart';
import 'package:connect_mobile/core/theme/app_theme.dart';
import 'package:connect_mobile/features/intros/data/warm_intros_service.dart';
import 'package:connect_mobile/features/intros/domain/intro_enums.dart';
import 'package:connect_mobile/features/intros/presentation/warm_intro_forward_sheet.dart';
import 'package:connect_mobile/features/profile/data/peer_profile_service.dart';
import 'package:connect_mobile/features/profile/domain/profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/intros_fixtures.dart';
import '../../../../helpers/pump.dart';

class _FakeWarmIntrosService extends Mock implements WarmIntrosService {}

class _FakePeerProfileService extends Mock implements PeerProfileService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => registerFallbackValue(<String, dynamic>{}));

  _FakePeerProfileService stubPeer() {
    final fake = _FakePeerProfileService();
    when(() => fake.fetchById(any())).thenAnswer((Invocation inv) async {
      final String id = inv.positionalArguments.first as String;
      if (id == 'target-x') {
        return const Profile(
          id: 'target-x',
          handle: 'bob',
          name: 'Bob',
          primaryRole: 'investor',
        );
      }
      return const Profile(
        id: 'sender-1',
        handle: 'asker',
        name: 'Ada Asker',
        primaryRole: 'founder',
      );
    });
    return fake;
  }

  testGoldens('WarmIntroForwardSheet — populated peers', (tester) async {
    final loader = await primedLocaleLoader();
    final intro = buildIntro(
      kind: IntroKind.warmRequest,
      warmTargetId: 'target-x',
      note: 'Please introduce me to Bob — we have great mutual goals around '
          'investing in MENA fintech and I would like to share my deck.',
    );
    await tester.pumpWidgetBuilder(
      ProviderScope(
        overrides: <Override>[
          localeLoaderProvider.overrideWithValue(loader),
          warmIntrosServiceProvider.overrideWithValue(_FakeWarmIntrosService()),
          peerProfileServiceProvider.overrideWithValue(stubPeer()),
        ],
        child: Scaffold(body: WarmIntroForwardSheet(intro: intro)),
      ),
      wrapper: materialAppWrapper(theme: buildAppTheme(Brightness.light)),
      surfaceSize: const Size(390, 800),
    );
    await tester.pumpAndSettle();
    await screenMatchesGolden(tester, 'warm_intro_forward_sheet_populated');
  });
}
