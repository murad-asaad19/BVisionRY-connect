// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'onboarding_draft.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$OnboardingDraftImpl _$$OnboardingDraftImplFromJson(
        Map<String, dynamic> json) =>
    _$OnboardingDraftImpl(
      goalText: json['goal_text'] as String? ?? '',
      goalType:
          const GoalTypeConverter().fromJson(json['goal_type'] as String?),
      name: json['name'] as String? ?? '',
      handle: json['handle'] as String? ?? '',
      roles:
          (json['roles'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const <String>[],
      primaryRole: json['primary_role'] as String?,
      city: json['city'] as String? ?? '',
      country: json['country'] as String? ?? '',
      headline: json['headline'] as String?,
      bio: json['bio'] as String?,
    );

Map<String, dynamic> _$$OnboardingDraftImplToJson(
        _$OnboardingDraftImpl instance) =>
    <String, dynamic>{
      'goal_text': instance.goalText,
      'goal_type': const GoalTypeConverter().toJson(instance.goalType),
      'name': instance.name,
      'handle': instance.handle,
      'roles': instance.roles,
      'primary_role': instance.primaryRole,
      'city': instance.city,
      'country': instance.country,
      'headline': instance.headline,
      'bio': instance.bio,
    };
