// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'opportunity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Opportunity _$OpportunityFromJson(Map<String, dynamic> json) {
  return _Opportunity.fromJson(json);
}

/// @nodoc
mixin _$Opportunity {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'author_id')
  String get authorId => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _kindFromJson, toJson: _kindToJson)
  OpportunityKind get kind => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get body => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _tagsFromJson)
  List<String> get tags => throw _privateConstructorUsedError;
  @JsonKey(name: 'location_city')
  String? get locationCity => throw _privateConstructorUsedError;
  @JsonKey(name: 'location_country')
  String? get locationCountry => throw _privateConstructorUsedError;
  @JsonKey(name: 'remote_ok')
  bool get remoteOk => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _statusFromJson, toJson: _statusToJson)
  OpportunityStatus get status => throw _privateConstructorUsedError;
  @JsonKey(name: 'expires_at', fromJson: _utcFromJson, toJson: _utcToJson)
  DateTime get expiresAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at', fromJson: _utcFromJson, toJson: _utcToJson)
  DateTime get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_at', fromJson: _utcFromJson, toJson: _utcToJson)
  DateTime get updatedAt => throw _privateConstructorUsedError;
  @JsonKey(
      name: 'closed_at',
      fromJson: _utcFromJsonNullable,
      toJson: _utcToJsonNullable)
  DateTime? get closedAt => throw _privateConstructorUsedError;

  /// Serializes this Opportunity to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Opportunity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $OpportunityCopyWith<Opportunity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OpportunityCopyWith<$Res> {
  factory $OpportunityCopyWith(
          Opportunity value, $Res Function(Opportunity) then) =
      _$OpportunityCopyWithImpl<$Res, Opportunity>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'author_id') String authorId,
      @JsonKey(fromJson: _kindFromJson, toJson: _kindToJson)
      OpportunityKind kind,
      String title,
      String body,
      @JsonKey(fromJson: _tagsFromJson) List<String> tags,
      @JsonKey(name: 'location_city') String? locationCity,
      @JsonKey(name: 'location_country') String? locationCountry,
      @JsonKey(name: 'remote_ok') bool remoteOk,
      @JsonKey(fromJson: _statusFromJson, toJson: _statusToJson)
      OpportunityStatus status,
      @JsonKey(name: 'expires_at', fromJson: _utcFromJson, toJson: _utcToJson)
      DateTime expiresAt,
      @JsonKey(name: 'created_at', fromJson: _utcFromJson, toJson: _utcToJson)
      DateTime createdAt,
      @JsonKey(name: 'updated_at', fromJson: _utcFromJson, toJson: _utcToJson)
      DateTime updatedAt,
      @JsonKey(
          name: 'closed_at',
          fromJson: _utcFromJsonNullable,
          toJson: _utcToJsonNullable)
      DateTime? closedAt});
}

/// @nodoc
class _$OpportunityCopyWithImpl<$Res, $Val extends Opportunity>
    implements $OpportunityCopyWith<$Res> {
  _$OpportunityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Opportunity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? authorId = null,
    Object? kind = null,
    Object? title = null,
    Object? body = null,
    Object? tags = null,
    Object? locationCity = freezed,
    Object? locationCountry = freezed,
    Object? remoteOk = null,
    Object? status = null,
    Object? expiresAt = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? closedAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      authorId: null == authorId
          ? _value.authorId
          : authorId // ignore: cast_nullable_to_non_nullable
              as String,
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as OpportunityKind,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      body: null == body
          ? _value.body
          : body // ignore: cast_nullable_to_non_nullable
              as String,
      tags: null == tags
          ? _value.tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      locationCity: freezed == locationCity
          ? _value.locationCity
          : locationCity // ignore: cast_nullable_to_non_nullable
              as String?,
      locationCountry: freezed == locationCountry
          ? _value.locationCountry
          : locationCountry // ignore: cast_nullable_to_non_nullable
              as String?,
      remoteOk: null == remoteOk
          ? _value.remoteOk
          : remoteOk // ignore: cast_nullable_to_non_nullable
              as bool,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as OpportunityStatus,
      expiresAt: null == expiresAt
          ? _value.expiresAt
          : expiresAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      closedAt: freezed == closedAt
          ? _value.closedAt
          : closedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$OpportunityImplCopyWith<$Res>
    implements $OpportunityCopyWith<$Res> {
  factory _$$OpportunityImplCopyWith(
          _$OpportunityImpl value, $Res Function(_$OpportunityImpl) then) =
      __$$OpportunityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'author_id') String authorId,
      @JsonKey(fromJson: _kindFromJson, toJson: _kindToJson)
      OpportunityKind kind,
      String title,
      String body,
      @JsonKey(fromJson: _tagsFromJson) List<String> tags,
      @JsonKey(name: 'location_city') String? locationCity,
      @JsonKey(name: 'location_country') String? locationCountry,
      @JsonKey(name: 'remote_ok') bool remoteOk,
      @JsonKey(fromJson: _statusFromJson, toJson: _statusToJson)
      OpportunityStatus status,
      @JsonKey(name: 'expires_at', fromJson: _utcFromJson, toJson: _utcToJson)
      DateTime expiresAt,
      @JsonKey(name: 'created_at', fromJson: _utcFromJson, toJson: _utcToJson)
      DateTime createdAt,
      @JsonKey(name: 'updated_at', fromJson: _utcFromJson, toJson: _utcToJson)
      DateTime updatedAt,
      @JsonKey(
          name: 'closed_at',
          fromJson: _utcFromJsonNullable,
          toJson: _utcToJsonNullable)
      DateTime? closedAt});
}

