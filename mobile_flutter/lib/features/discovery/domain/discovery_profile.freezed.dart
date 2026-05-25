// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'discovery_profile.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

DiscoveryProfile _$DiscoveryProfileFromJson(Map<String, dynamic> json) {
  return _DiscoveryProfile.fromJson(json);
}

/// @nodoc
mixin _$DiscoveryProfile {
  String get id => throw _privateConstructorUsedError;
  String get handle => throw _privateConstructorUsedError;
  String? get name => throw _privateConstructorUsedError;
  @JsonKey(name: 'photo_url')
  String? get photoUrl => throw _privateConstructorUsedError;
  String? get headline => throw _privateConstructorUsedError;
  String? get bio => throw _privateConstructorUsedError;
  String? get city => throw _privateConstructorUsedError;
  String? get country => throw _privateConstructorUsedError;
  @JsonKey(name: 'primary_role')
  String? get primaryRole => throw _privateConstructorUsedError;
  List<String> get roles => throw _privateConstructorUsedError;
  @JsonKey(name: 'goal_type')
  String? get goalType => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime? get createdAt => throw _privateConstructorUsedError;

  /// Serializes this DiscoveryProfile to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of DiscoveryProfile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DiscoveryProfileCopyWith<DiscoveryProfile> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DiscoveryProfileCopyWith<$Res> {
  factory $DiscoveryProfileCopyWith(
          DiscoveryProfile value, $Res Function(DiscoveryProfile) then) =
      _$DiscoveryProfileCopyWithImpl<$Res, DiscoveryProfile>;
  @useResult
  $Res call(
      {String id,
      String handle,
      String? name,
      @JsonKey(name: 'photo_url') String? photoUrl,
      String? headline,
      String? bio,
      String? city,
      String? country,
      @JsonKey(name: 'primary_role') String? primaryRole,
      List<String> roles,
      @JsonKey(name: 'goal_type') String? goalType,
      @JsonKey(name: 'created_at') DateTime? createdAt});
}

/// @nodoc
class _$DiscoveryProfileCopyWithImpl<$Res, $Val extends DiscoveryProfile>
    implements $DiscoveryProfileCopyWith<$Res> {
  _$DiscoveryProfileCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DiscoveryProfile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? handle = null,
    Object? name = freezed,
    Object? photoUrl = freezed,
    Object? headline = freezed,
    Object? bio = freezed,
    Object? city = freezed,
    Object? country = freezed,
    Object? primaryRole = freezed,
    Object? roles = null,
    Object? goalType = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      handle: null == handle
          ? _value.handle
          : handle // ignore: cast_nullable_to_non_nullable
              as String,
      name: freezed == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String?,
      photoUrl: freezed == photoUrl
          ? _value.photoUrl
          : photoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      headline: freezed == headline
          ? _value.headline
          : headline // ignore: cast_nullable_to_non_nullable
              as String?,
      bio: freezed == bio
          ? _value.bio
          : bio // ignore: cast_nullable_to_non_nullable
              as String?,
      city: freezed == city
          ? _value.city
          : city // ignore: cast_nullable_to_non_nullable
              as String?,
      country: freezed == country
          ? _value.country
          : country // ignore: cast_nullable_to_non_nullable
              as String?,
      primaryRole: freezed == primaryRole
          ? _value.primaryRole
          : primaryRole // ignore: cast_nullable_to_non_nullable
              as String?,
      roles: null == roles
          ? _value.roles
          : roles // ignore: cast_nullable_to_non_nullable
              as List<String>,
      goalType: freezed == goalType
          ? _value.goalType
          : goalType // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DiscoveryProfileImplCopyWith<$Res>
    implements $DiscoveryProfileCopyWith<$Res> {
  factory _$$DiscoveryProfileImplCopyWith(_$DiscoveryProfileImpl value,
          $Res Function(_$DiscoveryProfileImpl) then) =
      __$$DiscoveryProfileImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String handle,
      String? name,
      @JsonKey(name: 'photo_url') String? photoUrl,
      String? headline,
      String? bio,
      String? city,
      String? country,
      @JsonKey(name: 'primary_role') String? primaryRole,
      List<String> roles,
      @JsonKey(name: 'goal_type') String? goalType,
      @JsonKey(name: 'created_at') DateTime? createdAt});
}

