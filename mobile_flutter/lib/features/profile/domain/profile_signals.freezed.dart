// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'profile_signals.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ProfileSignals _$ProfileSignalsFromJson(Map<String, dynamic> json) {
  return _ProfileSignals.fromJson(json);
}

/// @nodoc
mixin _$ProfileSignals {
  @JsonKey(name: 'mutual_connection_count')
  int get mutualConnectionCount => throw _privateConstructorUsedError;
  @JsonKey(name: 'mutual_top_user_ids')
  List<String> get mutualTopUserIds => throw _privateConstructorUsedError;
  @JsonKey(name: 'avg_meeting_rating', fromJson: _avgFromJson)
  double? get avgMeetingRating => throw _privateConstructorUsedError;
  @JsonKey(name: 'total_meeting_reviews')
  int get totalMeetingReviews => throw _privateConstructorUsedError;

  /// Serializes this ProfileSignals to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ProfileSignals
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProfileSignalsCopyWith<ProfileSignals> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProfileSignalsCopyWith<$Res> {
  factory $ProfileSignalsCopyWith(
          ProfileSignals value, $Res Function(ProfileSignals) then) =
      _$ProfileSignalsCopyWithImpl<$Res, ProfileSignals>;
  @useResult
  $Res call(
      {@JsonKey(name: 'mutual_connection_count') int mutualConnectionCount,
      @JsonKey(name: 'mutual_top_user_ids') List<String> mutualTopUserIds,
      @JsonKey(name: 'avg_meeting_rating', fromJson: _avgFromJson)
      double? avgMeetingRating,
      @JsonKey(name: 'total_meeting_reviews') int totalMeetingReviews});
}

/// @nodoc
class _$ProfileSignalsCopyWithImpl<$Res, $Val extends ProfileSignals>
    implements $ProfileSignalsCopyWith<$Res> {
  _$ProfileSignalsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProfileSignals
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? mutualConnectionCount = null,
    Object? mutualTopUserIds = null,
    Object? avgMeetingRating = freezed,
    Object? totalMeetingReviews = null,
  }) {
    return _then(_value.copyWith(
      mutualConnectionCount: null == mutualConnectionCount
          ? _value.mutualConnectionCount
          : mutualConnectionCount // ignore: cast_nullable_to_non_nullable
              as int,
      mutualTopUserIds: null == mutualTopUserIds
          ? _value.mutualTopUserIds
          : mutualTopUserIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      avgMeetingRating: freezed == avgMeetingRating
          ? _value.avgMeetingRating
          : avgMeetingRating // ignore: cast_nullable_to_non_nullable
              as double?,
      totalMeetingReviews: null == totalMeetingReviews
          ? _value.totalMeetingReviews
          : totalMeetingReviews // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ProfileSignalsImplCopyWith<$Res>
    implements $ProfileSignalsCopyWith<$Res> {
  factory _$$ProfileSignalsImplCopyWith(_$ProfileSignalsImpl value,
          $Res Function(_$ProfileSignalsImpl) then) =
      __$$ProfileSignalsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'mutual_connection_count') int mutualConnectionCount,
      @JsonKey(name: 'mutual_top_user_ids') List<String> mutualTopUserIds,
      @JsonKey(name: 'avg_meeting_rating', fromJson: _avgFromJson)
      double? avgMeetingRating,
      @JsonKey(name: 'total_meeting_reviews') int totalMeetingReviews});
}

