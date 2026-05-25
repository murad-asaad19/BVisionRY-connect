import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/discovery_service.dart';
import '../domain/daily_match.dart';
import 'midnight_invalidator.dart';

/// `Today's matches` provider — fetches once per local calendar day and
/// auto-invalidates when [currentLocalDayProvider] rolls past midnight.
///
/// Also exposes:
/// - `refresh()` — pull-to-refresh on the home screen
/// - `markViewed(matchId)` — fired from each [MatchCard]'s `onSeen`
final AsyncNotifierProvider<DailyMatchesController, List<DailyMatch>>
    dailyMatchesProvider =
    AsyncNotifierProvider<DailyMatchesController, List<DailyMatch>>(
  DailyMatchesController.new,
);

class DailyMatchesController extends AsyncNotifier<List<DailyMatch>> {
  @override
  Future<List<DailyMatch>> build() async {
    // Re-build whenever the local calendar day rolls.
    final day = ref.watch(currentLocalDayProvider);
    // Keep the midnight invalidator alive for the lifetime of the screen.
    ref.watch(midnightInvalidatorProvider);
    final service = ref.read(discoveryServiceProvider);
    return service.fetchDailyMatches(date: day);
  }

  /// Pull-to-refresh: re-fires the RPC for the current local day.
  Future<void> refresh() async {
    state = const AsyncLoading<List<DailyMatch>>().copyWithPrevious(state);
    state = await AsyncValue.guard<List<DailyMatch>>(() {
      final day = ref.read(currentLocalDayProvider);
      return ref.read(discoveryServiceProvider).fetchDailyMatches(date: day);
    });
  }

  /// Stamps [matchId] as viewed on both the server (best-effort) and the
  /// local cached state (so a re-render doesn't fire `onSeen` again).
  Future<void> markViewed(String matchId) async {
    final service = ref.read(discoveryServiceProvider);
    await service.markMatchViewed(matchId);
    final current = state.value ?? const <DailyMatch>[];
    state = AsyncData(<DailyMatch>[
      for (final m in current)
        if (m.id == matchId) m.copyWith(viewedAt: DateTime.now()) else m,
    ]);
  }
}
