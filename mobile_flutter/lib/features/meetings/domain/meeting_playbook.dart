import 'package:freezed_annotation/freezed_annotation.dart';

part 'meeting_playbook.freezed.dart';

/// AI-generated briefing card returned by `get_meeting_playbook` (cache)
/// or the `meeting-playbook` edge function (regenerate). Spec §2.10
/// + §4.5.
///
/// Renders the four-section card seen in gallery G3:
/// summary, sharedInterests, conversationStarters, doNotes, dontNotes.
///
/// [canRegenerate] enforces the 1-hour client-side cooldown per spec.
/// The server has its own enforcement; this is purely a UX guard so
/// repeated taps don't spam the function.
@freezed
class MeetingPlaybook with _$MeetingPlaybook {
  const MeetingPlaybook._();

  const factory MeetingPlaybook({
    required String meetingId,
    required String viewerId,
    required String targetId,
    required String summary,
    required List<String> sharedInterests,
    required List<String> conversationStarters,
    required List<String> doNotes,
    required List<String> dontNotes,
    required DateTime generatedAt,
  }) = _MeetingPlaybook;

  /// Construct from a cached `get_meeting_playbook` row or the edge
  /// function's JSON response. Hand-rolled — wire format uses snake_case.
  static MeetingPlaybook fromJson(Map<String, dynamic> json) => MeetingPlaybook(
        meetingId: json['meeting_id'] as String,
        viewerId: json['viewer_id'] as String,
        targetId: json['target_id'] as String,
        summary: json['summary'] as String,
        sharedInterests:
            List<String>.from(json['shared_interests'] as List<dynamic>),
        conversationStarters:
            List<String>.from(json['conversation_starters'] as List<dynamic>),
        doNotes: List<String>.from(json['do_notes'] as List<dynamic>),
        dontNotes: List<String>.from(json['dont_notes'] as List<dynamic>),
        generatedAt: DateTime.parse(json['generated_at'] as String).toUtc(),
      );

  /// Per spec §4.5: regenerate is rate-limited to 1 hour client-side.
  bool get canRegenerate =>
      DateTime.now().toUtc().difference(generatedAt) >= const Duration(hours: 1);
}
