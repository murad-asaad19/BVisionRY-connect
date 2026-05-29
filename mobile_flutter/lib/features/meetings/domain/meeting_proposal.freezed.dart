// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'meeting_proposal.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$MeetingProposal {
  String get id => throw _privateConstructorUsedError;
  String get conversationId => throw _privateConstructorUsedError;
  String get proposedById => throw _privateConstructorUsedError;
  List<DateTime> get slots => throw _privateConstructorUsedError;
  DateTime? get confirmedSlot => throw _privateConstructorUsedError;
  int get durationMinutes => throw _privateConstructorUsedError;
  String? get meetingUrl => throw _privateConstructorUsedError;
  String get timezone => throw _privateConstructorUsedError;
  MeetingState get state => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;
  int? get preferredSlotIndex => throw _privateConstructorUsedError;
  String? get note => throw _privateConstructorUsedError;

  /// Create a copy of MeetingProposal
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MeetingProposalCopyWith<MeetingProposal> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MeetingProposalCopyWith<$Res> {
  factory $MeetingProposalCopyWith(
          MeetingProposal value, $Res Function(MeetingProposal) then) =
      _$MeetingProposalCopyWithImpl<$Res, MeetingProposal>;
  @useResult
  $Res call(
      {String id,
      String conversationId,
      String proposedById,
      List<DateTime> slots,
      DateTime? confirmedSlot,
      int durationMinutes,
      String? meetingUrl,
      String timezone,
      MeetingState state,
      DateTime createdAt,
      DateTime updatedAt,
      int? preferredSlotIndex,
      String? note});
}

/// @nodoc
class _$MeetingProposalCopyWithImpl<$Res, $Val extends MeetingProposal>
    implements $MeetingProposalCopyWith<$Res> {
  _$MeetingProposalCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MeetingProposal
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? conversationId = null,
    Object? proposedById = null,
    Object? slots = null,
    Object? confirmedSlot = freezed,
    Object? durationMinutes = null,
    Object? meetingUrl = freezed,
    Object? timezone = null,
    Object? state = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? preferredSlotIndex = freezed,
    Object? note = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      conversationId: null == conversationId
          ? _value.conversationId
          : conversationId // ignore: cast_nullable_to_non_nullable
              as String,
      proposedById: null == proposedById
          ? _value.proposedById
          : proposedById // ignore: cast_nullable_to_non_nullable
              as String,
      slots: null == slots
          ? _value.slots
          : slots // ignore: cast_nullable_to_non_nullable
              as List<DateTime>,
      confirmedSlot: freezed == confirmedSlot
          ? _value.confirmedSlot
          : confirmedSlot // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      durationMinutes: null == durationMinutes
          ? _value.durationMinutes
          : durationMinutes // ignore: cast_nullable_to_non_nullable
              as int,
      meetingUrl: freezed == meetingUrl
          ? _value.meetingUrl
          : meetingUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      timezone: null == timezone
          ? _value.timezone
          : timezone // ignore: cast_nullable_to_non_nullable
              as String,
      state: null == state
          ? _value.state
          : state // ignore: cast_nullable_to_non_nullable
              as MeetingState,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      preferredSlotIndex: freezed == preferredSlotIndex
          ? _value.preferredSlotIndex
          : preferredSlotIndex // ignore: cast_nullable_to_non_nullable
              as int?,
      note: freezed == note
          ? _value.note
          : note // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MeetingProposalImplCopyWith<$Res>
    implements $MeetingProposalCopyWith<$Res> {
  factory _$$MeetingProposalImplCopyWith(_$MeetingProposalImpl value,
          $Res Function(_$MeetingProposalImpl) then) =
      __$$MeetingProposalImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String conversationId,
      String proposedById,
      List<DateTime> slots,
      DateTime? confirmedSlot,
      int durationMinutes,
      String? meetingUrl,
      String timezone,
      MeetingState state,
      DateTime createdAt,
      DateTime updatedAt,
      int? preferredSlotIndex,
      String? note});
}

