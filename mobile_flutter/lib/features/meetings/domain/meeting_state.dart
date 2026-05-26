/// Lifecycle state of a `public.meeting_proposals` row (spec §2.7).
///
/// Mapped 1:1 with the `meeting_state` DB enum.
/// - [proposed]: created by the proposer; awaiting the recipient's decision.
/// - [confirmed]: recipient picked a slot; meeting is locked in.
/// - [declined]: recipient said no; flow ends.
/// - [cancelled]: proposer pulled the offer before confirmation.
enum MeetingState {
  proposed,
  confirmed,
  declined,
  cancelled;

  /// Parse a DB string value into a [MeetingState]. Throws [ArgumentError]
  /// for unknown values so a backend schema drift surfaces immediately
  /// instead of silently mis-rendering the bubble.
  static MeetingState fromJson(String value) => switch (value) {
        'proposed' => MeetingState.proposed,
        'confirmed' => MeetingState.confirmed,
        'declined' => MeetingState.declined,
        'cancelled' => MeetingState.cancelled,
        _ => throw ArgumentError('Unknown MeetingState: $value'),
      };

  /// Wire value, matching the DB enum verbatim.
  String toJson() => name;

  /// `true` while the recipient may still confirm or decline.
  bool get isOpen => this == MeetingState.proposed;
}
