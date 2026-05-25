import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/warm_intros_service.dart';
import '../domain/warm_suggestion.dart';

/// Today's 2nd-degree warm-intro suggestions for the caller. Default
/// `limit=10` matches the gallery suggestion-strip's budget.
///
/// Refreshes on app foreground (via the same lifecycle listener that
/// refreshes the daily picks) and on explicit `ref.invalidate`.
final FutureProvider<List<WarmSuggestion>> warmSuggestionsProvider =
    FutureProvider<List<WarmSuggestion>>((ref) async {
  return ref.watch(warmIntrosServiceProvider).suggestWarmIntros(limit: 10);
});
