import 'package:freezed_annotation/freezed_annotation.dart';

import 'office_hours_window.dart';

part 'office_hours_settings.freezed.dart';
part 'office_hours_settings.g.dart';

DateTime? _utcFromJsonNullable(Object? v) =>
    v == null ? null : DateTime.parse(v as String).toUtc();
String? _utcToJsonNullable(DateTime? v) => v?.toUtc().toIso8601String();

/// One row from `public.office_hours_settings` (spec §2.20).
///
/// Holds the host's availability config: the weekly windows JSONB, slot
/// duration / buffer / weekly cap, and the meeting-link + notes templates.
/// [meetingLinkTemplate] supports a single `{slot_id}` literal placeholder
/// that the server substitutes when `book_slot` is called.
@freezed
class OfficeHoursSettings with _$OfficeHoursSettings {
  const factory OfficeHoursSettings({
    @JsonKey(name: 'user_id') required String userId,
    required bool enabled,
    @Default(<OfficeHoursWindow>[]) List<OfficeHoursWindow> windows,
    @JsonKey(name: 'slot_duration_minutes') required int slotDurationMinutes,
    @JsonKey(name: 'max_bookings_per_week') required int maxBookingsPerWeek,
    @JsonKey(name: 'buffer_minutes') required int bufferMinutes,
    @JsonKey(name: 'meeting_link_template') String? meetingLinkTemplate,
    @JsonKey(name: 'notes_template') String? notesTemplate,
    @JsonKey(
      name: 'updated_at',
      fromJson: _utcFromJsonNullable,
      toJson: _utcToJsonNullable,
    )
    DateTime? updatedAt,
  }) = _OfficeHoursSettings;

  const OfficeHoursSettings._();

  factory OfficeHoursSettings.fromJson(Map<String, dynamic> json) =>
      _$OfficeHoursSettingsFromJson(json);

  /// New-host defaults (matches `set_office_hours` server-side defaults).
  factory OfficeHoursSettings.defaults({required String userId}) =>
      OfficeHoursSettings(
        userId: userId,
        enabled: false,
        windows: const <OfficeHoursWindow>[],
        slotDurationMinutes: 15,
        maxBookingsPerWeek: 5,
        bufferMinutes: 5,
      );

  /// Exactly the set enforced by the `slot_duration_minutes_check` CHECK.
  static const List<int> allowedSlotDurations = <int>[15, 30, 45, 60];

  /// Returns the i18n error key when invalid; null when ok.
  String? validate() {
    if (!allowedSlotDurations.contains(slotDurationMinutes)) {
      return 'officeHours.settings.invalidSlotDuration';
    }
    if (maxBookingsPerWeek < 1 || maxBookingsPerWeek > 50) {
      return 'officeHours.settings.invalidMaxBookings';
    }
    if (bufferMinutes < 0 || bufferMinutes > 60) {
      return 'officeHours.settings.invalidBuffer';
    }
    final link = meetingLinkTemplate?.trim();
    if (enabled &&
        link != null &&
        link.isNotEmpty &&
        !link.startsWith('https://')) {
      return 'officeHours.settings.meetingLinkHttpsRequired';
    }
    for (final w in windows) {
      final err = w.validate();
      if (err != null) return err;
    }
    return null;
  }
}
