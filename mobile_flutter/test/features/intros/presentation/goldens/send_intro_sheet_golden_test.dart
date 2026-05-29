import 'package:connect_mobile/core/i18n/locale_notifier.dart';
import 'package:connect_mobile/core/theme/app_theme.dart';
import 'package:connect_mobile/features/intros/data/intros_service.dart';
import 'package:connect_mobile/features/intros/presentation/send_intro_sheet.dart';
import 'package:connect_mobile/features/intros/providers/intros_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/pump.dart';

class _FakeIntrosService extends Mock implements IntrosService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => registerFallbackValue(<String, dynamic>{}));

  _FakeIntrosService stub({int today = 3, int sent = 3, int cap = 5}) {
    final fake = _FakeIntrosService();
    when(() => fake.introsTodayCount()).thenAnswer((_) async => today);
    when(
      () => fake.introsSentTodayCount(),
    ).thenAnswer((_) async => (used: sent, cap: cap));
    return fake;
  }

  testGoldens('SendIntroSheet — empty + recipient preview', (tester) async {
    final loader = await primedLocaleLoader();
    await tester.pumpWidgetBuilder(
      ProviderScope(
        overrides: <Override>[
          localeLoaderProvider.overrideWithValue(loader),
          introsServiceProvider.overrideWithValue(stub()),
          currentUserIdProvider.overrideWithValue('me'),
          dailyIntroCapProvider.overrideWith((_) => 5),
          accountTierProvider.overrideWith((_) => IntrosTier.free),
        ],
        child: const Scaffold(
          body: SendIntroSheet(
            recipient: SendIntroRecipient(
              id: 'r-1',
              name: 'Rachel Doe',
              handle: 'rachel',
              verified: true,
            ),
          ),
        ),
      ),
      wrapper: materialAppWrapper(theme: buildAppTheme(Brightness.light)),
      surfaceSize: const Size(390, 600),
    );
    await tester.pumpAndSettle();
    await screenMatchesGolden(tester, 'send_intro_sheet_empty');
  });
}
