import 'package:flutter/material.dart';

import '../../../core/i18n/i18n.dart';
import '../../../core/widgets/pill.dart';
import '../domain/match_reason.dart';

/// Small chip rendered inline on a [MatchCard] surfacing the match
/// reason. Two flavours:
///
/// * **Specific** — when [specificText] is provided (e.g. "open to
///   fractional CTO; you're hiring one"), render it verbatim with a
///   "Match:" prefix.
/// * **Categorical** — fall back to the i18n-resolved label of [reason]
///   (e.g. "Shared role") when nothing more specific was derivable.
///
/// Featured cards use the gold-solid variant; other cards use the
/// default goldPale variant.
class MatchReasonChip extends StatelessWidget {
  const MatchReasonChip({
    super.key,
    required this.reason,
    this.specificText,
    this.featured = false,
  });

  final MatchReason reason;

  /// Optional client-composed, profile-specific text. Takes precedence
  /// over the categorical [reason] label.
  final String? specificText;

  final bool featured;

  @override
  Widget build(BuildContext context) {
    final label = (specificText != null && specificText!.isNotEmpty)
        ? 'Match: $specificText'
        : context.t(reason.i18nKey);
    return Pill(
      label: label,
      variant: featured ? PillVariant.solid : PillVariant.defaultVariant,
    );
  }
}