/// @nodoc
class __$$OpportunityImplCopyWithImpl<$Res>
    extends _$OpportunityCopyWithImpl<$Res, _$OpportunityImpl>
    implements _$$OpportunityImplCopyWith<$Res> {
  __$$OpportunityImplCopyWithImpl(
      _$OpportunityImpl _value, $Res Function(_$OpportunityImpl) _then)
      : super(_value, _then);

  /// Create a copy of Opportunity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? authorId = null,
    Object? kind = null,
    Object? title = null,
    Object? body = null,
    Object? tags = null,
    Object? locationCity = freezed,
    Object? locationCountry = freezed,
    Object? remoteOk = null,
    Object? status = null,
    Object? expiresAt = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? closedAt = freezed,
  }) {
    return _then(_$OpportunityImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      authorId: null == authorId
          ? _value.authorId
          : authorId // ignore: cast_nullable_to_non_nullable
              as String,
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as OpportunityKind,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      body: null == body
          ? _value.body
          : body // ignore: cast_nullable_to_non_nullable
              as String,
      tags: null == tags
          ? _value._tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      locationCity: freezed == locationCity
          ? _value.locationCity
          : locationCity // ignore: cast_nullable_to_non_nullable
              as String?,
      locationCountry: freezed == locationCountry
          ? _value.locationCountry
          : locationCountry // ignore: cast_nullable_to_non_nullable
              as String?,
      remoteOk: null == remoteOk
          ? _value.remoteOk
          : remoteOk // ignore: cast_nullable_to_non_nullable
              as bool,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as OpportunityStatus,
      expiresAt: null == expiresAt
          ? _value.expiresAt
          : expiresAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      closedAt: freezed == closedAt
          ? _value.closedAt
          : closedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$OpportunityImpl implements _Opportunity {
  const _$OpportunityImpl(
      {required this.id,
      @JsonKey(name: 'author_id') required this.authorId,
      @JsonKey(fromJson: _kindFromJson, toJson: _kindToJson) required this.kind,
      required this.title,
      required this.body,
      @JsonKey(fromJson: _tagsFromJson) required final List<String> tags,
      @JsonKey(name: 'location_city') this.locationCity,
      @JsonKey(name: 'location_country') this.locationCountry,
      @JsonKey(name: 'remote_ok') required this.remoteOk,
      @JsonKey(fromJson: _statusFromJson, toJson: _statusToJson)
      required this.status,
      @JsonKey(name: 'expires_at', fromJson: _utcFromJson, toJson: _utcToJson)
      required this.expiresAt,
      @JsonKey(name: 'created_at', fromJson: _utcFromJson, toJson: _utcToJson)
      required this.createdAt,
      @JsonKey(name: 'updated_at', fromJson: _utcFromJson, toJson: _utcToJson)
      required this.updatedAt,
      @JsonKey(
          name: 'closed_at',
          fromJson: _utcFromJsonNullable,
          toJson: _utcToJsonNullable)
      this.closedAt})
      : _tags = tags;

  factory _$OpportunityImpl.fromJson(Map<String, dynamic> json) =>
      _$$OpportunityImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'author_id')
  final String authorId;
  @override
  @JsonKey(fromJson: _kindFromJson, toJson: _kindToJson)
  final OpportunityKind kind;
  @override
  final String title;
  @override
  final String body;
  final List<String> _tags;
  @override
  @JsonKey(fromJson: _tagsFromJson)
  List<String> get tags {
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tags);
  }

  @override
  @JsonKey(name: 'location_city')
  final String? locationCity;
  @override
  @JsonKey(name: 'location_country')
  final String? locationCountry;
  @override
  @JsonKey(name: 'remote_ok')
  final bool remoteOk;
  @override
  @JsonKey(fromJson: _statusFromJson, toJson: _statusToJson)
  final OpportunityStatus status;
  @override
  @JsonKey(name: 'expires_at', fromJson: _utcFromJson, toJson: _utcToJson)
  final DateTime expiresAt;
  @override
  @JsonKey(name: 'created_at', fromJson: _utcFromJson, toJson: _utcToJson)
  final DateTime createdAt;
  @override
  @JsonKey(name: 'updated_at', fromJson: _utcFromJson, toJson: _utcToJson)
  final DateTime updatedAt;
  @override
  @JsonKey(
      name: 'closed_at',
      fromJson: _utcFromJsonNullable,
      toJson: _utcToJsonNullable)
  final DateTime? closedAt;

  @override
  String toString() {
    return 'Opportunity(id: $id, authorId: $authorId, kind: $kind, title: $title, body: $body, tags: $tags, locationCity: $locationCity, locationCountry: $locationCountry, remoteOk: $remoteOk, status: $status, expiresAt: $expiresAt, createdAt: $createdAt, updatedAt: $updatedAt, closedAt: $closedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OpportunityImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.authorId, authorId) ||
                other.authorId == authorId) &&
            (identical(other.kind, kind) || other.kind == kind) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.body, body) || other.body == body) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
            (identical(other.locationCity, locationCity) ||
                other.locationCity == locationCity) &&
            (identical(other.locationCountry, locationCountry) ||
                other.locationCountry == locationCountry) &&
            (identical(other.remoteOk, remoteOk) ||
                other.remoteOk == remoteOk) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.expiresAt, expiresAt) ||
                other.expiresAt == expiresAt) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.closedAt, closedAt) ||
                other.closedAt == closedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      authorId,
      kind,
      title,
      body,
      const DeepCollectionEquality().hash(_tags),
      locationCity,
      locationCountry,
      remoteOk,
      status,
      expiresAt,
      createdAt,
      updatedAt,
      closedAt);

  /// Create a copy of Opportunity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OpportunityImplCopyWith<_$OpportunityImpl> get copyWith =>
      __$$OpportunityImplCopyWithImpl<_$OpportunityImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$OpportunityImplToJson(
      this,
    );
  }
}

