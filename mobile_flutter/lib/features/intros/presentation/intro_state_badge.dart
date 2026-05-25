import 'package:flutter/widgets.dart';

import '../../../core/i18n/i18n.dart';
import '../../../core/widgets/widgets.dart';
import '../domain/intro_enums.dart';

/// Pill badge that maps an [IntroState] to a semantic-intent [Pill].
///
/// Colour mapping mirrors the gallery: pending uses the brand-gold pale
/// chrome via `info`, accepted/connected use `success`, declined uses
/// `danger`, expired uses `muted`. The widget delegates entirely to
/// [Pill] so it inherits the existing intent palette and golden tests.
///
/// The `ValueKey('intro-badge-<state>')` exposes a stable hook for
/// widget tests to assert which badge variant is rendered.
class IntroStateBadge extends StatelessWidget {
  const IntroStateBadge({super.key, required this.state});

  final IntroState state;

  @override
  Widget build(BuildContext context) {
    final (PillVariant variant, String labelKey) = switch (state) {
      IntroState.delivered => (PillVariant.info, 'intros.state.delivered'),
      IntroState.accepted => (PillVariant.success, 'intros.state.accepted'),
      IntroState.declined => (PillVariant.danger, 'intros.state.declined'),
      IntroState.expired => (PillVariant.muted, 'intros.state.expired'),
      IntroState.connected => (PillVariant.success, 'intros.state.connected'),
    };
    return Pill(
      key: ValueKey<String>('intro-badge-${state.name}'),
      label: context.t(labelKey),
      variant: variant,
    );
  }
}
