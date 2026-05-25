// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'intro.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Intro _$IntroFromJson(Map<String, dynamic> json) {
  return _Intro.fromJson(json);
}

/// @nodoc
mixin _$Intro {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'sender_id')
  String get senderId => throw _privateConstructorUsedError;
  @JsonKey(name: 'recipient_id')
  String get recipientId => throw _privateConstructorUsedError;
  String get note => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _stateFromJson, toJson: _stateToJson)
  IntroState get state => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _kindFromJson, toJson: _kindToJson)
  IntroKind get kind => throw _privateConstructorUsedError;
  @JsonKey(name: 'warm_target_id')
  String? get warmTargetId => throw _privateConstructorUsedError;
  @JsonKey(name: 'conversation_id')
  String? get conversationId => throw _privateConstructorUsedError;
  @JsonKey(name: 'expires_at', fromJson: _utcFromJson, toJson: _utcToJson)
  DateTime get expiresAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at', fromJson: _utcFromJson, toJson: _utcToJson)
  DateTime get createdAt => throw _privateConstructorUsedError;
  @JsonKey(
      name: 'declined_at',
      fromJson: _utcFromJsonNullable,
      toJson: _utcToJsonNullable)
  DateTime? get declinedAt => throw _privateConstructorUsedError;
  @JsonKey(includeIfNull: false)
  Profile? get sender => throw _privateConstructorUsedError;
  @JsonKey(includeIfNull: false)
  Profile? get recipient => throw _privateConstructorUsedError;

  /// Serializes this Intro to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Intro
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $IntroCopyWith<Intro> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $IntroCopyWith<$Res> {
  factory $IntroCopyWith(Intro value, $Res Function(Intro) then) =
      _$IntroCopyWithImpl<$Res, Intro>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'sender_id') String senderId,
      @JsonKey(name: 'recipient_id') String recipientId,
      String note,
      @JsonKey(fromJson: _stateFromJson, toJson: _stateToJson) IntroState state,
      @JsonKey(fromJson: _kindFromJson, toJson: _kindToJson) IntroKind kind,
      @JsonKey(name: 'warm_target_id') String? warmTargetId,
      @JsonKey(name: 'conversation_id') String? conversationId,
      @JsonKey(name: 'expires_at', fromJson: _utcFromJson, toJson: _utcToJson)
      DateTime expiresAt,
      @JsonKey(name: 'created_at', fromJson: _utcFromJson, toJson: _utcToJson)
      DateTime createdAt,
      @JsonKey(
          name: 'declined_at',
          fromJson: _utcFromJsonNullable,
          toJson: _utcToJsonNullable)
      DateTime? declinedAt,
      @JsonKey(includeIfNull: false) Profile? sender,
      @JsonKey(includeIfNull: false) Profile? recipient});

  $ProfileCopyWith<$Res>? get sender;
  $ProfileCopyWith<$Res>? get recipient;
}

