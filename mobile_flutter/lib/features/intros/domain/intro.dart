import 'package:freezed_annotation/freezed_annotation.dart';

import '../../profile/domain/profile.dart';
import 'intro_enums.dart';

part 'intro.freezed.dart';
part 'intro.g.dart';

IntroState _stateFromJson(String raw) => IntroState.fromJson(raw);
String _stateToJson(IntroState s) => s.toJson();
IntroKind _kindFromJson(String raw) => IntroKind.fromJson(raw);
String _kindToJson(IntroKind k) => k.toJson();

DateTime _utcFromJson(Object v) => DateTime.parse(v as String).toUtc();
String _utcToJson(DateTime v) => v.toUtc().toIso8601String();
DateTime? _utcFromJsonNullable(Object? v) =>
    v == null ? null : DateTime.parse(v as String).toUtc();
String? _utcToJsonNullable(DateTime? v) => v?.toUtc().toIso8601String();

/// One row from `public.intros` (spec §2.4).
///
/// Carries every column on the table so the same model serves both list
/// rows and the detail screen. The optional [sender] / [recipient] nested
/// [Profile] objects are populated when the gateway joins against
/// `profiles` (e.g. for the list-by-side helpers).
///
/// The [isActionable] helper centralises the rule "row can show Accept /
/// Decline buttons" — `state == delivered` AND `expires_at` in the future.
@freezed
class Intro with _$Intro {
  const Intro._();

  const factory Intro({
    required String id,
    @JsonKey(name: 'sender_id') required String senderId,
    @JsonKey(name: 'recipient_id') required String recipientId,
    required String note,
    @JsonKey(fromJson: _stateFromJson, toJson: _stateToJson)
    required IntroState state,
    @JsonKey(fromJson: _kindFromJson, toJson: _kindToJson)
    required IntroKind kind,
    @JsonKey(name: 'warm_target_id') required String? warmTargetId,
    @JsonKey(name: 'conversation_id') required String? conversationId,
    @JsonKey(
      name: 'expires_at',
      fromJson: _utcFromJson,
      toJson: _utcToJson,
    )
    required DateTime expiresAt,
    @JsonKey(
      name: 'created_at',
      fromJson: _utcFromJson,
      toJson: _utcToJson,
    )
    required DateTime createdAt,
    @JsonKey(
      name: 'declined_at',
      fromJson: _utcFromJsonNullable,
      toJson: _utcToJsonNullable,
    )
    required DateTime? declinedAt,
    @JsonKey(includeIfNull: false) Profile? sender,
    @JsonKey(includeIfNull: false) Profile? recipient,
  }) = _Intro;

  factory Intro.fromJson(Map<String, dynamic> json) => _$IntroFromJson(json);

  /// `true` when the recipient can act on this row right now.
  bool get isActionable {
    if (state != IntroState.delivered) return false;
    return expiresAt.isAfter(DateTime.now().toUtc());
  }

  bool get isWarmRequest => kind == IntroKind.warmRequest;
  bool get isWarmForward => kind == IntroKind.warmForward;
  bool get isDirect => kind == IntroKind.direct;
}
