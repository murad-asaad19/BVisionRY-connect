// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'public_profile_service.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

PublicProfile _$PublicProfileFromJson(Map<String, dynamic> json) {
  return _PublicProfile.fromJson(json);
}

/// @nodoc
mixin _$PublicProfile {
  String get id => throw _privateConstructorUsedError;
  String get handle => throw _privateConstructorUsedError;
  String? get name => throw _privateConstructorUsedError;
  @JsonKey(name: 'photo_url')
  String? get photoUrl => throw _privateConstructorUsedError;
  String? get headline => throw _privateConstructorUsedError;
  String? get bio => throw _privateConstructorUsedError;
  @JsonKey(name: 'primary_role')
  String? get primaryRole => throw _privateConstructorUsedError;
  List<String> get roles => throw _privateConstructorUsedError;
  String? get city => throw _privateConstructorUsedError;
  String? get country => throw _privateConstructorUsedError;
  @JsonKey(name: 'verified_github_username')
  String? get verifiedGithubUsername => throw _privateConstructorUsedError;

  /// Serializes this PublicProfile to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PublicProfile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PublicProfileCopyWith<PublicProfile> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PublicProfileCopyWith<$Res> {
  factory $PublicProfileCopyWith(
          PublicProfile value, $Res Function(PublicProfile) then) =
      _$PublicProfileCopyWithImpl<$Res, PublicProfile>;
  @useResult
  $Res call(
      {String id,
      String handle,
      String? name,
      @JsonKey(name: 'photo_url') String? photoUrl,
      String? headline,
      String? bio,
      @JsonKey(name: 'primary_role') String? primaryRole,
      List<String> roles,
      String? city,
      String? country,
      @JsonKey(name: 'verified_github_username')
      String? verifiedGithubUsername});
}

/// @nodoc
class _$PublicProfileCopyWithImpl<$Res, $Val extends PublicProfile>
    implements $PublicProfileCopyWith<$Res> {
  _$PublicProfileCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PublicProfile
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
    Object? primaryRole = freezed,
    Object? roles = null,
    Object? city = freezed,
    Object? country = freezed,
    Object? verifiedGithubUsername = freezed,
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
      primaryRole: freezed == primaryRole
          ? _value.primaryRole
          : primaryRole // ignore: cast_nullable_to_non_nullable
              as String?,
      roles: null == roles
          ? _value.roles
          : roles // ignore: cast_nullable_to_non_nullable
              as List<String>,
      city: freezed == city
          ? _value.city
          : city // ignore: cast_nullable_to_non_nullable
              as String?,
      country: freezed == country
          ? _value.country
          : country // ignore: cast_nullable_to_non_nullable
              as String?,
      verifiedGithubUsername: freezed == verifiedGithubUsername
          ? _value.verifiedGithubUsername
          : verifiedGithubUsername // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PublicProfileImplCopyWith<$Res>
    implements $PublicProfileCopyWith<$Res> {
  factory _$$PublicProfileImplCopyWith(
          _$PublicProfileImpl value, $Res Function(_$PublicProfileImpl) then) =
      __$$PublicProfileImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String handle,
      String? name,
      @JsonKey(name: 'photo_url') String? photoUrl,
      String? headline,
      String? bio,
      @JsonKey(name: 'primary_role') String? primaryRole,
      List<String> roles,
      String? city,
      String? country,
      @JsonKey(name: 'verified_github_username')
      String? verifiedGithubUsername});
}

