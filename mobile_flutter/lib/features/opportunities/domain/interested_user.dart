import 'package:freezed_annotation/freezed_annotation.dart';

part 'interested_user.freezed.dart';
part 'interested_user.g.dart';

DateTime _utcFromJson(Object v) => DateTime.parse(v as String).toUtc();
String _utcToJson(DateTime v) => v.toUtc().toIso8601String();

/// One row of `list_interested(p_opportunity_id)` (spec §3.7).
///
/// Author-only view of an interested user — RLS gates the RPC so non-authors
/// receive a 42501 / `ForbiddenException` instead of an empty list.
@freezed
class InterestedUser with _$InterestedUser {
  const factory InterestedUser({
    @JsonKey(name: 'user_id') required String userId,
    required String handle,
    required String name,
    @JsonKey(name: 'photo_url') String? photoUrl,
    @JsonKey(name: 'primary_role') String? primaryRole,
    String? note,
    @JsonKey(name: 'created_at', fromJson: _utcFromJson, toJson: _utcToJson)
    required DateTime createdAt,
  }) = _InterestedUser;

  factory InterestedUser.fromJson(Map<String, dynamic> json) =>
      _$InterestedUserFromJson(json);
}
