// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'my_booking.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

MyBooking _$MyBookingFromJson(Map<String, dynamic> json) {
  return _MyBooking.fromJson(json);
}

/// @nodoc
mixin _$MyBooking {
  @JsonKey(name: 'slot_id')
  String get slotId => throw _privateConstructorUsedError;
  @JsonKey(name: 'host_id')
  String get hostId => throw _privateConstructorUsedError;
  @JsonKey(name: 'host_handle')
  String get hostHandle => throw _privateConstructorUsedError;
  @JsonKey(name: 'host_name')
  String get hostName => throw _privateConstructorUsedError;
  @JsonKey(name: 'host_photo_url')
  String? get hostPhotoUrl => throw _privateConstructorUsedError;
  @JsonKey(name: 'starts_at', fromJson: _utcFromJson, toJson: _utcToJson)
  DateTime get startsAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'ends_at', fromJson: _utcFromJson, toJson: _utcToJson)
  DateTime get endsAt => throw _privateConstructorUsedError;
  String? get topic => throw _privateConstructorUsedError;
  @JsonKey(name: 'meeting_proposal_id')
  String? get meetingProposalId => throw _privateConstructorUsedError;

  /// Serializes this MyBooking to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MyBooking
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MyBookingCopyWith<MyBooking> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MyBookingCopyWith<$Res> {
  factory $MyBookingCopyWith(MyBooking value, $Res Function(MyBooking) then) =
      _$MyBookingCopyWithImpl<$Res, MyBooking>;
  @useResult
  $Res call(
      {@JsonKey(name: 'slot_id') String slotId,
      @JsonKey(name: 'host_id') String hostId,
      @JsonKey(name: 'host_handle') String hostHandle,
      @JsonKey(name: 'host_name') String hostName,
      @JsonKey(name: 'host_photo_url') String? hostPhotoUrl,
      @JsonKey(name: 'starts_at', fromJson: _utcFromJson, toJson: _utcToJson)
      DateTime startsAt,
      @JsonKey(name: 'ends_at', fromJson: _utcFromJson, toJson: _utcToJson)
      DateTime endsAt,
      String? topic,
      @JsonKey(name: 'meeting_proposal_id') String? meetingProposalId});
}

/// @nodoc
class _$MyBookingCopyWithImpl<$Res, $Val extends MyBooking>
    implements $MyBookingCopyWith<$Res> {
  _$MyBookingCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MyBooking
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? slotId = null,
    Object? hostId = null,
    Object? hostHandle = null,
    Object? hostName = null,
    Object? hostPhotoUrl = freezed,
    Object? startsAt = null,
    Object? endsAt = null,
    Object? topic = freezed,
    Object? meetingProposalId = freezed,
  }) {
    return _then(_value.copyWith(
      slotId: null == slotId
          ? _value.slotId
          : slotId // ignore: cast_nullable_to_non_nullable
              as String,
      hostId: null == hostId
          ? _value.hostId
          : hostId // ignore: cast_nullable_to_non_nullable
              as String,
      hostHandle: null == hostHandle
          ? _value.hostHandle
          : hostHandle // ignore: cast_nullable_to_non_nullable
              as String,
      hostName: null == hostName
          ? _value.hostName
          : hostName // ignore: cast_nullable_to_non_nullable
              as String,
      hostPhotoUrl: freezed == hostPhotoUrl
          ? _value.hostPhotoUrl
          : hostPhotoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      startsAt: null == startsAt
          ? _value.startsAt
          : startsAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      endsAt: null == endsAt
          ? _value.endsAt
          : endsAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      topic: freezed == topic
          ? _value.topic
          : topic // ignore: cast_nullable_to_non_nullable
              as String?,
      meetingProposalId: freezed == meetingProposalId
          ? _value.meetingProposalId
          : meetingProposalId // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MyBookingImplCopyWith<$Res>
    implements $MyBookingCopyWith<$Res> {
  factory _$$MyBookingImplCopyWith(
          _$MyBookingImpl value, $Res Function(_$MyBookingImpl) then) =
      __$$MyBookingImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'slot_id') String slotId,
      @JsonKey(name: 'host_id') String hostId,
      @JsonKey(name: 'host_handle') String hostHandle,
      @JsonKey(name: 'host_name') String hostName,
      @JsonKey(name: 'host_photo_url') String? hostPhotoUrl,
      @JsonKey(name: 'starts_at', fromJson: _utcFromJson, toJson: _utcToJson)
      DateTime startsAt,
      @JsonKey(name: 'ends_at', fromJson: _utcFromJson, toJson: _utcToJson)
      DateTime endsAt,
      String? topic,
      @JsonKey(name: 'meeting_proposal_id') String? meetingProposalId});
}

