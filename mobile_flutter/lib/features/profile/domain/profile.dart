import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile.freezed.dart';
part 'profile.g.dart';

/// Canonical profile model mirroring the full `profiles` table (spec §2.2).
///
/// Replaces the Phase 2 hand-written stub at
/// `lib/features/auth/domain/profile.dart`, which now re-exports this class.
/// Every nullable column in the schema is nullable here so a freshly created
/// (pre-onboarding) row can be represented faithfully.
///
/// Convention: helper getters expose semantic flags the UI layer reads
/// (`isVerified`, `isSuspended`, `isGoalStale`) instead of poking the raw
/// columns directly.
@freezed
class Profile with _$Profile {
  const Profile._();

  const factory Profile({
    required String id,
    String? handle,
    String? name,
    String? headline,
    String? bio,
    @Default(<String>[]) List<String> roles,
    @JsonKey(name: 'primary_role') String? primaryRole,
    String? city,
    String? country,
    @JsonKey(name: 'goal_type') String? goalType,
    @JsonKey(name: 'goal_text') String? goalText,
    @JsonKey(name: 'goal_updated_at') DateTime? goalUpdatedAt,
    @JsonKey(name: 'photo_url') String? photoUrl,
    @Default(false) bool onboarded,
    @JsonKey(name: 'verified_github_username') String? verifiedGithubUsername,
    @JsonKey(name: 'verified_github_id') int? verifiedGithubId,
    @JsonKey(name: 'verified_at') DateTime? verifiedAt,
    @JsonKey(name: 'suspended_at') DateTime? suspendedAt,
    @JsonKey(name: 'private_mode') @Default(false) bool privateMode,
    @JsonKey(name: 'read_receipts_enabled')
    @Default(false)
    bool readReceiptsEnabled,
    @JsonKey(name: 'public_investor_page')
    @Default(false)
    bool publicInvestorPage,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
    @JsonKey(name: 'last_active_at') DateTime? lastActiveAt,
    // Age-gate + legal consent (set by record_signup_consent). Both are
    // stamped together; the [consentRecorded] getter reads them to drive the
    // post-auth consent interstitial gate.
    @JsonKey(name: 'tos_accepted_at') DateTime? tosAcceptedAt,
    @JsonKey(name: 'privacy_accepted_at') DateTime? privacyAcceptedAt,
    // Role-specific structured details (spec §3a). All optional; the profile
    // screen renders only the rows that resolve to a non-null value.
    // Builder details
    @JsonKey(name: 'builder_discipline') String? builderDiscipline,
    @JsonKey(name: 'builder_seniority') String? builderSeniority,
    @JsonKey(name: 'builder_skills')
    @Default(<String>[])
    List<String> builderSkills,
    @JsonKey(name: 'builder_open_to')
    @Default(<String>[])
    List<String> builderOpenTo,
    @JsonKey(name: 'builder_rate_band') String? builderRateBand,
    // Founder details
    @JsonKey(name: 'founder_stage') String? founderStage,
    @JsonKey(name: 'founder_sector') String? founderSector,
    @JsonKey(name: 'founder_funding') String? founderFunding,
    @JsonKey(name: 'founder_hiring') bool? founderHiring,
    // Investor details
    @JsonKey(name: 'investor_type') String? investorType,
    @JsonKey(name: 'investor_check_size') String? investorCheckSize,
    @JsonKey(name: 'investor_sectors')
    @Default(<String>[])
    List<String> investorSectors,
    @JsonKey(name: 'investor_stage') String? investorStage,
  }) = _Profile;

  factory Profile.fromJson(Map<String, dynamic> json) =>
      _$ProfileFromJson(json);

