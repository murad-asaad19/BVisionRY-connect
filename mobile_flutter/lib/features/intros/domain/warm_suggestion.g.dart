// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'warm_suggestion.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$WarmSuggestionImpl _$$WarmSuggestionImplFromJson(Map<String, dynamic> json) =>
    _$WarmSuggestionImpl(
      targetId: json['target_id'] as String,
      targetHandle: json['target_handle'] as String,
      targetName: json['target_name'] as String,
      targetPhotoUrl: json['target_photo_url'] as String?,
      targetPrimaryRole: json['target_primary_role'] as String?,
      targetGoalType: json['target_goal_type'] as String?,
      mutualCount: (json['mutual_count'] as num).toInt(),
      topMutualId: json['top_mutual_id'] as String,
      topMutualName: json['top_mutual_name'] as String,
      topMutualHandle: json['top_mutual_handle'] as String,
    );

Map<String, dynamic> _$$WarmSuggestionImplToJson(
        _$WarmSuggestionImpl instance) =>
    <String, dynamic>{
      'target_id': instance.targetId,
      'target_handle': instance.targetHandle,
      'target_name': instance.targetName,
      'target_photo_url': instance.targetPhotoUrl,
      'target_primary_role': instance.targetPrimaryRole,
      'target_goal_type': instance.targetGoalType,
      'mutual_count': instance.mutualCount,
      'top_mutual_id': instance.topMutualId,
      'top_mutual_name': instance.topMutualName,
      'top_mutual_handle': instance.topMutualHandle,
    };