/// @nodoc
class __$$MyBookingImplCopyWithImpl<$Res>
    extends _$MyBookingCopyWithImpl<$Res, _$MyBookingImpl>
    implements _$$MyBookingImplCopyWith<$Res> {
  __$$MyBookingImplCopyWithImpl(
      _$MyBookingImpl _value, $Res Function(_$MyBookingImpl) _then)
      : super(_value, _then);

  /// Create a copy of MyBooking
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? slotId = null,
    Object? hostId = null,
    Object? hostHandle = null,
    Object? hostName = null,
    Object? hostPhotoUrl = freezed,
    Object? startsAt = null,
    Object? endsAt = null,
    Object? topic = freezed,
    Object? meetingProposalId = freezed,
  }) {
    return _then(_$MyBookingImpl(
      slotId: null == slotId
          ? _value.slotId
          : slotId // ignore: cast_nullable_to_non_nullable
              as String,
      hostId: null == hostId
          ? _value.hostId
          : hostId // ignore: cast_nullable_to_non_nullable
              as String,
      hostHandle: null == hostHandle
          ? _value.hostHandle
          : hostHandle // ignore: cast_nullable_to_non_nullable
              as String,
      hostName: null == hostName
          ? _value.hostName
          : hostName // ignore: cast_nullable_to_non_nullable
              as String,
      hostPhotoUrl: freezed == hostPhotoUrl
          ? _value.hostPhotoUrl
          : hostPhotoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      startsAt: null == startsAt
          ? _value.startsAt
          : startsAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      endsAt: null == endsAt
          ? _value.endsAt
          : endsAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      topic: freezed == topic
          ? _value.topic
          : topic // ignore: cast_nullable_to_non_nullable
              as String?,
      meetingProposalId: freezed == meetingProposalId
          ? _value.meetingProposalId
          : meetingProposalId // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MyBookingImpl extends _MyBooking {
  const _$MyBookingImpl(
      {@JsonKey(name: 'slot_id') required this.slotId,
      @JsonKey(name: 'host_id') required this.hostId,
      @JsonKey(name: 'host_handle') required this.hostHandle,
      @JsonKey(name: 'host_name') required this.hostName,
      @JsonKey(name: 'host_photo_url') this.hostPhotoUrl,
      @JsonKey(name: 'starts_at', fromJson: _utcFromJson, toJson: _utcToJson)
      required this.startsAt,
      @JsonKey(name: 'ends_at', fromJson: _utcFromJson, toJson: _utcToJson)
      required this.endsAt,
      this.topic,
      @JsonKey(name: 'meeting_proposal_id') this.meetingProposalId})
      : super._();

  factory _$MyBookingImpl.fromJson(Map<String, dynamic> json) =>
      _$$MyBookingImplFromJson(json);

  @override
  @JsonKey(name: 'slot_id')
  final String slotId;
  @override
  @JsonKey(name: 'host_id')
  final String hostId;
  @override
  @JsonKey(name: 'host_handle')
  final String hostHandle;
  @override
  @JsonKey(name: 'host_name')
  final String hostName;
  @override
  @JsonKey(name: 'host_photo_url')
  final String? hostPhotoUrl;
  @override
  @JsonKey(name: 'starts_at', fromJson: _utcFromJson, toJson: _utcToJson)
  final DateTime startsAt;
  @override
  @JsonKey(name: 'ends_at', fromJson: _utcFromJson, toJson: _utcToJson)
  final DateTime endsAt;
  @override
  final String? topic;
  @override
  @JsonKey(name: 'meeting_proposal_id')
  final String? meetingProposalId;

  @override
  String toString() {
    return 'MyBooking(slotId: $slotId, hostId: $hostId, hostHandle: $hostHandle, hostName: $hostName, hostPhotoUrl: $hostPhotoUrl, startsAt: $startsAt, endsAt: $endsAt, topic: $topic, meetingProposalId: $meetingProposalId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MyBookingImpl &&
            (identical(other.slotId, slotId) || other.slotId == slotId) &&
            (identical(other.hostId, hostId) || other.hostId == hostId) &&
            (identical(other.hostHandle, hostHandle) ||
                other.hostHandle == hostHandle) &&
            (identical(other.hostName, hostName) ||
                other.hostName == hostName) &&
            (identical(other.hostPhotoUrl, hostPhotoUrl) ||
                other.hostPhotoUrl == hostPhotoUrl) &&
            (identical(other.startsAt, startsAt) ||
                other.startsAt == startsAt) &&
            (identical(other.endsAt, endsAt) || other.endsAt == endsAt) &&
            (identical(other.topic, topic) || other.topic == topic) &&
            (identical(other.meetingProposalId, meetingProposalId) ||
                other.meetingProposalId == meetingProposalId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, slotId, hostId, hostHandle,
      hostName, hostPhotoUrl, startsAt, endsAt, topic, meetingProposalId);

  /// Create a copy of MyBooking
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MyBookingImplCopyWith<_$MyBookingImpl> get copyWith =>
      __$$MyBookingImplCopyWithImpl<_$MyBookingImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MyBookingImplToJson(
      this,
    );
  }
}

abstract class _MyBooking extends MyBooking {
  const factory _MyBooking(
      {@JsonKey(name: 'slot_id') required final String slotId,
      @JsonKey(name: 'host_id') required final String hostId,
      @JsonKey(name: 'host_handle') required final String hostHandle,
      @JsonKey(name: 'host_name') required final String hostName,
      @JsonKey(name: 'host_photo_url') final String? hostPhotoUrl,
      @JsonKey(name: 'starts_at', fromJson: _utcFromJson, toJson: _utcToJson)
      required final DateTime startsAt,
      @JsonKey(name: 'ends_at', fromJson: _utcFromJson, toJson: _utcToJson)
      required final DateTime endsAt,
      final String? topic,
      @JsonKey(name: 'meeting_proposal_id')
      final String? meetingProposalId}) = _$MyBookingImpl;
  const _MyBooking._() : super._();

  factory _MyBooking.fromJson(Map<String, dynamic> json) =
      _$MyBookingImpl.fromJson;

  @override
  @JsonKey(name: 'slot_id')
  String get slotId;
  @override
  @JsonKey(name: 'host_id')
  String get hostId;
  @override
  @JsonKey(name: 'host_handle')
  String get hostHandle;
  @override
  @JsonKey(name: 'host_name')
  String get hostName;
  @override
  @JsonKey(name: 'host_photo_url')
  String? get hostPhotoUrl;
  @override
  @JsonKey(name: 'starts_at', fromJson: _utcFromJson, toJson: _utcToJson)
  DateTime get startsAt;
  @override
  @JsonKey(name: 'ends_at', fromJson: _utcFromJson, toJson: _utcToJson)
  DateTime get endsAt;
  @override
  String? get topic;
  @override
  @JsonKey(name: 'meeting_proposal_id')
  String? get meetingProposalId;

  /// Create a copy of MyBooking
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MyBookingImplCopyWith<_$MyBookingImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
