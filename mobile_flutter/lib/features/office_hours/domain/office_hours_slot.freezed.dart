// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'office_hours_slot.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

OfficeHoursSlot _$OfficeHoursSlotFromJson(Map<String, dynamic> json) {
  return _OfficeHoursSlot.fromJson(json);
}

/// @nodoc
mixin _$OfficeHoursSlot {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'host_id')
  String get hostId => throw _privateConstructorUsedError;
  @JsonKey(name: 'starts_at', fromJson: _utcFromJson, toJson: _utcToJson)
  DateTime get startsAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'ends_at', fromJson: _utcFromJson, toJson: _utcToJson)
  DateTime get endsAt => throw _privateConstructorUsedError;
  SlotStatus get status => throw _privateConstructorUsedError;
  @JsonKey(name: 'booked_by')
  String? get bookedBy => throw _privateConstructorUsedError;
  @JsonKey(
      name: 'booked_at',
      fromJson: _utcFromJsonNullable,
      toJson: _utcToJsonNullable)
  DateTime? get bookedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'meeting_proposal_id')
  String? get meetingProposalId => throw _privateConstructorUsedError;
  String? get topic => throw _privateConstructorUsedError;
  @JsonKey(name: 'host_settings_notes_template')
  String? get hostNotesTemplate => throw _privateConstructorUsedError;

  /// Serializes this OfficeHoursSlot to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of OfficeHoursSlot
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $OfficeHoursSlotCopyWith<OfficeHoursSlot> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OfficeHoursSlotCopyWith<$Res> {
  factory $OfficeHoursSlotCopyWith(
          OfficeHoursSlot value, $Res Function(OfficeHoursSlot) then) =
      _$OfficeHoursSlotCopyWithImpl<$Res, OfficeHoursSlot>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'host_id') String hostId,
      @JsonKey(name: 'starts_at', fromJson: _utcFromJson, toJson: _utcToJson)
      DateTime startsAt,
      @JsonKey(name: 'ends_at', fromJson: _utcFromJson, toJson: _utcToJson)
      DateTime endsAt,
      SlotStatus status,
      @JsonKey(name: 'booked_by') String? bookedBy,
      @JsonKey(
          name: 'booked_at',
          fromJson: _utcFromJsonNullable,
          toJson: _utcToJsonNullable)
      DateTime? bookedAt,
      @JsonKey(name: 'meeting_proposal_id') String? meetingProposalId,
      String? topic,
      @JsonKey(name: 'host_settings_notes_template')
      String? hostNotesTemplate});
}

/// @nodoc
class _$OfficeHoursSlotCopyWithImpl<$Res, $Val extends OfficeHoursSlot>
    implements $OfficeHoursSlotCopyWith<$Res> {
  _$OfficeHoursSlotCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of OfficeHoursSlot
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? hostId = null,
    Object? startsAt = null,
    Object? endsAt = null,
    Object? status = null,
    Object? bookedBy = freezed,
    Object? bookedAt = freezed,
    Object? meetingProposalId = freezed,
    Object? topic = freezed,
    Object? hostNotesTemplate = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      hostId: null == hostId
          ? _value.hostId
          : hostId // ignore: cast_nullable_to_non_nullable
              as String,
      startsAt: null == startsAt
          ? _value.startsAt
          : startsAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      endsAt: null == endsAt
          ? _value.endsAt
          : endsAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as SlotStatus,
      bookedBy: freezed == bookedBy
          ? _value.bookedBy
          : bookedBy // ignore: cast_nullable_to_non_nullable
              as String?,
      bookedAt: freezed == bookedAt
          ? _value.bookedAt
          : bookedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      meetingProposalId: freezed == meetingProposalId
          ? _value.meetingProposalId
          : meetingProposalId // ignore: cast_nullable_to_non_nullable
              as String?,
      topic: freezed == topic
          ? _value.topic
          : topic // ignore: cast_nullable_to_non_nullable
              as String?,
      hostNotesTemplate: freezed == hostNotesTemplate
          ? _value.hostNotesTemplate
          : hostNotesTemplate // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$OfficeHoursSlotImplCopyWith<$Res>
    implements $OfficeHoursSlotCopyWith<$Res> {
  factory _$$OfficeHoursSlotImplCopyWith(_$OfficeHoursSlotImpl value,
          $Res Function(_$OfficeHoursSlotImpl) then) =
      __$$OfficeHoursSlotImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'host_id') String hostId,
      @JsonKey(name: 'starts_at', fromJson: _utcFromJson, toJson: _utcToJson)
      DateTime startsAt,
      @JsonKey(name: 'ends_at', fromJson: _utcFromJson, toJson: _utcToJson)
      DateTime endsAt,
      SlotStatus status,
      @JsonKey(name: 'booked_by') String? bookedBy,
      @JsonKey(
          name: 'booked_at',
          fromJson: _utcFromJsonNullable,
          toJson: _utcToJsonNullable)
      DateTime? bookedAt,
      @JsonKey(name: 'meeting_proposal_id') String? meetingProposalId,
      String? topic,
      @JsonKey(name: 'host_settings_notes_template')
      String? hostNotesTemplate});
}