/// @nodoc
class __$$ProfileSignalsImplCopyWithImpl<$Res>
    extends _$ProfileSignalsCopyWithImpl<$Res, _$ProfileSignalsImpl>
    implements _$$ProfileSignalsImplCopyWith<$Res> {
  __$$ProfileSignalsImplCopyWithImpl(
      _$ProfileSignalsImpl _value, $Res Function(_$ProfileSignalsImpl) _then)
      : super(_value, _then);

  /// Create a copy of ProfileSignals
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? mutualConnectionCount = null,
    Object? mutualTopUserIds = null,
    Object? avgMeetingRating = freezed,
    Object? totalMeetingReviews = null,
  }) {
    return _then(_$ProfileSignalsImpl(
      mutualConnectionCount: null == mutualConnectionCount
          ? _value.mutualConnectionCount
          : mutualConnectionCount // ignore: cast_nullable_to_non_nullable
              as int,
      mutualTopUserIds: null == mutualTopUserIds
          ? _value._mutualTopUserIds
          : mutualTopUserIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      avgMeetingRating: freezed == avgMeetingRating
          ? _value.avgMeetingRating
          : avgMeetingRating // ignore: cast_nullable_to_non_nullable
              as double?,
      totalMeetingReviews: null == totalMeetingReviews
          ? _value.totalMeetingReviews
          : totalMeetingReviews // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ProfileSignalsImpl extends _ProfileSignals {
  const _$ProfileSignalsImpl(
      {@JsonKey(name: 'mutual_connection_count') this.mutualConnectionCount = 0,
      @JsonKey(name: 'mutual_top_user_ids')
      final List<String> mutualTopUserIds = const <String>[],
      @JsonKey(name: 'avg_meeting_rating', fromJson: _avgFromJson)
      this.avgMeetingRating,
      @JsonKey(name: 'total_meeting_reviews') this.totalMeetingReviews = 0})
      : _mutualTopUserIds = mutualTopUserIds,
        super._();

  factory _$ProfileSignalsImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProfileSignalsImplFromJson(json);

  @override
  @JsonKey(name: 'mutual_connection_count')
  final int mutualConnectionCount;
  final List<String> _mutualTopUserIds;
  @override
  @JsonKey(name: 'mutual_top_user_ids')
  List<String> get mutualTopUserIds {
    if (_mutualTopUserIds is EqualUnmodifiableListView)
      return _mutualTopUserIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_mutualTopUserIds);
  }

  @override
  @JsonKey(name: 'avg_meeting_rating', fromJson: _avgFromJson)
  final double? avgMeetingRating;
  @override
  @JsonKey(name: 'total_meeting_reviews')
  final int totalMeetingReviews;

  @override
  String toString() {
    return 'ProfileSignals(mutualConnectionCount: $mutualConnectionCount, mutualTopUserIds: $mutualTopUserIds, avgMeetingRating: $avgMeetingRating, totalMeetingReviews: $totalMeetingReviews)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProfileSignalsImpl &&
            (identical(other.mutualConnectionCount, mutualConnectionCount) ||
                other.mutualConnectionCount == mutualConnectionCount) &&
            const DeepCollectionEquality()
                .equals(other._mutualTopUserIds, _mutualTopUserIds) &&
            (identical(other.avgMeetingRating, avgMeetingRating) ||
                other.avgMeetingRating == avgMeetingRating) &&
            (identical(other.totalMeetingReviews, totalMeetingReviews) ||
                other.totalMeetingReviews == totalMeetingReviews));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      mutualConnectionCount,
      const DeepCollectionEquality().hash(_mutualTopUserIds),
      avgMeetingRating,
      totalMeetingReviews);

  /// Create a copy of ProfileSignals
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProfileSignalsImplCopyWith<_$ProfileSignalsImpl> get copyWith =>
      __$$ProfileSignalsImplCopyWithImpl<_$ProfileSignalsImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProfileSignalsImplToJson(
      this,
    );
  }
}

abstract class _ProfileSignals extends ProfileSignals {
  const factory _ProfileSignals(
      {@JsonKey(name: 'mutual_connection_count')
      final int mutualConnectionCount,
      @JsonKey(name: 'mutual_top_user_ids') final List<String> mutualTopUserIds,
      @JsonKey(name: 'avg_meeting_rating', fromJson: _avgFromJson)
      final double? avgMeetingRating,
      @JsonKey(name: 'total_meeting_reviews')
      final int totalMeetingReviews}) = _$ProfileSignalsImpl;
  const _ProfileSignals._() : super._();

  factory _ProfileSignals.fromJson(Map<String, dynamic> json) =
      _$ProfileSignalsImpl.fromJson;

  @override
  @JsonKey(name: 'mutual_connection_count')
  int get mutualConnectionCount;
  @override
  @JsonKey(name: 'mutual_top_user_ids')
  List<String> get mutualTopUserIds;
  @override
  @JsonKey(name: 'avg_meeting_rating', fromJson: _avgFromJson)
  double? get avgMeetingRating;
  @override
  @JsonKey(name: 'total_meeting_reviews')
  int get totalMeetingReviews;

  /// Create a copy of ProfileSignals
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProfileSignalsImplCopyWith<_$ProfileSignalsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
