import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_client.dart';
import '../../auth/data/auth_service.dart' show FunctionsGateway;
import '../domain/goal_type.dart';

/// Confidence levels reported by the `infer-goal-type` edge function. The
/// UI uses this to decide whether to auto-select a chip (`high`) or merely
/// surface a hint (`low`).
enum InferConfidence { high, low }

class InferGoalResult {
  const InferGoalResult({required this.goalType, required this.confidence});
  final GoalType? goalType;
  final InferConfidence confidence;
}

class InferGoalException implements Exception {
  InferGoalException(this.message);
  final String message;
  @override
  String toString() => 'InferGoalException($message)';
}

/// Client for the `infer-goal-type` Supabase edge function (spec §4.4).
///
/// Sends `{text, primary_role?, roles?}` and parses the
/// `{goal_type, confidence}` response, tolerating null/"none" goal types
/// gracefully so the UI can degrade to manual selection.
class InferGoalService {
  InferGoalService(this._functions);

  final FunctionsGateway _functions;

  Future<InferGoalResult> infer({
    required String text,
    String? primaryRole,
    List<String>? roles,
  }) async {
    final Map<String, dynamic> body = <String, dynamic>{'text': text};
    if (primaryRole != null) body['primary_role'] = primaryRole;
    if (roles != null && roles.isNotEmpty) body['roles'] = roles;

    final FunctionResponse response =
        await _functions.invoke('infer-goal-type', body: body);

    if (response.status < 200 || response.status >= 300) {
      throw InferGoalException('status=${response.status}');
    }
    final Object? data = response.data;
    if (data is! Map<String, dynamic>) {
      throw InferGoalException('empty or malformed body');
    }
    final InferConfidence confidence = data['confidence'] == 'high'
        ? InferConfidence.high
        : InferConfidence.low;
    final Object? rawGoal = data['goal_type'];
    final String? wire =
        (rawGoal is String && rawGoal != 'none') ? rawGoal : null;
    return InferGoalResult(
      goalType: GoalType.fromWire(wire),
      confidence: confidence,
    );
  }
}

/// Concrete adapter binding [FunctionsGateway] to the live Supabase client.
class _SupabaseFunctionsGateway implements FunctionsGateway {
  _SupabaseFunctionsGateway(this._client);
  final SupabaseClient _client;
  @override
  Future<FunctionResponse> invoke(String name, {Object? body}) =>
      _client.functions.invoke(name, body: body);
}

final Provider<InferGoalService> inferGoalServiceProvider =
    Provider<InferGoalService>((Ref<InferGoalService> ref) {
  return InferGoalService(
    _SupabaseFunctionsGateway(ref.watch(supabaseClientProvider)),
  );
});
