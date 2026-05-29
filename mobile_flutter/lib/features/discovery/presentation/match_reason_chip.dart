import 'package:flutter/material.dart';

import '../../../core/i18n/i18n.dart';
import '../../../core/widgets/pill.dart';
import '../domain/match_reason.dart';

/// Small chip rendered inline on a [MatchCard] surfacing the match
/// reason. Two flavours:
///
/// * **Specific** — when [specificText] is provided (e.g. "open to
///   fractional CTO; you're hiring one"), render it verbatim with a
///   localized "Match:" prefix.
/// * **Categorical** — fall back to the i18n-resolved label of [reason]
///   (e.g. "Shared role") when nothing more specific was derivable.
///
/// Featured cards use the gold-solid variant; other cards use the
/// default goldPale variant. A long specific reason is truncated so the
/// single-line [Pill] never overflows the card row.
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

  /// Max characters of [specificText] surfaced inline. The [Pill] renders a
  /// single un-wrapping line, so anything longer is ellipsized at the source
  /// to keep the chip inside the card.
  static const int _kMaxReasonChars = 48;

  @override
  Widget build(BuildContext context) {
    final hasSpecific = specificText != null && specificText!.isNotEmpty;
    final String label;
    if (hasSpecific) {
      label = context.t(
        'discovery.matchPrefix',
        vars: <String, Object>{'reason': _truncate(specificText!)},
      );
    } else {
      label = context.t(reason.i18nKey);
    }
    return Pill(
      label: label,
      variant: featured ? PillVariant.solid : PillVariant.defaultVariant,
    );
  }

  static String _truncate(String s) {
    if (s.length <= _kMaxReasonChars) return s;
    return '${s.substring(0, _kMaxReasonChars).trimRight()}…';
  }
}
