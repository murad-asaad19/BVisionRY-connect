import 'package:connect_mobile/features/onboarding/data/infer_goal_service.dart';
import 'package:connect_mobile/features/onboarding/domain/goal_type.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../helpers/fake_supabase.dart';

void main() {
  late FakeFunctionsGateway functions;
  late InferGoalService service;

  setUp(() {
    functions = FakeFunctionsGateway();
    service = InferGoalService(functions);
  });

  test('returns parsed high-confidence result', () async {
    String? capturedName;
    Object? capturedBody;
    functions.onInvoke = (String name, {Object? body}) async {
      capturedName = name;
      capturedBody = body;
      return FunctionResponse(
        data: <String, dynamic>{'goal_type': 'hire', 'confidence': 'high'},
        status: 200,
      );
    };

    final InferGoalResult result = await service.infer(
      text: 'Looking to hire a fractional designer for my fintech startup.',
      primaryRole: 'founder',
      roles: const <String>['founder'],
    );

    expect(result.goalType, GoalType.hire);
    expect(result.confidence, InferConfidence.high);
    expect(capturedName, 'infer-goal-type');
    final Map<String, dynamic> body = capturedBody! as Map<String, dynamic>;
    expect(body['text'], contains('hire'));
    expect(body['primary_role'], 'founder');
    expect(body['roles'], <String>['founder']);
  });

  test('returns low confidence with null goal_type', () async {
    functions.onInvoke = (String name, {Object? body}) async =>
        FunctionResponse(
          data: <String, dynamic>{'goal_type': null, 'confidence': 'low'},
          status: 200,
        );

    final InferGoalResult r = await service.infer(
      text: 'looking for stuff in general here ok',
    );
    expect(r.goalType, isNull);
    expect(r.confidence, InferConfidence.low);
  });

  test('maps a sentinel "none" goal_type string to null', () async {
    // The infer-goal-type edge function may emit either null or the string
    // "none" for unclassifiable input; treat both as "no auto-selection".
    functions.onInvoke = (String name, {Object? body}) async =>
        FunctionResponse(
          data: <String, dynamic>{'goal_type': 'none', 'confidence': 'low'},
          status: 200,
        );
    final InferGoalResult r = await service.infer(text: 'a' * 25);
    expect(r.goalType, isNull);
  });

  test('omits primary_role/roles from body when not provided', () async {
    Object? capturedBody;
    functions.onInvoke = (String name, {Object? body}) async {
      capturedBody = body;
      return FunctionResponse(
        data: <String, dynamic>{'goal_type': 'advise', 'confidence': 'high'},
        status: 200,
      );
    };
    await service.infer(text: 'a goal text long enough to satisfy length');
    final Map<String, dynamic> body = capturedBody! as Map<String, dynamic>;
    expect(body.containsKey('primary_role'), isFalse);
    expect(body.containsKey('roles'), isFalse);
  });

  test('omits roles when an empty list is provided', () async {
    Object? capturedBody;
    functions.onInvoke = (String name, {Object? body}) async {
      capturedBody = body;
      return FunctionResponse(
        data: <String, dynamic>{'goal_type': 'advise', 'confidence': 'high'},
        status: 200,
      );
    };
    await service.infer(text: 'a' * 25, roles: const <String>[]);
    final Map<String, dynamic> body = capturedBody! as Map<String, dynamic>;
    expect(body.containsKey('roles'), isFalse);
  });

  test('throws InferGoalException on non-2xx', () async {
    functions.onInvoke = (String name, {Object? body}) async =>
        FunctionResponse(data: null, status: 500);
    expect(
      service.infer(text: 'goal text long enough to satisfy length'),
      throwsA(isA<InferGoalException>()),
    );
  });

  test('throws InferGoalException when body is null', () async {
    functions.onInvoke = (String name, {Object? body}) async =>
        FunctionResponse(data: null, status: 200);
    expect(
      service.infer(text: 'goal text long enough to satisfy length'),
      throwsA(isA<InferGoalException>()),
    );
  });
}
