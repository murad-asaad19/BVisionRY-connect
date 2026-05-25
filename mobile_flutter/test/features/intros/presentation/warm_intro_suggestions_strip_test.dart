import 'package:connect_mobile/features/intros/data/warm_intros_service.dart';
import 'package:connect_mobile/features/intros/domain/warm_suggestion.dart';
import 'package:connect_mobile/features/intros/presentation/warm_intro_suggestions_strip.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/intros_fixtures.dart';
import '../../../helpers/pump.dart';

class _FakeWarmIntrosService extends Mock implements WarmIntrosService {}

void main() {
  setUpAll(() => registerFallbackValue(<String, dynamic>{}));

  _FakeWarmIntrosService stub(List<WarmSuggestion> rows) {
    final fake = _FakeWarmIntrosService();
    when(() => fake.suggestWarmIntros(limit: any(named: 'limit')))
        .thenAnswer((_) async => rows);
    return fake;
  }

  testWidgets('renders nothing when there are no suggestions', (tester) async {
    final widget = await wrapWithTheme(
      child: const WarmIntroSuggestionsStrip(),
      overrides: <Override>[
        warmIntrosServiceProvider.overrideWithValue(stub(const [])),
      ],
    );
    await pumpWithI18n(tester, widget);
    expect(find.byType(WarmIntroSuggestionsStrip), findsOneWidget);
    expect(find.textContaining('Via'), findsNothing);
  });

  testWidgets('renders one card per suggestion with via copy', (tester) async {
    final widget = await wrapWithTheme(
      child: const WarmIntroSuggestionsStrip(),
      overrides: <Override>[
        warmIntrosServiceProvider.overrideWithValue(
          stub(<WarmSuggestion>[
            buildWarmSuggestion(),
            buildWarmSuggestion(targetId: 'target-2', targetName: 'Bob'),
          ]),
        ),
      ],
    );
    await pumpWithI18n(tester, widget);
    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('Bob'), findsOneWidget);
    expect(find.textContaining('Via Mia'), findsAtLeastNWidgets(1));
  });

  testWidgets('shows +N pill when mutual_count > 1', (tester) async {
    final widget = await wrapWithTheme(
      child: const WarmIntroSuggestionsStrip(),
      overrides: <Override>[
        warmIntrosServiceProvider.overrideWithValue(
          stub(<WarmSuggestion>[buildWarmSuggestion(mutualCount: 3)]),
        ),
      ],
    );
    await pumpWithI18n(tester, widget);
    expect(find.text('+2'), findsOneWidget);
  });
}
