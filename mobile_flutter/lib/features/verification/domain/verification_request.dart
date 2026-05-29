/// Domain model + enums for the generic manual-review verification system
/// (migration `20260612060000_verifications.sql`).
///
/// These mirror the Postgres enums one-for-one. Plain Dart (hand-written
/// `fromJson`) rather than freezed — there is no codegen step on this model.
library;

/// Mirrors the Postgres enum `public.verification_kind`.
///
/// Each value carries the literal `wire` string sent to / received from the
/// RPCs, the `group` it belongs to in the verification screen, and a `payload`
/// hint describing what evidence [submitVerification] should attach. GitHub
/// "Builder" verification is intentionally absent — it lives on its own
/// `profiles.verified_*` columns and is not part of this table.
enum VerificationKind {
  founderDomainEmail('founder_domain_email', VerificationGroup.founder),
  founderTeamPage('founder_team_page', VerificationGroup.founder),
  investorDomainEmail('investor_domain_email', VerificationGroup.investor),
  investorCrunchbase('investor_crunchbase', VerificationGroup.investor),
  investorPortfolio('investor_portfolio', VerificationGroup.investor);

  const VerificationKind(this.wire, this.group);

  /// Literal wire encoding — matches the SQL enum exactly.
  final String wire;

  /// Which proof group this kind renders under in the verification screen.
  final VerificationGroup group;

  /// Resolves a wire string back to a kind, or `null` if unknown (lets the
  /// client tolerate a future enum value the server added before the app
  /// shipped support for it).
  static VerificationKind? fromWire(String wire) {
    for (final VerificationKind k in VerificationKind.values) {
      if (k.wire == wire) return k;
    }
    return null;
  }
}

/// The two proof groups surfaced in the verification screen (the Builder /
/// GitHub group is handled separately).
enum VerificationGroup { founder, investor }

/// Mirrors the Postgres enum `public.verification_status`.
enum VerificationStatus {
  pending,
  approved,
  rejected;

  String get wire => name;

  static VerificationStatus? fromWire(String wire) {
    for (final VerificationStatus s in VerificationStatus.values) {
      if (s.wire == wire) return s;
    }
    return null;
  }
}

/// One row returned by `list_my_verifications()` — the caller's own
/// submission for a given [kind] plus its review state.
class VerificationRequest {
  const VerificationRequest({
    required this.id,
    required this.kind,
    required this.status,
    required this.createdAt,
    this.reviewedAt,
    this.note,
  });

  final String id;
  final VerificationKind kind;
  final VerificationStatus status;
  final DateTime createdAt;
  final DateTime? reviewedAt;

  /// Reviewer note — populated for rejected submissions to explain why.
  final String? note;

  /// Builds a [VerificationRequest] from a `list_my_verifications()` row,
  /// or `null` when the row carries an enum value this client doesn't know.
  static VerificationRequest? fromJson(Map<String, dynamic> json) {
    final VerificationKind? kind =
        VerificationKind.fromWire(json['kind'] as String);
    final VerificationStatus? status =
        VerificationStatus.fromWire(json['status'] as String);
    if (kind == null || status == null) return null;
    final Object? reviewedAt = json['reviewed_at'];
    return VerificationRequest(
      id: json['id'] as String,
      kind: kind,
      status: status,
      createdAt: DateTime.parse(json['created_at'] as String).toUtc(),
      reviewedAt: reviewedAt == null
          ? null
          : DateTime.parse(reviewedAt as String).toUtc(),
      note: json['note'] as String?,
    );
  }
}
