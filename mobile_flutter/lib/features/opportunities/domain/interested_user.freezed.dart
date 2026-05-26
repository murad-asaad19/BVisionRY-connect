// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'interested_user.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

InterestedUser _$InterestedUserFromJson(Map<String, dynamic> json) {
  return _InterestedUser.fromJson(json);
}

/// @nodoc
mixin _$InterestedUser {
  @JsonKey(name: 'user_id')
  String get userId => throw _privateConstructorUsedError;
  String get handle => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  @JsonKey(name: 'photo_url')
  String? get photoUrl => throw _privateConstructorUsedError;
  @JsonKey(name: 'primary_role')
  String? get primaryRole => throw _privateConstructorUsedError;
  String? get note => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at', fromJson: _utcFromJson, toJson: _utcToJson)
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Serializes this InterestedUser to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of InterestedUser
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $InterestedUserCopyWith<InterestedUser> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $InterestedUserCopyWith<$Res> {
  factory $InterestedUserCopyWith(
          InterestedUser value, $Res Function(InterestedUser) then) =
      _$InterestedUserCopyWithImpl<$Res, InterestedUser>;
  @useResult
  $Res call(
      {@JsonKey(name: 'user_id') String userId,
      String handle,
      String name,
      @JsonKey(name: 'photo_url') String? photoUrl,
      @JsonKey(name: 'primary_role') String? primaryRole,
      String? note,
      @JsonKey(name: 'created_at', fromJson: _utcFromJson, toJson: _utcToJson)
      DateTime createdAt});
}

/// @nodoc
class _$InterestedUserCopyWithImpl<$Res, $Val extends InterestedUser>
    implements $InterestedUserCopyWith<$Res> {
  _$InterestedUserCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of InterestedUser
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? handle = null,
    Object? name = null,
    Object? photoUrl = freezed,
    Object? primaryRole = freezed,
    Object? note = freezed,
    Object? createdAt = null,
  }) {
    return _then(_value.copyWith(
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
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
      primaryRole: freezed == primaryRole
          ? _value.primaryRole
          : primaryRole // ignore: cast_nullable_to_non_nullable
              as String?,
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
abstract class _$$InterestedUserImplCopyWith<$Res>
    implements $InterestedUserCopyWith<$Res> {
  factory _$$InterestedUserImplCopyWith(_$InterestedUserImpl value,
          $Res Function(_$InterestedUserImpl) then) =
      __$$InterestedUserImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'user_id') String userId,
      String handle,
      String name,
      @JsonKey(name: 'photo_url') String? photoUrl,
      @JsonKey(name: 'primary_role') String? primaryRole,
      String? note,
      @JsonKey(name: 'created_at', fromJson: _utcFromJson, toJson: _utcToJson)
      DateTime createdAt});
}

/// @nodoc
class __$$InterestedUserImplCopyWithImpl<$Res>
    extends _$InterestedUserCopyWithImpl<$Res, _$InterestedUserImpl>
    implements _$$InterestedUserImplCopyWith<$Res> {
  __$$InterestedUserImplCopyWithImpl(
      _$InterestedUserImpl _value, $Res Function(_$InterestedUserImpl) _then)
      : super(_value, _then);

  /// Create a copy of InterestedUser
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? handle = null,
    Object? name = null,
    Object? photoUrl = freezed,
    Object? primaryRole = freezed,
    Object? note = freezed,
    Object? createdAt = null,
  }) {
    return _then(_$InterestedUserImpl(
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
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
      primaryRole: freezed == primaryRole
          ? _value.primaryRole
          : primaryRole // ignore: cast_nullable_to_non_nullable
              as String?,
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
@JsonSerializable()
class _$InterestedUserImpl implements _InterestedUser {
  const _$InterestedUserImpl(
      {@JsonKey(name: 'user_id') required this.userId,
      required this.handle,
      required this.name,
      @JsonKey(name: 'photo_url') this.photoUrl,
      @JsonKey(name: 'primary_role') this.primaryRole,
      this.note,
      @JsonKey(name: 'created_at', fromJson: _utcFromJson, toJson: _utcToJson)
      required this.createdAt});

  factory _$InterestedUserImpl.fromJson(Map<String, dynamic> json) =>
      _$$InterestedUserImplFromJson(json);

  @override
  @JsonKey(name: 'user_id')
  final String userId;
  @override
  final String handle;
  @override
  final String name;
  @override
  @JsonKey(name: 'photo_url')
  final String? photoUrl;
  @override
  @JsonKey(name: 'primary_role')
  final String? primaryRole;
  @override
  final String? note;
  @override
  @JsonKey(name: 'created_at', fromJson: _utcFromJson, toJson: _utcToJson)
  final DateTime createdAt;

  @override
  String toString() {
    return 'InterestedUser(userId: $userId, handle: $handle, name: $name, photoUrl: $photoUrl, primaryRole: $primaryRole, note: $note, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$InterestedUserImpl &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.handle, handle) || other.handle == handle) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.photoUrl, photoUrl) ||
                other.photoUrl == photoUrl) &&
            (identical(other.primaryRole, primaryRole) ||
                other.primaryRole == primaryRole) &&
            (identical(other.note, note) || other.note == note) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, userId, handle, name, photoUrl,
      primaryRole, note, createdAt);

  /// Create a copy of InterestedUser
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$InterestedUserImplCopyWith<_$InterestedUserImpl> get copyWith =>
      __$$InterestedUserImplCopyWithImpl<_$InterestedUserImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$InterestedUserImplToJson(
      this,
    );
  }
}

abstract class _InterestedUser implements InterestedUser {
  const factory _InterestedUser(
      {@JsonKey(name: 'user_id') required final String userId,
      required final String handle,
      required final String name,
      @JsonKey(name: 'photo_url') final String? photoUrl,
      @JsonKey(name: 'primary_role') final String? primaryRole,
      final String? note,
      @JsonKey(name: 'created_at', fromJson: _utcFromJson, toJson: _utcToJson)
      required final DateTime createdAt}) = _$InterestedUserImpl;

  factory _InterestedUser.fromJson(Map<String, dynamic> json) =
      _$InterestedUserImpl.fromJson;

  @override
  @JsonKey(name: 'user_id')
  String get userId;
  @override
  String get handle;
  @override
  String get name;
  @override
  @JsonKey(name: 'photo_url')
  String? get photoUrl;
  @override
  @JsonKey(name: 'primary_role')
  String? get primaryRole;
  @override
  String? get note;
  @override
  @JsonKey(name: 'created_at', fromJson: _utcFromJson, toJson: _utcToJson)
  DateTime get createdAt;

  /// Create a copy of InterestedUser
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$InterestedUserImplCopyWith<_$InterestedUserImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
