/// Mirror of the Postgres `public.goal_type` enum (spec §2.2). Wire values are
/// the strings the server expects in `profiles.goal_type` and on the
/// `infer-goal-type` edge function payloads.
enum GoalType {
  hire('hire'),
  beHired('be_hired'),
  coFound('co_found'),
  invest('invest'),
  takeInvestment('take_investment'),
  advise('advise'),
  findAdvisor('find_advisor'),
  peerConnect('peer_connect');

  const GoalType(this.wire);

  /// The snake_case string persisted in the database column and returned by
  /// the AI inference edge function.
  final String wire;

  /// i18n key for the user-facing label. Matches keys under
  /// `discovery.goalLabel.<wire>` in the locale JSON.
  String get i18nLabelKey => 'discovery.goalLabel.$wire';

  /// Parses a wire-format value back into the enum.
  ///
  /// Returns `null` for `null`/unknown values so the caller (e.g. JSON
  /// deserialisation) can treat unrecognised goal types as "not set" rather
  /// than failing hard — useful when the server adds new variants the client
  /// has not yet been updated to handle.
  static GoalType? fromWire(String? wire) {
    if (wire == null) return null;
    for (final GoalType v in values) {
      if (v.wire == wire) return v;
    }
    return null;
  }
}
