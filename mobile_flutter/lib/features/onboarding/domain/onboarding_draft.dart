import 'package:freezed_annotation/freezed_annotation.dart';

import 'goal_type.dart';

part 'onboarding_draft.freezed.dart';
part 'onboarding_draft.g.dart';

/// In-progress onboarding submission. Mirrors the eleven `profiles.*` columns
/// the wizard writes plus a single `onboarded` flag (the latter is supplied
/// at submission time by [OnboardingService], not stored on the draft).
///
/// Persisted to SharedPreferences by [OnboardingDraftRepository] so the wizard
/// survives an app restart. JSON keys are snake_case to match the column
/// names — that way the same payload could (in principle) be sent straight to
/// the server, although in practice the service builds the patch explicitly.
@freezed
class OnboardingDraft with _$OnboardingDraft {
  const factory OnboardingDraft({
    @JsonKey(name: 'goal_text') @Default('') String goalText,
    @JsonKey(name: 'goal_type') @GoalTypeConverter() GoalType? goalType,
    @Default('') String name,
    @Default('') String handle,
    @Default(<String>[]) List<String> roles,
    @JsonKey(name: 'primary_role') String? primaryRole,
    @Default('') String city,
    @Default('') String country,
    String? headline,
    String? bio,
  }) = _OnboardingDraft;

  factory OnboardingDraft.fromJson(Map<String, dynamic> json) =>
      _$OnboardingDraftFromJson(json);
}

/// Round-trips [GoalType] through its `wire` string. Unknown values become
/// `null` rather than throwing so an out-of-date client tolerates server
/// schema additions gracefully (see [GoalType.fromWire]).
class GoalTypeConverter implements JsonConverter<GoalType?, String?> {
  const GoalTypeConverter();

  @override
  GoalType? fromJson(String? wire) => GoalType.fromWire(wire);

  @override
  String? toJson(GoalType? value) => value?.wire;
}
