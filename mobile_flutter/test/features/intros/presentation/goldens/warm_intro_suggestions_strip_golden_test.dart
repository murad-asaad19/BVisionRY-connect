import 'package:connect_mobile/core/i18n/locale_notifier.dart';
import 'package:connect_mobile/core/theme/app_theme.dart';
import 'package:connect_mobile/features/intros/data/warm_intros_service.dart';
import 'package:connect_mobile/features/intros/domain/warm_suggestion.dart';
import 'package:connect_mobile/features/intros/presentation/warm_intro_suggestions_strip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/intros_fixtures.dart';
import '../../../../helpers/pump.dart';

class _FakeWarmIntrosService extends Mock implements WarmIntrosService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => registerFallbackValue(<String, dynamic>{}));

  _FakeWarmIntrosService stub(List<WarmSuggestion> rows) {
    final fake = _FakeWarmIntrosService();
    when(() => fake.suggestWarmIntros(limit: any(named: 'limit')))
        .thenAnswer((_) async => rows);
    return fake;
  }

  testGoldens('WarmIntroSuggestionsStrip — three suggestions', (tester) async {
    final loader = await primedLocaleLoader();
    await tester.pumpWidgetBuilder(
      ProviderScope(
        overrides: <Override>[
          localeLoaderProvider.overrideWithValue(loader),
          warmIntrosServiceProvider.overrideWithValue(
            stub(<WarmSuggestion>[
              buildWarmSuggestion(),
              buildWarmSuggestion(
                targetId: 'target-2',
                targetName: 'Bob',
                topMutualName: 'Sara',
                mutualCount: 3,
              ),
              buildWarmSuggestion(
                targetId: 'target-3',
                targetName: 'Charlie',
                topMutualName: 'Mia',
              ),
            ]),
          ),
        ],
        child: const Scaffold(body: WarmIntroSuggestionsStrip()),
      ),
      wrapper: materialAppWrapper(theme: buildAppTheme(Brightness.light)),
      surfaceSize: const Size(390, 240),
    );
    await tester.pumpAndSettle();
    await screenMatchesGolden(tester, 'warm_intro_suggestions_strip');
  });
}
