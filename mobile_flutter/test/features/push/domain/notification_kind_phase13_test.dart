// Phase 13 augmentation of [NotificationKind] — assert the `hasEmitter`
// flag mirrors spec §17.4 (only 4 kinds currently have no server emitter).
import 'package:connect_mobile/features/push/domain/notification_channel.dart';
import 'package:connect_mobile/features/push/domain/notification_kind.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('NotificationKind exposes 10 values per spec §2.16', () {
    expect(NotificationKind.values.length, 10);
  });

  test('NotificationKind.uiMatrixOrder lists 10 rows in display order', () {
    expect(NotificationKind.uiMatrixOrder.length, 10);
    expect(
      NotificationKind.uiMatrixOrder.first,
      NotificationKind.introReceived,
    );
  });

  test('NotificationKind.hasEmitter is false only for the 4 §17.4 kinds', () {
    // No-emitter kinds.
    expect(NotificationKind.introAccepted.hasEmitter, isFalse);
    expect(NotificationKind.meetingReminder.hasEmitter, isFalse);
    expect(NotificationKind.dailyMatchesReady.hasEmitter, isFalse);
    expect(NotificationKind.goalStaleness.hasEmitter, isFalse);
    // Emitter-wired kinds.
    expect(NotificationKind.introReceived.hasEmitter, isTrue);
    expect(NotificationKind.messageReceived.hasEmitter, isTrue);
    expect(NotificationKind.voiceReceived.hasEmitter, isTrue);
    expect(NotificationKind.meetingProposal.hasEmitter, isTrue);
    expect(NotificationKind.meetingConfirmed.hasEmitter, isTrue);
    expect(NotificationKind.opportunityInterest.hasEmitter, isTrue);
  });

  test('NotificationChannel exposes 3 channels with stable dbValues', () {
    expect(NotificationChannel.values.length, 3);
    expect(NotificationChannel.push.dbValue, 'push');
    expect(NotificationChannel.email.dbValue, 'email');
    expect(NotificationChannel.inApp.dbValue, 'in_app');
  });
}