  /// Backwards-compatible factory mirroring the Phase 2 `Profile.fromMap`
  /// contract: tolerates open-shaped Maps that may omit columns the
  /// downstream caller does not care about (e.g. the auth gate only reads
  /// `id`, `onboarded`, `suspended_at`, `handle`, `name`, `private_mode`).
  ///
  /// The implementation funnels through [fromJson] after filling every
  /// nullable field with `null`, which is faithful to the column default
  /// at the SQL layer.
  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile.fromJson(<String, dynamic>{
      'id': map['id'],
      'handle': map['handle'],
      'name': map['name'],
      'headline': map['headline'],
      'bio': map['bio'],
      'roles': map['roles'] ?? const <String>[],
      'primary_role': map['primary_role'],
      'city': map['city'],
      'country': map['country'],
      'goal_type': map['goal_type'],
      'goal_text': map['goal_text'],
      'goal_updated_at': map['goal_updated_at'],
      'photo_url': map['photo_url'],
      'onboarded': map['onboarded'] ?? false,
      'verified_github_username': map['verified_github_username'],
      'verified_github_id': map['verified_github_id'],
      'verified_at': map['verified_at'],
      'suspended_at': map['suspended_at'],
      'private_mode': map['private_mode'] ?? false,
      'read_receipts_enabled': map['read_receipts_enabled'] ?? false,
      'public_investor_page': map['public_investor_page'] ?? false,
      'created_at': map['created_at'],
      'updated_at': map['updated_at'],
      'last_active_at': map['last_active_at'],
      'tos_accepted_at': map['tos_accepted_at'],
      'privacy_accepted_at': map['privacy_accepted_at'],
      'builder_discipline': map['builder_discipline'],
      'builder_seniority': map['builder_seniority'],
      'builder_skills': map['builder_skills'] ?? const <String>[],
      'builder_open_to': map['builder_open_to'] ?? const <String>[],
      'builder_rate_band': map['builder_rate_band'],
      'founder_stage': map['founder_stage'],
      'founder_sector': map['founder_sector'],
      'founder_funding': map['founder_funding'],
      'founder_hiring': map['founder_hiring'],
      'investor_type': map['investor_type'],
      'investor_check_size': map['investor_check_size'],
      'investor_sectors': map['investor_sectors'] ?? const <String>[],
      'investor_stage': map['investor_stage'],
    });
  }

  /// True when the profile recorded an activity timestamp within the last
  /// 7 days — drives the gallery's green "Active this week" recency pill
  /// on the profile hero. Returns false when [lastActiveAt] is null so we
  /// gracefully skip the pill when the data isn't available.
  bool get isActiveThisWeek {
    final DateTime? t = lastActiveAt;
    if (t == null) return false;
    return t.isAfter(DateTime.now().toUtc().subtract(const Duration(days: 7)));
  }

  /// Default profile carrying just the id — handy for tests and copyWith
  /// builders. Every other field defaults to its SQL-layer default.
  factory Profile.empty(String id) => Profile(id: id);

  /// True when the user has a verified GitHub identity attached (spec §17.3
  /// — GitHub is the only proof type implemented; other proofs are TBD).
  bool get isVerified => verifiedGithubUsername != null;

  /// True when the profile carries a non-null `suspended_at` timestamp.
  /// Mirrors spec §5.3 — suspension is a soft-state flag, not a deletion.
  bool get isSuspended => suspendedAt != null;

  /// True once both the Terms of Service and Privacy Policy have been accepted
  /// (stamped together by `record_signup_consent`). Drives the post-auth
  /// consent interstitial gate — a profile that returns `false` here is routed
  /// to [Routes.consent] before onboarding regardless of how it authenticated.
  bool get consentRecorded =>
      tosAcceptedAt != null && privacyAcceptedAt != null;

  /// True when the most recent goal change is older than 28 days / 4 weeks —
  /// the *soft* threshold. Pairs with [GoalRefreshCard]'s muted inline
  /// nudge.
  bool get isGoalStale =>
      goalUpdatedAt != null &&
      goalUpdatedAt!
          .isBefore(DateTime.now().toUtc().subtract(const Duration(days: 28)));

  /// True once the goal change is older than 56 days / 8 weeks — the *hard*
  /// threshold that promotes the inline nudge to a full warning card with
  /// dismiss + update actions. Two-tier model avoids the "stop pestering
  /// me" reflex while still surfacing genuinely stale goals.
  bool get isGoalVeryStale =>
      goalUpdatedAt != null &&
      goalUpdatedAt!
          .isBefore(DateTime.now().toUtc().subtract(const Duration(days: 56)));
}
