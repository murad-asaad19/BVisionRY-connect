import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../core/widgets/user_card.dart';
import '../../auth/providers/profile_provider.dart';
import '../domain/daily_match.dart';
import '../domain/match_reason.dart';
import '../domain/specific_match_reason.dart';
import 'match_reason_chip.dart';

/// Discovery card surfaced on the Home screen for each daily pick.
///
/// Wraps the foundation [UserCard] and passes the [MatchReasonChip] into
/// its `reason` slot. When the viewer profile is available, the chip text
/// is composed with [composeSpecificMatchReason] for a per-pick specific
/// line (gallery §9 "highest-specificity heuristic per pick"); otherwise
/// the categorical label is shown.
///
/// View-tracking: when [onSeen] is provided AND the underlying match has
/// not yet been seen (`match.viewedAt == null`), wraps the card in a
/// [VisibilityDetector] that fires `onSeen` exactly once at ≥ 50% visible.
class MatchCard extends ConsumerStatefulWidget {
  const MatchCard({
    super.key,
    required this.match,
    required this.onTap,
    this.featured = false,
    this.onSeen,
  });

  final DailyMatch match;
  final VoidCallback onTap;
  final bool featured;
  final VoidCallback? onSeen;

  @override
  ConsumerState<MatchCard> createState() => _MatchCardState();
}

class _MatchCardState extends ConsumerState<MatchCard> {
  bool _seenDispatched = false;

  @override
  Widget build(BuildContext context) {
    final reason = MatchReason.fromServer(widget.match.matchReason);
    final profile = widget.match.profile;
    final viewer = ref.watch(profileProvider).asData?.value;
    final specific = viewer == null
        ? null
        : composeSpecificMatchReason(viewer: viewer, match: profile);
    final card = UserCard(
      name: profile.name ?? '@${profile.handle}',
      primaryRole: profile.primaryRole ?? '',
      photoUrl: profile.photoUrl,
      headline: profile.headline,
      city: profile.city,
      country: profile.country,
      featured: widget.featured,
      reason: MatchReasonChip(
        reason: reason,
        specificText: specific,
        featured: widget.featured,
      ),
      onTap: widget.onTap,
    );

    if (widget.onSeen == null || widget.match.viewedAt != null) {
      return card;
    }
    return VisibilityDetector(
      key: Key('match-${widget.match.id}'),
      onVisibilityChanged: (info) {
        if (_seenDispatched) return;
        if (info.visibleFraction >= 0.5) {
          _seenDispatched = true;
          widget.onSeen!();
        }
      },
      child: card,
    );
  }
}
