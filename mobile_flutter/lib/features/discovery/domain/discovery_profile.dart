import 'package:freezed_annotation/freezed_annotation.dart';

part 'discovery_profile.freezed.dart';
part 'discovery_profile.g.dart';

/// Lightweight profile subset returned by `get_daily_matches` and
/// `search_discoverable_profiles`.
///
/// Differs from the canonical [Profile] in `features/profile/domain/profile.dart`
/// because Discovery only needs the fields the card / row UI actually
/// renders. Carries an optional [createdAt] used as the keyset cursor by
/// [SearchController].
@freezed
class DiscoveryProfile with _$DiscoveryProfile {
  const factory DiscoveryProfile({
    required String id,
    required String handle,
    String? name,
    @JsonKey(name: 'photo_url') String? photoUrl,
    String? headline,
    String? bio,
    String? city,
    String? country,
    @JsonKey(name: 'primary_role') String? primaryRole,
    @Default(<String>[]) List<String> roles,
    @JsonKey(name: 'goal_type') String? goalType,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _DiscoveryProfile;

  factory DiscoveryProfile.fromJson(Map<String, dynamic> json) =>
      _$DiscoveryProfileFromJson(json);
}
