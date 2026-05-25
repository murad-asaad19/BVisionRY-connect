import 'package:freezed_annotation/freezed_annotation.dart';

import 'discovery_profile.dart';

part 'daily_match.freezed.dart';

/// One row from the `get_daily_matches` RPC.
///
/// The RPC returns rows flattened with the joined profile fields. The
/// [fromRow] factory normalises a flat RPC row into a [DailyMatch] with
/// a nested [DiscoveryProfile] so callers can pass the model straight to
/// [MatchCard] / [UserCard].
@Freezed(toJson: false, fromJson: false)
class DailyMatch with _$DailyMatch {
  const factory DailyMatch({
    required String id,
    required String pickUserId,
    required String matchReason,
    required DateTime forDateLocal,
    DateTime? viewedAt,
    required DateTime createdAt,
    required DiscoveryProfile profile,
  }) = _DailyMatch;

  /// Builds a [DailyMatch] from a flat `get_daily_matches` RPC row that
  /// includes the joined profile fields.
  factory DailyMatch.fromJson(Map<String, dynamic> json) => DailyMatch(
        id: json['id'] as String,
        pickUserId: json['pick_user_id'] as String,
        matchReason: json['match_reason'] as String,
        forDateLocal: DateTime.parse('${json['for_date_local']}T00:00:00Z'),
        viewedAt: json['viewed_at'] == null
            ? null
            : DateTime.parse(json['viewed_at'] as String),
        createdAt: DateTime.parse(json['created_at'] as String),
        profile: DiscoveryProfile.fromJson(<String, dynamic>{
          'id': json['pick_user_id'],
          'handle': json['handle'],
          'name': json['name'],
          'photo_url': json['photo_url'],
          'headline': json['headline'],
          'bio': json['bio'],
          'city': json['city'],
          'country': json['country'],
          'primary_role': json['primary_role'],
          'roles': (json['roles'] as List?)?.cast<String>() ?? const <String>[],
          'goal_type': json['goal_type'],
        }),
      );
}
