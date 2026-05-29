import 'package:flutter/widgets.dart';

import '../../../../core/i18n/i18n.dart';
import '../../../../core/widgets/pill.dart';
import '../../domain/discovery_profile.dart';

/// Small status pill rendered on non-featured browse rows (gallery C1/C3).
///
/// Mirrors the gallery's two browse-row status affordances:
/// * green success `★ Active this week` when the profile was active in the
///   last 7 days ([DiscoveryProfile.isActiveThisWeek]);
/// * muted `No badge yet` when the profile is not verified.
///
/// Returns [SizedBox.shrink] when neither applies (e.g. a verified-but-idle
/// profile carries no row-level status pill), so the slot collapses cleanly.
/// The verified case is intentionally not shown here — the verified role pill
/// already renders beside the name.
class DiscoveryStatusPill extends StatelessWidget {
  const DiscoveryStatusPill({super.key, required this.profile});

  final DiscoveryProfile profile;

  /// Whether [profile] resolves to any status pill at all — lets callers
  /// avoid allocating an empty slot when nothing would render.
  static bool hasStatus(DiscoveryProfile profile) =>
      profile.isActiveThisWeek || !profile.verified;

  @override
  Widget build(BuildContext context) {
    if (profile.isActiveThisWeek) {
      return Pill(
        label: '★ ${context.t('discovery.status.activeThisWeek')}',
        variant: PillVariant.success,
      );
    }
    if (!profile.verified) {
      return Pill(
        label: context.t('discovery.status.noBadge'),
        variant: PillVariant.muted,
      );
    }
    return const SizedBox.shrink();
  }
}
