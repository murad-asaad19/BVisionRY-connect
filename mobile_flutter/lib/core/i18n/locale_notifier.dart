import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'locale_loader.dart';

/// Singleton [LocaleLoader] shared across the app. Replace in tests by
/// overriding this provider on the `ProviderScope`.
final Provider<LocaleLoader> localeLoaderProvider =
    Provider<LocaleLoader>((Ref<LocaleLoader> ref) => LocaleLoader());

/// Currently selected [Locale]. Defaults to English; updated by the
/// settings screen or the system fallback in `ConnectApp`.
final StateProvider<Locale> localeProvider =
    StateProvider<Locale>((Ref<Locale> ref) => const Locale('en'));

/// Triggers a load of the active locale into the [LocaleLoader] singleton.
/// Watch this provider near the top of the widget tree (e.g. in `ConnectApp`
/// and in any test that calls `context.t(...)`) to ensure translations are
/// available before reading them.
final FutureProvider<void> localeReadyProvider =
    FutureProvider<void>((Ref<void> ref) async {
  final LocaleLoader loader = ref.watch(localeLoaderProvider);
  final Locale locale = ref.watch(localeProvider);
  final String code = locale.languageCode;
  // Wire `package:intl` so every DateFormat / number / relative-time render
  // follows the active language instead of falling back to en_US. Done
  // atomically with the JSON bundle load on every locale switch.
  Intl.defaultLocale = code;
  await initializeDateFormatting(code);
  if (loader.code != code) {
    await loader.load(code);
  }
});
