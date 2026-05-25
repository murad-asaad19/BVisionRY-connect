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
    });
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

  /// True when the most recent goal change is older than 56 days (spec
  /// §17.5). The Profile screen uses this to render the goal-refresh
  /// banner; the threshold matches `GoalRefreshCard._staleDays`.
  bool get isGoalStale =>
      goalUpdatedAt != null &&
      goalUpdatedAt!
          .isBefore(DateTime.now().toUtc().subtract(const Duration(days: 56)));
}
