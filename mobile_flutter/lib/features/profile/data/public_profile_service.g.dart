// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'public_profile_service.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PublicProfileImpl _$$PublicProfileImplFromJson(Map<String, dynamic> json) =>
    _$PublicProfileImpl(
      id: json['id'] as String,
      handle: json['handle'] as String,
      name: json['name'] as String?,
      photoUrl: json['photo_url'] as String?,
      headline: json['headline'] as String?,
      bio: json['bio'] as String?,
      primaryRole: json['primary_role'] as String?,
      roles:
          (json['roles'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const <String>[],
      city: json['city'] as String?,
      country: json['country'] as String?,
      verifiedGithubUsername: json['verified_github_username'] as String?,
    );

Map<String, dynamic> _$$PublicProfileImplToJson(_$PublicProfileImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'handle': instance.handle,
      'name': instance.name,
      'photo_url': instance.photoUrl,
      'headline': instance.headline,
      'bio': instance.bio,
      'primary_role': instance.primaryRole,
      'roles': instance.roles,
      'city': instance.city,
      'country': instance.country,
      'verified_github_username': instance.verifiedGithubUsername,
    };
