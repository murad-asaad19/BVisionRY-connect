// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'opportunity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$OpportunityImpl _$$OpportunityImplFromJson(Map<String, dynamic> json) =>
    _$OpportunityImpl(
      id: json['id'] as String,
      authorId: json['author_id'] as String,
      kind: _kindFromJson(json['kind'] as String),
      title: json['title'] as String,
      body: json['body'] as String,
      tags: _tagsFromJson(json['tags']),
      locationCity: json['location_city'] as String?,
      locationCountry: json['location_country'] as String?,
      remoteOk: json['remote_ok'] as bool,
      status: _statusFromJson(json['status'] as String),
      expiresAt: _utcFromJson(json['expires_at'] as Object),
      createdAt: _utcFromJson(json['created_at'] as Object),
      updatedAt: _utcFromJson(json['updated_at'] as Object),
      closedAt: _utcFromJsonNullable(json['closed_at']),
    );

Map<String, dynamic> _$$OpportunityImplToJson(_$OpportunityImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'author_id': instance.authorId,
      'kind': _kindToJson(instance.kind),
      'title': instance.title,
      'body': instance.body,
      'tags': instance.tags,
      'location_city': instance.locationCity,
      'location_country': instance.locationCountry,
      'remote_ok': instance.remoteOk,
      'status': _statusToJson(instance.status),
      'expires_at': _utcToJson(instance.expiresAt),
      'created_at': _utcToJson(instance.createdAt),
      'updated_at': _utcToJson(instance.updatedAt),
      'closed_at': _utcToJsonNullable(instance.closedAt),
    };
