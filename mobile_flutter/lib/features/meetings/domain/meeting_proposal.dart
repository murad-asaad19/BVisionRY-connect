import 'package:freezed_annotation/freezed_annotation.dart';

import 'meeting_state.dart';

part 'meeting_proposal.freezed.dart';

/// One row from `public.meeting_proposals` (spec §2.7).
///
/// Carries the full lifecycle: the 1-3 proposed slots, the optional
/// confirmed slot, the meeting URL, the proposer's timezone, and the
/// current [MeetingState]. The model is created from RPC return rows
/// (`propose_meeting`, `confirm_meeting`, `decline_meeting`,
/// `cancel_meeting`) or the direct table SELECT used by
/// `meetingProposalsProvider`.
///
/// [isProposer] / [hasEnded] centralize the gating rules so widgets
/// can render without re-deriving them.
@freezed
class MeetingProposal with _$MeetingProposal {
  const MeetingProposal._();

  const factory MeetingProposal({
    required String id,
    required String conversationId,
    required String proposedById,
    required List<DateTime> slots,
    DateTime? confirmedSlot,
    required int durationMinutes,
    String? meetingUrl,
    required String timezone,
    required MeetingState state,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _MeetingProposal;

  factory MeetingProposal.fromJson(Map<String, dynamic> json) =>
      MeetingProposal(
        id: json['id'] as String,
        conversationId: json['conversation_id'] as String,
        proposedById: json['proposed_by_id'] as String,
        slots: (json['slots'] as List<dynamic>)
            .map((s) => DateTime.parse(s as String).toUtc())
            .toList(growable: false),
        confirmedSlot: json['confirmed_slot'] == null
            ? null
            : DateTime.parse(json['confirmed_slot'] as String).toUtc(),
        durationMinutes: (json['duration_minutes'] as num).toInt(),
        meetingUrl: json['meeting_url'] as String?,
        timezone: json['timezone'] as String,
        state: MeetingState.fromJson(json['state'] as String),
        createdAt: DateTime.parse(json['created_at'] as String).toUtc(),
        updatedAt: DateTime.parse(json['updated_at'] as String).toUtc(),
      );

  /// `true` when the supplied [userId] is the proposer. The proposer may
  /// only Cancel — they may NOT Confirm (server raises `42501`).
  bool isProposer(String userId) => proposedById == userId;

  /// `true` when the meeting is confirmed and the slot + duration has
  /// already elapsed. Used to gate review prompts client-side; the server
  /// enforces this in `pending_meeting_reviews`.
  bool get hasEnded {
    if (state != MeetingState.confirmed) return false;
    final slot = confirmedSlot;
    if (slot == null) return false;
    final endsAt = slot.add(Duration(minutes: durationMinutes));
    return endsAt.isBefore(DateTime.now().toUtc());
  }
}
