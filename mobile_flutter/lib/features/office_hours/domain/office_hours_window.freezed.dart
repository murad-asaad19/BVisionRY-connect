// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'office_hours_window.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

OfficeHoursWindow _$OfficeHoursWindowFromJson(Map<String, dynamic> json) {
  return _OfficeHoursWindow.fromJson(json);
}

/// @nodoc
mixin _$OfficeHoursWindow {
  int get weekday =>
      throw _privateConstructorUsedError; // 0=Sun..6=Sat (DB convention)
  @JsonKey(name: 'start_minute')
  int get startMinute => throw _privateConstructorUsedError;
  @JsonKey(name: 'end_minute')
  int get endMinute => throw _privateConstructorUsedError;
  String get timezone => throw _privateConstructorUsedError;

  /// Serializes this OfficeHoursWindow to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of OfficeHoursWindow
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $OfficeHoursWindowCopyWith<OfficeHoursWindow> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OfficeHoursWindowCopyWith<$Res> {
  factory $OfficeHoursWindowCopyWith(
          OfficeHoursWindow value, $Res Function(OfficeHoursWindow) then) =
      _$OfficeHoursWindowCopyWithImpl<$Res, OfficeHoursWindow>;
  @useResult
  $Res call(
      {int weekday,
      @JsonKey(name: 'start_minute') int startMinute,
      @JsonKey(name: 'end_minute') int endMinute,
      String timezone});
}

/// @nodoc
class _$OfficeHoursWindowCopyWithImpl<$Res, $Val extends OfficeHoursWindow>
    implements $OfficeHoursWindowCopyWith<$Res> {
  _$OfficeHoursWindowCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of OfficeHoursWindow
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? weekday = null,
    Object? startMinute = null,
    Object? endMinute = null,
    Object? timezone = null,
  }) {
    return _then(_value.copyWith(
      weekday: null == weekday
          ? _value.weekday
          : weekday // ignore: cast_nullable_to_non_nullable
              as int,
      startMinute: null == startMinute
          ? _value.startMinute
          : startMinute // ignore: cast_nullable_to_non_nullable
              as int,
      endMinute: null == endMinute
          ? _value.endMinute
          : endMinute // ignore: cast_nullable_to_non_nullable
              as int,
      timezone: null == timezone
          ? _value.timezone
          : timezone // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$OfficeHoursWindowImplCopyWith<$Res>
    implements $OfficeHoursWindowCopyWith<$Res> {
  factory _$$OfficeHoursWindowImplCopyWith(_$OfficeHoursWindowImpl value,
          $Res Function(_$OfficeHoursWindowImpl) then) =
      __$$OfficeHoursWindowImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int weekday,
      @JsonKey(name: 'start_minute') int startMinute,
      @JsonKey(name: 'end_minute') int endMinute,
      String timezone});
}

/// @nodoc
class __$$OfficeHoursWindowImplCopyWithImpl<$Res>
    extends _$OfficeHoursWindowCopyWithImpl<$Res, _$OfficeHoursWindowImpl>
    implements _$$OfficeHoursWindowImplCopyWith<$Res> {
  __$$OfficeHoursWindowImplCopyWithImpl(_$OfficeHoursWindowImpl _value,
      $Res Function(_$OfficeHoursWindowImpl) _then)
      : super(_value, _then);

  /// Create a copy of OfficeHoursWindow
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? weekday = null,
    Object? startMinute = null,
    Object? endMinute = null,
    Object? timezone = null,
  }) {
    return _then(_$OfficeHoursWindowImpl(
      weekday: null == weekday
          ? _value.weekday
          : weekday // ignore: cast_nullable_to_non_nullable
              as int,
      startMinute: null == startMinute
          ? _value.startMinute
          : startMinute // ignore: cast_nullable_to_non_nullable
              as int,
      endMinute: null == endMinute
          ? _value.endMinute
          : endMinute // ignore: cast_nullable_to_non_nullable
              as int,
      timezone: null == timezone
          ? _value.timezone
          : timezone // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$OfficeHoursWindowImpl extends _OfficeHoursWindow {
  const _$OfficeHoursWindowImpl(
      {required this.weekday,
      @JsonKey(name: 'start_minute') required this.startMinute,
      @JsonKey(name: 'end_minute') required this.endMinute,
      required this.timezone})
      : super._();

  factory _$OfficeHoursWindowImpl.fromJson(Map<String, dynamic> json) =>
      _$$OfficeHoursWindowImplFromJson(json);

  @override
  final int weekday;
// 0=Sun..6=Sat (DB convention)
  @override
  @JsonKey(name: 'start_minute')
  final int startMinute;
  @override
  @JsonKey(name: 'end_minute')
  final int endMinute;
  @override
  final String timezone;

  @override
  String toString() {
    return 'OfficeHoursWindow(weekday: $weekday, startMinute: $startMinute, endMinute: $endMinute, timezone: $timezone)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OfficeHoursWindowImpl &&
            (identical(other.weekday, weekday) || other.weekday == weekday) &&
            (identical(other.startMinute, startMinute) ||
                other.startMinute == startMinute) &&
            (identical(other.endMinute, endMinute) ||
                other.endMinute == endMinute) &&
            (identical(other.timezone, timezone) ||
                other.timezone == timezone));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, weekday, startMinute, endMinute, timezone);

  /// Create a copy of OfficeHoursWindow
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OfficeHoursWindowImplCopyWith<_$OfficeHoursWindowImpl> get copyWith =>
      __$$OfficeHoursWindowImplCopyWithImpl<_$OfficeHoursWindowImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$OfficeHoursWindowImplToJson(
      this,
    );
  }
}

abstract class _OfficeHoursWindow extends OfficeHoursWindow {
  const factory _OfficeHoursWindow(
      {required final int weekday,
      @JsonKey(name: 'start_minute') required final int startMinute,
      @JsonKey(name: 'end_minute') required final int endMinute,
      required final String timezone}) = _$OfficeHoursWindowImpl;
  const _OfficeHoursWindow._() : super._();

  factory _OfficeHoursWindow.fromJson(Map<String, dynamic> json) =
      _$OfficeHoursWindowImpl.fromJson;

  @override
  int get weekday; // 0=Sun..6=Sat (DB convention)
  @override
  @JsonKey(name: 'start_minute')
  int get startMinute;
  @override
  @JsonKey(name: 'end_minute')
  int get endMinute;
  @override
  String get timezone;

  /// Create a copy of OfficeHoursWindow
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OfficeHoursWindowImplCopyWith<_$OfficeHoursWindowImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
