import 'package:flutter/material.dart';

import '../../../../core/widgets/user_card.dart';
import '../../domain/discovery_profile.dart';

/// Thin wrapper over [UserCard] that maps a [DiscoveryProfile] onto the
/// foundation user-card props. Used by the search results list and any
/// future feed surface that needs to render a discoverable profile.
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
    return UserCard(
      name: profile.name ?? '@${profile.handle}',
      primaryRole: profile.primaryRole ?? '',
      photoUrl: profile.photoUrl,
      headline: profile.headline,
      city: profile.city,
      country: profile.country,
      onTap: onTap,
    );
  }
}
