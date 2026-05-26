// Phase 13 cold-start locale restoration smoke test. Mirrors the order
// `main.dart` performs: read [LanguageService.load] then push the result
// onto [localeProvider].
import 'package:connect_mobile/core/i18n/locale_notifier.dart';
import 'package:connect_mobile/features/settings/settings_providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Saved es locale is restored on cold start', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'connect.locale': 'es',
    });
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);
    final Locale saved = await container.read(languageServiceProvider).load();
    container.read(localeProvider.notifier).state = saved;
    expect(container.read(localeProvider).languageCode, 'es');
  });

  test('Missing locale falls back to en on cold start', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);
    final Locale saved = await container.read(languageServiceProvider).load();
    container.read(localeProvider.notifier).state = saved;
    expect(container.read(localeProvider).languageCode, 'en');
  });
}
