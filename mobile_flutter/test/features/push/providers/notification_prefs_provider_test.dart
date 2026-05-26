import 'package:connect_mobile/features/push/data/notification_preferences_service.dart';
import 'package:connect_mobile/features/push/domain/notification_channel.dart';
import 'package:connect_mobile/features/push/domain/notification_kind.dart';
import 'package:connect_mobile/features/push/domain/notification_preference.dart';
import 'package:connect_mobile/features/push/providers/notification_prefs_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeService implements NotificationPreferencesService {
  _FakeService(this.prefs);
  final List<NotificationPreference> prefs;

  @override
  Future<List<NotificationPreference>> listMyPreferences() async => prefs;

  @override
  Future<void> setPreference({
    required NotificationKind kind,
    required NotificationChannel channel,
    required bool enabled,
  }) async {}
}

void main() {
  test('notificationPrefsProvider returns the gateway list', () async {
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        notificationPrefsServiceProvider.overrideWithValue(
          _FakeService(<NotificationPreference>[
            const NotificationPreference(
              userId: 'u1',
              kind: NotificationKind.messageReceived,
              channel: NotificationChannel.push,
              enabled: false,
            ),
          ]),
        ),
      ],
    );
    addTearDown(container.dispose);

    final List<NotificationPreference> prefs =
        await container.read(notificationPrefsProvider.future);
    expect(prefs, hasLength(1));
  });

  test('matrix.isEnabled defaults to true when no row exists', () async {
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        notificationPrefsServiceProvider.overrideWithValue(
          _FakeService(<NotificationPreference>[
            const NotificationPreference(
              userId: 'u1',
              kind: NotificationKind.messageReceived,
              channel: NotificationChannel.push,
              enabled: false,
            ),
          ]),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(notificationPrefsProvider.future);
    final NotificationPrefsMatrix matrix =
        container.read(notificationPrefsMatrixProvider).requireValue;
    expect(
      matrix.isEnabled(
        NotificationKind.messageReceived,
        NotificationChannel.push,
      ),
      isFalse,
    );
    expect(
      matrix.isEnabled(
        NotificationKind.introReceived,
        NotificationChannel.email,
      ),
      isTrue,
      reason: 'absent rows default to enabled=true',
    );
  });
}
