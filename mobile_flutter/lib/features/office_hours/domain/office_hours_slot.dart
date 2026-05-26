import 'package:freezed_annotation/freezed_annotation.dart';

part 'office_hours_slot.freezed.dart';
part 'office_hours_slot.g.dart';

DateTime _utcFromJson(Object v) => DateTime.parse(v as String).toUtc();
String _utcToJson(DateTime v) => v.toUtc().toIso8601String();
DateTime? _utcFromJsonNullable(Object? v) =>
    v == null ? null : DateTime.parse(v as String).toUtc();
String? _utcToJsonNullable(DateTime? v) => v?.toUtc().toIso8601String();

/// Lifecycle of an office-hours slot (`public.office_hours_slots.status`).
enum SlotStatus {
  @JsonValue('open')
  open,
  @JsonValue('booked')
  booked,
  @JsonValue('cancelled')
  cancelled;

  /// Parses the wire-format value. Throws [FormatException] when given an
  /// unknown literal — that surfaces as a generic error toast instead of
  /// silently coercing to `open` (which would be a data integrity bug).
  static SlotStatus fromString(String v) => switch (v) {
        'open' => SlotStatus.open,
        'booked' => SlotStatus.booked,
        'cancelled' => SlotStatus.cancelled,
        _ => throw FormatException('Unknown slot status: $v'),
      };
}

/// One row of `list_upcoming_slots(host_id)` (spec §3.6).
///
/// `host_settings_notes_template` is the host's pre-meeting notes carried
/// through so the viewer can preview the prompt before booking.
@freezed
class OfficeHoursSlot with _$OfficeHoursSlot {
  const factory OfficeHoursSlot({
    required String id,
    @JsonKey(name: 'host_id') required String hostId,
    @JsonKey(
      name: 'starts_at',
      fromJson: _utcFromJson,
      toJson: _utcToJson,
    )
    required DateTime startsAt,
    @JsonKey(
      name: 'ends_at',
      fromJson: _utcFromJson,
      toJson: _utcToJson,
    )
    required DateTime endsAt,
    @Default(SlotStatus.open) SlotStatus status,
    @JsonKey(name: 'booked_by') String? bookedBy,
    @JsonKey(
      name: 'booked_at',
      fromJson: _utcFromJsonNullable,
      toJson: _utcToJsonNullable,
    )
    DateTime? bookedAt,
    @JsonKey(name: 'meeting_proposal_id') String? meetingProposalId,
    String? topic,
    @JsonKey(name: 'host_settings_notes_template') String? hostNotesTemplate,
  }) = _OfficeHoursSlot;

  const OfficeHoursSlot._();

  factory OfficeHoursSlot.fromJson(Map<String, dynamic> json) =>
      _$OfficeHoursSlotFromJson(json);

  int get durationMinutes => endsAt.difference(startsAt).inMinutes;
}
