import 'package:connect_mobile/features/push/domain/notification_channel.dart';
import 'package:connect_mobile/features/push/domain/notification_kind.dart';
import 'package:connect_mobile/features/push/domain/notification_preference.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fromJson parses a row from notification_preferences', () {
    final Map<String, dynamic> row = <String, dynamic>{
      'user_id': 'uid-1',
      'kind': 'message_received',
      'channel': 'push',
      'enabled': false,
    };
    final NotificationPreference pref = NotificationPreference.fromJson(row);
    expect(pref.userId, 'uid-1');
    expect(pref.kind, NotificationKind.messageReceived);
    expect(pref.channel, NotificationChannel.push);
    expect(pref.enabled, isFalse);
  });

  test('fromJson defaults enabled=true when the column is null', () {
    final NotificationPreference pref =
        NotificationPreference.fromJson(<String, dynamic>{
      'user_id': 'uid-1',
      'kind': 'intro_received',
      'channel': 'email',
      'enabled': null,
    });
    expect(pref.enabled, isTrue);
  });

  test('fromJson throws on unknown kind/channel', () {
    expect(
      () => NotificationPreference.fromJson(<String, dynamic>{
        'user_id': 'uid-1',
        'kind': 'mystery_kind',
        'channel': 'push',
        'enabled': true,
      }),
      throwsFormatException,
    );
  });

  test('default enabled is true (matches should_notify default-open)', () {
    final NotificationPreference pref = NotificationPreference.defaultEnabled(
      userId: 'uid-1',
      kind: NotificationKind.introReceived,
      channel: NotificationChannel.push,
    );
    expect(pref.enabled, isTrue);
  });
}
