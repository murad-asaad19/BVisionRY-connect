import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Test-friendly clock alias. Default is `DateTime.now`; tests override
/// the [clockProvider] with a deterministic `FakeClock.now`.
typedef Clock = DateTime Function();

/// Provides the active wall-clock function. Tests override this with
/// `clockProvider.overrideWithValue(fakeClock.now)` to drive midnight
/// transitions deterministically.
final Provider<Clock> clockProvider = Provider<Clock>((_) => DateTime.now);

DateTime _truncateToDay(DateTime t) => DateTime(t.year, t.month, t.day);

/// The caller's current local calendar day, truncated to local midnight.
///
/// Watched by `dailyMatchesProvider` so when the day rolls (via the
/// [MidnightInvalidator] timer or AppLifecycleListener.onResume), the
/// daily-matches RPC re-runs.
final StateProvider<DateTime> currentLocalDayProvider =
    StateProvider<DateTime>((Ref<DateTime> ref) {
  final clock = ref.watch(clockProvider);
  return _truncateToDay(clock());
});

/// Schedules a one-shot `Timer` to bump [currentLocalDayProvider] at the
/// next local midnight (+5s slack) AND listens for app-resume to handle
/// the case where the OS suspended the process across a midnight boundary.
///
/// Lifecycle: install the [midnightInvalidatorProvider] eagerly from
/// `app.dart` (e.g. via `ref.watch(midnightInvalidatorProvider)`) so the
/// timer registers at app start.
final NotifierProvider<MidnightInvalidator, void> midnightInvalidatorProvider =
    NotifierProvider<MidnightInvalidator, void>(MidnightInvalidator.new);

class MidnightInvalidator extends Notifier<void> {
  Timer? _timer;
  AppLifecycleListener? _lifecycle;

  @override
  void build() {
    _schedule();
    _lifecycle = AppLifecycleListener(onResume: bumpIfRolled);
    ref.onDispose(() {
      _timer?.cancel();
      _lifecycle?.dispose();
    });
  }

  void _schedule() {
    _timer?.cancel();
    final clock = ref.read(clockProvider);
    final now = clock();
    final nextMidnight =
        DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    final dur = nextMidnight.difference(now);
    // Add 5s slack so we never fire just before midnight due to clock drift.
    _timer = Timer(dur + const Duration(seconds: 5), () {
      bumpIfRolled();
      _schedule();
    });
  }

  /// Compares the truncated current clock day against the cached
  /// [currentLocalDayProvider] and bumps when the day has advanced. Safe to
  /// invoke from `AppLifecycleListener.onResume`.
  void bumpIfRolled() {
    final clock = ref.read(clockProvider);
    final today = _truncateToDay(clock());
    final current = ref.read(currentLocalDayProvider);
    if (today.isAfter(current)) {
      ref.read(currentLocalDayProvider.notifier).state = today;
    }
  }
}
