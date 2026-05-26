import 'package:freezed_annotation/freezed_annotation.dart';

part 'blocked_user.freezed.dart';
part 'blocked_user.g.dart';

DateTime _utcFromJson(Object v) => DateTime.parse(v as String).toUtc();
String _utcToJson(DateTime v) => v.toUtc().toIso8601String();

/// One row of `list_blocked_users()` (spec §3.8).
///
/// Returned by the RPC as `(blocked_id, handle, name, photo_url, created_at)`
/// — RLS guarantees the caller only sees rows where they are the blocker
/// (the `created_at` column reflects when the block was placed, not when the
/// blocked user signed up).
@freezed
class BlockedUser with _$BlockedUser {
  const factory BlockedUser({
    @JsonKey(name: 'blocked_id') required String blockedId,
    required String handle,
    required String name,
    @JsonKey(name: 'photo_url') String? photoUrl,
    @JsonKey(name: 'created_at', fromJson: _utcFromJson, toJson: _utcToJson)
    required DateTime createdAt,
  }) = _BlockedUser;

  factory BlockedUser.fromJson(Map<String, dynamic> json) =>
      _$BlockedUserFromJson(json);
}
