import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/meetings_service.dart';
import '../domain/meeting_proposal.dart';

/// `pending_meeting_reviews` (spec §3.5) — list of confirmed meetings the
/// caller still owes a review on. When [conversationId] is `null` the
/// server returns the full inbox of pending reviews (used by the home
/// banner / settings; Phase 8 only consumes the conversation-scoped
/// variant for the inline review strip).
///
/// AutoDispose: the review strip lives inside `ChatScreen` whose lifetime
/// matches the conversation; refreshing happens via
/// `ref.invalidate(pendingMeetingReviewsProvider(conversationId))` after
/// `submit_meeting_review` succeeds.
final AutoDisposeFutureProviderFamily<List<MeetingProposal>, String?>
    pendingMeetingReviewsProvider = FutureProvider.autoDispose
        .family<List<MeetingProposal>, String?>((ref, conversationId) async {
  final svc = ref.watch(meetingsServiceProvider);
  return svc.pendingMeetingReviews(conversationId: conversationId);
});