abstract class _Opportunity implements Opportunity {
  const factory _Opportunity(
      {required final String id,
      @JsonKey(name: 'author_id') required final String authorId,
      @JsonKey(fromJson: _kindFromJson, toJson: _kindToJson)
      required final OpportunityKind kind,
      required final String title,
      required final String body,
      @JsonKey(fromJson: _tagsFromJson) required final List<String> tags,
      @JsonKey(name: 'location_city') final String? locationCity,
      @JsonKey(name: 'location_country') final String? locationCountry,
      @JsonKey(name: 'remote_ok') required final bool remoteOk,
      @JsonKey(fromJson: _statusFromJson, toJson: _statusToJson)
      required final OpportunityStatus status,
      @JsonKey(name: 'expires_at', fromJson: _utcFromJson, toJson: _utcToJson)
      required final DateTime expiresAt,
      @JsonKey(name: 'created_at', fromJson: _utcFromJson, toJson: _utcToJson)
      required final DateTime createdAt,
      @JsonKey(name: 'updated_at', fromJson: _utcFromJson, toJson: _utcToJson)
      required final DateTime updatedAt,
      @JsonKey(
          name: 'closed_at',
          fromJson: _utcFromJsonNullable,
          toJson: _utcToJsonNullable)
      final DateTime? closedAt}) = _$OpportunityImpl;

  factory _Opportunity.fromJson(Map<String, dynamic> json) =
      _$OpportunityImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'author_id')
  String get authorId;
  @override
  @JsonKey(fromJson: _kindFromJson, toJson: _kindToJson)
  OpportunityKind get kind;
  @override
  String get title;
  @override
  String get body;
  @override
  @JsonKey(fromJson: _tagsFromJson)
  List<String> get tags;
  @override
  @JsonKey(name: 'location_city')
  String? get locationCity;
  @override
  @JsonKey(name: 'location_country')
  String? get locationCountry;
  @override
  @JsonKey(name: 'remote_ok')
  bool get remoteOk;
  @override
  @JsonKey(fromJson: _statusFromJson, toJson: _statusToJson)
  OpportunityStatus get status;
  @override
  @JsonKey(name: 'expires_at', fromJson: _utcFromJson, toJson: _utcToJson)
  DateTime get expiresAt;
  @override
  @JsonKey(name: 'created_at', fromJson: _utcFromJson, toJson: _utcToJson)
  DateTime get createdAt;
  @override
  @JsonKey(name: 'updated_at', fromJson: _utcFromJson, toJson: _utcToJson)
  DateTime get updatedAt;
  @override
  @JsonKey(
      name: 'closed_at',
      fromJson: _utcFromJsonNullable,
      toJson: _utcToJsonNullable)
  DateTime? get closedAt;

  /// Create a copy of Opportunity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OpportunityImplCopyWith<_$OpportunityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
