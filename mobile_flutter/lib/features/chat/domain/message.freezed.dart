// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'message.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$Message {
  String get id => throw _privateConstructorUsedError;
  String get conversationId => throw _privateConstructorUsedError;
  String get senderId => throw _privateConstructorUsedError;
  MessageKind get kind => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  String? get body => throw _privateConstructorUsedError;
  String? get meetingProposalId => throw _privateConstructorUsedError;
  String? get mediaPath => throw _privateConstructorUsedError;
  int? get mediaDurationMs => throw _privateConstructorUsedError;
  int? get mediaSizeBytes => throw _privateConstructorUsedError;
  DateTime? get editedAt => throw _privateConstructorUsedError;
  DateTime? get deletedAt => throw _privateConstructorUsedError;
  String? get transcript => throw _privateConstructorUsedError;
  TranscriptStatus? get transcriptStatus =>
      throw _privateConstructorUsedError; // --- Transient, client-only optimistic-send fields ---
// Never populated by [Message.fromRow]; carried only by locally-created
// optimistic bubbles so they can render before the server row exists and
// reconcile against it afterwards.
  /// Non-null while the bubble is a local optimistic placeholder.
  MessageSendStatus? get sendStatus => throw _privateConstructorUsedError;

  /// Locally-picked image bytes shown under an upload overlay until the
  /// real (signed-URL) image is available. Optimistic image bubbles only.
  Uint8List? get localImageBytes => throw _privateConstructorUsedError;

  /// Create a copy of Message
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MessageCopyWith<Message> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MessageCopyWith<$Res> {
  factory $MessageCopyWith(Message value, $Res Function(Message) then) =
      _$MessageCopyWithImpl<$Res, Message>;
  @useResult
  $Res call(
      {String id,
      String conversationId,
      String senderId,
      MessageKind kind,
      DateTime createdAt,
      String? body,
      String? meetingProposalId,
      String? mediaPath,
      int? mediaDurationMs,
      int? mediaSizeBytes,
      DateTime? editedAt,
      DateTime? deletedAt,
      String? transcript,
      TranscriptStatus? transcriptStatus,
      MessageSendStatus? sendStatus,
      Uint8List? localImageBytes});
}

/// @nodoc
class _$MessageCopyWithImpl<$Res, $Val extends Message>
    implements $MessageCopyWith<$Res> {
  _$MessageCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Message
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? conversationId = null,
    Object? senderId = null,
    Object? kind = null,
    Object? createdAt = null,
    Object? body = freezed,
    Object? meetingProposalId = freezed,
    Object? mediaPath = freezed,
    Object? mediaDurationMs = freezed,
    Object? mediaSizeBytes = freezed,
    Object? editedAt = freezed,
    Object? deletedAt = freezed,
    Object? transcript = freezed,
    Object? transcriptStatus = freezed,
    Object? sendStatus = freezed,
    Object? localImageBytes = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      conversationId: null == conversationId
          ? _value.conversationId
          : conversationId // ignore: cast_nullable_to_non_nullable
              as String,
      senderId: null == senderId
          ? _value.senderId
          : senderId // ignore: cast_nullable_to_non_nullable
              as String,
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as MessageKind,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      body: freezed == body
          ? _value.body
          : body // ignore: cast_nullable_to_non_nullable
              as String?,
      meetingProposalId: freezed == meetingProposalId
          ? _value.meetingProposalId
          : meetingProposalId // ignore: cast_nullable_to_non_nullable
              as String?,
      mediaPath: freezed == mediaPath
          ? _value.mediaPath
          : mediaPath // ignore: cast_nullable_to_non_nullable
              as String?,
      mediaDurationMs: freezed == mediaDurationMs
          ? _value.mediaDurationMs
          : mediaDurationMs // ignore: cast_nullable_to_non_nullable
              as int?,
      mediaSizeBytes: freezed == mediaSizeBytes
          ? _value.mediaSizeBytes
          : mediaSizeBytes // ignore: cast_nullable_to_non_nullable
              as int?,
      editedAt: freezed == editedAt
          ? _value.editedAt
          : editedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      deletedAt: freezed == deletedAt
          ? _value.deletedAt
          : deletedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      transcript: freezed == transcript
          ? _value.transcript
          : transcript // ignore: cast_nullable_to_non_nullable
              as String?,
      transcriptStatus: freezed == transcriptStatus
          ? _value.transcriptStatus
          : transcriptStatus // ignore: cast_nullable_to_non_nullable
              as TranscriptStatus?,
      sendStatus: freezed == sendStatus
          ? _value.sendStatus
          : sendStatus // ignore: cast_nullable_to_non_nullable
              as MessageSendStatus?,
      localImageBytes: freezed == localImageBytes
          ? _value.localImageBytes
          : localImageBytes // ignore: cast_nullable_to_non_nullable
              as Uint8List?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MessageImplCopyWith<$Res> implements $MessageCopyWith<$Res> {
  factory _$$MessageImplCopyWith(
          _$MessageImpl value, $Res Function(_$MessageImpl) then) =
      __$$MessageImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String conversationId,
      String senderId,
      MessageKind kind,
      DateTime createdAt,
      String? body,
      String? meetingProposalId,
      String? mediaPath,
      int? mediaDurationMs,
      int? mediaSizeBytes,
      DateTime? editedAt,
      DateTime? deletedAt,
      String? transcript,
      TranscriptStatus? transcriptStatus,
      MessageSendStatus? sendStatus,
      Uint8List? localImageBytes});
}

