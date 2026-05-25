/// Lifecycle states of a row in `public.intros` (spec §2.3 enum
/// `intro_state`).
///
/// `delivered` is the initial state after the safety check passes;
/// `accepted` / `declined` are recipient-driven transitions;
/// `expired` is set by the nightly cron after `expires_at` lapses while
/// still `delivered`; `connected` is the terminal state once a chat is
/// opened from an accepted intro.
enum IntroState {
  delivered,
  accepted,
  declined,
  expired,
  connected;

  String toJson() => name;

  /// Throws [ArgumentError] when [raw] is not one of the five canonical
  /// values — callers should pass server data only.
  static IntroState fromJson(String raw) {
    for (final v in IntroState.values) {
      if (v.name == raw) return v;
    }
    throw ArgumentError.value(raw, 'IntroState', 'unknown intro_state');
  }
}

/// Kind of intro (spec §2.3 enum `intro_kind`).
///
/// - `direct` — A → B compose flow.
/// - `warm_request` — A asks mutual M to introduce them to target T.
/// - `warm_forward` — the resulting M → T row after M accepts the request.
///
/// Enum names use Dart `camelCase` and `json` carries the wire string
/// (`warm_request` / `warm_forward`) so JSON conversion is explicit.
enum IntroKind {
  direct('direct'),
  warmRequest('warm_request'),
  warmForward('warm_forward');

  const IntroKind(this.json);
  final String json;

  String toJson() => json;

  /// Throws [ArgumentError] when [raw] is not one of the three canonical
  /// values.
  static IntroKind fromJson(String raw) {
    for (final v in IntroKind.values) {
      if (v.json == raw) return v;
    }
    throw ArgumentError.value(raw, 'IntroKind', 'unknown intro_kind');
  }
}
