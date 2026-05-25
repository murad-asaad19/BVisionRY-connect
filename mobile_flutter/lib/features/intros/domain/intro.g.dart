// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'intro.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$IntroImpl _$$IntroImplFromJson(Map<String, dynamic> json) => _$IntroImpl(
      id: json['id'] as String,
      senderId: json['sender_id'] as String,
      recipientId: json['recipient_id'] as String,
      note: json['note'] as String,
      state: _stateFromJson(json['state'] as String),
      kind: _kindFromJson(json['kind'] as String),
      warmTargetId: json['warm_target_id'] as String?,
      conversationId: json['conversation_id'] as String?,
      expiresAt: _utcFromJson(json['expires_at'] as Object),
      createdAt: _utcFromJson(json['created_at'] as Object),
      declinedAt: _utcFromJsonNullable(json['declined_at']),
      sender: json['sender'] == null
          ? null
          : Profile.fromJson(json['sender'] as Map<String, dynamic>),
      recipient: json['recipient'] == null
          ? null
          : Profile.fromJson(json['recipient'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$IntroImplToJson(_$IntroImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'sender_id': instance.senderId,
      'recipient_id': instance.recipientId,
      'note': instance.note,
      'state': _stateToJson(instance.state),
      'kind': _kindToJson(instance.kind),
      'warm_target_id': instance.warmTargetId,
      'conversation_id': instance.conversationId,
      'expires_at': _utcToJson(instance.expiresAt),
      'created_at': _utcToJson(instance.createdAt),
      'declined_at': _utcToJsonNullable(instance.declinedAt),
      if (instance.sender case final value?) 'sender': value,
      if (instance.recipient case final value?) 'recipient': value,
    };
