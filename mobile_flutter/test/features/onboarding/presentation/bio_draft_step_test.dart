import 'package:connect_mobile/core/i18n/locale_loader.dart';
import 'package:connect_mobile/core/i18n/locale_notifier.dart';
import 'package:connect_mobile/core/routing/routes.dart';
import 'package:connect_mobile/core/theme/app_theme.dart';
import 'package:connect_mobile/core/widgets/widgets.dart';
import 'package:connect_mobile/features/onboarding/data/onboarding_draft_repository.dart';
import 'package:connect_mobile/features/onboarding/domain/goal_type.dart';
import 'package:connect_mobile/features/onboarding/domain/onboarding_draft.dart';
import 'package:connect_mobile/features/onboarding/presentation/bio_draft_step.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/pump.dart';

const OnboardingDraft _seedDraft = OnboardingDraft(
  goalText: 'Hiring a fractional designer for our healthtech app.',
  goalType: GoalType.hire,
  name: 'Ada',
  handle: 'ada',
  roles: <String>['founder'],
  primaryRole: 'founder',
  // No headline / bio -> fresh seed prefills from the deterministic template.
);

/// Reads the live text of an [AppInput] identified by [key]. The inner
/// `TextField` holds the current value.
String _inputText(WidgetTester tester, String key) {
  final TextField field = tester.widget<TextField>(
    find.descendant(
      of: find.byKey(ValueKey<String>(key)),
      matching: find.byType(TextField),
    ),
  );
  return field.controller?.text ?? '';
}

Future<Widget> _renderWith(
  SharedPreferences prefs,
  OnboardingDraftRepository repo,
) {
  return wrapWithTheme(
    child: const BioDraftStep(),
    overrides: <Override>[
      onboardingDraftRepositoryProvider.overrideWith((_) async => repo),
      sharedPreferencesProvider.overrideWith((_) async => prefs),
    ],
  );
}

/// Router-backed wrapper for the save path: tapping "Looks good" calls
/// `context.go(Routes.onboardingAbout)`, which needs a [GoRouter] in the tree.
/// A bare [MaterialApp] (as in [_renderWith]) would throw on navigation.
Future<Widget> _renderRouted(
  SharedPreferences prefs,
  OnboardingDraftRepository repo,
) async {
  final LocaleLoader loader = await primedLocaleLoader();
  final GoRouter router = GoRouter(
    initialLocation: Routes.onboardingBio,
    routes: <RouteBase>[
      GoRoute(
        path: Routes.onboardingBio,
        builder: (_, __) => const BioDraftStep(),
      ),
      GoRoute(
        path: Routes.onboardingAbout,
        builder: (_, __) =>
            const Scaffold(body: Text('about', key: ValueKey<String>('about'))),
      ),
    ],
  );
  return ProviderScope(
    overrides: <Override>[
      localeLoaderProvider.overrideWithValue(loader),
      onboardingDraftRepositoryProvider.overrideWith((_) async => repo),
      sharedPreferencesProvider.overrideWith((_) async => prefs),
    ],
    child: MaterialApp.router(
      theme: buildAppTheme(Brightness.light),
      routerConfig: router,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  testWidgets(
    'fresh draft -> fields prefilled from the template, Looks good saves',
    (WidgetTester tester) async {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final OnboardingDraftRepository repo = OnboardingDraftRepository(prefs);
      await repo.write(_seedDraft);

      // No spinner now, so pumpAndSettle is safe.
      await pumpWithI18n(tester, await _renderRouted(prefs, repo));

      // Both fields are present and prefilled (non-empty) from the template.
      final String headline = _inputText(tester, 'bio-custom-headline');
      final String bio = _inputText(tester, 'bio-custom-bio');
      expect(headline.isNotEmpty, isTrue);
      expect(bio.isNotEmpty, isTrue);

      // The template derives from the role + goal, so the role label appears.
      expect(headline.contains('Founder'), isTrue);

      // Looks-good is enabled with the valid prefilled values; tapping it
      // persists the headline + bio and advances to the About step.
      final Finder looksGood =
          find.byKey(const ValueKey<String>('bio-looks-good'));
      expect(looksGood, findsOneWidget);
      await tester.tap(looksGood);
      await tester.pumpAndSettle();

      final OnboardingDraft? saved = await repo.read();
      expect(saved?.headline, headline.trim());
      expect(saved?.bio, bio.trim());
      // Navigation advanced without crashing.
      expect(find.byKey(const ValueKey<String>('about')), findsOneWidget);
    },
  );

  testWidgets(
    'back-nav with an existing headline+bio -> fields prefilled with those',
    (WidgetTester tester) async {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final OnboardingDraftRepository repo = OnboardingDraftRepository(prefs);
      await repo.write(
        _seedDraft.copyWith(
          headline: 'Existing headline',
          bio: 'An existing bio that was chosen earlier in the flow.',
        ),
      );

      await pumpWithI18n(tester, await _renderWith(prefs, repo));

      expect(_inputText(tester, 'bio-custom-headline'), 'Existing headline');
      expect(
        _inputText(tester, 'bio-custom-bio'),
        'An existing bio that was chosen earlier in the flow.',
      );
    },
  );

  testWidgets(
    'too-short input keeps the Looks-good button disabled',
    (WidgetTester tester) async {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final OnboardingDraftRepository repo = OnboardingDraftRepository(prefs);
      await repo.write(_seedDraft);

      await pumpWithI18n(tester, await _renderWith(prefs, repo));

      // Headline below the 5-char minimum invalidates the form.
      await tester.enterText(
        find.byKey(const ValueKey<String>('bio-custom-headline')),
        'Hi',
      );
      await tester.pump();

      final AppButton button = tester.widget<AppButton>(
        find.byKey(const ValueKey<String>('bio-looks-good')),
      );
      expect(button.onPressed, isNull);

      // A valid headline but a too-short bio also gates the button.
      await tester.enterText(
        find.byKey(const ValueKey<String>('bio-custom-headline')),
        'A valid headline',
      );
      await tester.enterText(
        find.byKey(const ValueKey<String>('bio-custom-bio')),
        'short',
      );
      await tester.pump();

      final AppButton button2 = tester.widget<AppButton>(
        find.byKey(const ValueKey<String>('bio-looks-good')),
      );
      expect(button2.onPressed, isNull);
    },
  );
}
