import 'package:connect_mobile/features/onboarding/data/onboarding_draft_repository.dart';
import 'package:connect_mobile/features/onboarding/domain/goal_type.dart';
import 'package:connect_mobile/features/onboarding/domain/onboarding_draft.dart';
import 'package:connect_mobile/features/onboarding/providers/onboarding_draft_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Regression coverage: the onboarding draft must survive an app restart
/// (modeled here as disposing one ProviderContainer and booting a fresh
/// one against the same SharedPreferences). Without persistence we'd risk
/// losing user input when the OS evicts the process mid-flow.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('draft mutations persist across a simulated app restart', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    ProviderContainer makeContainer() => ProviderContainer(
          overrides: <Override>[
            sharedPreferencesProvider.overrideWith((_) async => prefs),
            onboardingDraftRepositoryProvider
                .overrideWith((_) async => OnboardingDraftRepository(prefs)),
          ],
        );

    // "First boot": mutate a few fields, then dispose the container as if
    // the user backgrounded the app.
    final ProviderContainer first = makeContainer();
    await first.read(onboardingDraftProvider.future);
    await first.read(onboardingDraftProvider.notifier).updateName('Ada');
    await first.read(onboardingDraftProvider.notifier).updateHandle('ada');
    await first
        .read(onboardingDraftProvider.notifier)
        .updateGoalType(GoalType.hire);
    await first
        .read(onboardingDraftProvider.notifier)
        .updateGoalText('Looking to hire a fractional designer for our app.');
    first.dispose();

    // "Second boot": brand-new container against the same SharedPreferences.
    final ProviderContainer second = makeContainer();
    addTearDown(second.dispose);
    final OnboardingDraft restored =
        await second.read(onboardingDraftProvider.future);

    expect(restored.name, 'Ada');
    expect(restored.handle, 'ada');
    expect(restored.goalType, GoalType.hire);
    expect(restored.goalText, contains('designer'));
  });

  test('seeded draft is hydrated by the notifier on first read', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    // Pre-seed as if a prior run had persisted the draft.
    await OnboardingDraftRepository(prefs).write(
      const OnboardingDraft(
        name: 'Pre Seeded',
        handle: 'preseed',
        roles: <String>['founder'],
        primaryRole: 'founder',
      ),
    );

    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        sharedPreferencesProvider.overrideWith((_) async => prefs),
        onboardingDraftRepositoryProvider
            .overrideWith((_) async => OnboardingDraftRepository(prefs)),
      ],
    );
    addTearDown(container.dispose);

    final OnboardingDraft draft =
        await container.read(onboardingDraftProvider.future);
    expect(draft.name, 'Pre Seeded');
    expect(draft.handle, 'preseed');
    expect(draft.roles, <String>['founder']);
    expect(draft.primaryRole, 'founder');
  });
}
