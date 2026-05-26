// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'blocked_user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$BlockedUserImpl _$$BlockedUserImplFromJson(Map<String, dynamic> json) =>
    _$BlockedUserImpl(
      blockedId: json['blocked_id'] as String,
      handle: json['handle'] as String,
      name: json['name'] as String,
      photoUrl: json['photo_url'] as String?,
      createdAt: _utcFromJson(json['created_at'] as Object),
    );

Map<String, dynamic> _$$BlockedUserImplToJson(_$BlockedUserImpl instance) =>
    <String, dynamic>{
      'blocked_id': instance.blockedId,
      'handle': instance.handle,
      'name': instance.name,
      'photo_url': instance.photoUrl,
      'created_at': _utcToJson(instance.createdAt),
    };
