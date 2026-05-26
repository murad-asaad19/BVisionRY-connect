// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'blocked_user.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

BlockedUser _$BlockedUserFromJson(Map<String, dynamic> json) {
  return _BlockedUser.fromJson(json);
}

/// @nodoc
mixin _$BlockedUser {
  @JsonKey(name: 'blocked_id')
  String get blockedId => throw _privateConstructorUsedError;
  String get handle => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  @JsonKey(name: 'photo_url')
  String? get photoUrl => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at', fromJson: _utcFromJson, toJson: _utcToJson)
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Serializes this BlockedUser to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of BlockedUser
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BlockedUserCopyWith<BlockedUser> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BlockedUserCopyWith<$Res> {
  factory $BlockedUserCopyWith(
          BlockedUser value, $Res Function(BlockedUser) then) =
      _$BlockedUserCopyWithImpl<$Res, BlockedUser>;
  @useResult
  $Res call(
      {@JsonKey(name: 'blocked_id') String blockedId,
      String handle,
      String name,
      @JsonKey(name: 'photo_url') String? photoUrl,
      @JsonKey(name: 'created_at', fromJson: _utcFromJson, toJson: _utcToJson)
      DateTime createdAt});
}

/// @nodoc
class _$BlockedUserCopyWithImpl<$Res, $Val extends BlockedUser>
    implements $BlockedUserCopyWith<$Res> {
  _$BlockedUserCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BlockedUser
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? blockedId = null,
    Object? handle = null,
    Object? name = null,
    Object? photoUrl = freezed,
    Object? createdAt = null,
  }) {
    return _then(_value.copyWith(
      blockedId: null == blockedId
          ? _value.blockedId
          : blockedId // ignore: cast_nullable_to_non_nullable
              as String,
      handle: null == handle
          ? _value.handle
          : handle // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      photoUrl: freezed == photoUrl
          ? _value.photoUrl
          : photoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$BlockedUserImplCopyWith<$Res>
    implements $BlockedUserCopyWith<$Res> {
  factory _$$BlockedUserImplCopyWith(
          _$BlockedUserImpl value, $Res Function(_$BlockedUserImpl) then) =
      __$$BlockedUserImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'blocked_id') String blockedId,
      String handle,
      String name,
      @JsonKey(name: 'photo_url') String? photoUrl,
      @JsonKey(name: 'created_at', fromJson: _utcFromJson, toJson: _utcToJson)
      DateTime createdAt});
}

/// @nodoc
class __$$BlockedUserImplCopyWithImpl<$Res>
    extends _$BlockedUserCopyWithImpl<$Res, _$BlockedUserImpl>
    implements _$$BlockedUserImplCopyWith<$Res> {
  __$$BlockedUserImplCopyWithImpl(
      _$BlockedUserImpl _value, $Res Function(_$BlockedUserImpl) _then)
      : super(_value, _then);

  /// Create a copy of BlockedUser
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? blockedId = null,
    Object? handle = null,
    Object? name = null,
    Object? photoUrl = freezed,
    Object? createdAt = null,
  }) {
    return _then(_$BlockedUserImpl(
      blockedId: null == blockedId
          ? _value.blockedId
          : blockedId // ignore: cast_nullable_to_non_nullable
              as String,
      handle: null == handle
          ? _value.handle
          : handle // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      photoUrl: freezed == photoUrl
          ? _value.photoUrl
          : photoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$BlockedUserImpl implements _BlockedUser {
  const _$BlockedUserImpl(
      {@JsonKey(name: 'blocked_id') required this.blockedId,
      required this.handle,
      required this.name,
      @JsonKey(name: 'photo_url') this.photoUrl,
      @JsonKey(name: 'created_at', fromJson: _utcFromJson, toJson: _utcToJson)
      required this.createdAt});

  factory _$BlockedUserImpl.fromJson(Map<String, dynamic> json) =>
      _$$BlockedUserImplFromJson(json);

  @override
  @JsonKey(name: 'blocked_id')
  final String blockedId;
  @override
  final String handle;
  @override
  final String name;
  @override
  @JsonKey(name: 'photo_url')
  final String? photoUrl;
  @override
  @JsonKey(name: 'created_at', fromJson: _utcFromJson, toJson: _utcToJson)
  final DateTime createdAt;

  @override
  String toString() {
    return 'BlockedUser(blockedId: $blockedId, handle: $handle, name: $name, photoUrl: $photoUrl, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BlockedUserImpl &&
            (identical(other.blockedId, blockedId) ||
                other.blockedId == blockedId) &&
            (identical(other.handle, handle) || other.handle == handle) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.photoUrl, photoUrl) ||
                other.photoUrl == photoUrl) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, blockedId, handle, name, photoUrl, createdAt);

  /// Create a copy of BlockedUser
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BlockedUserImplCopyWith<_$BlockedUserImpl> get copyWith =>
      __$$BlockedUserImplCopyWithImpl<_$BlockedUserImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$BlockedUserImplToJson(
      this,
    );
  }
}

abstract class _BlockedUser implements BlockedUser {
  const factory _BlockedUser(
      {@JsonKey(name: 'blocked_id') required final String blockedId,
      required final String handle,
      required final String name,
      @JsonKey(name: 'photo_url') final String? photoUrl,
      @JsonKey(name: 'created_at', fromJson: _utcFromJson, toJson: _utcToJson)
      required final DateTime createdAt}) = _$BlockedUserImpl;

  factory _BlockedUser.fromJson(Map<String, dynamic> json) =
      _$BlockedUserImpl.fromJson;

  @override
  @JsonKey(name: 'blocked_id')
  String get blockedId;
  @override
  String get handle;
  @override
  String get name;
  @override
  @JsonKey(name: 'photo_url')
  String? get photoUrl;
  @override
  @JsonKey(name: 'created_at', fromJson: _utcFromJson, toJson: _utcToJson)
  DateTime get createdAt;

  /// Create a copy of BlockedUser
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BlockedUserImplCopyWith<_$BlockedUserImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
