// Phase 13 routes-catalog test. Asserts the canonical paths for every
// settings + legal destination exist on [Routes]. Adding a new screen
// without wiring its constant here would fail this test.
import 'package:connect_mobile/core/routing/routes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Phase 13 route constants exist with the expected paths', () {
    expect(Routes.settingsLanguage, '/settings/language');
    expect(Routes.settings, '/settings');
    expect(Routes.settingsAccount, '/settings/account');
    expect(Routes.settingsPrivacy, '/settings/privacy');
    expect(Routes.settingsNotifications, '/settings/notifications');
    expect(Routes.settingsVerification, '/settings/verification');
    expect(Routes.settingsBlocked, '/settings/blocked-users');
    expect(Routes.settingsOfficeHours, '/settings/office-hours');
    expect(Routes.settingsHelp, '/settings/help');
    expect(Routes.legalPrivacy, '/legal/privacy');
    expect(Routes.legalTerms, '/legal/terms');
  });
}
