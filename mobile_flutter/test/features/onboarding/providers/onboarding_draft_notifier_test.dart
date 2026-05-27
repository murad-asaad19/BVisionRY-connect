import 'package:connect_mobile/features/onboarding/data/onboarding_draft_repository.dart';
import 'package:connect_mobile/features/onboarding/domain/goal_type.dart';
import 'package:connect_mobile/features/onboarding/domain/onboarding_draft.dart';
import 'package:connect_mobile/features/onboarding/providers/onboarding_draft_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  Future<ProviderContainer> makeContainer() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return ProviderContainer(
      overrides: <Override>[
        onboardingDraftRepositoryProvider.overrideWith(
          (Ref<AsyncValue<OnboardingDraftRepository>> ref) async =>
              OnboardingDraftRepository(prefs),
        ),
      ],
    );
  }

  test('initial state is the empty draft when nothing persisted', () async {
    final ProviderContainer container = await makeContainer();
    addTearDown(container.dispose);
    final OnboardingDraft state =
        await container.read(onboardingDraftProvider.future);
    expect(state, const OnboardingDraft());
  });

  test('updateGoalText/Type mutate state AND persist to repo', () async {
    final ProviderContainer container = await makeContainer();
    addTearDown(container.dispose);
    await container.read(onboardingDraftProvider.future);

    await container
        .read(onboardingDraftProvider.notifier)
        .updateGoalText('I want to hire a designer for our app.');
    await container
        .read(onboardingDraftProvider.notifier)
        .updateGoalType(GoalType.hire);

    final OnboardingDraft state =
        container.read(onboardingDraftProvider).value!;
    expect(state.goalText, contains('designer'));
    expect(state.goalType, GoalType.hire);

    final OnboardingDraftRepository repo =
        await container.read(onboardingDraftRepositoryProvider.future);
    final OnboardingDraft? reloaded = await repo.read();
    expect(reloaded?.goalType, GoalType.hire);
    expect(reloaded?.goalText, contains('designer'));
  });

  test('rehydrates from repo on first load', () async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await OnboardingDraftRepository(prefs).write(
      const OnboardingDraft(name: 'Ada', handle: 'ada'),
    );
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        onboardingDraftRepositoryProvider.overrideWith(
          (Ref<AsyncValue<OnboardingDraftRepository>> ref) async =>
              OnboardingDraftRepository(prefs),
        ),
      ],
    );
    addTearDown(container.dispose);
    final OnboardingDraft state =
        await container.read(onboardingDraftProvider.future);
    expect(state.name, 'Ada');
    expect(state.handle, 'ada');
  });

  test('reset() clears persistence and resets state', () async {
    final ProviderContainer container = await makeContainer();
    addTearDown(container.dispose);
    await container.read(onboardingDraftProvider.future);
    await container.read(onboardingDraftProvider.notifier).updateName('Ada');
    await container.read(onboardingDraftProvider.notifier).reset();
    expect(
      container.read(onboardingDraftProvider).value,
      const OnboardingDraft(),
    );
    final OnboardingDraftRepository repo =
        await container.read(onboardingDraftRepositoryProvider.future);
    expect(await repo.read(), isNull);
  });

  test('updateRoles re-defaults primaryRole when it falls out of the new set',
      () async {
    final ProviderContainer container = await makeContainer();
    addTearDown(container.dispose);
    await container.read(onboardingDraftProvider.future);

    final OnboardingDraftNotifier notifier =
        container.read(onboardingDraftProvider.notifier);
    await notifier.updateRoles(<String>['founder', 'leader']);
    await notifier.updatePrimaryRole('founder');
    expect(
      container.read(onboardingDraftProvider).value!.primaryRole,
      'founder',
    );

    // Drop "founder" — primary falls out, so the notifier re-defaults
    // primary to the first remaining role ("leader"). This removes the
    // "Next is disabled with no indication why" friction users hit
    // after picking roles but forgetting to also tap a primary.
    await notifier.updateRoles(<String>['leader']);
    expect(
      container.read(onboardingDraftProvider).value!.primaryRole,
      'leader',
    );

    // Removing every role still clears primary (no role to default to).
    await notifier.updateRoles(<String>[]);
    expect(container.read(onboardingDraftProvider).value!.primaryRole, isNull);
  });

  test('updateRoles preserves primaryRole when it stays in the new set',
      () async {
    final ProviderContainer container = await makeContainer();
    addTearDown(container.dispose);
    await container.read(onboardingDraftProvider.future);

    final OnboardingDraftNotifier notifier =
        container.read(onboardingDraftProvider.notifier);
    await notifier.updateRoles(<String>['founder', 'leader']);
    await notifier.updatePrimaryRole('founder');
    await notifier.updateRoles(<String>['founder', 'investor']);
    expect(
      container.read(onboardingDraftProvider).value!.primaryRole,
      'founder',
    );
  });

  test('updateHeadline(null) clears the field', () async {
    final ProviderContainer container = await makeContainer();
    addTearDown(container.dispose);
    await container.read(onboardingDraftProvider.future);
    final OnboardingDraftNotifier notifier =
        container.read(onboardingDraftProvider.notifier);
    await notifier.updateHeadline('Hardware founder');
    await notifier.updateHeadline(null);
    expect(container.read(onboardingDraftProvider).value!.headline, isNull);
  });
}
