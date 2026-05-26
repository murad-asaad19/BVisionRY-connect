// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'office_hours_slot.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$OfficeHoursSlotImpl _$$OfficeHoursSlotImplFromJson(
        Map<String, dynamic> json) =>
    _$OfficeHoursSlotImpl(
      id: json['id'] as String,
      hostId: json['host_id'] as String,
      startsAt: _utcFromJson(json['starts_at'] as Object),
      endsAt: _utcFromJson(json['ends_at'] as Object),
      status: $enumDecodeNullable(_$SlotStatusEnumMap, json['status']) ??
          SlotStatus.open,
      bookedBy: json['booked_by'] as String?,
      bookedAt: _utcFromJsonNullable(json['booked_at']),
      meetingProposalId: json['meeting_proposal_id'] as String?,
      topic: json['topic'] as String?,
      hostNotesTemplate: json['host_settings_notes_template'] as String?,
    );

Map<String, dynamic> _$$OfficeHoursSlotImplToJson(
        _$OfficeHoursSlotImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'host_id': instance.hostId,
      'starts_at': _utcToJson(instance.startsAt),
      'ends_at': _utcToJson(instance.endsAt),
      'status': _$SlotStatusEnumMap[instance.status]!,
      'booked_by': instance.bookedBy,
      'booked_at': _utcToJsonNullable(instance.bookedAt),
      'meeting_proposal_id': instance.meetingProposalId,
      'topic': instance.topic,
      'host_settings_notes_template': instance.hostNotesTemplate,
    };

const _$SlotStatusEnumMap = {
  SlotStatus.open: 'open',
  SlotStatus.booked: 'booked',
  SlotStatus.cancelled: 'cancelled',
};
