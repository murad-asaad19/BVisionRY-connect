// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feed_filters.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$FeedFiltersImpl _$$FeedFiltersImplFromJson(Map<String, dynamic> json) =>
    _$FeedFiltersImpl(
      query: json['query'] as String? ?? '',
      roles:
          (json['roles'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const <String>[],
      goalTypes: (json['goalTypes'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
      country: json['country'] as String?,
    );

Map<String, dynamic> _$$FeedFiltersImplToJson(_$FeedFiltersImpl instance) =>
    <String, dynamic>{
      'query': instance.query,
      'roles': instance.roles,
      'goalTypes': instance.goalTypes,
      'country': instance.country,
    };
