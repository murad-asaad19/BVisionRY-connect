import 'package:connect_mobile/core/errors/app_exception.dart';
import 'package:connect_mobile/features/onboarding/data/onboarding_service.dart';
import 'package:connect_mobile/features/onboarding/domain/goal_type.dart';
import 'package:connect_mobile/features/onboarding/domain/onboarding_draft.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakeRunner implements ProfileUpdateRunner {
  _FakeRunner({this.willThrow});
  final Object? willThrow;

  Map<String, dynamic>? capturedPatch;
  String? capturedUserId;

  @override
  Future<void> update({
    required String userId,
    required Map<String, dynamic> patch,
  }) async {
    capturedUserId = userId;
    capturedPatch = patch;
    if (willThrow != null) {
      // ignore: only_throw_errors
      throw willThrow!;
    }
  }
}

void main() {
  test('submitOnboarding patches profile with all fields and onboarded=true',
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

    await service.submitOnboarding(userId: 'user-1', draft: draft);

    expect(runner.capturedUserId, 'user-1');
    final Map<String, dynamic> patch = runner.capturedPatch!;
    expect(patch['name'], 'Ada');
    expect(patch['handle'], 'ada');
    expect(patch['goal_text'], contains('designer'));
    expect(patch['goal_type'], 'hire');
    expect(patch['roles'], <String>['founder']);
    expect(patch['primary_role'], 'founder');
    expect(patch['city'], 'Berlin');
    expect(patch['country'], 'Germany');
    expect(patch['headline'], 'Founder');
    expect(patch['bio'], 'A short but valid bio entry.');
    expect(patch['onboarded'], isTrue);
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
    await service.submitOnboarding(userId: 'u', draft: draft);
    expect(runner.capturedPatch!['headline'], isNull);
    expect(runner.capturedPatch!['bio'], isNull);
  });

  test('empty-string headline/bio is normalised to null in the patch',
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
    await service.submitOnboarding(userId: 'u', draft: draft);
    expect(runner.capturedPatch!['headline'], isNull);
    expect(runner.capturedPatch!['bio'], isNull);
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
      () => service.submitOnboarding(userId: 'u', draft: draft),
      throwsA(isA<StateError>()),
    );
    expect(runner.capturedPatch, isNull);
  });

  test('PostgrestException is mapped via mapPostgrestError', () async {
    final _FakeRunner runner = _FakeRunner(
      willThrow: PostgrestException(
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
      () => service.submitOnboarding(userId: 'u', draft: draft),
      throwsA(isA<DuplicateException>()),
    );
  });
}
