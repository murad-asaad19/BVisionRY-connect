// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'onboarding_draft.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

OnboardingDraft _$OnboardingDraftFromJson(Map<String, dynamic> json) {
  return _OnboardingDraft.fromJson(json);
}

/// @nodoc
mixin _$OnboardingDraft {
  @JsonKey(name: 'goal_text')
  String get goalText => throw _privateConstructorUsedError;
  @JsonKey(name: 'goal_type')
  @GoalTypeConverter()
  GoalType? get goalType => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get handle => throw _privateConstructorUsedError;
  List<String> get roles => throw _privateConstructorUsedError;
  @JsonKey(name: 'primary_role')
  String? get primaryRole => throw _privateConstructorUsedError;
  String get city => throw _privateConstructorUsedError;
  String get country => throw _privateConstructorUsedError;
  String? get headline => throw _privateConstructorUsedError;
  String? get bio => throw _privateConstructorUsedError;

  /// Serializes this OnboardingDraft to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of OnboardingDraft
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $OnboardingDraftCopyWith<OnboardingDraft> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OnboardingDraftCopyWith<$Res> {
  factory $OnboardingDraftCopyWith(
          OnboardingDraft value, $Res Function(OnboardingDraft) then) =
      _$OnboardingDraftCopyWithImpl<$Res, OnboardingDraft>;
  @useResult
  $Res call(
      {@JsonKey(name: 'goal_text') String goalText,
      @JsonKey(name: 'goal_type') @GoalTypeConverter() GoalType? goalType,
      String name,
      String handle,
      List<String> roles,
      @JsonKey(name: 'primary_role') String? primaryRole,
      String city,
      String country,
      String? headline,
      String? bio});
}

/// @nodoc
class _$OnboardingDraftCopyWithImpl<$Res, $Val extends OnboardingDraft>
    implements $OnboardingDraftCopyWith<$Res> {
  _$OnboardingDraftCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of OnboardingDraft
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? goalText = null,
    Object? goalType = freezed,
    Object? name = null,
    Object? handle = null,
    Object? roles = null,
    Object? primaryRole = freezed,
    Object? city = null,
    Object? country = null,
    Object? headline = freezed,
    Object? bio = freezed,
  }) {
    return _then(_value.copyWith(
      goalText: null == goalText
          ? _value.goalText
          : goalText // ignore: cast_nullable_to_non_nullable
              as String,
      goalType: freezed == goalType
          ? _value.goalType
          : goalType // ignore: cast_nullable_to_non_nullable
              as GoalType?,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      handle: null == handle
          ? _value.handle
          : handle // ignore: cast_nullable_to_non_nullable
              as String,
      roles: null == roles
          ? _value.roles
          : roles // ignore: cast_nullable_to_non_nullable
              as List<String>,
      primaryRole: freezed == primaryRole
          ? _value.primaryRole
          : primaryRole // ignore: cast_nullable_to_non_nullable
              as String?,
      city: null == city
          ? _value.city
          : city // ignore: cast_nullable_to_non_nullable
              as String,
      country: null == country
          ? _value.country
          : country // ignore: cast_nullable_to_non_nullable
              as String,
      headline: freezed == headline
          ? _value.headline
          : headline // ignore: cast_nullable_to_non_nullable
              as String?,
      bio: freezed == bio
          ? _value.bio
          : bio // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$OnboardingDraftImplCopyWith<$Res>
    implements $OnboardingDraftCopyWith<$Res> {
  factory _$$OnboardingDraftImplCopyWith(_$OnboardingDraftImpl value,
          $Res Function(_$OnboardingDraftImpl) then) =
      __$$OnboardingDraftImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'goal_text') String goalText,
      @JsonKey(name: 'goal_type') @GoalTypeConverter() GoalType? goalType,
      String name,
      String handle,
      List<String> roles,
      @JsonKey(name: 'primary_role') String? primaryRole,
      String city,
      String country,
      String? headline,
      String? bio});
}

