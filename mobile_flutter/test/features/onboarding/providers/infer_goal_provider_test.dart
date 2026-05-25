import 'package:connect_mobile/features/onboarding/data/infer_goal_service.dart';
import 'package:connect_mobile/features/onboarding/domain/goal_type.dart';
import 'package:connect_mobile/features/onboarding/providers/infer_goal_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Hand-rolled fake — avoids mocktail boilerplate for a single-method
/// interface and gives us a precise call-count assertion.
class _FakeInferService implements InferGoalService {
  _FakeInferService(this._answer);
  final Future<InferGoalResult> Function({
    required String text,
    String? primaryRole,
    List<String>? roles,
  })
      _answer;

  int calls = 0;
  String? lastText;
  String? lastPrimaryRole;
  List<String>? lastRoles;

  @override
  Future<InferGoalResult> infer({
    required String text,
    String? primaryRole,
    List<String>? roles,
  }) {
    calls++;
    lastText = text;
    lastPrimaryRole = primaryRole;
    lastRoles = roles;
    return _answer(
      text: text,
      primaryRole: primaryRole,
      roles: roles,
    );
  }
}

void main() {
  ProviderContainer makeContainer(_FakeInferService svc) {
    return ProviderContainer(
      overrides: <Override>[
        inferGoalServiceProvider.overrideWithValue(svc),
      ],
    );
  }

  test('starts idle', () {
    final _FakeInferService svc = _FakeInferService(
      ({required String text, String? primaryRole, List<String>? roles}) async =>
          const InferGoalResult(
            goalType: GoalType.hire,
            confidence: InferConfidence.high,
          ),
    );
    final ProviderContainer c = makeContainer(svc);
    addTearDown(c.dispose);
    expect(c.read(inferGoalProvider), isA<InferIdle>());
  });

  test('does NOT call service when text < 20 chars', () async {
    final _FakeInferService svc = _FakeInferService(
      ({required String text, String? primaryRole, List<String>? roles}) async =>
          const InferGoalResult(
            goalType: GoalType.hire,
            confidence: InferConfidence.high,
          ),
    );
    final ProviderContainer c = makeContainer(svc);
    addTearDown(c.dispose);
    c.read(inferGoalProvider.notifier).requestInference(text: 'short text');
    await Future<void>.delayed(const Duration(milliseconds: 900));
    expect(svc.calls, 0);
  });

  test('debounces multiple rapid calls into a single invocation', () async {
    final _FakeInferService svc = _FakeInferService(
      ({required String text, String? primaryRole, List<String>? roles}) async =>
          const InferGoalResult(
            goalType: GoalType.hire,
            confidence: InferConfidence.high,
          ),
    );
    final ProviderContainer c = makeContainer(svc);
    addTearDown(c.dispose);

    final InferGoalNotifier notifier = c.read(inferGoalProvider.notifier);
    notifier.requestInference(text: 'a' * 20);
    notifier.requestInference(text: 'a' * 21);
    notifier.requestInference(text: 'a' * 22);
    await Future<void>.delayed(const Duration(milliseconds: 900));

    expect(svc.calls, 1);
    expect(svc.lastText, 'a' * 22);
    final InferGoalState state = c.read(inferGoalProvider);
    expect(state, isA<Inferred>());
    expect((state as Inferred).result.goalType, GoalType.hire);
  });

  test('supersedes in-flight calls when a new request lands', () async {
    int invocation = 0;
    final _FakeInferService svc = _FakeInferService(
      ({required String text, String? primaryRole, List<String>? roles}) async {
        invocation++;
        if (invocation == 1) {
          await Future<void>.delayed(const Duration(milliseconds: 200));
        }
        return InferGoalResult(
          goalType: invocation == 1 ? GoalType.hire : GoalType.advise,
          confidence: InferConfidence.high,
        );
      },
    );
    final ProviderContainer c = makeContainer(svc);
    addTearDown(c.dispose);

    final InferGoalNotifier notifier = c.read(inferGoalProvider.notifier);
    notifier.requestInference(text: 'first call text long enough');
    await Future<void>.delayed(const Duration(milliseconds: 850));
    // Second request lands while first is still resolving.
    notifier.requestInference(text: 'second call text long enough');
    await Future<void>.delayed(const Duration(milliseconds: 1200));

    final InferGoalState state = c.read(inferGoalProvider);
    expect(state, isA<Inferred>());
    expect((state as Inferred).result.goalType, GoalType.advise);
  });

  test('failure transitions to InferFailed state', () async {
    final _FakeInferService svc = _FakeInferService(
      ({required String text, String? primaryRole, List<String>? roles}) async {
        throw InferGoalException('boom');
      },
    );
    final ProviderContainer c = makeContainer(svc);
    addTearDown(c.dispose);
    c.read(inferGoalProvider.notifier).requestInference(text: 'a' * 25);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    expect(c.read(inferGoalProvider), isA<InferFailed>());
  });

  test('forwards primaryRole + roles to the service', () async {
    final _FakeInferService svc = _FakeInferService(
      ({required String text, String? primaryRole, List<String>? roles}) async =>
          const InferGoalResult(
            goalType: GoalType.hire,
            confidence: InferConfidence.high,
          ),
    );
    final ProviderContainer c = makeContainer(svc);
    addTearDown(c.dispose);
    c.read(inferGoalProvider.notifier).requestInference(
          text: 'a long enough text to fire the inference',
          primaryRole: 'founder',
          roles: const <String>['founder', 'leader'],
        );
    await Future<void>.delayed(const Duration(milliseconds: 900));
    expect(svc.lastPrimaryRole, 'founder');
    expect(svc.lastRoles, <String>['founder', 'leader']);
  });

  test('reset() returns to idle and cancels pending timer', () async {
    final _FakeInferService svc = _FakeInferService(
      ({required String text, String? primaryRole, List<String>? roles}) async =>
          const InferGoalResult(
            goalType: GoalType.hire,
            confidence: InferConfidence.high,
          ),
    );
    final ProviderContainer c = makeContainer(svc);
    addTearDown(c.dispose);
    final InferGoalNotifier notifier = c.read(inferGoalProvider.notifier);
    notifier.requestInference(text: 'a' * 25);
    notifier.reset();
    await Future<void>.delayed(const Duration(milliseconds: 900));
    expect(c.read(inferGoalProvider), isA<InferIdle>());
    expect(svc.calls, 0);
  });

  test('shrinking text below the 20-char gate returns to idle', () async {
    final _FakeInferService svc = _FakeInferService(
      ({required String text, String? primaryRole, List<String>? roles}) async =>
          const InferGoalResult(
            goalType: GoalType.hire,
            confidence: InferConfidence.high,
          ),
    );
    final ProviderContainer c = makeContainer(svc);
    addTearDown(c.dispose);
    final InferGoalNotifier notifier = c.read(inferGoalProvider.notifier);
    notifier.requestInference(text: 'a' * 25);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    expect(c.read(inferGoalProvider), isA<Inferred>());
    // User deletes text back below the threshold.
    notifier.requestInference(text: 'short');
    expect(c.read(inferGoalProvider), isA<InferIdle>());
  });
}