/// @nodoc
class _$IntroCopyWithImpl<$Res, $Val extends Intro>
    implements $IntroCopyWith<$Res> {
  _$IntroCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Intro
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? senderId = null,
    Object? recipientId = null,
    Object? note = null,
    Object? state = null,
    Object? kind = null,
    Object? warmTargetId = freezed,
    Object? conversationId = freezed,
    Object? expiresAt = null,
    Object? createdAt = null,
    Object? declinedAt = freezed,
    Object? sender = freezed,
    Object? recipient = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      senderId: null == senderId
          ? _value.senderId
          : senderId // ignore: cast_nullable_to_non_nullable
              as String,
      recipientId: null == recipientId
          ? _value.recipientId
          : recipientId // ignore: cast_nullable_to_non_nullable
              as String,
      note: null == note
          ? _value.note
          : note // ignore: cast_nullable_to_non_nullable
              as String,
      state: null == state
          ? _value.state
          : state // ignore: cast_nullable_to_non_nullable
              as IntroState,
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as IntroKind,
      warmTargetId: freezed == warmTargetId
          ? _value.warmTargetId
          : warmTargetId // ignore: cast_nullable_to_non_nullable
              as String?,
      conversationId: freezed == conversationId
          ? _value.conversationId
          : conversationId // ignore: cast_nullable_to_non_nullable
              as String?,
      expiresAt: null == expiresAt
          ? _value.expiresAt
          : expiresAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      declinedAt: freezed == declinedAt
          ? _value.declinedAt
          : declinedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      sender: freezed == sender
          ? _value.sender
          : sender // ignore: cast_nullable_to_non_nullable
              as Profile?,
      recipient: freezed == recipient
          ? _value.recipient
          : recipient // ignore: cast_nullable_to_non_nullable
              as Profile?,
    ) as $Val);
  }

  /// Create a copy of Intro
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ProfileCopyWith<$Res>? get sender {
    if (_value.sender == null) {
      return null;
    }

    return $ProfileCopyWith<$Res>(_value.sender!, (value) {
      return _then(_value.copyWith(sender: value) as $Val);
    });
  }

  /// Create a copy of Intro
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ProfileCopyWith<$Res>? get recipient {
    if (_value.recipient == null) {
      return null;
    }

    return $ProfileCopyWith<$Res>(_value.recipient!, (value) {
      return _then(_value.copyWith(recipient: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$IntroImplCopyWith<$Res> implements $IntroCopyWith<$Res> {
  factory _$$IntroImplCopyWith(
          _$IntroImpl value, $Res Function(_$IntroImpl) then) =
      __$$IntroImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'sender_id') String senderId,
      @JsonKey(name: 'recipient_id') String recipientId,
      String note,
      @JsonKey(fromJson: _stateFromJson, toJson: _stateToJson) IntroState state,
      @JsonKey(fromJson: _kindFromJson, toJson: _kindToJson) IntroKind kind,
      @JsonKey(name: 'warm_target_id') String? warmTargetId,
      @JsonKey(name: 'conversation_id') String? conversationId,
      @JsonKey(name: 'expires_at', fromJson: _utcFromJson, toJson: _utcToJson)
      DateTime expiresAt,
      @JsonKey(name: 'created_at', fromJson: _utcFromJson, toJson: _utcToJson)
      DateTime createdAt,
      @JsonKey(
          name: 'declined_at',
          fromJson: _utcFromJsonNullable,
          toJson: _utcToJsonNullable)
      DateTime? declinedAt,
      @JsonKey(includeIfNull: false) Profile? sender,
      @JsonKey(includeIfNull: false) Profile? recipient});

  @override
  $ProfileCopyWith<$Res>? get sender;
  @override
  $ProfileCopyWith<$Res>? get recipient;
}

/// @nodoc
class __$$IntroImplCopyWithImpl<$Res>
    extends _$IntroCopyWithImpl<$Res, _$IntroImpl>
    implements _$$IntroImplCopyWith<$Res> {
  __$$IntroImplCopyWithImpl(
      _$IntroImpl _value, $Res Function(_$IntroImpl) _then)
      : super(_value, _then);

  /// Create a copy of Intro
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? senderId = null,
    Object? recipientId = null,
    Object? note = null,
    Object? state = null,
    Object? kind = null,
    Object? warmTargetId = freezed,
    Object? conversationId = freezed,
    Object? expiresAt = null,
    Object? createdAt = null,
    Object? declinedAt = freezed,
    Object? sender = freezed,
    Object? recipient = freezed,
  }) {
    return _then(_$IntroImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      senderId: null == senderId
          ? _value.senderId
          : senderId // ignore: cast_nullable_to_non_nullable
              as String,
      recipientId: null == recipientId
          ? _value.recipientId
          : recipientId // ignore: cast_nullable_to_non_nullable
              as String,
      note: null == note
          ? _value.note
          : note // ignore: cast_nullable_to_non_nullable
              as String,
      state: null == state
          ? _value.state
          : state // ignore: cast_nullable_to_non_nullable
              as IntroState,
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as IntroKind,
      warmTargetId: freezed == warmTargetId
          ? _value.warmTargetId
          : warmTargetId // ignore: cast_nullable_to_non_nullable
              as String?,
      conversationId: freezed == conversationId
          ? _value.conversationId
          : conversationId // ignore: cast_nullable_to_non_nullable
              as String?,
      expiresAt: null == expiresAt
          ? _value.expiresAt
          : expiresAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      declinedAt: freezed == declinedAt
          ? _value.declinedAt
          : declinedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      sender: freezed == sender
          ? _value.sender
          : sender // ignore: cast_nullable_to_non_nullable
              as Profile?,
      recipient: freezed == recipient
          ? _value.recipient
          : recipient // ignore: cast_nullable_to_non_nullable
              as Profile?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$IntroImpl extends _Intro {
  const _$IntroImpl(
      {required this.id,
      @JsonKey(name: 'sender_id') required this.senderId,
      @JsonKey(name: 'recipient_id') required this.recipientId,
      required this.note,
      @JsonKey(fromJson: _stateFromJson, toJson: _stateToJson)
      required this.state,
      @JsonKey(fromJson: _kindFromJson, toJson: _kindToJson) required this.kind,
      @JsonKey(name: 'warm_target_id') required this.warmTargetId,
      @JsonKey(name: 'conversation_id') required this.conversationId,
      @JsonKey(name: 'expires_at', fromJson: _utcFromJson, toJson: _utcToJson)
      required this.expiresAt,
      @JsonKey(name: 'created_at', fromJson: _utcFromJson, toJson: _utcToJson)
      required this.createdAt,
      @JsonKey(
          name: 'declined_at',
          fromJson: _utcFromJsonNullable,
          toJson: _utcToJsonNullable)
      required this.declinedAt,
      @JsonKey(includeIfNull: false) this.sender,
      @JsonKey(includeIfNull: false) this.recipient})
      : super._();

  factory _$IntroImpl.fromJson(Map<String, dynamic> json) =>
      _$$IntroImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'sender_id')
  final String senderId;
  @override
  @JsonKey(name: 'recipient_id')
  final String recipientId;
  @override
  final String note;
  @override
  @JsonKey(fromJson: _stateFromJson, toJson: _stateToJson)
  final IntroState state;
  @override
  @JsonKey(fromJson: _kindFromJson, toJson: _kindToJson)
  final IntroKind kind;
  @override
  @JsonKey(name: 'warm_target_id')
  final String? warmTargetId;
  @override
  @JsonKey(name: 'conversation_id')
  final String? conversationId;
  @override
  @JsonKey(name: 'expires_at', fromJson: _utcFromJson, toJson: _utcToJson)
  final DateTime expiresAt;
  @override
  @JsonKey(name: 'created_at', fromJson: _utcFromJson, toJson: _utcToJson)
  final DateTime createdAt;
  @override
  @JsonKey(
      name: 'declined_at',
      fromJson: _utcFromJsonNullable,
      toJson: _utcToJsonNullable)
  final DateTime? declinedAt;
  @override
  @JsonKey(includeIfNull: false)
  final Profile? sender;
  @override
  @JsonKey(includeIfNull: false)
  final Profile? recipient;

  @override
  String toString() {
    return 'Intro(id: $id, senderId: $senderId, recipientId: $recipientId, note: $note, state: $state, kind: $kind, warmTargetId: $warmTargetId, conversationId: $conversationId, expiresAt: $expiresAt, createdAt: $createdAt, declinedAt: $declinedAt, sender: $sender, recipient: $recipient)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$IntroImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.senderId, senderId) ||
                other.senderId == senderId) &&
            (identical(other.recipientId, recipientId) ||
                other.recipientId == recipientId) &&
            (identical(other.note, note) || other.note == note) &&
            (identical(other.state, state) || other.state == state) &&
            (identical(other.kind, kind) || other.kind == kind) &&
            (identical(other.warmTargetId, warmTargetId) ||
                other.warmTargetId == warmTargetId) &&
            (identical(other.conversationId, conversationId) ||
                other.conversationId == conversationId) &&
            (identical(other.expiresAt, expiresAt) ||
                other.expiresAt == expiresAt) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.declinedAt, declinedAt) ||
                other.declinedAt == declinedAt) &&
            (identical(other.sender, sender) || other.sender == sender) &&
            (identical(other.recipient, recipient) ||
                other.recipient == recipient));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      senderId,
      recipientId,
      note,
      state,
      kind,
      warmTargetId,
      conversationId,
      expiresAt,
      createdAt,
      declinedAt,
      sender,
      recipient);

  /// Create a copy of Intro
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$IntroImplCopyWith<_$IntroImpl> get copyWith =>
      __$$IntroImplCopyWithImpl<_$IntroImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$IntroImplToJson(
      this,
    );
  }
}

