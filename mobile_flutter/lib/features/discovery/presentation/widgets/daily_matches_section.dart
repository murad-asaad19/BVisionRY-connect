import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/routes.dart';
import '../../domain/daily_match.dart';
import '../../providers/daily_matches_provider.dart';
import '../match_card.dart';

/// Renders the up-to-5 daily matches on the home screen.
///
/// The #1 pick renders as a featured full-width card (gold gradient via
/// [MatchCard]'s `featured: true` flag) carrying the match-reason chip.
/// The remaining picks stack vertically below as regular (non-featured)
/// cards — gallery C1 shows these plain rows with a muted match-reason chip
/// (or an activity/badge status pill) instead of the gold chip (handled
/// inside [MatchCard]). The separate "BROWSE ALL" filter feed sits below
/// this section on the Home screen.
class DailyMatchesSection extends ConsumerWidget {
  const DailyMatchesSection({super.key, required this.matches});

  final List<DailyMatch> matches;

  /// Number of leading picks rendered as full-width featured cards.
  static const int kFeaturedCount = 1;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (var i = 0; i < matches.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: MatchCard(
              match: matches[i],
              featured: i < kFeaturedCount,
              entranceIndex: i,
              onTap: () => context.push(
                Routes.publicProfile(matches[i].profile.handle),
              ),
              onSeen: () => ref
                  .read(dailyMatchesProvider.notifier)
                  .markViewed(matches[i].id),
            ),
          ),
      ],
    );
  }
}
