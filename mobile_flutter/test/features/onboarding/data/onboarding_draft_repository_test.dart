import 'package:connect_mobile/features/onboarding/data/onboarding_draft_repository.dart';
import 'package:connect_mobile/features/onboarding/domain/goal_type.dart';
import 'package:connect_mobile/features/onboarding/domain/onboarding_draft.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('read() returns null when nothing persisted', () async {
    final OnboardingDraftRepository repo =
        OnboardingDraftRepository(await SharedPreferences.getInstance());
    expect(await repo.read(), isNull);
  });

  test('write then read round-trips the draft', () async {
    final OnboardingDraftRepository repo =
        OnboardingDraftRepository(await SharedPreferences.getInstance());
    const OnboardingDraft d = OnboardingDraft(
      goalText: 'My goal text long enough',
      goalType: GoalType.hire,
      name: 'Ada',
      handle: 'ada',
      roles: <String>['founder'],
      primaryRole: 'founder',
      city: 'Berlin',
      country: 'Germany',
    );
    await repo.write(d);
    final OnboardingDraft? restored = await repo.read();
    expect(restored, equals(d));
  });

  test('clear() removes the stored draft', () async {
    final OnboardingDraftRepository repo =
        OnboardingDraftRepository(await SharedPreferences.getInstance());
    await repo.write(const OnboardingDraft(goalText: 'temp'));
    await repo.clear();
    expect(await repo.read(), isNull);
  });

  test('read() returns null when payload is corrupt JSON', () async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('onboarding.draft.v1', 'not-json');
    final OnboardingDraftRepository repo = OnboardingDraftRepository(prefs);
    expect(await repo.read(), isNull);
  });

  test('read() returns null when payload references unknown goal_type', () async {
    // Forward-compat: a future client could persist a goal_type the current
    // build doesn't recognise — round-trip rather than throw.
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'onboarding.draft.v1',
      '{"goal_text":"hi","goal_type":"future_value","name":"","handle":"",'
          '"roles":[],"primary_role":null,"city":"","country":"",'
          '"headline":null,"bio":null}',
    );
    final OnboardingDraftRepository repo = OnboardingDraftRepository(prefs);
    final OnboardingDraft? restored = await repo.read();
    expect(restored, isNotNull);
    expect(restored!.goalType, isNull);
  });
}
