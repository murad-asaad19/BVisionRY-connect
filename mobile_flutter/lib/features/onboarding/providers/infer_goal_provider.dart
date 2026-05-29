import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/infer_goal_service.dart';

/// State machine for the AI-driven goal-type chip pre-selector.
///
/// • [InferIdle] — text is too short, no inference attempted yet, or the
///   user just reset the flow.
/// • [Inferring] — debounce elapsed; service call in flight.
/// • [Inferred] — service returned a result (confidence may still be low).
/// • [InferFailed] — service threw; the UI shows a fallback hint.
sealed class InferGoalState {
  const InferGoalState();
}

class InferIdle extends InferGoalState {
  const InferIdle();
  @override
  bool operator ==(Object other) => other is InferIdle;
  @override
  int get hashCode => 0;
}

class Inferring extends InferGoalState {
  const Inferring();
  @override
  bool operator ==(Object other) => other is Inferring;
  @override
  int get hashCode => 1;
}

class Inferred extends InferGoalState {
  const Inferred(this.result);
  final InferGoalResult result;
}

class InferFailed extends InferGoalState {
  const InferFailed(this.error);
  final Object error;
}

/// Debounced controller for [InferGoalService].
///
/// Two superseding mechanisms keep the state monotonic w.r.t. user input:
///
/// 1. The debounce timer is cancelled on every new request, so only the
///    final keystroke in a typing burst actually triggers a network call.
/// 2. Every fired call captures a monotonically-increasing sequence ticket;
///    once a newer request lands the stale call's result/error is ignored
///    on arrival (the user may have typed past the inferred answer).
class InferGoalNotifier extends Notifier<InferGoalState> {
  Timer? _timer;
  int _seq = 0;

  /// Matches `mobile/src/features/profile/useInferGoal.ts` — wait 800ms of
  /// inactivity before firing.
  static const Duration debounce = Duration(milliseconds: 800);

  /// Don't waste a network call on near-empty input. Matches the gate the
  /// React Native client uses (`text.trim().length >= 20`).
  static const int minChars = 20;

  @override
  InferGoalState build() {
    ref.onDispose(() => _timer?.cancel());
    return const InferIdle();
  }

  /// Schedules an inference call after [debounce]. Subsequent calls before
  /// the timer fires cancel and replace it.
  void requestInference({
    required String text,
    String? primaryRole,
    List<String>? roles,
  }) {
    _timer?.cancel();
    if (text.trim().length < minChars) {
      _seq++; // invalidate any in-flight call
      state = const InferIdle();
      return;
    }
    // Clear any stale Inferred/InferFailed result the moment the user edits
    // again, so the "we couldn't infer your goal" warning never lingers over
    // a field the user is still typing into. The next debounce tick will
    // surface Inferring → Inferred/InferFailed once a real attempt resolves.
    if (state is Inferred || state is InferFailed) {
      state = const InferIdle();
    }
    final int ticket = ++_seq;
    _timer = Timer(debounce, () async {
      state = const Inferring();
      try {
        final InferGoalResult result =
            await ref.read(inferGoalServiceProvider).infer(
                  text: text,
                  primaryRole: primaryRole,
                  roles: roles,
                );
        if (ticket != _seq) return; // superseded
        state = Inferred(result);
      } on Object catch (e) {
        if (ticket != _seq) return;
        state = InferFailed(e);
      }
    });
  }

  /// Cancels any pending timer/in-flight call and rewinds to [InferIdle].
  void reset() {
    _timer?.cancel();
    _seq++;
    state = const InferIdle();
  }
}

final NotifierProvider<InferGoalNotifier, InferGoalState> inferGoalProvider =
    NotifierProvider<InferGoalNotifier, InferGoalState>(
  InferGoalNotifier.new,
);
