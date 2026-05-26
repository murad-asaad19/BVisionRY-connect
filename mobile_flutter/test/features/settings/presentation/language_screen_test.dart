// Phase 13 LanguageScreen test. The screen pulls the current locale from
// `localeProvider` and persists changes through `LanguageService`. The
// test substitutes a fake LanguageService that records `save` calls and
// asserts the provider is flipped after the tap resolves.
import 'package:connect_mobile/core/i18n/locale_loader.dart';
import 'package:connect_mobile/core/i18n/locale_notifier.dart';
import 'package:connect_mobile/core/theme/app_theme.dart';
import 'package:connect_mobile/features/settings/presentation/language_screen.dart';
import 'package:connect_mobile/features/settings/settings_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump.dart';

class _RecorderLanguageService extends LanguageService {
  Locale? savedLocale;

  @override
  Future<void> save(Locale locale) async {
    savedLocale = locale;
  }
}

void main() {
  testWidgets('Tapping Spanish persists + flips localeProvider',
      (WidgetTester tester) async {
    final _RecorderLanguageService svc = _RecorderLanguageService();
    final LocaleLoader loader = await primedLocaleLoader();
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        languageServiceProvider.overrideWithValue(svc),
        localeLoaderProvider.overrideWithValue(loader),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: buildAppTheme(Brightness.light),
          home: const LanguageScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('lang.es')));
    await tester.pumpAndSettle();
    expect(svc.savedLocale, const Locale('es'));
    expect(container.read(localeProvider).languageCode, 'es');
  });
}