/// @nodoc
class __$$DiscoveryProfileImplCopyWithImpl<$Res>
    extends _$DiscoveryProfileCopyWithImpl<$Res, _$DiscoveryProfileImpl>
    implements _$$DiscoveryProfileImplCopyWith<$Res> {
  __$$DiscoveryProfileImplCopyWithImpl(_$DiscoveryProfileImpl _value,
      $Res Function(_$DiscoveryProfileImpl) _then)
      : super(_value, _then);

  /// Create a copy of DiscoveryProfile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? handle = null,
    Object? name = freezed,
    Object? photoUrl = freezed,
    Object? headline = freezed,
    Object? bio = freezed,
    Object? city = freezed,
    Object? country = freezed,
    Object? primaryRole = freezed,
    Object? roles = null,
    Object? goalType = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(_$DiscoveryProfileImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      handle: null == handle
          ? _value.handle
          : handle // ignore: cast_nullable_to_non_nullable
              as String,
      name: freezed == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String?,
      photoUrl: freezed == photoUrl
          ? _value.photoUrl
          : photoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      headline: freezed == headline
          ? _value.headline
          : headline // ignore: cast_nullable_to_non_nullable
              as String?,
      bio: freezed == bio
          ? _value.bio
          : bio // ignore: cast_nullable_to_non_nullable
              as String?,
      city: freezed == city
          ? _value.city
          : city // ignore: cast_nullable_to_non_nullable
              as String?,
      country: freezed == country
          ? _value.country
          : country // ignore: cast_nullable_to_non_nullable
              as String?,
      primaryRole: freezed == primaryRole
          ? _value.primaryRole
          : primaryRole // ignore: cast_nullable_to_non_nullable
              as String?,
      roles: null == roles
          ? _value._roles
          : roles // ignore: cast_nullable_to_non_nullable
              as List<String>,
      goalType: freezed == goalType
          ? _value.goalType
          : goalType // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$DiscoveryProfileImpl implements _DiscoveryProfile {
  const _$DiscoveryProfileImpl(
      {required this.id,
      required this.handle,
      this.name,
      @JsonKey(name: 'photo_url') this.photoUrl,
      this.headline,
      this.bio,
      this.city,
      this.country,
      @JsonKey(name: 'primary_role') this.primaryRole,
      final List<String> roles = const <String>[],
      @JsonKey(name: 'goal_type') this.goalType,
      @JsonKey(name: 'created_at') this.createdAt})
      : _roles = roles;

  factory _$DiscoveryProfileImpl.fromJson(Map<String, dynamic> json) =>
      _$$DiscoveryProfileImplFromJson(json);

  @override
  final String id;
  @override
  final String handle;
  @override
  final String? name;
  @override
  @JsonKey(name: 'photo_url')
  final String? photoUrl;
  @override
  final String? headline;
  @override
  final String? bio;
  @override
  final String? city;
  @override
  final String? country;
  @override
  @JsonKey(name: 'primary_role')
  final String? primaryRole;
  final List<String> _roles;
  @override
  @JsonKey()
  List<String> get roles {
    if (_roles is EqualUnmodifiableListView) return _roles;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_roles);
  }

  @override
  @JsonKey(name: 'goal_type')
  final String? goalType;
  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  @override
  String toString() {
    return 'DiscoveryProfile(id: $id, handle: $handle, name: $name, photoUrl: $photoUrl, headline: $headline, bio: $bio, city: $city, country: $country, primaryRole: $primaryRole, roles: $roles, goalType: $goalType, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DiscoveryProfileImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.handle, handle) || other.handle == handle) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.photoUrl, photoUrl) ||
                other.photoUrl == photoUrl) &&
            (identical(other.headline, headline) ||
                other.headline == headline) &&
            (identical(other.bio, bio) || other.bio == bio) &&
            (identical(other.city, city) || other.city == city) &&
            (identical(other.country, country) || other.country == country) &&
            (identical(other.primaryRole, primaryRole) ||
                other.primaryRole == primaryRole) &&
            const DeepCollectionEquality().equals(other._roles, _roles) &&
            (identical(other.goalType, goalType) ||
                other.goalType == goalType) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      handle,
      name,
      photoUrl,
      headline,
      bio,
      city,
      country,
      primaryRole,
      const DeepCollectionEquality().hash(_roles),
      goalType,
      createdAt);

  /// Create a copy of DiscoveryProfile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DiscoveryProfileImplCopyWith<_$DiscoveryProfileImpl> get copyWith =>
      __$$DiscoveryProfileImplCopyWithImpl<_$DiscoveryProfileImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DiscoveryProfileImplToJson(
      this,
    );
  }
}

abstract class _DiscoveryProfile implements DiscoveryProfile {
  const factory _DiscoveryProfile(
          {required final String id,
          required final String handle,
          final String? name,
          @JsonKey(name: 'photo_url') final String? photoUrl,
          final String? headline,
          final String? bio,
          final String? city,
          final String? country,
          @JsonKey(name: 'primary_role') final String? primaryRole,
          final List<String> roles,
          @JsonKey(name: 'goal_type') final String? goalType,
          @JsonKey(name: 'created_at') final DateTime? createdAt}) =
      _$DiscoveryProfileImpl;

  factory _DiscoveryProfile.fromJson(Map<String, dynamic> json) =
      _$DiscoveryProfileImpl.fromJson;

  @override
  String get id;
  @override
  String get handle;
  @override
  String? get name;
  @override
  @JsonKey(name: 'photo_url')
  String? get photoUrl;
  @override
  String? get headline;
  @override
  String? get bio;
  @override
  String? get city;
  @override
  String? get country;
  @override
  @JsonKey(name: 'primary_role')
  String? get primaryRole;
  @override
  List<String> get roles;
  @override
  @JsonKey(name: 'goal_type')
  String? get goalType;
  @override
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;

  /// Create a copy of DiscoveryProfile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DiscoveryProfileImplCopyWith<_$DiscoveryProfileImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
