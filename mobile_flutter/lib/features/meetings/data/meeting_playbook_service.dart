import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_map.dart';
import '../../../core/supabase/supabase_client.dart';
import '../domain/meeting_playbook.dart';

/// Test-seam abstraction over the Supabase surface used by the meeting
/// playbook card: a single RPC (cache lookup) and a single edge function
/// (regenerate).
abstract class MeetingPlaybookGateway {
  Future<Object?> rpc(String name, {Map<String, dynamic>? params});
  Future<FunctionResponse> invokeFunction(String name, {Object? body});
}

class SupabaseMeetingPlaybookGateway implements MeetingPlaybookGateway {
  SupabaseMeetingPlaybookGateway(this._client);
  final SupabaseClient _client;

  @override
  Future<Object?> rpc(String name, {Map<String, dynamic>? params}) =>
      _client.rpc(name, params: params);

  @override
  Future<FunctionResponse> invokeFunction(String name, {Object? body}) =>
      _client.functions.invoke(name, body: body);
}

/// Backs spec §4.5 — the AI-briefing card shown in gallery G3.
///
/// `fetchPlaybook` reads the cached row via `get_meeting_playbook` and
/// returns null when there's nothing cached (so the UI can show the
/// "Generate playbook" CTA). `regeneratePlaybook` invokes the
/// `meeting-playbook` edge function with `force: true`; the function
/// rate-limits server-side, the client adds a 1-hour cooldown via
/// [MeetingPlaybook.canRegenerate].
class MeetingPlaybookService {
  MeetingPlaybookService(this._gateway);
  final MeetingPlaybookGateway _gateway;

  /// Returns the cached row, or `null` when no row exists yet.
  Future<MeetingPlaybook?> fetchPlaybook(String meetingId) async {
    try {
      final raw = await _gateway.rpc(
        'get_meeting_playbook',
        params: <String, dynamic>{'p_meeting_id': meetingId},
      );
      if (raw is List) {
        if (raw.isEmpty) return null;
        return MeetingPlaybook.fromJson(
          Map<String, dynamic>.from(raw.first as Map),
        );
      }
      if (raw == null) return null;
      return MeetingPlaybook.fromJson(Map<String, dynamic>.from(raw as Map));
    } on PostgrestException catch (e) {
      throw mapPostgrestError(e);
    }
  }

  /// Calls the `meeting-playbook` edge function. The server returns the
  /// freshly generated row (or 429 / 500 on failure).
  Future<MeetingPlaybook> regeneratePlaybook(
    String meetingId, {
    bool force = true,
  }) async {
    try {
      final res = await _gateway.invokeFunction(
        'meeting-playbook',
        body: <String, dynamic>{'meeting_id': meetingId, 'force': force},
      );
      if (res.status >= 400 || res.data == null) {
        throw GenericAppException(res);
      }
      return MeetingPlaybook.fromJson(
        Map<String, dynamic>.from(res.data as Map),
      );
    } on FunctionException catch (e) {
      throw GenericAppException(e);
    }
  }
}

final Provider<MeetingPlaybookService> meetingPlaybookServiceProvider =
    Provider<MeetingPlaybookService>((Ref<MeetingPlaybookService> ref) {
  return MeetingPlaybookService(
    SupabaseMeetingPlaybookGateway(ref.watch(supabaseClientProvider)),
  );
});
