// Phase 13 i18n parity test. Every locale must carry the Phase 13 settings
// keys; a missing entry would show as raw `settings.foo.bar` in the UI.
import 'package:connect_mobile/core/i18n/locale_loader.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final String code in const <String>['en', 'es']) {
    test('$code locale has Phase 13 settings keys', () async {
      final LocaleLoader loader = LocaleLoader();
      await loader.load(code);
      for (final String key in const <String>[
        'settings.notif.kind.opportunity_interest',
        'settings.notif.emailUnavailable',
        'settings.publicInvestorPage.title',
        'settings.publicInvestorPage.subtitle',
        'settings.publicInvestorPage.comingSoon',
        'settings.changePassword.title',
        'settings.changePassword.newPassword',
        'settings.changePassword.confirm',
        'settings.changePassword.tooShort',
        'settings.changePassword.success',
        'settings.deleteConfirm.typeWord',
        'settings.deleteConfirm.typedMismatch',
        'settings.tabs.networkRecentlyActive',
        'settings.tabs.networkEmptyTitle',
        'settings.tabs.networkEmptyBody',
        'settings.language.title',
        'settings.language.en',
        'settings.language.es',
      ]) {
        expect(
          loader.t(key),
          isNot(equals(key)),
          reason: '$code locale missing $key',
        );
      }
    });
  }
}