/// @nodoc
class __$$MeetingProposalImplCopyWithImpl<$Res>
    extends _$MeetingProposalCopyWithImpl<$Res, _$MeetingProposalImpl>
    implements _$$MeetingProposalImplCopyWith<$Res> {
  __$$MeetingProposalImplCopyWithImpl(
      _$MeetingProposalImpl _value, $Res Function(_$MeetingProposalImpl) _then)
      : super(_value, _then);

  /// Create a copy of MeetingProposal
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? conversationId = null,
    Object? proposedById = null,
    Object? slots = null,
    Object? confirmedSlot = freezed,
    Object? durationMinutes = null,
    Object? meetingUrl = freezed,
    Object? timezone = null,
    Object? state = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? preferredSlotIndex = freezed,
    Object? note = freezed,
  }) {
    return _then(_$MeetingProposalImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      conversationId: null == conversationId
          ? _value.conversationId
          : conversationId // ignore: cast_nullable_to_non_nullable
              as String,
      proposedById: null == proposedById
          ? _value.proposedById
          : proposedById // ignore: cast_nullable_to_non_nullable
              as String,
      slots: null == slots
          ? _value._slots
          : slots // ignore: cast_nullable_to_non_nullable
              as List<DateTime>,
      confirmedSlot: freezed == confirmedSlot
          ? _value.confirmedSlot
          : confirmedSlot // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      durationMinutes: null == durationMinutes
          ? _value.durationMinutes
          : durationMinutes // ignore: cast_nullable_to_non_nullable
              as int,
      meetingUrl: freezed == meetingUrl
          ? _value.meetingUrl
          : meetingUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      timezone: null == timezone
          ? _value.timezone
          : timezone // ignore: cast_nullable_to_non_nullable
              as String,
      state: null == state
          ? _value.state
          : state // ignore: cast_nullable_to_non_nullable
              as MeetingState,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      preferredSlotIndex: freezed == preferredSlotIndex
          ? _value.preferredSlotIndex
          : preferredSlotIndex // ignore: cast_nullable_to_non_nullable
              as int?,
      note: freezed == note
          ? _value.note
          : note // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$MeetingProposalImpl extends _MeetingProposal {
  const _$MeetingProposalImpl(
      {required this.id,
      required this.conversationId,
      required this.proposedById,
      required final List<DateTime> slots,
      this.confirmedSlot,
      required this.durationMinutes,
      this.meetingUrl,
      required this.timezone,
      required this.state,
      required this.createdAt,
      required this.updatedAt,
      this.preferredSlotIndex,
      this.note})
      : _slots = slots,
        super._();

  @override
  final String id;
  @override
  final String conversationId;
  @override
  final String proposedById;
  final List<DateTime> _slots;
  @override
  List<DateTime> get slots {
    if (_slots is EqualUnmodifiableListView) return _slots;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_slots);
  }

  @override
  final DateTime? confirmedSlot;
  @override
  final int durationMinutes;
  @override
  final String? meetingUrl;
  @override
  final String timezone;
  @override
  final MeetingState state;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  @override
  final int? preferredSlotIndex;
  @override
  final String? note;

  @override
  String toString() {
    return 'MeetingProposal(id: $id, conversationId: $conversationId, proposedById: $proposedById, slots: $slots, confirmedSlot: $confirmedSlot, durationMinutes: $durationMinutes, meetingUrl: $meetingUrl, timezone: $timezone, state: $state, createdAt: $createdAt, updatedAt: $updatedAt, preferredSlotIndex: $preferredSlotIndex, note: $note)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MeetingProposalImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.conversationId, conversationId) ||
                other.conversationId == conversationId) &&
            (identical(other.proposedById, proposedById) ||
                other.proposedById == proposedById) &&
            const DeepCollectionEquality().equals(other._slots, _slots) &&
            (identical(other.confirmedSlot, confirmedSlot) ||
                other.confirmedSlot == confirmedSlot) &&
            (identical(other.durationMinutes, durationMinutes) ||
                other.durationMinutes == durationMinutes) &&
            (identical(other.meetingUrl, meetingUrl) ||
                other.meetingUrl == meetingUrl) &&
            (identical(other.timezone, timezone) ||
                other.timezone == timezone) &&
            (identical(other.state, state) || other.state == state) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.preferredSlotIndex, preferredSlotIndex) ||
                other.preferredSlotIndex == preferredSlotIndex) &&
            (identical(other.note, note) || other.note == note));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      conversationId,
      proposedById,
      const DeepCollectionEquality().hash(_slots),
      confirmedSlot,
      durationMinutes,
      meetingUrl,
      timezone,
      state,
      createdAt,
      updatedAt,
      preferredSlotIndex,
      note);

  /// Create a copy of MeetingProposal
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MeetingProposalImplCopyWith<_$MeetingProposalImpl> get copyWith =>
      __$$MeetingProposalImplCopyWithImpl<_$MeetingProposalImpl>(
          this, _$identity);
}

abstract class _MeetingProposal extends MeetingProposal {
  const factory _MeetingProposal(
      {required final String id,
      required final String conversationId,
      required final String proposedById,
      required final List<DateTime> slots,
      final DateTime? confirmedSlot,
      required final int durationMinutes,
      final String? meetingUrl,
      required final String timezone,
      required final MeetingState state,
      required final DateTime createdAt,
      required final DateTime updatedAt,
      final int? preferredSlotIndex,
      final String? note}) = _$MeetingProposalImpl;
  const _MeetingProposal._() : super._();

  @override
  String get id;
  @override
  String get conversationId;
  @override
  String get proposedById;
  @override
  List<DateTime> get slots;
  @override
  DateTime? get confirmedSlot;
  @override
  int get durationMinutes;
  @override
  String? get meetingUrl;
  @override
  String get timezone;
  @override
  MeetingState get state;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;
  @override
  int? get preferredSlotIndex;
  @override
  String? get note;

  /// Create a copy of MeetingProposal
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MeetingProposalImplCopyWith<_$MeetingProposalImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
