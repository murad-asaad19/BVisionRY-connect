// Phase 15 — RPC coverage gate.
//
// Asserts that every RPC named in [requiredRpcs] has at least one
// `rpc('name'` invocation somewhere under `lib/`. The canonical list is
// derived from the actual implementation (Phases 4–14) and from the spec
// §3 RPC registry. Out-of-scope RPCs (auth-side admin helpers, server-
// only utilities) are intentionally omitted.
import 'dart:io';

const requiredRpcs = <String>[
  // intros + warm intros (Phase 6)
  'send_intro',
  'accept_intro',
  'decline_intro',
  'intros_today_count',
  'send_warm_request',
  'forward_warm_intro',
  'suggest_warm_intros',
  // chat (Phase 7)
  'list_conversation_overview',
  'list_conversation_unread',
  'mark_conversation_read',
  'mute_conversation',
  'unmute_conversation',
  'edit_message',
  'delete_message',
  'send_image_message',
  'send_voice_message',
  // meetings + office hours (Phase 8)
  'propose_meeting',
  'confirm_meeting',
  'decline_meeting',
  'cancel_meeting',
  'submit_meeting_review',
  'pending_meeting_reviews',
  'get_meeting_playbook',
  'set_office_hours',
  'my_office_hours_settings',
  'list_upcoming_slots',
  'book_slot',
  'cancel_booking',
  'my_bookings',
  // opportunities (Phase 9)
  'list_opportunities',
  'get_opportunity',
  'create_opportunity',
  'update_opportunity',
  'close_opportunity',
  'express_interest',
  'list_my_opportunities',
  'list_interested',
  // privacy + settings (Phase 10)
  'block_user',
  'unblock_user',
  'list_blocked_users',
  'report_target',
  'set_private_mode',
  'export_my_data',
  // discovery (Phase 4)
  'get_daily_matches',
  'mark_match_viewed',
  'is_mutual_match',
  'search_discoverable_profiles',
  // profile (Phase 3)
  'get_public_profile',
  'get_profile_signals',
  // verification (Phase 11)
  'set_github_verification',
  'clear_github_verification',
  // connections (Phase 13)
  'list_connections',
  // push (Phase 12)
  'register_device_token',
  'unregister_device_token',
];

Future<void> main() async {
  final libDir = Directory('lib');
  if (!libDir.existsSync()) {
    stderr.writeln('lib/ directory not found — run from mobile_flutter/');
    exit(2);
  }
  final missing = <String>[];
  final allText = StringBuffer();
  await for (final entity in libDir.list(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      allText.write(await entity.readAsString());
      allText.write('\n');
    }
  }
  final text = allText.toString();
  for (final rpc in requiredRpcs) {
    final pattern = RegExp("rpc\\(\\s*['\"]$rpc['\"]");
    if (!pattern.hasMatch(text)) missing.add(rpc);
  }
  if (missing.isEmpty) {
    stdout.writeln('OK: all ${requiredRpcs.length} RPCs have callers.');
    exit(0);
  }
  stderr.writeln('MISSING callers for: ${missing.join(', ')}');
  exit(1);
}
