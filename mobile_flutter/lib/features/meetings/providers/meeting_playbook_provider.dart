import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/meeting_playbook_service.dart';
import '../domain/meeting_playbook.dart';

/// Cache-only fetch for the AI meeting briefing (spec §4.5).
///
/// Returns `null` when no cached row exists — the UI shows a "Generate
/// playbook" CTA in that state. Regeneration is a separate imperative
/// call on [MeetingPlaybookService.regeneratePlaybook]; after success,
/// invalidate this provider to refresh the cached row.
final AutoDisposeFutureProviderFamily<MeetingPlaybook?, String>
    meetingPlaybookProvider = FutureProvider.autoDispose
        .family<MeetingPlaybook?, String>((ref, meetingId) async {
  final svc = ref.watch(meetingPlaybookServiceProvider);
  return svc.fetchPlaybook(meetingId);
});