/// @nodoc
class __$$MessageImplCopyWithImpl<$Res>
    extends _$MessageCopyWithImpl<$Res, _$MessageImpl>
    implements _$$MessageImplCopyWith<$Res> {
  __$$MessageImplCopyWithImpl(
      _$MessageImpl _value, $Res Function(_$MessageImpl) _then)
      : super(_value, _then);

  /// Create a copy of Message
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? conversationId = null,
    Object? senderId = null,
    Object? kind = null,
    Object? createdAt = null,
    Object? body = freezed,
    Object? meetingProposalId = freezed,
    Object? mediaPath = freezed,
    Object? mediaDurationMs = freezed,
    Object? mediaSizeBytes = freezed,
    Object? editedAt = freezed,
    Object? deletedAt = freezed,
    Object? transcript = freezed,
    Object? transcriptStatus = freezed,
    Object? sendStatus = freezed,
    Object? localImageBytes = freezed,
  }) {
    return _then(_$MessageImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      conversationId: null == conversationId
          ? _value.conversationId
          : conversationId // ignore: cast_nullable_to_non_nullable
              as String,
      senderId: null == senderId
          ? _value.senderId
          : senderId // ignore: cast_nullable_to_non_nullable
              as String,
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as MessageKind,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      body: freezed == body
          ? _value.body
          : body // ignore: cast_nullable_to_non_nullable
              as String?,
      meetingProposalId: freezed == meetingProposalId
          ? _value.meetingProposalId
          : meetingProposalId // ignore: cast_nullable_to_non_nullable
              as String?,
      mediaPath: freezed == mediaPath
          ? _value.mediaPath
          : mediaPath // ignore: cast_nullable_to_non_nullable
              as String?,
      mediaDurationMs: freezed == mediaDurationMs
          ? _value.mediaDurationMs
          : mediaDurationMs // ignore: cast_nullable_to_non_nullable
              as int?,
      mediaSizeBytes: freezed == mediaSizeBytes
          ? _value.mediaSizeBytes
          : mediaSizeBytes // ignore: cast_nullable_to_non_nullable
              as int?,
      editedAt: freezed == editedAt
          ? _value.editedAt
          : editedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      deletedAt: freezed == deletedAt
          ? _value.deletedAt
          : deletedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      transcript: freezed == transcript
          ? _value.transcript
          : transcript // ignore: cast_nullable_to_non_nullable
              as String?,
      transcriptStatus: freezed == transcriptStatus
          ? _value.transcriptStatus
          : transcriptStatus // ignore: cast_nullable_to_non_nullable
              as TranscriptStatus?,
      sendStatus: freezed == sendStatus
          ? _value.sendStatus
          : sendStatus // ignore: cast_nullable_to_non_nullable
              as MessageSendStatus?,
      localImageBytes: freezed == localImageBytes
          ? _value.localImageBytes
          : localImageBytes // ignore: cast_nullable_to_non_nullable
              as Uint8List?,
    ));
  }
}

/// @nodoc

class _$MessageImpl extends _Message {
  const _$MessageImpl(
      {required this.id,
      required this.conversationId,
      required this.senderId,
      required this.kind,
      required this.createdAt,
      this.body,
      this.meetingProposalId,
      this.mediaPath,
      this.mediaDurationMs,
      this.mediaSizeBytes,
      this.editedAt,
      this.deletedAt,
      this.transcript,
      this.transcriptStatus,
      this.sendStatus,
      this.localImageBytes = null})
      : super._();

  @override
  final String id;
  @override
  final String conversationId;
  @override
  final String senderId;
  @override
  final MessageKind kind;
  @override
  final DateTime createdAt;
  @override
  final String? body;
  @override
  final String? meetingProposalId;
  @override
  final String? mediaPath;
  @override
  final int? mediaDurationMs;
  @override
  final int? mediaSizeBytes;
  @override
  final DateTime? editedAt;
  @override
  final DateTime? deletedAt;
  @override
  final String? transcript;
  @override
  final TranscriptStatus? transcriptStatus;
// --- Transient, client-only optimistic-send fields ---
// Never populated by [Message.fromRow]; carried only by locally-created
// optimistic bubbles so they can render before the server row exists and
// reconcile against it afterwards.
  /// Non-null while the bubble is a local optimistic placeholder.
  @override
  final MessageSendStatus? sendStatus;

