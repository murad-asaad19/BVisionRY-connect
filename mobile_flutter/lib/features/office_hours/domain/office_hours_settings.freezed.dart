// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'office_hours_settings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

OfficeHoursSettings _$OfficeHoursSettingsFromJson(Map<String, dynamic> json) {
  return _OfficeHoursSettings.fromJson(json);
}

/// @nodoc
mixin _$OfficeHoursSettings {
  @JsonKey(name: 'user_id')
  String get userId => throw _privateConstructorUsedError;
  bool get enabled => throw _privateConstructorUsedError;
  List<OfficeHoursWindow> get windows => throw _privateConstructorUsedError;
  @JsonKey(name: 'slot_duration_minutes')
  int get slotDurationMinutes => throw _privateConstructorUsedError;
  @JsonKey(name: 'max_bookings_per_week')
  int get maxBookingsPerWeek => throw _privateConstructorUsedError;
  @JsonKey(name: 'buffer_minutes')
  int get bufferMinutes => throw _privateConstructorUsedError;
  @JsonKey(name: 'meeting_link_template')
  String? get meetingLinkTemplate => throw _privateConstructorUsedError;
  @JsonKey(name: 'notes_template')
  String? get notesTemplate => throw _privateConstructorUsedError;
  @JsonKey(
      name: 'updated_at',
      fromJson: _utcFromJsonNullable,
      toJson: _utcToJsonNullable)
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this OfficeHoursSettings to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of OfficeHoursSettings
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $OfficeHoursSettingsCopyWith<OfficeHoursSettings> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OfficeHoursSettingsCopyWith<$Res> {
  factory $OfficeHoursSettingsCopyWith(
          OfficeHoursSettings value, $Res Function(OfficeHoursSettings) then) =
      _$OfficeHoursSettingsCopyWithImpl<$Res, OfficeHoursSettings>;
  @useResult
  $Res call(
      {@JsonKey(name: 'user_id') String userId,
      bool enabled,
      List<OfficeHoursWindow> windows,
      @JsonKey(name: 'slot_duration_minutes') int slotDurationMinutes,
      @JsonKey(name: 'max_bookings_per_week') int maxBookingsPerWeek,
      @JsonKey(name: 'buffer_minutes') int bufferMinutes,
      @JsonKey(name: 'meeting_link_template') String? meetingLinkTemplate,
      @JsonKey(name: 'notes_template') String? notesTemplate,
      @JsonKey(
          name: 'updated_at',
          fromJson: _utcFromJsonNullable,
          toJson: _utcToJsonNullable)
      DateTime? updatedAt});
}

/// @nodoc
class _$OfficeHoursSettingsCopyWithImpl<$Res, $Val extends OfficeHoursSettings>
    implements $OfficeHoursSettingsCopyWith<$Res> {
  _$OfficeHoursSettingsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of OfficeHoursSettings
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? enabled = null,
    Object? windows = null,
    Object? slotDurationMinutes = null,
    Object? maxBookingsPerWeek = null,
    Object? bufferMinutes = null,
    Object? meetingLinkTemplate = freezed,
    Object? notesTemplate = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_value.copyWith(
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      enabled: null == enabled
          ? _value.enabled
          : enabled // ignore: cast_nullable_to_non_nullable
              as bool,
      windows: null == windows
          ? _value.windows
          : windows // ignore: cast_nullable_to_non_nullable
              as List<OfficeHoursWindow>,
      slotDurationMinutes: null == slotDurationMinutes
          ? _value.slotDurationMinutes
          : slotDurationMinutes // ignore: cast_nullable_to_non_nullable
              as int,
      maxBookingsPerWeek: null == maxBookingsPerWeek
          ? _value.maxBookingsPerWeek
          : maxBookingsPerWeek // ignore: cast_nullable_to_non_nullable
              as int,
      bufferMinutes: null == bufferMinutes
          ? _value.bufferMinutes
          : bufferMinutes // ignore: cast_nullable_to_non_nullable
              as int,
      meetingLinkTemplate: freezed == meetingLinkTemplate
          ? _value.meetingLinkTemplate
          : meetingLinkTemplate // ignore: cast_nullable_to_non_nullable
              as String?,
      notesTemplate: freezed == notesTemplate
          ? _value.notesTemplate
          : notesTemplate // ignore: cast_nullable_to_non_nullable
              as String?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$OfficeHoursSettingsImplCopyWith<$Res>
    implements $OfficeHoursSettingsCopyWith<$Res> {
  factory _$$OfficeHoursSettingsImplCopyWith(_$OfficeHoursSettingsImpl value,
          $Res Function(_$OfficeHoursSettingsImpl) then) =
      __$$OfficeHoursSettingsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'user_id') String userId,
      bool enabled,
      List<OfficeHoursWindow> windows,
      @JsonKey(name: 'slot_duration_minutes') int slotDurationMinutes,
      @JsonKey(name: 'max_bookings_per_week') int maxBookingsPerWeek,
      @JsonKey(name: 'buffer_minutes') int bufferMinutes,
      @JsonKey(name: 'meeting_link_template') String? meetingLinkTemplate,
      @JsonKey(name: 'notes_template') String? notesTemplate,
      @JsonKey(
          name: 'updated_at',
          fromJson: _utcFromJsonNullable,
          toJson: _utcToJsonNullable)
      DateTime? updatedAt});
}

