import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../core/widgets/user_card.dart';
import '../domain/daily_match.dart';
import '../domain/match_reason.dart';
import 'match_reason_chip.dart';

/// Discovery card surfaced on the Home screen for each daily pick.
///
/// Wraps the foundation [UserCard] so the card chrome (avatar, name, role
/// pill, headline, location) stays consistent with search/intro lists, and
/// stacks a [MatchReasonChip] in the top-right corner.
///
/// View-tracking: when [onSeen] is provided AND the underlying match has not
/// yet been seen (`match.viewedAt == null`), wraps the card in a
/// [VisibilityDetector] that fires `onSeen` exactly once at ≥ 50% visible.
class MatchCard extends StatefulWidget {
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
  State<MatchCard> createState() => _MatchCardState();
}

class _MatchCardState extends State<MatchCard> {
  bool _seenDispatched = false;

  @override
  Widget build(BuildContext context) {
    final reason = MatchReason.fromServer(widget.match.matchReason);
    final profile = widget.match.profile;
    final card = Stack(
      children: <Widget>[
        UserCard(
          name: profile.name ?? '@${profile.handle}',
          primaryRole: profile.primaryRole ?? '',
          photoUrl: profile.photoUrl,
          headline: profile.headline,
          city: profile.city,
          country: profile.country,
          featured: widget.featured,
          onTap: widget.onTap,
        ),
        Positioned(
          top: 8,
          right: 8,
          child: MatchReasonChip(reason: reason, featured: widget.featured),
        ),
      ],
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