/// @nodoc
class __$$OnboardingDraftImplCopyWithImpl<$Res>
    extends _$OnboardingDraftCopyWithImpl<$Res, _$OnboardingDraftImpl>
    implements _$$OnboardingDraftImplCopyWith<$Res> {
  __$$OnboardingDraftImplCopyWithImpl(
      _$OnboardingDraftImpl _value, $Res Function(_$OnboardingDraftImpl) _then)
      : super(_value, _then);

  /// Create a copy of OnboardingDraft
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? goalText = null,
    Object? goalType = freezed,
    Object? name = null,
    Object? handle = null,
    Object? roles = null,
    Object? primaryRole = freezed,
    Object? city = null,
    Object? country = null,
    Object? headline = freezed,
    Object? bio = freezed,
  }) {
    return _then(_$OnboardingDraftImpl(
      goalText: null == goalText
          ? _value.goalText
          : goalText // ignore: cast_nullable_to_non_nullable
              as String,
      goalType: freezed == goalType
          ? _value.goalType
          : goalType // ignore: cast_nullable_to_non_nullable
              as GoalType?,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      handle: null == handle
          ? _value.handle
          : handle // ignore: cast_nullable_to_non_nullable
              as String,
      roles: null == roles
          ? _value._roles
          : roles // ignore: cast_nullable_to_non_nullable
              as List<String>,
      primaryRole: freezed == primaryRole
          ? _value.primaryRole
          : primaryRole // ignore: cast_nullable_to_non_nullable
              as String?,
      city: null == city
          ? _value.city
          : city // ignore: cast_nullable_to_non_nullable
              as String,
      country: null == country
          ? _value.country
          : country // ignore: cast_nullable_to_non_nullable
              as String,
      headline: freezed == headline
          ? _value.headline
          : headline // ignore: cast_nullable_to_non_nullable
              as String?,
      bio: freezed == bio
          ? _value.bio
          : bio // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$OnboardingDraftImpl implements _OnboardingDraft {
  const _$OnboardingDraftImpl(
      {@JsonKey(name: 'goal_text') this.goalText = '',
      @JsonKey(name: 'goal_type') @GoalTypeConverter() this.goalType,
      this.name = '',
      this.handle = '',
      final List<String> roles = const <String>[],
      @JsonKey(name: 'primary_role') this.primaryRole,
      this.city = '',
      this.country = '',
      this.headline,
      this.bio})
      : _roles = roles;

  factory _$OnboardingDraftImpl.fromJson(Map<String, dynamic> json) =>
      _$$OnboardingDraftImplFromJson(json);

  @override
  @JsonKey(name: 'goal_text')
  final String goalText;
  @override
  @JsonKey(name: 'goal_type')
  @GoalTypeConverter()
  final GoalType? goalType;
  @override
  @JsonKey()
  final String name;
  @override
  @JsonKey()
  final String handle;
  final List<String> _roles;
  @override
  @JsonKey()
  List<String> get roles {
    if (_roles is EqualUnmodifiableListView) return _roles;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_roles);
  }

  @override
  @JsonKey(name: 'primary_role')
  final String? primaryRole;
  @override
  @JsonKey()
  final String city;
  @override
  @JsonKey()
  final String country;
  @override
  final String? headline;
  @override
  final String? bio;

  @override
  String toString() {
    return 'OnboardingDraft(goalText: $goalText, goalType: $goalType, name: $name, handle: $handle, roles: $roles, primaryRole: $primaryRole, city: $city, country: $country, headline: $headline, bio: $bio)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OnboardingDraftImpl &&
            (identical(other.goalText, goalText) ||
                other.goalText == goalText) &&
            (identical(other.goalType, goalType) ||
                other.goalType == goalType) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.handle, handle) || other.handle == handle) &&
            const DeepCollectionEquality().equals(other._roles, _roles) &&
            (identical(other.primaryRole, primaryRole) ||
                other.primaryRole == primaryRole) &&
            (identical(other.city, city) || other.city == city) &&
            (identical(other.country, country) || other.country == country) &&
            (identical(other.headline, headline) ||
                other.headline == headline) &&
            (identical(other.bio, bio) || other.bio == bio));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      goalText,
      goalType,
      name,
      handle,
      const DeepCollectionEquality().hash(_roles),
      primaryRole,
      city,
      country,
      headline,
      bio);

  /// Create a copy of OnboardingDraft
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OnboardingDraftImplCopyWith<_$OnboardingDraftImpl> get copyWith =>
      __$$OnboardingDraftImplCopyWithImpl<_$OnboardingDraftImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$OnboardingDraftImplToJson(
      this,
    );
  }
}

abstract class _OnboardingDraft implements OnboardingDraft {
  const factory _OnboardingDraft(
      {@JsonKey(name: 'goal_text') final String goalText,
      @JsonKey(name: 'goal_type') @GoalTypeConverter() final GoalType? goalType,
      final String name,
      final String handle,
      final List<String> roles,
      @JsonKey(name: 'primary_role') final String? primaryRole,
      final String city,
      final String country,
      final String? headline,
      final String? bio}) = _$OnboardingDraftImpl;

  factory _OnboardingDraft.fromJson(Map<String, dynamic> json) =
      _$OnboardingDraftImpl.fromJson;

  @override
  @JsonKey(name: 'goal_text')
  String get goalText;
  @override
  @JsonKey(name: 'goal_type')
  @GoalTypeConverter()
  GoalType? get goalType;
  @override
  String get name;
  @override
  String get handle;
  @override
  List<String> get roles;
  @override
  @JsonKey(name: 'primary_role')
  String? get primaryRole;
  @override
  String get city;
  @override
  String get country;
  @override
  String? get headline;
  @override
  String? get bio;

  /// Create a copy of OnboardingDraft
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OnboardingDraftImplCopyWith<_$OnboardingDraftImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
