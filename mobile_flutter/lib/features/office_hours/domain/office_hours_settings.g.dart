// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'office_hours_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$OfficeHoursSettingsImpl _$$OfficeHoursSettingsImplFromJson(
        Map<String, dynamic> json) =>
    _$OfficeHoursSettingsImpl(
      userId: json['user_id'] as String,
      enabled: json['enabled'] as bool,
      windows: (json['windows'] as List<dynamic>?)
              ?.map(
                  (e) => OfficeHoursWindow.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <OfficeHoursWindow>[],
      slotDurationMinutes: (json['slot_duration_minutes'] as num).toInt(),
      maxBookingsPerWeek: (json['max_bookings_per_week'] as num).toInt(),
      bufferMinutes: (json['buffer_minutes'] as num).toInt(),
      meetingLinkTemplate: json['meeting_link_template'] as String?,
      notesTemplate: json['notes_template'] as String?,
      updatedAt: _utcFromJsonNullable(json['updated_at']),
    );

Map<String, dynamic> _$$OfficeHoursSettingsImplToJson(
        _$OfficeHoursSettingsImpl instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'enabled': instance.enabled,
      'windows': instance.windows,
      'slot_duration_minutes': instance.slotDurationMinutes,
      'max_bookings_per_week': instance.maxBookingsPerWeek,
      'buffer_minutes': instance.bufferMinutes,
      'meeting_link_template': instance.meetingLinkTemplate,
      'notes_template': instance.notesTemplate,
      'updated_at': _utcToJsonNullable(instance.updatedAt),
    };
