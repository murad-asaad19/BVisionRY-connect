import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/error_map.dart';
import '../../../core/supabase/supabase_client.dart';
import '../domain/my_booking.dart';
import '../domain/office_hours_settings.dart';
import '../domain/office_hours_slot.dart';
import '../domain/office_hours_window.dart';

/// Test-seam abstraction over the Supabase surface the office-hours feature
/// touches. Mirrors the gateway pattern used by `MeetingsService` so tests
/// can fake every RPC without spinning up Supabase.
abstract class OfficeHoursGateway {
  Future<Object?> rpc(String name, {Map<String, dynamic>? params});

  /// Used by `conversationIdForProposal` to look up the canonical
  /// conversation id for a `meeting_proposals` row inserted by `book_slot`.
  Future<Map<String, dynamic>> meetingProposalById(String id);
}

class SupabaseOfficeHoursGateway implements OfficeHoursGateway {
  SupabaseOfficeHoursGateway(this._client);
  final SupabaseClient _client;

  @override
  Future<Object?> rpc(String name, {Map<String, dynamic>? params}) =>
      _client.rpc(name, params: params);

  @override
  Future<Map<String, dynamic>> meetingProposalById(String id) async {
    final row = await _client
        .from('meeting_proposals')
        .select('conversation_id')
        .eq('id', id)
        .single();
    return Map<String, dynamic>.from(row);
  }
}

/// Thin wrapper over the six office-hours RPCs (spec §3.6):
/// `set_office_hours`, `my_office_hours_settings`, `list_upcoming_slots`,
/// `book_slot`, `cancel_booking`, `my_bookings`.
///
/// All Postgrest errors are funnelled through [mapPostgrestError] so the
/// UI receives typed [AppException]s. The 10 `P0001` HINT values raised
/// by `book_slot` and `cancel_booking` map to dedicated subclasses such
/// as [SlotUnavailableException], [WeeklyCapException], etc.
class OfficeHoursService {
  OfficeHoursService(this._gateway);
  final OfficeHoursGateway _gateway;

  /// `set_office_hours(p_enabled, p_windows, p_slot_duration_minutes,
  /// p_max_bookings_per_week, p_buffer_minutes, p_meeting_link_template,
  /// p_notes_template)` returns the persisted [OfficeHoursSettings] row.
  Future<OfficeHoursSettings> setOfficeHours({
    required bool enabled,
    required List<OfficeHoursWindow> windows,
    required int slotDurationMinutes,
    required int maxBookingsPerWeek,
    required int bufferMinutes,
    String? meetingLinkTemplate,
    String? notesTemplate,
  }) async {
    try {
      final raw = await _gateway.rpc(
        'set_office_hours',
        params: <String, dynamic>{
          'p_enabled': enabled,
          'p_windows': windows.map((w) => w.toJson()).toList(growable: false),
          'p_slot_duration_minutes': slotDurationMinutes,
          'p_max_bookings_per_week': maxBookingsPerWeek,
          'p_buffer_minutes': bufferMinutes,
          'p_meeting_link_template': meetingLinkTemplate,
          'p_notes_template': notesTemplate,
        },
      );
      return OfficeHoursSettings.fromJson(_normaliseRow(raw));
    } on PostgrestException catch (e) {
      throw mapPostgrestError(e);
    }
  }

  /// `my_office_hours_settings()` — returns the caller's row (or the
  /// server-side defaults shape when no row exists yet).
  Future<OfficeHoursSettings> myOfficeHoursSettings() async {
    try {
      final raw = await _gateway.rpc('my_office_hours_settings');
      return OfficeHoursSettings.fromJson(_normaliseRow(raw));
    } on PostgrestException catch (e) {
      throw mapPostgrestError(e);
    }
  }

  /// `list_upcoming_slots(p_host)` — public, anon-allowed read of open
  /// future slots for [hostId] over the next 14 days.
  Future<List<OfficeHoursSlot>> listUpcomingSlots(String hostId) async {
    try {
      final raw = await _gateway.rpc(
        'list_upcoming_slots',
        params: <String, dynamic>{'p_host': hostId},
      );
      final rows = (raw as List).cast<dynamic>();
      return rows
          .map(
            (r) =>
                OfficeHoursSlot.fromJson(Map<String, dynamic>.from(r as Map)),
          )
          .toList(growable: false);
    } on PostgrestException catch (e) {
      throw mapPostgrestError(e);
    }
  }

  /// `book_slot(p_slot_id, p_topic)` — inserts a `meeting_proposals` row
  /// with `state = 'confirmed'` plus the `kind=meeting` chat bubble.
  ///
  /// Returns the new `meeting_proposal_id` (uuid).
  ///
  /// PUSH CONTRACT (spec §10.5):
  /// `book_slot` inserts a chat message (kind=meeting, state=confirmed) but
  /// `notify_message_inserted` suppresses the chat-message push for
  /// confirmed states. The host receives a canonical `meeting_confirmed`
  /// push instead. Phase 12 routes that payload to `/chats/:conversation_id`.
  Future<String> bookSlot({
    required String slotId,
    required String topic,
  }) async {
    try {
      final raw = await _gateway.rpc(
        'book_slot',
        params: <String, dynamic>{'p_slot_id': slotId, 'p_topic': topic},
      );
      return raw as String;
    } on PostgrestException catch (e) {
      throw mapPostgrestError(e);
    }
  }

  /// `cancel_booking(p_slot_id)` — either party may call. Slot reopens
  /// (vs cancels in place) when `starts_at > now() + 24h`.
  Future<void> cancelBooking(String slotId) async {
    try {
      await _gateway.rpc(
        'cancel_booking',
        params: <String, dynamic>{'p_slot_id': slotId},
      );
    } on PostgrestException catch (e) {
      throw mapPostgrestError(e);
    }
  }

  /// `my_bookings()` — list of upcoming bookings the caller holds.
  Future<List<MyBooking>> myBookings() async {
    try {
      final raw = await _gateway.rpc('my_bookings');
      final rows = (raw as List).cast<dynamic>();
      return rows
          .map((r) => MyBooking.fromJson(Map<String, dynamic>.from(r as Map)))
          .toList(growable: false);
    } on PostgrestException catch (e) {
      throw mapPostgrestError(e);
    }
  }

  /// Resolves the canonical `conversation_id` for a `meeting_proposals.id`.
  ///
  /// Used after `bookSlot` (and from the My Bookings card tap) to navigate
  /// to `/chats/:conversation_id` — the RPC doesn't return the conversation
  /// id directly, so we read it via the table.
  Future<String> conversationIdForProposal(String proposalId) async {
    try {
      final row = await _gateway.meetingProposalById(proposalId);
      return row['conversation_id'] as String;
    } on PostgrestException catch (e) {
      throw mapPostgrestError(e);
    }
  }

  Map<String, dynamic> _normaliseRow(Object? raw) {
    if (raw is List && raw.isNotEmpty) {
      return Map<String, dynamic>.from(raw.first as Map);
    }
    return Map<String, dynamic>.from(raw as Map);
  }
}

final Provider<OfficeHoursService> officeHoursServiceProvider =
    Provider<OfficeHoursService>((Ref<OfficeHoursService> ref) {
  return OfficeHoursService(
    SupabaseOfficeHoursGateway(ref.watch(supabaseClientProvider)),
  );
});
