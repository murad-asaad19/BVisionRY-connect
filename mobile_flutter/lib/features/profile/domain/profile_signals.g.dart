// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_signals.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ProfileSignalsImpl _$$ProfileSignalsImplFromJson(Map<String, dynamic> json) =>
    _$ProfileSignalsImpl(
      mutualConnectionCount:
          (json['mutual_connection_count'] as num?)?.toInt() ?? 0,
      mutualTopUserIds: (json['mutual_top_user_ids'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
      avgMeetingRating: _avgFromJson(json['avg_meeting_rating']),
      totalMeetingReviews:
          (json['total_meeting_reviews'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$ProfileSignalsImplToJson(
        _$ProfileSignalsImpl instance) =>
    <String, dynamic>{
      'mutual_connection_count': instance.mutualConnectionCount,
      'mutual_top_user_ids': instance.mutualTopUserIds,
      'avg_meeting_rating': instance.avgMeetingRating,
      'total_meeting_reviews': instance.totalMeetingReviews,
    };
