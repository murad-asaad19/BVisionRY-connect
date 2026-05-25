import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/routes.dart';
import '../../domain/daily_match.dart';
import '../../providers/daily_matches_provider.dart';
import '../match_card.dart';

/// Renders the up-to-5 daily matches on the home screen.
///
/// Top 3 picks render as featured full-width cards (gold gradient via
/// [MatchCard]'s `featured: true` flag). Picks 4–5 (if present) overflow
/// into a horizontal scroller below.
class DailyMatchesSection extends ConsumerWidget {
  const DailyMatchesSection({super.key, required this.matches});

  final List<DailyMatch> matches;

  /// Number of leading picks rendered as full-width featured cards.
  static const int kFeaturedCount = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final featured = matches.take(kFeaturedCount).toList();
    final rest = matches.length > kFeaturedCount
        ? matches.sublist(kFeaturedCount)
        : <DailyMatch>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final m in featured)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: MatchCard(
              match: m,
              featured: true,
              onTap: () => context.push(Routes.publicProfile(m.profile.handle)),
              onSeen: () =>
                  ref.read(dailyMatchesProvider.notifier).markViewed(m.id),
            ),
          ),
        if (rest.isNotEmpty)
          SizedBox(
            height: 132,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: rest.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) {
                final m = rest[i];
                return SizedBox(
                  width: 280,
                  child: MatchCard(
                    match: m,
                    onTap: () =>
                        context.push(Routes.publicProfile(m.profile.handle)),
                    onSeen: () => ref
                        .read(dailyMatchesProvider.notifier)
                        .markViewed(m.id),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
