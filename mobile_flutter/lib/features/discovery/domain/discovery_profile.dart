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
  const DiscoveryProfile._();

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
    // Discovery-card affordances (gallery C1/C3). Both default off so a
    // profile renders cleanly when the RPC hasn't yet been extended to
    // SELECT these columns; once it does, the card surfaces the verified
    // role pill + the "★ Active this week" status pill automatically.
    @JsonKey(name: 'verified') @Default(false) bool verified,
    @JsonKey(name: 'last_active_at') DateTime? lastActiveAt,
  }) = _DiscoveryProfile;

  factory DiscoveryProfile.fromJson(Map<String, dynamic> json) =>
      _$DiscoveryProfileFromJson(json);

  /// True when the profile recorded activity within the last 7 days — drives
  /// the gallery's green "★ Active this week" status pill on browse rows
  /// (gallery C3 line 1556). Returns false when [lastActiveAt] is absent so
  /// the pill gracefully disappears when the data isn't available.
  bool get isActiveThisWeek {
    final DateTime? t = lastActiveAt;
    if (t == null) return false;
    return t.isAfter(DateTime.now().toUtc().subtract(const Duration(days: 7)));
  }
}
