import 'package:flutter/material.dart';

import '../../../core/i18n/i18n.dart';
import '../../../core/widgets/pill.dart';
import '../domain/match_reason.dart';

/// Small chip rendered in the corner of a [MatchCard] surfacing the
/// machine-picked match reason (Complementary goals, Shared role, …).
///
/// Featured cards (top 3 daily matches) use the gold `solid` variant;
/// remaining cards use the default goldPale variant. The label is always
/// the i18n-resolved display string — never the raw server enum.
class MatchReasonChip extends StatelessWidget {
  const MatchReasonChip({
    super.key,
    required this.reason,
    this.featured = false,
  });

  final MatchReason reason;
  final bool featured;

  @override
  Widget build(BuildContext context) {
    return Pill(
      label: context.t(reason.i18nKey),
      variant: featured ? PillVariant.solid : PillVariant.defaultVariant,
    );
  }
}
