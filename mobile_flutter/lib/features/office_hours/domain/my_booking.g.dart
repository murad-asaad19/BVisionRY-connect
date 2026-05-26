// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'my_booking.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MyBookingImpl _$$MyBookingImplFromJson(Map<String, dynamic> json) =>
    _$MyBookingImpl(
      slotId: json['slot_id'] as String,
      hostId: json['host_id'] as String,
      hostHandle: json['host_handle'] as String,
      hostName: json['host_name'] as String,
      hostPhotoUrl: json['host_photo_url'] as String?,
      startsAt: _utcFromJson(json['starts_at'] as Object),
      endsAt: _utcFromJson(json['ends_at'] as Object),
      topic: json['topic'] as String?,
      meetingProposalId: json['meeting_proposal_id'] as String?,
    );

Map<String, dynamic> _$$MyBookingImplToJson(_$MyBookingImpl instance) =>
    <String, dynamic>{
      'slot_id': instance.slotId,
      'host_id': instance.hostId,
      'host_handle': instance.hostHandle,
      'host_name': instance.hostName,
      'host_photo_url': instance.hostPhotoUrl,
      'starts_at': _utcToJson(instance.startsAt),
      'ends_at': _utcToJson(instance.endsAt),
      'topic': instance.topic,
      'meeting_proposal_id': instance.meetingProposalId,
    };
