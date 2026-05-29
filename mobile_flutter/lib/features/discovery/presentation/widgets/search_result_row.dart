import 'package:flutter/material.dart';

import '../../../../core/widgets/user_card.dart';
import '../../domain/discovery_profile.dart';
import '../../domain/role_label.dart';
import 'discovery_status_pill.dart';

/// Thin wrapper over [UserCard] that maps a [DiscoveryProfile] onto the
/// foundation user-card props. Used by the search results list and any
/// future feed surface that needs to render a discoverable profile.
///
/// Browse rows carry NO match-reason chip (gallery C3) — instead the
/// [DiscoveryStatusPill] (`★ Active this week` / `No badge yet`) occupies
/// the card's `reason` slot, and verified profiles get the labelled role
/// pill beside the name via [UserCard.verified].
class SearchResultRow extends StatelessWidget {
  const SearchResultRow({
    super.key,
    required this.profile,
    required this.onTap,
  });

  final DiscoveryProfile profile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final role = profile.primaryRole;
    return UserCard(
      name: profile.name ?? '@${profile.handle}',
      primaryRole:
          (role == null || role.isEmpty) ? '' : roleLabel(context, role),
      photoUrl: profile.photoUrl,
      headline: profile.headline,
      city: profile.city,
      country: profile.country,
      verified: profile.verified,
      reason: DiscoveryStatusPill.hasStatus(profile)
          ? DiscoveryStatusPill(profile: profile)
          : null,
      onTap: onTap,
    );
  }
}
