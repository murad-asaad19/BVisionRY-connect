import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_map.dart';
import '../../../core/supabase/supabase_client.dart';
import '../domain/meeting_proposal.dart';
import '../domain/meeting_review.dart';

/// Test-seam abstraction over the Supabase RPC surface the meetings
/// feature touches. Six entry points map 1:1 to spec §3.5.
abstract class MeetingsGateway {
  Future<Object?> rpc(String name, {Map<String, dynamic>? params});
}

class SupabaseMeetingsGateway implements MeetingsGateway {
  SupabaseMeetingsGateway(this._client);
  final SupabaseClient _client;

  @override
  Future<Object?> rpc(String name, {Map<String, dynamic>? params}) =>
      _client.rpc(name, params: params);
}

/// Thin wrapper over the six meetings RPCs (spec §3.5).
///
/// All Postgrest errors are funnelled through [mapPostgrestError] so the
/// UI receives typed [AppException]s — in particular [ValidationException]
/// with a meetings-specific i18n key.
///
/// `proposeMeeting` validates client-side BEFORE hitting the network so a
/// user with no slots / bad URL / out-of-range duration gets immediate
/// inline feedback (matches the React Native composer behaviour and avoids
/// burning a round-trip on the most common input mistakes).
class MeetingsService {
  MeetingsService(this._gateway);
  final MeetingsGateway _gateway;

  /// `propose_meeting(p_conversation_id, p_slots, p_duration_minutes,
  /// p_meeting_url, p_timezone, p_preferred_slot_index, p_note)` returns
  /// the inserted row.
  ///
  /// [preferredSlotIndex] / [note] are forwarded only when set so older
  /// server versions that don't expose the new params keep working — the
  /// server ignores unknown named args.
  Future<MeetingProposal> proposeMeeting({
    required String conversationId,
    required List<DateTime> slots,
    required int durationMinutes,
    required String? meetingUrl,
    required String timezone,
    int? preferredSlotIndex,
    String? note,
  }) async {
    _validatePropose(
      slots: slots,
      durationMinutes: durationMinutes,
      meetingUrl: meetingUrl,
    );
    try {
      final raw = await _gateway.rpc(
        'propose_meeting',
        params: <String, dynamic>{
          'p_conversation_id': conversationId,
          'p_slots': slots.map((s) => s.toUtc().toIso8601String()).toList(),
          'p_duration_minutes': durationMinutes,
          'p_meeting_url': meetingUrl,
          'p_timezone': timezone,
          if (preferredSlotIndex != null)
            'p_preferred_slot_index': preferredSlotIndex,
          if (note != null && note.isNotEmpty) 'p_note': note,
        },
      );
      return MeetingProposal.fromJson(_normaliseRow(raw));
    } on PostgrestException catch (e) {
      throw mapPostgrestError(e);
    }
  }

  /// `confirm_meeting(p_meeting_id, p_slot)`. Per spec §3.5 the proposer
  /// CANNOT call this — the server raises `42501` and we surface it as
  /// [ForbiddenException]. The UI prevents this by hiding the Confirm
  /// button on the proposer's side.
  Future<MeetingProposal> confirmMeeting(
    String meetingId,
    DateTime slot,
  ) async {
    try {
      final raw = await _gateway.rpc(
        'confirm_meeting',
        params: <String, dynamic>{
          'p_meeting_id': meetingId,
          'p_slot': slot.toUtc().toIso8601String(),
        },
      );
      return MeetingProposal.fromJson(_normaliseRow(raw));
    } on PostgrestException catch (e) {
      throw mapPostgrestError(e);
    }
  }

  /// `decline_meeting(p_meeting_id)`. Either participant may decline a
  /// `proposed` row.
  Future<MeetingProposal> declineMeeting(String meetingId) async {
    try {
      final raw = await _gateway.rpc(
        'decline_meeting',
        params: <String, dynamic>{'p_meeting_id': meetingId},
      );
      return MeetingProposal.fromJson(_normaliseRow(raw));
    } on PostgrestException catch (e) {
      throw mapPostgrestError(e);
    }
  }

  /// `cancel_meeting(p_meeting_id)`. Only the proposer may cancel, and
  /// only while `state = 'proposed'` — the server enforces both.
  Future<MeetingProposal> cancelMeeting(String meetingId) async {
    try {
      final raw = await _gateway.rpc(
        'cancel_meeting',
        params: <String, dynamic>{'p_meeting_id': meetingId},
      );
      return MeetingProposal.fromJson(_normaliseRow(raw));
    } on PostgrestException catch (e) {
      throw mapPostgrestError(e);
    }
  }

  /// `submit_meeting_review(p_meeting_id, p_outcome, p_note)` returns the
  /// inserted row. The server enforces "meeting must have ended" and
  /// "caller is a participant".
  Future<MeetingReview> submitMeetingReview({
    required String meetingId,
    required MeetingReviewOutcome outcome,
    String? note,
  }) async {
    try {
      final raw = await _gateway.rpc(
        'submit_meeting_review',
        params: <String, dynamic>{
          'p_meeting_id': meetingId,
          'p_outcome': outcome.toJson(),
          'p_note': note,
        },
      );
      return MeetingReview.fromJson(_normaliseRow(raw));
    } on PostgrestException catch (e) {
      throw mapPostgrestError(e);
    }
  }

  /// `pending_meeting_reviews(p_conversation_id default null)` returns the
  /// list of meeting_proposals rows the caller still owes a review for.
  /// The server applies the "ended + no existing review by this user"
  /// filter; the client just renders whatever rows come back.
  Future<List<MeetingProposal>> pendingMeetingReviews({
    String? conversationId,
  }) async {
    try {
      final raw = await _gateway.rpc(
        'pending_meeting_reviews',
        params: <String, dynamic>{'p_conversation_id': conversationId},
      );
      final rows = (raw as List).cast<Map<String, dynamic>>();
      return rows.map(MeetingProposal.fromJson).toList(growable: false);
    } on PostgrestException catch (e) {
      throw mapPostgrestError(e);
    }
  }

  void _validatePropose({
    required List<DateTime> slots,
    required int durationMinutes,
    required String? meetingUrl,
  }) {
    if (slots.isEmpty || slots.length > 3) {
      throw ValidationException('meetings.propose.errors.slotsRange');
    }
    final now = DateTime.now().toUtc();
    for (final s in slots) {
      if (!s.toUtc().isAfter(now)) {
        throw ValidationException('meetings.propose.errors.slotsRange');
      }
    }
    if (durationMinutes < 15 || durationMinutes > 240) {
      throw ValidationException('meetings.propose.errors.duration');
    }
    if (meetingUrl != null &&
        meetingUrl.isNotEmpty &&
        !meetingUrl.startsWith('https://')) {
      throw ValidationException('meetings.propose.errors.url');
    }
  }

  Map<String, dynamic> _normaliseRow(Object? raw) {
    if (raw is List && raw.isNotEmpty) {
      return Map<String, dynamic>.from(raw.first as Map);
    }
    return Map<String, dynamic>.from(raw as Map);
  }
}

final Provider<MeetingsService> meetingsServiceProvider =
    Provider<MeetingsService>((Ref<MeetingsService> ref) {
  return MeetingsService(
    SupabaseMeetingsGateway(ref.watch(supabaseClientProvider)),
  );
});
