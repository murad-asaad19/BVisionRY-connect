import 'package:freezed_annotation/freezed_annotation.dart';

import 'opportunity.dart';

part 'opportunity_with_author.freezed.dart';

/// Join shape returned by `list_opportunities` (and re-used by
/// `list_my_opportunities`) — wraps an [Opportunity] with the author's
/// display fields (handle / name / photo / primary role / verified GitHub).
///
/// `interestedCount` is populated only by `list_my_opportunities` (so authors
/// can see the running count on each of their own posts without a second
/// roundtrip). Other call sites leave it `null`.
@freezed
class OpportunityWithAuthor with _$OpportunityWithAuthor {
  const factory OpportunityWithAuthor({
    required Opportunity opportunity,
    required String authorHandle,
    required String authorName,
    String? authorPhotoUrl,
    String? authorPrimaryRole,
    String? authorVerifiedGithubUsername,
    int? interestedCount,
  }) = _OpportunityWithAuthor;

  const OpportunityWithAuthor._();

  /// Parses a flat join row — the RPC unnests all opportunity columns plus
  /// the `author_*` and (optionally) `interested_count` columns onto a
  /// single object.
  factory OpportunityWithAuthor.fromJson(Map<String, dynamic> json) {
    final Opportunity opp = Opportunity.fromJson(json);
    final Object? rawCount = json['interested_count'];
    return OpportunityWithAuthor(
      opportunity: opp,
      authorHandle: json['author_handle'] as String,
      authorName: json['author_name'] as String,
      authorPhotoUrl: json['author_photo_url'] as String?,
      authorPrimaryRole: json['author_primary_role'] as String?,
      authorVerifiedGithubUsername:
          json['author_verified_github_username'] as String?,
      interestedCount: rawCount == null ? null : (rawCount as num).toInt(),
    );
  }
}
