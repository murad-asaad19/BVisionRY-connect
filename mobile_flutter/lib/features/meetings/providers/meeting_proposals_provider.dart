import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_client.dart';
import '../../chat/providers/messages_provider.dart' as chat;
import '../domain/meeting_proposal.dart';

/// Realtime stream of `public.meeting_proposals` rows for a single
/// conversation. Spec §14.1 confirms `meeting_proposals` IS in
/// `supabase_realtime`, so we subscribe to postgres_changes and merge
/// INSERT / UPDATE / DELETE events into a local cache.
///
/// On any change, we ALSO invalidate
/// `chat.messagesProvider(conversationId)` so the linked `kind=meeting`
/// bubble re-renders with the new proposal state.
///
/// AutoDispose so leaving a thread releases the realtime channel.
final AutoDisposeStreamProviderFamily<List<MeetingProposal>, String>
    meetingProposalsProvider = StreamProvider.autoDispose
        .family<List<MeetingProposal>, String>((ref, conversationId) {
  final client = ref.watch(supabaseClientProvider);
  final controller = StreamController<List<MeetingProposal>>();
  final cache = <String, MeetingProposal>{};

  void emit() {
    final list = cache.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    controller.add(List.unmodifiable(list));
  }

  Future<void> initial() async {
    try {
      final rows = await client
          .from('meeting_proposals')
          .select()
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: false) as List<dynamic>;
      cache
        ..clear()
        ..addEntries(
          rows.cast<Map<String, dynamic>>().map((r) {
            final p = MeetingProposal.fromJson(r);
            return MapEntry(p.id, p);
          }),
        );
      emit();
    } catch (e, st) {
      if (!controller.isClosed) controller.addError(e, st);
    }
  }

  final channel = client.channel('meeting_proposals:$conversationId')
    ..onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'meeting_proposals',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'conversation_id',
        value: conversationId,
      ),
      callback: (payload) {
        switch (payload.eventType) {
          case PostgresChangeEvent.insert:
          case PostgresChangeEvent.update:
            final row = MeetingProposal.fromJson(payload.newRecord);
            cache[row.id] = row;
          case PostgresChangeEvent.delete:
            final id = payload.oldRecord['id'] as String?;
            if (id != null) cache.remove(id);
          // ignore: no_default_cases
          default:
            break;
        }
        emit();
        // Re-render any kind=meeting message bubbles bound to this
        // conversation — their state is keyed off the proposal row.
        ref.invalidate(chat.messagesProvider(conversationId));
      },
    )
    ..subscribe();

  initial();

  ref.onDispose(() {
    channel.unsubscribe();
    controller.close();
  });

  return controller.stream;
});