/// @nodoc
class __$$OfficeHoursSettingsImplCopyWithImpl<$Res>
    extends _$OfficeHoursSettingsCopyWithImpl<$Res, _$OfficeHoursSettingsImpl>
    implements _$$OfficeHoursSettingsImplCopyWith<$Res> {
  __$$OfficeHoursSettingsImplCopyWithImpl(_$OfficeHoursSettingsImpl _value,
      $Res Function(_$OfficeHoursSettingsImpl) _then)
      : super(_value, _then);

  /// Create a copy of OfficeHoursSettings
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? enabled = null,
    Object? windows = null,
    Object? slotDurationMinutes = null,
    Object? maxBookingsPerWeek = null,
    Object? bufferMinutes = null,
    Object? meetingLinkTemplate = freezed,
    Object? notesTemplate = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_$OfficeHoursSettingsImpl(
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      enabled: null == enabled
          ? _value.enabled
          : enabled // ignore: cast_nullable_to_non_nullable
              as bool,
      windows: null == windows
          ? _value._windows
          : windows // ignore: cast_nullable_to_non_nullable
              as List<OfficeHoursWindow>,
      slotDurationMinutes: null == slotDurationMinutes
          ? _value.slotDurationMinutes
          : slotDurationMinutes // ignore: cast_nullable_to_non_nullable
              as int,
      maxBookingsPerWeek: null == maxBookingsPerWeek
          ? _value.maxBookingsPerWeek
          : maxBookingsPerWeek // ignore: cast_nullable_to_non_nullable
              as int,
      bufferMinutes: null == bufferMinutes
          ? _value.bufferMinutes
          : bufferMinutes // ignore: cast_nullable_to_non_nullable
              as int,
      meetingLinkTemplate: freezed == meetingLinkTemplate
          ? _value.meetingLinkTemplate
          : meetingLinkTemplate // ignore: cast_nullable_to_non_nullable
              as String?,
      notesTemplate: freezed == notesTemplate
          ? _value.notesTemplate
          : notesTemplate // ignore: cast_nullable_to_non_nullable
              as String?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$OfficeHoursSettingsImpl extends _OfficeHoursSettings {
  const _$OfficeHoursSettingsImpl(
      {@JsonKey(name: 'user_id') required this.userId,
      required this.enabled,
      final List<OfficeHoursWindow> windows = const <OfficeHoursWindow>[],
      @JsonKey(name: 'slot_duration_minutes') required this.slotDurationMinutes,
      @JsonKey(name: 'max_bookings_per_week') required this.maxBookingsPerWeek,
      @JsonKey(name: 'buffer_minutes') required this.bufferMinutes,
      @JsonKey(name: 'meeting_link_template') this.meetingLinkTemplate,
      @JsonKey(name: 'notes_template') this.notesTemplate,
      @JsonKey(
          name: 'updated_at',
          fromJson: _utcFromJsonNullable,
          toJson: _utcToJsonNullable)
      this.updatedAt})
      : _windows = windows,
        super._();

  factory _$OfficeHoursSettingsImpl.fromJson(Map<String, dynamic> json) =>
      _$$OfficeHoursSettingsImplFromJson(json);

  @override
  @JsonKey(name: 'user_id')
  final String userId;
  @override
  final bool enabled;
  final List<OfficeHoursWindow> _windows;
  @override
  @JsonKey()
  List<OfficeHoursWindow> get windows {
    if (_windows is EqualUnmodifiableListView) return _windows;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_windows);
  }

  @override
  @JsonKey(name: 'slot_duration_minutes')
  final int slotDurationMinutes;
  @override
  @JsonKey(name: 'max_bookings_per_week')
  final int maxBookingsPerWeek;
  @override
  @JsonKey(name: 'buffer_minutes')
  final int bufferMinutes;
  @override
  @JsonKey(name: 'meeting_link_template')
  final String? meetingLinkTemplate;
  @override
  @JsonKey(name: 'notes_template')
  final String? notesTemplate;
  @override
  @JsonKey(
      name: 'updated_at',
      fromJson: _utcFromJsonNullable,
      toJson: _utcToJsonNullable)
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'OfficeHoursSettings(userId: $userId, enabled: $enabled, windows: $windows, slotDurationMinutes: $slotDurationMinutes, maxBookingsPerWeek: $maxBookingsPerWeek, bufferMinutes: $bufferMinutes, meetingLinkTemplate: $meetingLinkTemplate, notesTemplate: $notesTemplate, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OfficeHoursSettingsImpl &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.enabled, enabled) || other.enabled == enabled) &&
            const DeepCollectionEquality().equals(other._windows, _windows) &&
            (identical(other.slotDurationMinutes, slotDurationMinutes) ||
                other.slotDurationMinutes == slotDurationMinutes) &&
            (identical(other.maxBookingsPerWeek, maxBookingsPerWeek) ||
                other.maxBookingsPerWeek == maxBookingsPerWeek) &&
            (identical(other.bufferMinutes, bufferMinutes) ||
                other.bufferMinutes == bufferMinutes) &&
            (identical(other.meetingLinkTemplate, meetingLinkTemplate) ||
                other.meetingLinkTemplate == meetingLinkTemplate) &&
            (identical(other.notesTemplate, notesTemplate) ||
                other.notesTemplate == notesTemplate) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      userId,
      enabled,
      const DeepCollectionEquality().hash(_windows),
      slotDurationMinutes,
      maxBookingsPerWeek,
      bufferMinutes,
      meetingLinkTemplate,
      notesTemplate,
      updatedAt);

  /// Create a copy of OfficeHoursSettings
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OfficeHoursSettingsImplCopyWith<_$OfficeHoursSettingsImpl> get copyWith =>
      __$$OfficeHoursSettingsImplCopyWithImpl<_$OfficeHoursSettingsImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$OfficeHoursSettingsImplToJson(
      this,
    );
  }
}

