// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'connection.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ConnectionImpl _$$ConnectionImplFromJson(Map<String, dynamic> json) =>
    _$ConnectionImpl(
      userId: json['user_id'] as String,
      handle: json['handle'] as String,
      name: json['name'] as String,
      photoUrl: json['photo_url'] as String?,
      primaryRole: json['primary_role'] as String?,
      conversationId: json['conversation_id'] as String,
      connectedAt: _utcFromJson(json['connected_at'] as Object),
    );

Map<String, dynamic> _$$ConnectionImplToJson(_$ConnectionImpl instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'handle': instance.handle,
      'name': instance.name,
      'photo_url': instance.photoUrl,
      'primary_role': instance.primaryRole,
      'conversation_id': instance.conversationId,
      'connected_at': _utcToJson(instance.connectedAt),
    };
