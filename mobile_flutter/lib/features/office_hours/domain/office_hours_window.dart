import 'package:freezed_annotation/freezed_annotation.dart';

part 'office_hours_window.freezed.dart';
part 'office_hours_window.g.dart';

/// One row from `office_hours_settings.windows` JSONB column (spec §2.20).
///
/// **Weekday convention is 0=Sunday … 6=Saturday** (matches the DB
/// trigger `materialize_office_hours_slots`). The two-minute precision of
/// `start_minute` / `end_minute` is intentional — slots are then
/// materialized at the host's chosen `slot_duration_minutes` cadence.
@freezed
class OfficeHoursWindow with _$OfficeHoursWindow {
  const factory OfficeHoursWindow({
    required int weekday, // 0=Sun..6=Sat (DB convention)
    @JsonKey(name: 'start_minute') required int startMinute,
    @JsonKey(name: 'end_minute') required int endMinute,
    required String timezone, // IANA name
  }) = _OfficeHoursWindow;

  const OfficeHoursWindow._();

  factory OfficeHoursWindow.fromJson(Map<String, dynamic> json) =>
      _$OfficeHoursWindowFromJson(json);

  /// Returns the localized i18n key when invalid, or null if valid.
  String? validate() {
    if (weekday < 0 || weekday > 6) {
      return 'officeHours.settings.windowInvalidWeekday';
    }
    if (startMinute < 0 || startMinute > 1439) {
      return 'officeHours.settings.windowInvalidStart';
    }
    if (endMinute < 0 || endMinute > 1439) {
      return 'officeHours.settings.windowInvalidEnd';
    }
    if (endMinute <= startMinute) {
      return 'officeHours.settings.windowEndAfterStart';
    }
    if (timezone.isEmpty) return 'officeHours.settings.windowInvalidTimezone';
    return null;
  }

  /// True when this window's time range overlaps [other] on the same weekday
  /// (timezone-aware: only windows sharing a weekday + timezone can clash,
  /// since a different tz materializes to a different wall-clock band).
  /// Touching edges (one ends exactly where the next starts) do not overlap.
  bool overlaps(OfficeHoursWindow other) {
    if (weekday != other.weekday) return false;
    if (timezone != other.timezone) return false;
    return startMinute < other.endMinute && other.startMinute < endMinute;
  }

  /// Validates this window standalone AND against the already-saved
  /// [existing] windows, returning the localized i18n error key for the first
  /// problem or null when it's safe to save. Pass [excludeIndex] when editing
  /// an existing row so the window isn't compared against its own old value.
  String? validateAgainst(
    List<OfficeHoursWindow> existing, {
    int? excludeIndex,
  }) {
    final selfError = validate();
    if (selfError != null) return selfError;
    for (var i = 0; i < existing.length; i++) {
      if (i == excludeIndex) continue;
      final other = existing[i];
      if (weekday == other.weekday &&
          startMinute == other.startMinute &&
          endMinute == other.endMinute &&
          timezone == other.timezone) {
        return 'officeHours.settings.windowDuplicate';
      }
      if (overlaps(other)) {
        return 'officeHours.settings.windowOverlap';
      }
    }
    return null;
  }

  static const List<String> _weekdayNames = <String>[
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  static String weekdayName(int w) => _weekdayNames[w];

  /// `540` → `09:00`.
  static String minuteToHhmm(int m) {
    final h = (m ~/ 60).toString().padLeft(2, '0');
    final mm = (m % 60).toString().padLeft(2, '0');
    return '$h:$mm';
  }

  /// `09:00` → `540`. Throws [FormatException] on malformed input.
  static int hhmmToMinute(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length != 2) {
      throw FormatException('Invalid HH:MM: $hhmm');
    }
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }
}
