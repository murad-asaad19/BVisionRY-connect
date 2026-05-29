// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'discovery_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$DiscoveryProfileImpl _$$DiscoveryProfileImplFromJson(
        Map<String, dynamic> json) =>
    _$DiscoveryProfileImpl(
      id: json['id'] as String,
      handle: json['handle'] as String,
      name: json['name'] as String?,
      photoUrl: json['photo_url'] as String?,
      headline: json['headline'] as String?,
      bio: json['bio'] as String?,
      city: json['city'] as String?,
      country: json['country'] as String?,
      primaryRole: json['primary_role'] as String?,
      roles:
          (json['roles'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const <String>[],
      goalType: json['goal_type'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      verified: json['verified'] as bool? ?? false,
      lastActiveAt: json['last_active_at'] == null
          ? null
          : DateTime.parse(json['last_active_at'] as String),
    );

Map<String, dynamic> _$$DiscoveryProfileImplToJson(
        _$DiscoveryProfileImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'handle': instance.handle,
      'name': instance.name,
      'photo_url': instance.photoUrl,
      'headline': instance.headline,
      'bio': instance.bio,
      'city': instance.city,
      'country': instance.country,
      'primary_role': instance.primaryRole,
      'roles': instance.roles,
      'goal_type': instance.goalType,
      'created_at': instance.createdAt?.toIso8601String(),
      'verified': instance.verified,
      'last_active_at': instance.lastActiveAt?.toIso8601String(),
    };
