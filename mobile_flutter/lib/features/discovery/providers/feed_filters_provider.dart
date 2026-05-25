import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/feed_filters.dart';

const String _kPersistKey = 'discovery.feedFilters';

/// Async-loaded, mutable [FeedFilters] store backed by `shared_preferences`.
///
/// `query` is **never** persisted (matches the RN `feedFiltersStore`'s
/// Zustand `partialize`); roles / goal types / country ARE persisted so
/// the filters survive a cold-start.
final AsyncNotifierProvider<FeedFiltersController, FeedFilters>
    feedFiltersProvider =
    AsyncNotifierProvider<FeedFiltersController, FeedFilters>(
  FeedFiltersController.new,
);

class FeedFiltersController extends AsyncNotifier<FeedFilters> {
  @override
  Future<FeedFilters> build() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kPersistKey);
    if (raw == null) return const FeedFilters();
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      // Ensure query is reset on rehydrate.
      return FeedFilters.fromJson(<String, dynamic>{...m, 'query': ''});
    } catch (_) {
      return const FeedFilters();
    }
  }

  Future<void> _update(FeedFilters next, {bool persist = true}) async {
    state = AsyncData(next);
    if (!persist) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPersistKey, jsonEncode(next.persistedJson()));
  }

  Future<void> setQuery(String q) async {
    final cur = state.value ?? const FeedFilters();
    await _update(cur.copyWith(query: q), persist: false);
  }

  Future<void> setRoles(List<String> roles) async {
    final cur = state.value ?? const FeedFilters();
    await _update(cur.copyWith(roles: roles));
  }

  Future<void> setGoalTypes(List<String> goalTypes) async {
    final cur = state.value ?? const FeedFilters();
    await _update(cur.copyWith(goalTypes: goalTypes));
  }

  Future<void> setCountry(String? country) async {
    final cur = state.value ?? const FeedFilters();
    await _update(cur.copyWith(country: country));
  }

  Future<void> reset() async {
    await _update(const FeedFilters());
  }
}
