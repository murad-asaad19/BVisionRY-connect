// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'warm_suggestion.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

WarmSuggestion _$WarmSuggestionFromJson(Map<String, dynamic> json) {
  return _WarmSuggestion.fromJson(json);
}

/// @nodoc
mixin _$WarmSuggestion {
  @JsonKey(name: 'target_id')
  String get targetId => throw _privateConstructorUsedError;
  @JsonKey(name: 'target_handle')
  String get targetHandle => throw _privateConstructorUsedError;
  @JsonKey(name: 'target_name')
  String get targetName => throw _privateConstructorUsedError;
  @JsonKey(name: 'target_photo_url')
  String? get targetPhotoUrl => throw _privateConstructorUsedError;
  @JsonKey(name: 'target_primary_role')
  String? get targetPrimaryRole => throw _privateConstructorUsedError;
  @JsonKey(name: 'target_goal_type')
  String? get targetGoalType => throw _privateConstructorUsedError;
  @JsonKey(name: 'mutual_count')
  int get mutualCount => throw _privateConstructorUsedError;
  @JsonKey(name: 'top_mutual_id')
  String get topMutualId => throw _privateConstructorUsedError;
  @JsonKey(name: 'top_mutual_name')
  String get topMutualName => throw _privateConstructorUsedError;
  @JsonKey(name: 'top_mutual_handle')
  String get topMutualHandle => throw _privateConstructorUsedError;

  /// Serializes this WarmSuggestion to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of WarmSuggestion
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $WarmSuggestionCopyWith<WarmSuggestion> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WarmSuggestionCopyWith<$Res> {
  factory $WarmSuggestionCopyWith(
          WarmSuggestion value, $Res Function(WarmSuggestion) then) =
      _$WarmSuggestionCopyWithImpl<$Res, WarmSuggestion>;
  @useResult
  $Res call(
      {@JsonKey(name: 'target_id') String targetId,
      @JsonKey(name: 'target_handle') String targetHandle,
      @JsonKey(name: 'target_name') String targetName,
      @JsonKey(name: 'target_photo_url') String? targetPhotoUrl,
      @JsonKey(name: 'target_primary_role') String? targetPrimaryRole,
      @JsonKey(name: 'target_goal_type') String? targetGoalType,
      @JsonKey(name: 'mutual_count') int mutualCount,
      @JsonKey(name: 'top_mutual_id') String topMutualId,
      @JsonKey(name: 'top_mutual_name') String topMutualName,
      @JsonKey(name: 'top_mutual_handle') String topMutualHandle});
}

/// @nodoc
class _$WarmSuggestionCopyWithImpl<$Res, $Val extends WarmSuggestion>
    implements $WarmSuggestionCopyWith<$Res> {
  _$WarmSuggestionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of WarmSuggestion
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? targetId = null,
    Object? targetHandle = null,
    Object? targetName = null,
    Object? targetPhotoUrl = freezed,
    Object? targetPrimaryRole = freezed,
    Object? targetGoalType = freezed,
    Object? mutualCount = null,
    Object? topMutualId = null,
    Object? topMutualName = null,
    Object? topMutualHandle = null,
  }) {
    return _then(_value.copyWith(
      targetId: null == targetId
          ? _value.targetId
          : targetId // ignore: cast_nullable_to_non_nullable
              as String,
      targetHandle: null == targetHandle
          ? _value.targetHandle
          : targetHandle // ignore: cast_nullable_to_non_nullable
              as String,
      targetName: null == targetName
          ? _value.targetName
          : targetName // ignore: cast_nullable_to_non_nullable
              as String,
      targetPhotoUrl: freezed == targetPhotoUrl
          ? _value.targetPhotoUrl
          : targetPhotoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      targetPrimaryRole: freezed == targetPrimaryRole
          ? _value.targetPrimaryRole
          : targetPrimaryRole // ignore: cast_nullable_to_non_nullable
              as String?,
      targetGoalType: freezed == targetGoalType
          ? _value.targetGoalType
          : targetGoalType // ignore: cast_nullable_to_non_nullable
              as String?,
      mutualCount: null == mutualCount
          ? _value.mutualCount
          : mutualCount // ignore: cast_nullable_to_non_nullable
              as int,
      topMutualId: null == topMutualId
          ? _value.topMutualId
          : topMutualId // ignore: cast_nullable_to_non_nullable
              as String,
      topMutualName: null == topMutualName
          ? _value.topMutualName
          : topMutualName // ignore: cast_nullable_to_non_nullable
              as String,
      topMutualHandle: null == topMutualHandle
          ? _value.topMutualHandle
          : topMutualHandle // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$WarmSuggestionImplCopyWith<$Res>
    implements $WarmSuggestionCopyWith<$Res> {
  factory _$$WarmSuggestionImplCopyWith(_$WarmSuggestionImpl value,
          $Res Function(_$WarmSuggestionImpl) then) =
      __$$WarmSuggestionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'target_id') String targetId,
      @JsonKey(name: 'target_handle') String targetHandle,
      @JsonKey(name: 'target_name') String targetName,
      @JsonKey(name: 'target_photo_url') String? targetPhotoUrl,
      @JsonKey(name: 'target_primary_role') String? targetPrimaryRole,
      @JsonKey(name: 'target_goal_type') String? targetGoalType,
      @JsonKey(name: 'mutual_count') int mutualCount,
      @JsonKey(name: 'top_mutual_id') String topMutualId,
      @JsonKey(name: 'top_mutual_name') String topMutualName,
      @JsonKey(name: 'top_mutual_handle') String topMutualHandle});
}

