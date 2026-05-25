import 'package:freezed_annotation/freezed_annotation.dart';

part 'warm_suggestion.freezed.dart';
part 'warm_suggestion.g.dart';

/// One row of `suggest_warm_intros` (spec §3.3) — a 2nd-degree
/// connection the caller can ask one of their mutuals to introduce them to.
///
/// Each suggestion is keyed on the [targetId] (the prospective new
/// connection) and surfaces the top mutual that bridges the gap, so the UI
/// can render "Via {topMutualName}" copy without an extra lookup.
@freezed
class WarmSuggestion with _$WarmSuggestion {
  const factory WarmSuggestion({
    @JsonKey(name: 'target_id') required String targetId,
    @JsonKey(name: 'target_handle') required String targetHandle,
    @JsonKey(name: 'target_name') required String targetName,
    @JsonKey(name: 'target_photo_url') required String? targetPhotoUrl,
    @JsonKey(name: 'target_primary_role') required String? targetPrimaryRole,
    @JsonKey(name: 'target_goal_type') required String? targetGoalType,
    @JsonKey(name: 'mutual_count') required int mutualCount,
    @JsonKey(name: 'top_mutual_id') required String topMutualId,
    @JsonKey(name: 'top_mutual_name') required String topMutualName,
    @JsonKey(name: 'top_mutual_handle') required String topMutualHandle,
  }) = _WarmSuggestion;

  factory WarmSuggestion.fromJson(Map<String, dynamic> json) =>
      _$WarmSuggestionFromJson(json);
}
