import 'package:flutter/widgets.dart';

import '../../../core/i18n/i18n.dart';
import '../../../core/i18n/relative_time.dart';
import '../../../core/widgets/widgets.dart';
import '../domain/intro_enums.dart';

/// Pill badge that maps an [IntroState] to a semantic-intent [Pill].
///
/// Colour mapping mirrors the gallery: pending uses the brand-gold pale
/// chrome via `info`, accepted/connected use `success`, declined uses
/// `danger`, expired uses `muted`. The widget delegates entirely to
/// [Pill] so it inherits the existing intent palette and golden tests.
///
/// When [fromSender] is true the labels switch to the sender's POV (per
/// gallery E2):
///   - `delivered` -> "Delivered, awaiting response" (muted)
///   - `expired` -> "Expired · 14 days, no response" (muted)
///   - `connected` -> "Connected · {ago}" (success, with a relative time
///     suffix computed off [connectedAt]).
///
/// The `ValueKey('intro-badge-<state>')` exposes a stable hook for
/// widget tests to assert which badge variant is rendered.
class IntroStateBadge extends StatelessWidget {
  const IntroStateBadge({
    super.key,
    required this.state,
    this.fromSender = false,
    this.connectedAt,
  });

  final IntroState state;

  /// `true` when the viewing user is the sender of this intro — flips
  /// declined/delivered/expired/connected to the sender-facing copy
  /// from §12 of the spec ("decline is silent").
  final bool fromSender;

  /// Reference timestamp for the `connectedAgo` suffix. Falls back to
  /// the intro's `created_at` (or now) when null.
  final DateTime? connectedAt;

  @override
  Widget build(BuildContext context) {
    final PillVariant variant;
    final String label;
    switch (state) {
      case IntroState.delivered:
        if (fromSender) {
          variant = PillVariant.muted;
          label = context.t('intros.badge.awaitingResponse');
        } else {
          variant = PillVariant.info;
          label = context.t('intros.state.delivered');
        }
      case IntroState.accepted:
        variant = PillVariant.success;
        label = context.t('intros.state.accepted');
      case IntroState.declined:
        if (fromSender) {
          // Spec §12: decline is silent. The sender's Sent tab fetches its
          // own rows via RLS and would otherwise leak the recipient's
          // decline through a 'Declined' danger pill — keep the row
          // visually identical to "delivered, awaiting response" so the
          // sender can't infer the decline from the badge alone.
          variant = PillVariant.muted;
          label = context.t('intros.badge.awaitingResponse');
        } else {
          variant = PillVariant.danger;
          label = context.t('intros.state.declined');
        }
      case IntroState.expired:
        variant = PillVariant.muted;
        label = fromSender
            ? context.t('intros.badge.expiredNoResponse')
            : context.t('intros.state.expired');
      case IntroState.connected:
        variant = PillVariant.success;
        if (fromSender) {
          final ts = connectedAt ?? DateTime.now().toUtc();
          label = context.t(
            'intros.badge.connectedAgo',
            vars: <String, Object>{'ago': relativeTimeAgo(context, ts)},
          );
        } else {
          label = context.t('intros.state.connected');
        }
    }
    return Pill(
      key: ValueKey<String>('intro-badge-${state.name}'),
      label: label,
      variant: variant,
    );
  }
}
