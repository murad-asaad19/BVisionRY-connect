// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'office_hours_window.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$OfficeHoursWindowImpl _$$OfficeHoursWindowImplFromJson(
        Map<String, dynamic> json) =>
    _$OfficeHoursWindowImpl(
      weekday: (json['weekday'] as num).toInt(),
      startMinute: (json['start_minute'] as num).toInt(),
      endMinute: (json['end_minute'] as num).toInt(),
      timezone: json['timezone'] as String,
    );

Map<String, dynamic> _$$OfficeHoursWindowImplToJson(
        _$OfficeHoursWindowImpl instance) =>
    <String, dynamic>{
      'weekday': instance.weekday,
      'start_minute': instance.startMinute,
      'end_minute': instance.endMinute,
      'timezone': instance.timezone,
    };
