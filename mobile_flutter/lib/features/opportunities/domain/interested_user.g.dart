// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'interested_user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$InterestedUserImpl _$$InterestedUserImplFromJson(Map<String, dynamic> json) =>
    _$InterestedUserImpl(
      userId: json['user_id'] as String,
      handle: json['handle'] as String,
      name: json['name'] as String,
      photoUrl: json['photo_url'] as String?,
      primaryRole: json['primary_role'] as String?,
      note: json['note'] as String?,
      createdAt: _utcFromJson(json['created_at'] as Object),
    );

Map<String, dynamic> _$$InterestedUserImplToJson(
        _$InterestedUserImpl instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'handle': instance.handle,
      'name': instance.name,
      'photo_url': instance.photoUrl,
      'primary_role': instance.primaryRole,
      'note': instance.note,
      'created_at': _utcToJson(instance.createdAt),
    };
