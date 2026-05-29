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
  ///
  /// Kinds are *taxonomy*, not state — they read as categories, so they only
  /// use the brand-neutral variants (`solid` / `navy` / `outline` /
  /// `defaultVariant`). The semantic intents (`danger`/`warning`/`success`/
  /// `info`) are reserved for actual error/caution/ok states and are
  /// deliberately NOT used here: a red "seeking advisor" pill reads as an
  /// error, an orange "fundraising" pill reads as a warning.
  static PillVariant variantFor(OpportunityKind k) {
    return switch (k) {
      OpportunityKind.hiring => PillVariant.solid,
      OpportunityKind.seekingRole => PillVariant.outline,
      OpportunityKind.cofounder => PillVariant.navy,
      OpportunityKind.collaboration => PillVariant.defaultVariant,
      OpportunityKind.fundraising => PillVariant.solid,
      OpportunityKind.investing => PillVariant.navy,
      OpportunityKind.advising => PillVariant.outline,
      OpportunityKind.seekingAdvisor => PillVariant.defaultVariant,
    };
  }
}
