import 'package:connect_mobile/core/errors/app_exception.dart';
import 'package:connect_mobile/features/onboarding/data/onboarding_service.dart';
import 'package:connect_mobile/features/onboarding/domain/goal_type.dart';
import 'package:connect_mobile/features/onboarding/domain/onboarding_draft.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakeRunner implements FinishOnboardingRunner {
  _FakeRunner({this.willThrow});
  final Object? willThrow;

  Map<String, dynamic>? capturedParams;

  @override
  Future<void> finish(Map<String, dynamic> params) async {
    capturedParams = params;
    if (willThrow != null) {
      // ignore: only_throw_errors
      throw willThrow!;
    }
  }
}

void main() {
  test('submitOnboarding forwards every wizard field to finish_onboarding',
      () async {
    final _FakeRunner runner = _FakeRunner();
    final OnboardingService service = OnboardingService(runner);
    const OnboardingDraft draft = OnboardingDraft(
      goalText: 'Hiring a fractional designer',
      goalType: GoalType.hire,
      name: 'Ada',
      handle: 'ada',
      roles: <String>['founder'],
      primaryRole: 'founder',
      city: 'Berlin',
      country: 'Germany',
      headline: 'Founder',
      bio: 'A short but valid bio entry.',
    );

    await service.submitOnboarding(draft: draft);

    final Map<String, dynamic> params = runner.capturedParams!;
    expect(params['p_name'], 'Ada');
    expect(params['p_handle'], 'ada');
    expect(params['p_goal_text'], contains('designer'));
    expect(params['p_goal_type'], 'hire');
    expect(params['p_roles'], <String>['founder']);
    expect(params['p_primary_role'], 'founder');
    expect(params['p_city'], 'Berlin');
    expect(params['p_country'], 'Germany');
    expect(params['p_headline'], 'Founder');
    expect(params['p_bio'], 'A short but valid bio entry.');
  });

  test('null headline/bio is sent as null (clears prior value)', () async {
    final _FakeRunner runner = _FakeRunner();
    final OnboardingService service = OnboardingService(runner);
    const OnboardingDraft draft = OnboardingDraft(
      goalText: 'Goal text long enough',
      goalType: GoalType.peerConnect,
      name: 'B',
      handle: 'bb',
      roles: <String>['builder'],
      primaryRole: 'builder',
      city: 'X',
      country: 'Y',
    );
    await service.submitOnboarding(draft: draft);
    expect(runner.capturedParams!['p_headline'], isNull);
    expect(runner.capturedParams!['p_bio'], isNull);
  });

  test('empty-string headline/bio is normalised to null in params',
      () async {
    final _FakeRunner runner = _FakeRunner();
    final OnboardingService service = OnboardingService(runner);
    const OnboardingDraft draft = OnboardingDraft(
      goalText: 'Goal text long enough',
      goalType: GoalType.peerConnect,
      name: 'B',
      handle: 'bb',
      roles: <String>['builder'],
      primaryRole: 'builder',
      city: 'X',
      country: 'Y',
      headline: '',
      bio: '',
    );
    await service.submitOnboarding(draft: draft);
    expect(runner.capturedParams!['p_headline'], isNull);
    expect(runner.capturedParams!['p_bio'], isNull);
  });

  test('throws StateError when submitting without a goal_type', () async {
    final _FakeRunner runner = _FakeRunner();
    final OnboardingService service = OnboardingService(runner);
    const OnboardingDraft draft = OnboardingDraft(
      goalText: 'Goal text long enough',
      name: 'B',
      handle: 'bb',
      roles: <String>['builder'],
      primaryRole: 'builder',
      city: 'X',
      country: 'Y',
    );
    expect(
      () => service.submitOnboarding(draft: draft),
      throwsA(isA<StateError>()),
    );
    expect(runner.capturedParams, isNull);
  });

  test('PostgrestException is mapped via mapPostgrestError', () async {
    final _FakeRunner runner = _FakeRunner(
      willThrow: const PostgrestException(
        message: 'duplicate key',
        code: '23505',
      ),
    );
    final OnboardingService service = OnboardingService(runner);
    const OnboardingDraft draft = OnboardingDraft(
      goalText: 'Goal text long enough',
      goalType: GoalType.hire,
      name: 'A',
      handle: 'a',
      roles: <String>['founder'],
      primaryRole: 'founder',
      city: 'C',
      country: 'D',
    );
    expect(
      () => service.submitOnboarding(draft: draft),
      throwsA(isA<DuplicateException>()),
    );
  });
}