abstract class _OfficeHoursSettings extends OfficeHoursSettings {
  const factory _OfficeHoursSettings(
      {@JsonKey(name: 'user_id') required final String userId,
      required final bool enabled,
      final List<OfficeHoursWindow> windows,
      @JsonKey(name: 'slot_duration_minutes')
      required final int slotDurationMinutes,
      @JsonKey(name: 'max_bookings_per_week')
      required final int maxBookingsPerWeek,
      @JsonKey(name: 'buffer_minutes') required final int bufferMinutes,
      @JsonKey(name: 'meeting_link_template') final String? meetingLinkTemplate,
      @JsonKey(name: 'notes_template') final String? notesTemplate,
      @JsonKey(
          name: 'updated_at',
          fromJson: _utcFromJsonNullable,
          toJson: _utcToJsonNullable)
      final DateTime? updatedAt}) = _$OfficeHoursSettingsImpl;
  const _OfficeHoursSettings._() : super._();

  factory _OfficeHoursSettings.fromJson(Map<String, dynamic> json) =
      _$OfficeHoursSettingsImpl.fromJson;

  @override
  @JsonKey(name: 'user_id')
  String get userId;
  @override
  bool get enabled;
  @override
  List<OfficeHoursWindow> get windows;
  @override
  @JsonKey(name: 'slot_duration_minutes')
  int get slotDurationMinutes;
  @override
  @JsonKey(name: 'max_bookings_per_week')
  int get maxBookingsPerWeek;
  @override
  @JsonKey(name: 'buffer_minutes')
  int get bufferMinutes;
  @override
  @JsonKey(name: 'meeting_link_template')
  String? get meetingLinkTemplate;
  @override
  @JsonKey(name: 'notes_template')
  String? get notesTemplate;
  @override
  @JsonKey(
      name: 'updated_at',
      fromJson: _utcFromJsonNullable,
      toJson: _utcToJsonNullable)
  DateTime? get updatedAt;

  /// Create a copy of OfficeHoursSettings
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OfficeHoursSettingsImplCopyWith<_$OfficeHoursSettingsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
