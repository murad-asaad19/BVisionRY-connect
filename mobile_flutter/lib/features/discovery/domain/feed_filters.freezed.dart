// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'feed_filters.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

FeedFilters _$FeedFiltersFromJson(Map<String, dynamic> json) {
  return _FeedFilters.fromJson(json);
}

/// @nodoc
mixin _$FeedFilters {
  String get query => throw _privateConstructorUsedError;
  List<String> get roles => throw _privateConstructorUsedError;
  List<String> get goalTypes => throw _privateConstructorUsedError;
  String? get country => throw _privateConstructorUsedError;

  /// Serializes this FeedFilters to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of FeedFilters
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FeedFiltersCopyWith<FeedFilters> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FeedFiltersCopyWith<$Res> {
  factory $FeedFiltersCopyWith(
          FeedFilters value, $Res Function(FeedFilters) then) =
      _$FeedFiltersCopyWithImpl<$Res, FeedFilters>;
  @useResult
  $Res call(
      {String query,
      List<String> roles,
      List<String> goalTypes,
      String? country});
}

/// @nodoc
class _$FeedFiltersCopyWithImpl<$Res, $Val extends FeedFilters>
    implements $FeedFiltersCopyWith<$Res> {
  _$FeedFiltersCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FeedFilters
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? query = null,
    Object? roles = null,
    Object? goalTypes = null,
    Object? country = freezed,
  }) {
    return _then(_value.copyWith(
      query: null == query
          ? _value.query
          : query // ignore: cast_nullable_to_non_nullable
              as String,
      roles: null == roles
          ? _value.roles
          : roles // ignore: cast_nullable_to_non_nullable
              as List<String>,
      goalTypes: null == goalTypes
          ? _value.goalTypes
          : goalTypes // ignore: cast_nullable_to_non_nullable
              as List<String>,
      country: freezed == country
          ? _value.country
          : country // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$FeedFiltersImplCopyWith<$Res>
    implements $FeedFiltersCopyWith<$Res> {
  factory _$$FeedFiltersImplCopyWith(
          _$FeedFiltersImpl value, $Res Function(_$FeedFiltersImpl) then) =
      __$$FeedFiltersImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String query,
      List<String> roles,
      List<String> goalTypes,
      String? country});
}

/// @nodoc
class __$$FeedFiltersImplCopyWithImpl<$Res>
    extends _$FeedFiltersCopyWithImpl<$Res, _$FeedFiltersImpl>
    implements _$$FeedFiltersImplCopyWith<$Res> {
  __$$FeedFiltersImplCopyWithImpl(
      _$FeedFiltersImpl _value, $Res Function(_$FeedFiltersImpl) _then)
      : super(_value, _then);

  /// Create a copy of FeedFilters
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? query = null,
    Object? roles = null,
    Object? goalTypes = null,
    Object? country = freezed,
  }) {
    return _then(_$FeedFiltersImpl(
      query: null == query
          ? _value.query
          : query // ignore: cast_nullable_to_non_nullable
              as String,
      roles: null == roles
          ? _value._roles
          : roles // ignore: cast_nullable_to_non_nullable
              as List<String>,
      goalTypes: null == goalTypes
          ? _value._goalTypes
          : goalTypes // ignore: cast_nullable_to_non_nullable
              as List<String>,
      country: freezed == country
          ? _value.country
          : country // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$FeedFiltersImpl extends _FeedFilters {
  const _$FeedFiltersImpl(
      {this.query = '',
      final List<String> roles = const <String>[],
      final List<String> goalTypes = const <String>[],
      this.country})
      : _roles = roles,
        _goalTypes = goalTypes,
        super._();

  factory _$FeedFiltersImpl.fromJson(Map<String, dynamic> json) =>
      _$$FeedFiltersImplFromJson(json);

  @override
  @JsonKey()
  final String query;
  final List<String> _roles;
  @override
  @JsonKey()
  List<String> get roles {
    if (_roles is EqualUnmodifiableListView) return _roles;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_roles);
  }

  final List<String> _goalTypes;
  @override
  @JsonKey()
  List<String> get goalTypes {
    if (_goalTypes is EqualUnmodifiableListView) return _goalTypes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_goalTypes);
  }

  @override
  final String? country;

  @override
  String toString() {
    return 'FeedFilters(query: $query, roles: $roles, goalTypes: $goalTypes, country: $country)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FeedFiltersImpl &&
            (identical(other.query, query) || other.query == query) &&
            const DeepCollectionEquality().equals(other._roles, _roles) &&
            const DeepCollectionEquality()
                .equals(other._goalTypes, _goalTypes) &&
            (identical(other.country, country) || other.country == country));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      query,
      const DeepCollectionEquality().hash(_roles),
      const DeepCollectionEquality().hash(_goalTypes),
      country);

  /// Create a copy of FeedFilters
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FeedFiltersImplCopyWith<_$FeedFiltersImpl> get copyWith =>
      __$$FeedFiltersImplCopyWithImpl<_$FeedFiltersImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FeedFiltersImplToJson(
      this,
    );
  }
}

abstract class _FeedFilters extends FeedFilters {
  const factory _FeedFilters(
      {final String query,
      final List<String> roles,
      final List<String> goalTypes,
      final String? country}) = _$FeedFiltersImpl;
  const _FeedFilters._() : super._();

  factory _FeedFilters.fromJson(Map<String, dynamic> json) =
      _$FeedFiltersImpl.fromJson;

  @override
  String get query;
  @override
  List<String> get roles;
  @override
  List<String> get goalTypes;
  @override
  String? get country;

  /// Create a copy of FeedFilters
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FeedFiltersImplCopyWith<_$FeedFiltersImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