/// @nodoc
class __$$PublicProfileImplCopyWithImpl<$Res>
    extends _$PublicProfileCopyWithImpl<$Res, _$PublicProfileImpl>
    implements _$$PublicProfileImplCopyWith<$Res> {
  __$$PublicProfileImplCopyWithImpl(
      _$PublicProfileImpl _value, $Res Function(_$PublicProfileImpl) _then)
      : super(_value, _then);

  /// Create a copy of PublicProfile
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
    Object? primaryRole = freezed,
    Object? roles = null,
    Object? city = freezed,
    Object? country = freezed,
    Object? verifiedGithubUsername = freezed,
  }) {
    return _then(_$PublicProfileImpl(
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
      primaryRole: freezed == primaryRole
          ? _value.primaryRole
          : primaryRole // ignore: cast_nullable_to_non_nullable
              as String?,
      roles: null == roles
          ? _value._roles
          : roles // ignore: cast_nullable_to_non_nullable
              as List<String>,
      city: freezed == city
          ? _value.city
          : city // ignore: cast_nullable_to_non_nullable
              as String?,
      country: freezed == country
          ? _value.country
          : country // ignore: cast_nullable_to_non_nullable
              as String?,
      verifiedGithubUsername: freezed == verifiedGithubUsername
          ? _value.verifiedGithubUsername
          : verifiedGithubUsername // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PublicProfileImpl implements _PublicProfile {
  const _$PublicProfileImpl(
      {required this.id,
      required this.handle,
      this.name,
      @JsonKey(name: 'photo_url') this.photoUrl,
      this.headline,
      this.bio,
      @JsonKey(name: 'primary_role') this.primaryRole,
      final List<String> roles = const <String>[],
      this.city,
      this.country,
      @JsonKey(name: 'verified_github_username') this.verifiedGithubUsername})
      : _roles = roles;

  factory _$PublicProfileImpl.fromJson(Map<String, dynamic> json) =>
      _$$PublicProfileImplFromJson(json);

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
  final String? city;
  @override
  final String? country;
  @override
  @JsonKey(name: 'verified_github_username')
  final String? verifiedGithubUsername;

  @override
  String toString() {
    return 'PublicProfile(id: $id, handle: $handle, name: $name, photoUrl: $photoUrl, headline: $headline, bio: $bio, primaryRole: $primaryRole, roles: $roles, city: $city, country: $country, verifiedGithubUsername: $verifiedGithubUsername)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PublicProfileImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.handle, handle) || other.handle == handle) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.photoUrl, photoUrl) ||
                other.photoUrl == photoUrl) &&
            (identical(other.headline, headline) ||
                other.headline == headline) &&
            (identical(other.bio, bio) || other.bio == bio) &&
            (identical(other.primaryRole, primaryRole) ||
                other.primaryRole == primaryRole) &&
            const DeepCollectionEquality().equals(other._roles, _roles) &&
            (identical(other.city, city) || other.city == city) &&
            (identical(other.country, country) || other.country == country) &&
            (identical(other.verifiedGithubUsername, verifiedGithubUsername) ||
                other.verifiedGithubUsername == verifiedGithubUsername));
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
      primaryRole,
      const DeepCollectionEquality().hash(_roles),
      city,
      country,
      verifiedGithubUsername);

  /// Create a copy of PublicProfile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PublicProfileImplCopyWith<_$PublicProfileImpl> get copyWith =>
      __$$PublicProfileImplCopyWithImpl<_$PublicProfileImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PublicProfileImplToJson(
      this,
    );
  }
}

abstract class _PublicProfile implements PublicProfile {
  const factory _PublicProfile(
      {required final String id,
      required final String handle,
      final String? name,
      @JsonKey(name: 'photo_url') final String? photoUrl,
      final String? headline,
      final String? bio,
      @JsonKey(name: 'primary_role') final String? primaryRole,
      final List<String> roles,
      final String? city,
      final String? country,
      @JsonKey(name: 'verified_github_username')
      final String? verifiedGithubUsername}) = _$PublicProfileImpl;

  factory _PublicProfile.fromJson(Map<String, dynamic> json) =
      _$PublicProfileImpl.fromJson;

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
  @JsonKey(name: 'primary_role')
  String? get primaryRole;
  @override
  List<String> get roles;
  @override
  String? get city;
  @override
  String? get country;
  @override
  @JsonKey(name: 'verified_github_username')
  String? get verifiedGithubUsername;

  /// Create a copy of PublicProfile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PublicProfileImplCopyWith<_$PublicProfileImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
