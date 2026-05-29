import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme_mode.dart';
import '../data/appearance_store.dart';

/// The configured [AppearanceStore] singleton. Override in tests via
/// `appearanceStoreProvider.overrideWithValue(...)`.
final Provider<AppearanceStore> appearanceStoreProvider =
    Provider<AppearanceStore>(
  (Ref<AppearanceStore> ref) => AppearanceStore(),
);

/// Riverpod surface for the persisted appearance ([ThemeMode]) choice.
///
/// `build()` rehydrates the stored value from [AppearanceStore] and pushes it
/// into [themeModeProvider] (which `ConnectApp` watches to drive
/// `MaterialApp.themeMode`). [setMode] persists + applies a new choice.
///
/// We mirror the locale/telemetry pattern: the controller is the read/write
/// surface and [themeModeProvider] stays the live, app-wide source the root
/// widget watches. Keeping both in sync means cold-start restore and the
/// settings toggle flow through one place.
class AppearanceController extends AsyncNotifier<ThemeMode> {
  late AppearanceStore _store;

  @override
  Future<ThemeMode> build() async {
    _store = ref.watch(appearanceStoreProvider);
    final ThemeMode mode = await _store.load();
    // Drive the live provider so the restored choice takes effect on the
    // first frame after rehydration completes.
    ref.read(themeModeProvider.notifier).state = mode;
    return mode;
  }

  /// Persists [mode], applies it to the live [themeModeProvider], and updates
  /// the exposed state so the settings control reflects the new selection
  /// immediately.
  Future<void> setMode(ThemeMode mode) async {
    ref.read(themeModeProvider.notifier).state = mode;
    state = AsyncData<ThemeMode>(mode);
    await _store.save(mode);
  }
}

/// AsyncNotifierProvider exposing the user's appearance choice. The settings
/// appearance control reads this [AsyncValue] for its current selection and
/// calls [AppearanceController.setMode] to change it.
final AsyncNotifierProvider<AppearanceController, ThemeMode>
    appearanceProvider = AsyncNotifierProvider<AppearanceController, ThemeMode>(
  AppearanceController.new,
);

/// Completes once the persisted appearance choice has been restored into
/// [themeModeProvider]. A startup path can `await` this (mirroring
/// `localeReadyProvider` / `telemetryReadyProvider`) so the first frame paints
/// in the saved theme.
final FutureProvider<void> appearanceReadyProvider =
    FutureProvider<void>((Ref<void> ref) async {
  await ref.watch(appearanceProvider.future);
});
