import 'package:connect_mobile/features/push/domain/notification_channel.dart';
import 'package:connect_mobile/features/push/domain/notification_kind.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('NotificationKind exposes all 10 DB enum values', () {
    expect(
      NotificationKind.values.map((NotificationKind k) => k.dbValue).toSet(),
      <String>{
        'intro_received',
        'intro_accepted',
        'message_received',
        'voice_received',
        'meeting_reminder',
        'daily_matches_ready',
        'goal_staleness',
        'meeting_proposal',
        'meeting_confirmed',
        'opportunity_interest',
      },
    );
  });

  test('NotificationKind.fromDb is round-trip safe', () {
    for (final NotificationKind k in NotificationKind.values) {
      expect(NotificationKind.fromDb(k.dbValue), equals(k));
    }
    expect(NotificationKind.fromDb('not_a_kind'), isNull);
    expect(NotificationKind.fromDb(null), isNull);
  });

  test('NotificationKind.i18nLabelKey maps to settings.notif.kind.* keys', () {
    expect(
      NotificationKind.introReceived.i18nLabelKey,
      equals('settings.notif.kind.intro_received'),
    );
    expect(
      NotificationKind.opportunityInterest.i18nLabelKey,
      equals('settings.notif.kind.opportunity_interest'),
    );
  });

  test('NotificationChannel exposes push, email, in_app', () {
    expect(
      NotificationChannel.values
          .map((NotificationChannel c) => c.dbValue)
          .toSet(),
      <String>{'push', 'email', 'in_app'},
    );
  });

  test('NotificationChannel.fromDb is round-trip safe', () {
    for (final NotificationChannel c in NotificationChannel.values) {
      expect(NotificationChannel.fromDb(c.dbValue), equals(c));
    }
    expect(NotificationChannel.fromDb('telegram'), isNull);
  });

  test('NotificationChannel.i18nLabelKey -> settings.notif.channel.*', () {
    expect(
      NotificationChannel.push.i18nLabelKey,
      equals('settings.notif.channel.push'),
    );
    expect(
      NotificationChannel.inApp.i18nLabelKey,
      equals('settings.notif.channel.in_app'),
    );
  });
}