/// @nodoc
class __$$WarmSuggestionImplCopyWithImpl<$Res>
    extends _$WarmSuggestionCopyWithImpl<$Res, _$WarmSuggestionImpl>
    implements _$$WarmSuggestionImplCopyWith<$Res> {
  __$$WarmSuggestionImplCopyWithImpl(
      _$WarmSuggestionImpl _value, $Res Function(_$WarmSuggestionImpl) _then)
      : super(_value, _then);

  /// Create a copy of WarmSuggestion
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? targetId = null,
    Object? targetHandle = null,
    Object? targetName = null,
    Object? targetPhotoUrl = freezed,
    Object? targetPrimaryRole = freezed,
    Object? targetGoalType = freezed,
    Object? mutualCount = null,
    Object? topMutualId = null,
    Object? topMutualName = null,
    Object? topMutualHandle = null,
  }) {
    return _then(_$WarmSuggestionImpl(
      targetId: null == targetId
          ? _value.targetId
          : targetId // ignore: cast_nullable_to_non_nullable
              as String,
      targetHandle: null == targetHandle
          ? _value.targetHandle
          : targetHandle // ignore: cast_nullable_to_non_nullable
              as String,
      targetName: null == targetName
          ? _value.targetName
          : targetName // ignore: cast_nullable_to_non_nullable
              as String,
      targetPhotoUrl: freezed == targetPhotoUrl
          ? _value.targetPhotoUrl
          : targetPhotoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      targetPrimaryRole: freezed == targetPrimaryRole
          ? _value.targetPrimaryRole
          : targetPrimaryRole // ignore: cast_nullable_to_non_nullable
              as String?,
      targetGoalType: freezed == targetGoalType
          ? _value.targetGoalType
          : targetGoalType // ignore: cast_nullable_to_non_nullable
              as String?,
      mutualCount: null == mutualCount
          ? _value.mutualCount
          : mutualCount // ignore: cast_nullable_to_non_nullable
              as int,
      topMutualId: null == topMutualId
          ? _value.topMutualId
          : topMutualId // ignore: cast_nullable_to_non_nullable
              as String,
      topMutualName: null == topMutualName
          ? _value.topMutualName
          : topMutualName // ignore: cast_nullable_to_non_nullable
              as String,
      topMutualHandle: null == topMutualHandle
          ? _value.topMutualHandle
          : topMutualHandle // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$WarmSuggestionImpl implements _WarmSuggestion {
  const _$WarmSuggestionImpl(
      {@JsonKey(name: 'target_id') required this.targetId,
      @JsonKey(name: 'target_handle') required this.targetHandle,
      @JsonKey(name: 'target_name') required this.targetName,
      @JsonKey(name: 'target_photo_url') required this.targetPhotoUrl,
      @JsonKey(name: 'target_primary_role') required this.targetPrimaryRole,
      @JsonKey(name: 'target_goal_type') required this.targetGoalType,
      @JsonKey(name: 'mutual_count') required this.mutualCount,
      @JsonKey(name: 'top_mutual_id') required this.topMutualId,
      @JsonKey(name: 'top_mutual_name') required this.topMutualName,
      @JsonKey(name: 'top_mutual_handle') required this.topMutualHandle});

  factory _$WarmSuggestionImpl.fromJson(Map<String, dynamic> json) =>
      _$$WarmSuggestionImplFromJson(json);

  @override
  @JsonKey(name: 'target_id')
  final String targetId;
  @override
  @JsonKey(name: 'target_handle')
  final String targetHandle;
  @override
  @JsonKey(name: 'target_name')
  final String targetName;
  @override
  @JsonKey(name: 'target_photo_url')
  final String? targetPhotoUrl;
  @override
  @JsonKey(name: 'target_primary_role')
  final String? targetPrimaryRole;
  @override
  @JsonKey(name: 'target_goal_type')
  final String? targetGoalType;
  @override
  @JsonKey(name: 'mutual_count')
  final int mutualCount;
  @override
  @JsonKey(name: 'top_mutual_id')
  final String topMutualId;
  @override
  @JsonKey(name: 'top_mutual_name')
  final String topMutualName;
  @override
  @JsonKey(name: 'top_mutual_handle')
  final String topMutualHandle;

  @override
  String toString() {
    return 'WarmSuggestion(targetId: $targetId, targetHandle: $targetHandle, targetName: $targetName, targetPhotoUrl: $targetPhotoUrl, targetPrimaryRole: $targetPrimaryRole, targetGoalType: $targetGoalType, mutualCount: $mutualCount, topMutualId: $topMutualId, topMutualName: $topMutualName, topMutualHandle: $topMutualHandle)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WarmSuggestionImpl &&
            (identical(other.targetId, targetId) ||
                other.targetId == targetId) &&
            (identical(other.targetHandle, targetHandle) ||
                other.targetHandle == targetHandle) &&
            (identical(other.targetName, targetName) ||
                other.targetName == targetName) &&
            (identical(other.targetPhotoUrl, targetPhotoUrl) ||
                other.targetPhotoUrl == targetPhotoUrl) &&
            (identical(other.targetPrimaryRole, targetPrimaryRole) ||
                other.targetPrimaryRole == targetPrimaryRole) &&
            (identical(other.targetGoalType, targetGoalType) ||
                other.targetGoalType == targetGoalType) &&
            (identical(other.mutualCount, mutualCount) ||
                other.mutualCount == mutualCount) &&
            (identical(other.topMutualId, topMutualId) ||
                other.topMutualId == topMutualId) &&
            (identical(other.topMutualName, topMutualName) ||
                other.topMutualName == topMutualName) &&
            (identical(other.topMutualHandle, topMutualHandle) ||
                other.topMutualHandle == topMutualHandle));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      targetId,
      targetHandle,
      targetName,
      targetPhotoUrl,
      targetPrimaryRole,
      targetGoalType,
      mutualCount,
      topMutualId,
      topMutualName,
      topMutualHandle);

  /// Create a copy of WarmSuggestion
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$WarmSuggestionImplCopyWith<_$WarmSuggestionImpl> get copyWith =>
      __$$WarmSuggestionImplCopyWithImpl<_$WarmSuggestionImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$WarmSuggestionImplToJson(
      this,
    );
  }
}

