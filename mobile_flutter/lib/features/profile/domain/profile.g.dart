// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ProfileImpl _$$ProfileImplFromJson(Map<String, dynamic> json) =>
    _$ProfileImpl(
      id: json['id'] as String,
      handle: json['handle'] as String?,
      name: json['name'] as String?,
      headline: json['headline'] as String?,
      bio: json['bio'] as String?,
      roles:
          (json['roles'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const <String>[],
      primaryRole: json['primary_role'] as String?,
      city: json['city'] as String?,
      country: json['country'] as String?,
      goalType: json['goal_type'] as String?,
      goalText: json['goal_text'] as String?,
      goalUpdatedAt: json['goal_updated_at'] == null
          ? null
          : DateTime.parse(json['goal_updated_at'] as String),
      photoUrl: json['photo_url'] as String?,
      onboarded: json['onboarded'] as bool? ?? false,
      verifiedGithubUsername: json['verified_github_username'] as String?,
      verifiedGithubId: (json['verified_github_id'] as num?)?.toInt(),
      verifiedAt: json['verified_at'] == null
          ? null
          : DateTime.parse(json['verified_at'] as String),
      suspendedAt: json['suspended_at'] == null
          ? null
          : DateTime.parse(json['suspended_at'] as String),
      privateMode: json['private_mode'] as bool? ?? false,
      readReceiptsEnabled: json['read_receipts_enabled'] as bool? ?? false,
      publicInvestorPage: json['public_investor_page'] as bool? ?? false,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$$ProfileImplToJson(_$ProfileImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'handle': instance.handle,
      'name': instance.name,
      'headline': instance.headline,
      'bio': instance.bio,
      'roles': instance.roles,
      'primary_role': instance.primaryRole,
      'city': instance.city,
      'country': instance.country,
      'goal_type': instance.goalType,
      'goal_text': instance.goalText,
      'goal_updated_at': instance.goalUpdatedAt?.toIso8601String(),
      'photo_url': instance.photoUrl,
      'onboarded': instance.onboarded,
      'verified_github_username': instance.verifiedGithubUsername,
      'verified_github_id': instance.verifiedGithubId,
      'verified_at': instance.verifiedAt?.toIso8601String(),
      'suspended_at': instance.suspendedAt?.toIso8601String(),
      'private_mode': instance.privateMode,
      'read_receipts_enabled': instance.readReceiptsEnabled,
      'public_investor_page': instance.publicInvestorPage,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };
