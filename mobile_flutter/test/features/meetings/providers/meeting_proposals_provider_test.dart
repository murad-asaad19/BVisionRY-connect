import 'package:connect_mobile/features/meetings/providers/meeting_proposals_provider.dart';
import 'package:flutter_test/flutter_test.dart';

/// The realtime channel logic in [meetingProposalsProvider] needs a live
/// Supabase client to subscribe; that's covered by the Phase 8 integration
/// smoke and Maestro flow. This file pins the provider symbol so a
/// rename of the public surface trips compilation.
void main() {
  test('meetingProposalsProvider symbol is exported', () {
    expect(meetingProposalsProvider, isNotNull);
  });
}
