import 'package:connect_mobile/core/i18n/locale_loader.dart';
import 'package:connect_mobile/features/push/domain/notification_channel.dart';
import 'package:connect_mobile/features/push/domain/notification_kind.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Every NotificationKind has a settings.notif.kind.* label in en + es',
      () async {
    for (final String code in const <String>['en', 'es']) {
      final LocaleLoader loader = LocaleLoader();
      await loader.load(code);
      for (final NotificationKind k in NotificationKind.values) {
        final String v = loader.t(k.i18nLabelKey);
        expect(
          v,
          isNot(equals(k.i18nLabelKey)),
          reason: 'missing $code/${k.i18nLabelKey}',
        );
      }
      for (final NotificationChannel c in NotificationChannel.values) {
        final String v = loader.t(c.i18nLabelKey);
        expect(
          v,
          isNot(equals(c.i18nLabelKey)),
          reason: 'missing $code/${c.i18nLabelKey}',
        );
      }
    }
  });

  test('push.* keys are present in en + es', () async {
    const List<String> required = <String>[
      'push.permissionDeniedTitle',
      'push.permissionDeniedBody',
      'push.toastOpenA11y',
      'push.toastDismissA11y',
    ];
    for (final String code in const <String>['en', 'es']) {
      final LocaleLoader loader = LocaleLoader();
      await loader.load(code);
      for (final String key in required) {
        final String v = loader.t(key);
        expect(v, isNot(equals(key)), reason: 'missing $code/$key');
      }
    }
  });
}
