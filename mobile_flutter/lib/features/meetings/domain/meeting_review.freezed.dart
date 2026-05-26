// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'meeting_review.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$MeetingReview {
  String get id => throw _privateConstructorUsedError;
  String get meetingId => throw _privateConstructorUsedError;
  String get reviewerId => throw _privateConstructorUsedError;
  MeetingReviewOutcome get outcome => throw _privateConstructorUsedError;
  String? get note => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Create a copy of MeetingReview
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MeetingReviewCopyWith<MeetingReview> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MeetingReviewCopyWith<$Res> {
  factory $MeetingReviewCopyWith(
          MeetingReview value, $Res Function(MeetingReview) then) =
      _$MeetingReviewCopyWithImpl<$Res, MeetingReview>;
  @useResult
  $Res call(
      {String id,
      String meetingId,
      String reviewerId,
      MeetingReviewOutcome outcome,
      String? note,
      DateTime createdAt});
}

/// @nodoc
class _$MeetingReviewCopyWithImpl<$Res, $Val extends MeetingReview>
    implements $MeetingReviewCopyWith<$Res> {
  _$MeetingReviewCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MeetingReview
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? meetingId = null,
    Object? reviewerId = null,
    Object? outcome = null,
    Object? note = freezed,
    Object? createdAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      meetingId: null == meetingId
          ? _value.meetingId
          : meetingId // ignore: cast_nullable_to_non_nullable
              as String,
      reviewerId: null == reviewerId
          ? _value.reviewerId
          : reviewerId // ignore: cast_nullable_to_non_nullable
              as String,
      outcome: null == outcome
          ? _value.outcome
          : outcome // ignore: cast_nullable_to_non_nullable
              as MeetingReviewOutcome,
      note: freezed == note
          ? _value.note
          : note // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MeetingReviewImplCopyWith<$Res>
    implements $MeetingReviewCopyWith<$Res> {
  factory _$$MeetingReviewImplCopyWith(
          _$MeetingReviewImpl value, $Res Function(_$MeetingReviewImpl) then) =
      __$$MeetingReviewImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String meetingId,
      String reviewerId,
      MeetingReviewOutcome outcome,
      String? note,
      DateTime createdAt});
}

/// @nodoc
class __$$MeetingReviewImplCopyWithImpl<$Res>
    extends _$MeetingReviewCopyWithImpl<$Res, _$MeetingReviewImpl>
    implements _$$MeetingReviewImplCopyWith<$Res> {
  __$$MeetingReviewImplCopyWithImpl(
      _$MeetingReviewImpl _value, $Res Function(_$MeetingReviewImpl) _then)
      : super(_value, _then);

  /// Create a copy of MeetingReview
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? meetingId = null,
    Object? reviewerId = null,
    Object? outcome = null,
    Object? note = freezed,
    Object? createdAt = null,
  }) {
    return _then(_$MeetingReviewImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      meetingId: null == meetingId
          ? _value.meetingId
          : meetingId // ignore: cast_nullable_to_non_nullable
              as String,
      reviewerId: null == reviewerId
          ? _value.reviewerId
          : reviewerId // ignore: cast_nullable_to_non_nullable
              as String,
      outcome: null == outcome
          ? _value.outcome
          : outcome // ignore: cast_nullable_to_non_nullable
              as MeetingReviewOutcome,
      note: freezed == note
          ? _value.note
          : note // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc

class _$MeetingReviewImpl implements _MeetingReview {
  const _$MeetingReviewImpl(
      {required this.id,
      required this.meetingId,
      required this.reviewerId,
      required this.outcome,
      this.note,
      required this.createdAt});

  @override
  final String id;
  @override
  final String meetingId;
  @override
  final String reviewerId;
  @override
  final MeetingReviewOutcome outcome;
  @override
  final String? note;
  @override
  final DateTime createdAt;

  @override
  String toString() {
    return 'MeetingReview(id: $id, meetingId: $meetingId, reviewerId: $reviewerId, outcome: $outcome, note: $note, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MeetingReviewImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.meetingId, meetingId) ||
                other.meetingId == meetingId) &&
            (identical(other.reviewerId, reviewerId) ||
                other.reviewerId == reviewerId) &&
            (identical(other.outcome, outcome) || other.outcome == outcome) &&
            (identical(other.note, note) || other.note == note) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, id, meetingId, reviewerId, outcome, note, createdAt);

  /// Create a copy of MeetingReview
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MeetingReviewImplCopyWith<_$MeetingReviewImpl> get copyWith =>
      __$$MeetingReviewImplCopyWithImpl<_$MeetingReviewImpl>(this, _$identity);
}

abstract class _MeetingReview implements MeetingReview {
  const factory _MeetingReview(
      {required final String id,
      required final String meetingId,
      required final String reviewerId,
      required final MeetingReviewOutcome outcome,
      final String? note,
      required final DateTime createdAt}) = _$MeetingReviewImpl;

  @override
  String get id;
  @override
  String get meetingId;
  @override
  String get reviewerId;
  @override
  MeetingReviewOutcome get outcome;
  @override
  String? get note;
  @override
  DateTime get createdAt;

  /// Create a copy of MeetingReview
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MeetingReviewImplCopyWith<_$MeetingReviewImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