/// @nodoc
class __$$OfficeHoursSlotImplCopyWithImpl<$Res>
    extends _$OfficeHoursSlotCopyWithImpl<$Res, _$OfficeHoursSlotImpl>
    implements _$$OfficeHoursSlotImplCopyWith<$Res> {
  __$$OfficeHoursSlotImplCopyWithImpl(
      _$OfficeHoursSlotImpl _value, $Res Function(_$OfficeHoursSlotImpl) _then)
      : super(_value, _then);

  /// Create a copy of OfficeHoursSlot
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? hostId = null,
    Object? startsAt = null,
    Object? endsAt = null,
    Object? status = null,
    Object? bookedBy = freezed,
    Object? bookedAt = freezed,
    Object? meetingProposalId = freezed,
    Object? topic = freezed,
    Object? hostNotesTemplate = freezed,
  }) {
    return _then(_$OfficeHoursSlotImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      hostId: null == hostId
          ? _value.hostId
          : hostId // ignore: cast_nullable_to_non_nullable
              as String,
      startsAt: null == startsAt
          ? _value.startsAt
          : startsAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      endsAt: null == endsAt
          ? _value.endsAt
          : endsAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as SlotStatus,
      bookedBy: freezed == bookedBy
          ? _value.bookedBy
          : bookedBy // ignore: cast_nullable_to_non_nullable
              as String?,
      bookedAt: freezed == bookedAt
          ? _value.bookedAt
          : bookedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      meetingProposalId: freezed == meetingProposalId
          ? _value.meetingProposalId
          : meetingProposalId // ignore: cast_nullable_to_non_nullable
              as String?,
      topic: freezed == topic
          ? _value.topic
          : topic // ignore: cast_nullable_to_non_nullable
              as String?,
      hostNotesTemplate: freezed == hostNotesTemplate
          ? _value.hostNotesTemplate
          : hostNotesTemplate // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$OfficeHoursSlotImpl extends _OfficeHoursSlot {
  const _$OfficeHoursSlotImpl(
      {required this.id,
      @JsonKey(name: 'host_id') required this.hostId,
      @JsonKey(name: 'starts_at', fromJson: _utcFromJson, toJson: _utcToJson)
      required this.startsAt,
      @JsonKey(name: 'ends_at', fromJson: _utcFromJson, toJson: _utcToJson)
      required this.endsAt,
      this.status = SlotStatus.open,
      @JsonKey(name: 'booked_by') this.bookedBy,
      @JsonKey(
          name: 'booked_at',
          fromJson: _utcFromJsonNullable,
          toJson: _utcToJsonNullable)
      this.bookedAt,
      @JsonKey(name: 'meeting_proposal_id') this.meetingProposalId,
      this.topic,
      @JsonKey(name: 'host_settings_notes_template') this.hostNotesTemplate})
      : super._();

  factory _$OfficeHoursSlotImpl.fromJson(Map<String, dynamic> json) =>
      _$$OfficeHoursSlotImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'host_id')
  final String hostId;
  @override
  @JsonKey(name: 'starts_at', fromJson: _utcFromJson, toJson: _utcToJson)
  final DateTime startsAt;
  @override
  @JsonKey(name: 'ends_at', fromJson: _utcFromJson, toJson: _utcToJson)
  final DateTime endsAt;
  @override
  @JsonKey()
  final SlotStatus status;
  @override
  @JsonKey(name: 'booked_by')
  final String? bookedBy;
  @override
  @JsonKey(
      name: 'booked_at',
      fromJson: _utcFromJsonNullable,
      toJson: _utcToJsonNullable)
  final DateTime? bookedAt;
  @override
  @JsonKey(name: 'meeting_proposal_id')
  final String? meetingProposalId;
  @override
  final String? topic;
  @override
  @JsonKey(name: 'host_settings_notes_template')
  final String? hostNotesTemplate;

  @override
  String toString() {
    return 'OfficeHoursSlot(id: $id, hostId: $hostId, startsAt: $startsAt, endsAt: $endsAt, status: $status, bookedBy: $bookedBy, bookedAt: $bookedAt, meetingProposalId: $meetingProposalId, topic: $topic, hostNotesTemplate: $hostNotesTemplate)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OfficeHoursSlotImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.hostId, hostId) || other.hostId == hostId) &&
            (identical(other.startsAt, startsAt) ||
                other.startsAt == startsAt) &&
            (identical(other.endsAt, endsAt) || other.endsAt == endsAt) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.bookedBy, bookedBy) ||
                other.bookedBy == bookedBy) &&
            (identical(other.bookedAt, bookedAt) ||
                other.bookedAt == bookedAt) &&
            (identical(other.meetingProposalId, meetingProposalId) ||
                other.meetingProposalId == meetingProposalId) &&
            (identical(other.topic, topic) || other.topic == topic) &&
            (identical(other.hostNotesTemplate, hostNotesTemplate) ||
                other.hostNotesTemplate == hostNotesTemplate));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, hostId, startsAt, endsAt,
      status, bookedBy, bookedAt, meetingProposalId, topic, hostNotesTemplate);

  /// Create a copy of OfficeHoursSlot
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OfficeHoursSlotImplCopyWith<_$OfficeHoursSlotImpl> get copyWith =>
      __$$OfficeHoursSlotImplCopyWithImpl<_$OfficeHoursSlotImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$OfficeHoursSlotImplToJson(
      this,
    );
  }
}

