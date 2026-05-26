import 'package:freezed_annotation/freezed_annotation.dart';

import 'opportunity_with_author.dart';

part 'opportunity_with_counts.freezed.dart';

/// Detail-shape row returned by `get_opportunity` (spec §3.7).
///
/// Wraps an [OpportunityWithAuthor] with the running `interestedCount` and
/// the viewer-relative `viewerHasExpressedInterest` flag — both are needed
/// by the detail screen to choose between the CTA (Express interest) and
/// the success banner (You expressed interest).
@freezed
class OpportunityWithCounts with _$OpportunityWithCounts {
  const factory OpportunityWithCounts({
    required OpportunityWithAuthor withAuthor,
    required int interestedCount,
    required bool viewerHasExpressedInterest,
  }) = _OpportunityWithCounts;

  const OpportunityWithCounts._();

  factory OpportunityWithCounts.fromJson(Map<String, dynamic> json) {
    return OpportunityWithCounts(
      withAuthor: OpportunityWithAuthor.fromJson(json),
      interestedCount: (json['interested_count'] as num).toInt(),
      viewerHasExpressedInterest: json['viewer_has_expressed_interest'] as bool,
    );
  }
}
