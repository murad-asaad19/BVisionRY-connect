// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'connection.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Connection _$ConnectionFromJson(Map<String, dynamic> json) {
  return _Connection.fromJson(json);
}

/// @nodoc
mixin _$Connection {
  @JsonKey(name: 'user_id')
  String get userId => throw _privateConstructorUsedError;
  String get handle => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  @JsonKey(name: 'photo_url')
  String? get photoUrl => throw _privateConstructorUsedError;
  @JsonKey(name: 'primary_role')
  String? get primaryRole => throw _privateConstructorUsedError;
  @JsonKey(name: 'conversation_id')
  String get conversationId => throw _privateConstructorUsedError;
  @JsonKey(name: 'connected_at', fromJson: _utcFromJson, toJson: _utcToJson)
  DateTime get connectedAt => throw _privateConstructorUsedError;

  /// Serializes this Connection to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Connection
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ConnectionCopyWith<Connection> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ConnectionCopyWith<$Res> {
  factory $ConnectionCopyWith(
          Connection value, $Res Function(Connection) then) =
      _$ConnectionCopyWithImpl<$Res, Connection>;
  @useResult
  $Res call(
      {@JsonKey(name: 'user_id') String userId,
      String handle,
      String name,
      @JsonKey(name: 'photo_url') String? photoUrl,
      @JsonKey(name: 'primary_role') String? primaryRole,
      @JsonKey(name: 'conversation_id') String conversationId,
      @JsonKey(name: 'connected_at', fromJson: _utcFromJson, toJson: _utcToJson)
      DateTime connectedAt});
}

/// @nodoc
class _$ConnectionCopyWithImpl<$Res, $Val extends Connection>
    implements $ConnectionCopyWith<$Res> {
  _$ConnectionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Connection
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? handle = null,
    Object? name = null,
    Object? photoUrl = freezed,
    Object? primaryRole = freezed,
    Object? conversationId = null,
    Object? connectedAt = null,
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
      conversationId: null == conversationId
          ? _value.conversationId
          : conversationId // ignore: cast_nullable_to_non_nullable
              as String,
      connectedAt: null == connectedAt
          ? _value.connectedAt
          : connectedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ConnectionImplCopyWith<$Res>
    implements $ConnectionCopyWith<$Res> {
  factory _$$ConnectionImplCopyWith(
          _$ConnectionImpl value, $Res Function(_$ConnectionImpl) then) =
      __$$ConnectionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'user_id') String userId,
      String handle,
      String name,
      @JsonKey(name: 'photo_url') String? photoUrl,
      @JsonKey(name: 'primary_role') String? primaryRole,
      @JsonKey(name: 'conversation_id') String conversationId,
      @JsonKey(name: 'connected_at', fromJson: _utcFromJson, toJson: _utcToJson)
      DateTime connectedAt});
}

/// @nodoc
class __$$ConnectionImplCopyWithImpl<$Res>
    extends _$ConnectionCopyWithImpl<$Res, _$ConnectionImpl>
    implements _$$ConnectionImplCopyWith<$Res> {
  __$$ConnectionImplCopyWithImpl(
      _$ConnectionImpl _value, $Res Function(_$ConnectionImpl) _then)
      : super(_value, _then);

  /// Create a copy of Connection
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? handle = null,
    Object? name = null,
    Object? photoUrl = freezed,
    Object? primaryRole = freezed,
    Object? conversationId = null,
    Object? connectedAt = null,
  }) {
    return _then(_$ConnectionImpl(
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
      conversationId: null == conversationId
          ? _value.conversationId
          : conversationId // ignore: cast_nullable_to_non_nullable
              as String,
      connectedAt: null == connectedAt
          ? _value.connectedAt
          : connectedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ConnectionImpl implements _Connection {
  const _$ConnectionImpl(
      {@JsonKey(name: 'user_id') required this.userId,
      required this.handle,
      required this.name,
      @JsonKey(name: 'photo_url') required this.photoUrl,
      @JsonKey(name: 'primary_role') required this.primaryRole,
      @JsonKey(name: 'conversation_id') required this.conversationId,
      @JsonKey(name: 'connected_at', fromJson: _utcFromJson, toJson: _utcToJson)
      required this.connectedAt});

  factory _$ConnectionImpl.fromJson(Map<String, dynamic> json) =>
      _$$ConnectionImplFromJson(json);

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
  @JsonKey(name: 'conversation_id')
  final String conversationId;
  @override
  @JsonKey(name: 'connected_at', fromJson: _utcFromJson, toJson: _utcToJson)
  final DateTime connectedAt;

  @override
  String toString() {
    return 'Connection(userId: $userId, handle: $handle, name: $name, photoUrl: $photoUrl, primaryRole: $primaryRole, conversationId: $conversationId, connectedAt: $connectedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ConnectionImpl &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.handle, handle) || other.handle == handle) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.photoUrl, photoUrl) ||
                other.photoUrl == photoUrl) &&
            (identical(other.primaryRole, primaryRole) ||
                other.primaryRole == primaryRole) &&
            (identical(other.conversationId, conversationId) ||
                other.conversationId == conversationId) &&
            (identical(other.connectedAt, connectedAt) ||
                other.connectedAt == connectedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, userId, handle, name, photoUrl,
      primaryRole, conversationId, connectedAt);

  /// Create a copy of Connection
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ConnectionImplCopyWith<_$ConnectionImpl> get copyWith =>
      __$$ConnectionImplCopyWithImpl<_$ConnectionImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ConnectionImplToJson(
      this,
    );
  }
}

abstract class _Connection implements Connection {
  const factory _Connection(
      {@JsonKey(name: 'user_id') required final String userId,
      required final String handle,
      required final String name,
      @JsonKey(name: 'photo_url') required final String? photoUrl,
      @JsonKey(name: 'primary_role') required final String? primaryRole,
      @JsonKey(name: 'conversation_id') required final String conversationId,
      @JsonKey(name: 'connected_at', fromJson: _utcFromJson, toJson: _utcToJson)
      required final DateTime connectedAt}) = _$ConnectionImpl;

  factory _Connection.fromJson(Map<String, dynamic> json) =
      _$ConnectionImpl.fromJson;

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
  @JsonKey(name: 'conversation_id')
  String get conversationId;
  @override
  @JsonKey(name: 'connected_at', fromJson: _utcFromJson, toJson: _utcToJson)
  DateTime get connectedAt;

  /// Create a copy of Connection
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ConnectionImplCopyWith<_$ConnectionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
