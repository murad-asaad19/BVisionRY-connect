import 'package:freezed_annotation/freezed_annotation.dart';

part 'connection.freezed.dart';
part 'connection.g.dart';

DateTime _utcFromJson(Object v) => DateTime.parse(v as String).toUtc();
String _utcToJson(DateTime v) => v.toUtc().toIso8601String();

/// One row of `list_connections` (spec §3.3) — a confirmed mutual
/// connection of the caller, paired with the `conversation_id` that lets
/// the UI open the existing 1:1 chat without re-creating it.
@freezed
class Connection with _$Connection {
  const factory Connection({
    @JsonKey(name: 'user_id') required String userId,
    required String handle,
    required String name,
    @JsonKey(name: 'photo_url') required String? photoUrl,
    @JsonKey(name: 'primary_role') required String? primaryRole,
    @JsonKey(name: 'conversation_id') required String conversationId,
    @JsonKey(
      name: 'connected_at',
      fromJson: _utcFromJson,
      toJson: _utcToJson,
    )
    required DateTime connectedAt,
  }) = _Connection;

  factory Connection.fromJson(Map<String, dynamic> json) =>
      _$ConnectionFromJson(json);
}
