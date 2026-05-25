// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'daily_match.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$DailyMatch {
  String get id => throw _privateConstructorUsedError;
  String get pickUserId => throw _privateConstructorUsedError;
  String get matchReason => throw _privateConstructorUsedError;
  DateTime get forDateLocal => throw _privateConstructorUsedError;
  DateTime? get viewedAt => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DiscoveryProfile get profile => throw _privateConstructorUsedError;

  /// Create a copy of DailyMatch
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DailyMatchCopyWith<DailyMatch> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DailyMatchCopyWith<$Res> {
  factory $DailyMatchCopyWith(
          DailyMatch value, $Res Function(DailyMatch) then) =
      _$DailyMatchCopyWithImpl<$Res, DailyMatch>;
  @useResult
  $Res call(
      {String id,
      String pickUserId,
      String matchReason,
      DateTime forDateLocal,
      DateTime? viewedAt,
      DateTime createdAt,
      DiscoveryProfile profile});

  $DiscoveryProfileCopyWith<$Res> get profile;
}

/// @nodoc
class _$DailyMatchCopyWithImpl<$Res, $Val extends DailyMatch>
    implements $DailyMatchCopyWith<$Res> {
  _$DailyMatchCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DailyMatch
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? pickUserId = null,
    Object? matchReason = null,
    Object? forDateLocal = null,
    Object? viewedAt = freezed,
    Object? createdAt = null,
    Object? profile = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      pickUserId: null == pickUserId
          ? _value.pickUserId
          : pickUserId // ignore: cast_nullable_to_non_nullable
              as String,
      matchReason: null == matchReason
          ? _value.matchReason
          : matchReason // ignore: cast_nullable_to_non_nullable
              as String,
      forDateLocal: null == forDateLocal
          ? _value.forDateLocal
          : forDateLocal // ignore: cast_nullable_to_non_nullable
              as DateTime,
      viewedAt: freezed == viewedAt
          ? _value.viewedAt
          : viewedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      profile: null == profile
          ? _value.profile
          : profile // ignore: cast_nullable_to_non_nullable
              as DiscoveryProfile,
    ) as $Val);
  }

  /// Create a copy of DailyMatch
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $DiscoveryProfileCopyWith<$Res> get profile {
    return $DiscoveryProfileCopyWith<$Res>(_value.profile, (value) {
      return _then(_value.copyWith(profile: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$DailyMatchImplCopyWith<$Res>
    implements $DailyMatchCopyWith<$Res> {
  factory _$$DailyMatchImplCopyWith(
          _$DailyMatchImpl value, $Res Function(_$DailyMatchImpl) then) =
      __$$DailyMatchImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String pickUserId,
      String matchReason,
      DateTime forDateLocal,
      DateTime? viewedAt,
      DateTime createdAt,
      DiscoveryProfile profile});

  @override
  $DiscoveryProfileCopyWith<$Res> get profile;
}

/// @nodoc
class __$$DailyMatchImplCopyWithImpl<$Res>
    extends _$DailyMatchCopyWithImpl<$Res, _$DailyMatchImpl>
    implements _$$DailyMatchImplCopyWith<$Res> {
  __$$DailyMatchImplCopyWithImpl(
      _$DailyMatchImpl _value, $Res Function(_$DailyMatchImpl) _then)
      : super(_value, _then);

  /// Create a copy of DailyMatch
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? pickUserId = null,
    Object? matchReason = null,
    Object? forDateLocal = null,
    Object? viewedAt = freezed,
    Object? createdAt = null,
    Object? profile = null,
  }) {
    return _then(_$DailyMatchImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      pickUserId: null == pickUserId
          ? _value.pickUserId
          : pickUserId // ignore: cast_nullable_to_non_nullable
              as String,
      matchReason: null == matchReason
          ? _value.matchReason
          : matchReason // ignore: cast_nullable_to_non_nullable
              as String,
      forDateLocal: null == forDateLocal
          ? _value.forDateLocal
          : forDateLocal // ignore: cast_nullable_to_non_nullable
              as DateTime,
      viewedAt: freezed == viewedAt
          ? _value.viewedAt
          : viewedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      profile: null == profile
          ? _value.profile
          : profile // ignore: cast_nullable_to_non_nullable
              as DiscoveryProfile,
    ));
  }
}

/// @nodoc

class _$DailyMatchImpl implements _DailyMatch {
  const _$DailyMatchImpl(
      {required this.id,
      required this.pickUserId,
      required this.matchReason,
      required this.forDateLocal,
      this.viewedAt,
      required this.createdAt,
      required this.profile});

  @override
  final String id;
  @override
  final String pickUserId;
  @override
  final String matchReason;
  @override
  final DateTime forDateLocal;
  @override
  final DateTime? viewedAt;
  @override
  final DateTime createdAt;
  @override
  final DiscoveryProfile profile;

  @override
  String toString() {
    return 'DailyMatch(id: $id, pickUserId: $pickUserId, matchReason: $matchReason, forDateLocal: $forDateLocal, viewedAt: $viewedAt, createdAt: $createdAt, profile: $profile)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DailyMatchImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.pickUserId, pickUserId) ||
                other.pickUserId == pickUserId) &&
            (identical(other.matchReason, matchReason) ||
                other.matchReason == matchReason) &&
            (identical(other.forDateLocal, forDateLocal) ||
                other.forDateLocal == forDateLocal) &&
            (identical(other.viewedAt, viewedAt) ||
                other.viewedAt == viewedAt) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.profile, profile) || other.profile == profile));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id, pickUserId, matchReason,
      forDateLocal, viewedAt, createdAt, profile);

  /// Create a copy of DailyMatch
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DailyMatchImplCopyWith<_$DailyMatchImpl> get copyWith =>
      __$$DailyMatchImplCopyWithImpl<_$DailyMatchImpl>(this, _$identity);
}

abstract class _DailyMatch implements DailyMatch {
  const factory _DailyMatch(
      {required final String id,
      required final String pickUserId,
      required final String matchReason,
      required final DateTime forDateLocal,
      final DateTime? viewedAt,
      required final DateTime createdAt,
      required final DiscoveryProfile profile}) = _$DailyMatchImpl;

  @override
  String get id;
  @override
  String get pickUserId;
  @override
  String get matchReason;
  @override
  DateTime get forDateLocal;
  @override
  DateTime? get viewedAt;
  @override
  DateTime get createdAt;
  @override
  DiscoveryProfile get profile;

  /// Create a copy of DailyMatch
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DailyMatchImplCopyWith<_$DailyMatchImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
