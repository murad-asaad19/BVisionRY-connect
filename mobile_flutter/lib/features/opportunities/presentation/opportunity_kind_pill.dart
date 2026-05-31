import 'package:flutter/material.dart';

import '../../../core/i18n/i18n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/pill.dart';
import '../domain/opportunity_kind.dart';

/// Pill rendering for an [OpportunityKind].
///
/// Each kind has a UNIQUE, category-stable colour so the eight taxonomy values
/// are instantly distinguishable across the feed / detail / my-opportunities
/// surfaces. The palette is a DEDICATED CATEGORICAL set — brand gold/navy plus
/// violet/rose/teal/indigo accents — kept deliberately separate from the
/// success/warning/info/danger STATUS palette so a kind chip never reads as a
/// state (e.g. "Fundraising" is teal, not success-green). Label resolves to
/// `context.t(kind.i18nKey)` (`opportunities.kind.*`).
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
    final label = context.t(kind.i18nKey);
    // Four kinds use a dedicated accent hue (violet/rose/teal/indigo) rendered
    // via Pill's explicit-colour overrides; the rest are brand-native variants.
    final accent = _accent(context, kind);
    if (accent != null) {
      return Pill(
        label: label,
        size: size,
        backgroundColor: accent.$1,
        foregroundColor: accent.$2,
      );
    }
    return Pill(label: label, variant: variantFor(kind), size: size);
  }

  /// Accent (bg, fg) for the four kinds that carry a dedicated categorical hue
  /// decoupled from the status palette. Returns null for the brand-native
  /// kinds (which use [variantFor]).
  static (Color, Color)? _accent(BuildContext context, OpportunityKind k) {
    final c = Theme.of(context).extension<AppColors>()!;
    return switch (k) {
      OpportunityKind.cofounder => (c.violetBg, c.violet),
      OpportunityKind.advising => (c.roseBg, c.rose),
      OpportunityKind.fundraising => (c.tealBg, c.teal),
      OpportunityKind.seekingAdvisor => (c.indigoBg, c.indigo),
      _ => null,
    };
  }

  /// Brand-native [PillVariant] for the four kinds that don't use an accent
  /// hue. (The accent kinds render via [_accent] and fall through to a neutral
  /// default here.) Exposed static so adjacent widgets/tests can reuse it.
  static PillVariant variantFor(OpportunityKind k) {
    return switch (k) {
      OpportunityKind.hiring => PillVariant.solid, // gold (flagship)
      OpportunityKind.collaboration => PillVariant.navy, // navy fill
      OpportunityKind.investing => PillVariant.outline, // navy outline
      OpportunityKind.seekingRole => PillVariant.muted, // gold soft
      _ => PillVariant.muted,
    };
  }
}