abstract class _Intro extends Intro {
  const factory _Intro(
      {required final String id,
      @JsonKey(name: 'sender_id') required final String senderId,
      @JsonKey(name: 'recipient_id') required final String recipientId,
      required final String note,
      @JsonKey(fromJson: _stateFromJson, toJson: _stateToJson)
      required final IntroState state,
      @JsonKey(fromJson: _kindFromJson, toJson: _kindToJson)
      required final IntroKind kind,
      @JsonKey(name: 'warm_target_id') required final String? warmTargetId,
      @JsonKey(name: 'conversation_id') required final String? conversationId,
      @JsonKey(name: 'expires_at', fromJson: _utcFromJson, toJson: _utcToJson)
      required final DateTime expiresAt,
      @JsonKey(name: 'created_at', fromJson: _utcFromJson, toJson: _utcToJson)
      required final DateTime createdAt,
      @JsonKey(
          name: 'declined_at',
          fromJson: _utcFromJsonNullable,
          toJson: _utcToJsonNullable)
      required final DateTime? declinedAt,
      @JsonKey(includeIfNull: false) final Profile? sender,
      @JsonKey(includeIfNull: false) final Profile? recipient}) = _$IntroImpl;
  const _Intro._() : super._();

  factory _Intro.fromJson(Map<String, dynamic> json) = _$IntroImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'sender_id')
  String get senderId;
  @override
  @JsonKey(name: 'recipient_id')
  String get recipientId;
  @override
  String get note;
  @override
  @JsonKey(fromJson: _stateFromJson, toJson: _stateToJson)
  IntroState get state;
  @override
  @JsonKey(fromJson: _kindFromJson, toJson: _kindToJson)
  IntroKind get kind;
  @override
  @JsonKey(name: 'warm_target_id')
  String? get warmTargetId;
  @override
  @JsonKey(name: 'conversation_id')
  String? get conversationId;
  @override
  @JsonKey(name: 'expires_at', fromJson: _utcFromJson, toJson: _utcToJson)
  DateTime get expiresAt;
  @override
  @JsonKey(name: 'created_at', fromJson: _utcFromJson, toJson: _utcToJson)
  DateTime get createdAt;
  @override
  @JsonKey(
      name: 'declined_at',
      fromJson: _utcFromJsonNullable,
      toJson: _utcToJsonNullable)
  DateTime? get declinedAt;
  @override
  @JsonKey(includeIfNull: false)
  Profile? get sender;
  @override
  @JsonKey(includeIfNull: false)
  Profile? get recipient;

  /// Create a copy of Intro
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$IntroImplCopyWith<_$IntroImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