abstract class _WarmSuggestion implements WarmSuggestion {
  const factory _WarmSuggestion(
      {@JsonKey(name: 'target_id') required final String targetId,
      @JsonKey(name: 'target_handle') required final String targetHandle,
      @JsonKey(name: 'target_name') required final String targetName,
      @JsonKey(name: 'target_photo_url') required final String? targetPhotoUrl,
      @JsonKey(name: 'target_primary_role')
      required final String? targetPrimaryRole,
      @JsonKey(name: 'target_goal_type') required final String? targetGoalType,
      @JsonKey(name: 'mutual_count') required final int mutualCount,
      @JsonKey(name: 'top_mutual_id') required final String topMutualId,
      @JsonKey(name: 'top_mutual_name') required final String topMutualName,
      @JsonKey(name: 'top_mutual_handle')
      required final String topMutualHandle}) = _$WarmSuggestionImpl;

  factory _WarmSuggestion.fromJson(Map<String, dynamic> json) =
      _$WarmSuggestionImpl.fromJson;

  @override
  @JsonKey(name: 'target_id')
  String get targetId;
  @override
  @JsonKey(name: 'target_handle')
  String get targetHandle;
  @override
  @JsonKey(name: 'target_name')
  String get targetName;
  @override
  @JsonKey(name: 'target_photo_url')
  String? get targetPhotoUrl;
  @override
  @JsonKey(name: 'target_primary_role')
  String? get targetPrimaryRole;
  @override
  @JsonKey(name: 'target_goal_type')
  String? get targetGoalType;
  @override
  @JsonKey(name: 'mutual_count')
  int get mutualCount;
  @override
  @JsonKey(name: 'top_mutual_id')
  String get topMutualId;
  @override
  @JsonKey(name: 'top_mutual_name')
  String get topMutualName;
  @override
  @JsonKey(name: 'top_mutual_handle')
  String get topMutualHandle;

  /// Create a copy of WarmSuggestion
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$WarmSuggestionImplCopyWith<_$WarmSuggestionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
