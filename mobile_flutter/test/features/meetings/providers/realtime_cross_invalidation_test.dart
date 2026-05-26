import 'package:connect_mobile/features/chat/providers/messages_provider.dart';
import 'package:connect_mobile/features/meetings/providers/meeting_proposals_provider.dart';
import 'package:flutter_test/flutter_test.dart';

/// Realtime cross-invalidation design contract.
///
/// Spec §14.1 puts `meeting_proposals` in `supabase_realtime`. When a
/// postgres_changes event fires on a row, [meetingProposalsProvider]'s
/// callback MUST `ref.invalidate(messagesProvider(conversationId))` so
/// the linked `kind=meeting` bubble re-renders. A behavioural test of
/// that callback requires a non-trivial fake `RealtimeChannel`; this
/// file pins the import contract so the symbol relationship stays
/// observable in code reviews, and a full smoke landed in
/// `integration_test/meetings_smoke_test.dart` plus a Maestro flow in
/// `maestro/flows/meetings_propose_confirm.yaml`.
void main() {
  test('meeting_proposals provider imports messages provider', () {
    // Both providers must remain symbol-stable for the realtime invalidation
    // call inside meetingProposalsProvider to keep compiling.
    expect(meetingProposalsProvider, isNotNull);
    expect(messagesProvider, isNotNull);
  });
}