  /// Locally-picked image bytes shown under an upload overlay until the
  /// real (signed-URL) image is available. Optimistic image bubbles only.
  @override
  @JsonKey()
  final Uint8List? localImageBytes;

  @override
  String toString() {
    return 'Message(id: $id, conversationId: $conversationId, senderId: $senderId, kind: $kind, createdAt: $createdAt, body: $body, meetingProposalId: $meetingProposalId, mediaPath: $mediaPath, mediaDurationMs: $mediaDurationMs, mediaSizeBytes: $mediaSizeBytes, editedAt: $editedAt, deletedAt: $deletedAt, transcript: $transcript, transcriptStatus: $transcriptStatus, sendStatus: $sendStatus, localImageBytes: $localImageBytes)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MessageImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.conversationId, conversationId) ||
                other.conversationId == conversationId) &&
            (identical(other.senderId, senderId) ||
                other.senderId == senderId) &&
            (identical(other.kind, kind) || other.kind == kind) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.body, body) || other.body == body) &&
            (identical(other.meetingProposalId, meetingProposalId) ||
                other.meetingProposalId == meetingProposalId) &&
            (identical(other.mediaPath, mediaPath) ||
                other.mediaPath == mediaPath) &&
            (identical(other.mediaDurationMs, mediaDurationMs) ||
                other.mediaDurationMs == mediaDurationMs) &&
            (identical(other.mediaSizeBytes, mediaSizeBytes) ||
                other.mediaSizeBytes == mediaSizeBytes) &&
            (identical(other.editedAt, editedAt) ||
                other.editedAt == editedAt) &&
            (identical(other.deletedAt, deletedAt) ||
                other.deletedAt == deletedAt) &&
            (identical(other.transcript, transcript) ||
                other.transcript == transcript) &&
            (identical(other.transcriptStatus, transcriptStatus) ||
                other.transcriptStatus == transcriptStatus) &&
            (identical(other.sendStatus, sendStatus) ||
                other.sendStatus == sendStatus) &&
            const DeepCollectionEquality()
                .equals(other.localImageBytes, localImageBytes));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      conversationId,
      senderId,
      kind,
      createdAt,
      body,
      meetingProposalId,
      mediaPath,
      mediaDurationMs,
      mediaSizeBytes,
      editedAt,
      deletedAt,
      transcript,
      transcriptStatus,
      sendStatus,
      const DeepCollectionEquality().hash(localImageBytes));

  /// Create a copy of Message
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MessageImplCopyWith<_$MessageImpl> get copyWith =>
      __$$MessageImplCopyWithImpl<_$MessageImpl>(this, _$identity);
}

abstract class _Message extends Message {
  const factory _Message(
      {required final String id,
      required final String conversationId,
      required final String senderId,
      required final MessageKind kind,
      required final DateTime createdAt,
      final String? body,
      final String? meetingProposalId,
      final String? mediaPath,
      final int? mediaDurationMs,
      final int? mediaSizeBytes,
      final DateTime? editedAt,
      final DateTime? deletedAt,
      final String? transcript,
      final TranscriptStatus? transcriptStatus,
      final MessageSendStatus? sendStatus,
      final Uint8List? localImageBytes}) = _$MessageImpl;
  const _Message._() : super._();

  @override
  String get id;
  @override
  String get conversationId;
  @override
  String get senderId;
  @override
  MessageKind get kind;
  @override
  DateTime get createdAt;
  @override
  String? get body;
  @override
  String? get meetingProposalId;
  @override
  String? get mediaPath;
  @override
  int? get mediaDurationMs;
  @override
  int? get mediaSizeBytes;
  @override
  DateTime? get editedAt;
  @override
  DateTime? get deletedAt;
  @override
  String? get transcript;
  @override
  TranscriptStatus?
      get transcriptStatus; // --- Transient, client-only optimistic-send fields ---
// Never populated by [Message.fromRow]; carried only by locally-created
// optimistic bubbles so they can render before the server row exists and
// reconcile against it afterwards.
  /// Non-null while the bubble is a local optimistic placeholder.
  @override
  MessageSendStatus? get sendStatus;

  /// Locally-picked image bytes shown under an upload overlay until the
  /// real (signed-URL) image is available. Optimistic image bubbles only.
  @override
  Uint8List? get localImageBytes;

  /// Create a copy of Message
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MessageImplCopyWith<_$MessageImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
