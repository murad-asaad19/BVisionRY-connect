// test/helpers/intros_fixtures.dart
//
// Shared model fixtures for Phase 6 intro / connection tests. Always
// produce deterministic values (no DateTime.now()) so widget and golden
// tests can pin the rendered output without flake.
import 'package:connect_mobile/features/connections/domain/connection.dart';
import 'package:connect_mobile/features/intros/domain/intro.dart';
import 'package:connect_mobile/features/intros/domain/intro_enums.dart';
import 'package:connect_mobile/features/intros/domain/warm_suggestion.dart';

final DateTime kFixtureNow = DateTime.utc(2026, 5, 25);

Intro buildIntro({
  String id = 'intro-1',
  String senderId = 'sender-1',
  String recipientId = 'recipient-1',
  String? note,
  IntroState state = IntroState.delivered,
  IntroKind kind = IntroKind.direct,
  String? warmTargetId,
  String? conversationId,
  DateTime? expiresAt,
  DateTime? createdAt,
  DateTime? declinedAt,
}) {
  return Intro(
    id: id,
    senderId: senderId,
    recipientId: recipientId,
    note: note ?? ('x' * 100),
    state: state,
    kind: kind,
    warmTargetId: warmTargetId,
    conversationId: conversationId,
    expiresAt: expiresAt ?? kFixtureNow.add(const Duration(days: 14)),
    createdAt: createdAt ?? kFixtureNow,
    declinedAt: declinedAt,
  );
}

WarmSuggestion buildWarmSuggestion({
  String targetId = 'target-1',
  String targetHandle = 'alice',
  String targetName = 'Alice',
  String? targetPhotoUrl,
  String? targetPrimaryRole = 'founder',
  String? targetGoalType = 'cofounder',
  int mutualCount = 2,
  String topMutualId = 'mutual-1',
  String topMutualName = 'Mia',
  String topMutualHandle = 'mia',
}) {
  return WarmSuggestion(
    targetId: targetId,
    targetHandle: targetHandle,
    targetName: targetName,
    targetPhotoUrl: targetPhotoUrl,
    targetPrimaryRole: targetPrimaryRole,
    targetGoalType: targetGoalType,
    mutualCount: mutualCount,
    topMutualId: topMutualId,
    topMutualName: topMutualName,
    topMutualHandle: topMutualHandle,
  );
}

Connection buildConnection({
  String userId = 'peer-1',
  String handle = 'peer',
  String name = 'Peer',
  String? photoUrl,
  String? primaryRole = 'engineer',
  String conversationId = 'conv-1',
  DateTime? connectedAt,
}) {
  return Connection(
    userId: userId,
    handle: handle,
    name: name,
    photoUrl: photoUrl,
    primaryRole: primaryRole,
    conversationId: conversationId,
    connectedAt: connectedAt ?? DateTime.utc(2026, 5, 20),
  );
}
