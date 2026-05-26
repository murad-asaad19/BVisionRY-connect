import 'package:flutter/material.dart';

import '../../../core/i18n/i18n.dart';
import '../../../core/widgets/pill.dart';
import '../domain/opportunity_kind.dart';

/// Pill rendering for an [OpportunityKind].
///
/// Each kind carries a fixed [PillVariant] mapping so the feed / detail /
/// my-opportunities surfaces all match. The label resolves to
/// `context.t(kind.i18nKey)` so localised strings come from
/// `opportunities.kind.*` in `en.json` / `es.json`.
class OpportunityKindPill extends StatelessWidget {
  const OpportunityKindPill({
    super.key,
    required this.kind,
    this.size = PillSize.md,
  });

  final OpportunityKind kind;
  final PillSize size;

  @override
  Widget build(BuildContext context) {
    return Pill(
      label: context.t(kind.i18nKey),
      variant: variantFor(kind),
      size: size,
    );
  }

  /// Stable mapping from [OpportunityKind] to [PillVariant]. Exposed as a
  /// static so tests and adjacent widgets (e.g. card status row) can re-use
  /// the same palette without duplicating the switch.
  static PillVariant variantFor(OpportunityKind k) {
    return switch (k) {
      OpportunityKind.hiring || OpportunityKind.seekingRole =>
        PillVariant.solid,
      OpportunityKind.cofounder => PillVariant.navy,
      OpportunityKind.collaboration => PillVariant.info,
      OpportunityKind.fundraising || OpportunityKind.investing =>
        PillVariant.defaultVariant,
      OpportunityKind.advising || OpportunityKind.seekingAdvisor =>
        PillVariant.muted,
    };
  }
}