abstract class _OfficeHoursSlot extends OfficeHoursSlot {
  const factory _OfficeHoursSlot(
      {required final String id,
      @JsonKey(name: 'host_id') required final String hostId,
      @JsonKey(name: 'starts_at', fromJson: _utcFromJson, toJson: _utcToJson)
      required final DateTime startsAt,
      @JsonKey(name: 'ends_at', fromJson: _utcFromJson, toJson: _utcToJson)
      required final DateTime endsAt,
      final SlotStatus status,
      @JsonKey(name: 'booked_by') final String? bookedBy,
      @JsonKey(
          name: 'booked_at',
          fromJson: _utcFromJsonNullable,
          toJson: _utcToJsonNullable)
      final DateTime? bookedAt,
      @JsonKey(name: 'meeting_proposal_id') final String? meetingProposalId,
      final String? topic,
      @JsonKey(name: 'host_settings_notes_template')
      final String? hostNotesTemplate}) = _$OfficeHoursSlotImpl;
  const _OfficeHoursSlot._() : super._();

  factory _OfficeHoursSlot.fromJson(Map<String, dynamic> json) =
      _$OfficeHoursSlotImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'host_id')
  String get hostId;
  @override
  @JsonKey(name: 'starts_at', fromJson: _utcFromJson, toJson: _utcToJson)
  DateTime get startsAt;
  @override
  @JsonKey(name: 'ends_at', fromJson: _utcFromJson, toJson: _utcToJson)
  DateTime get endsAt;
  @override
  SlotStatus get status;
  @override
  @JsonKey(name: 'booked_by')
  String? get bookedBy;
  @override
  @JsonKey(
      name: 'booked_at',
      fromJson: _utcFromJsonNullable,
      toJson: _utcToJsonNullable)
  DateTime? get bookedAt;
  @override
  @JsonKey(name: 'meeting_proposal_id')
  String? get meetingProposalId;
  @override
  String? get topic;
  @override
  @JsonKey(name: 'host_settings_notes_template')
  String? get hostNotesTemplate;

  /// Create a copy of OfficeHoursSlot
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OfficeHoursSlotImplCopyWith<_$OfficeHoursSlotImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
