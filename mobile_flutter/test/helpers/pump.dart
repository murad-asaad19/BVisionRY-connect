// test/helpers/pump.dart
//
// Helpers for widget tests that need the i18n loader to be primed before
// `context.t(...)` calls.
//
// Loading the locale JSON via `rootBundle.loadString` is async, and a fresh
// `ProviderScope` per test resets the [LocaleLoader] singleton, racing the
// load against the test body. To keep widget tests deterministic we eagerly
// load the English locale into a shared [LocaleLoader] before the test
// renders and override `localeLoaderProvider` so every test reuses the
// already-primed loader.
import 'package:connect_mobile/core/i18n/locale_loader.dart';
import 'package:connect_mobile/core/i18n/locale_notifier.dart';
import 'package:connect_mobile/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

LocaleLoader? _cachedLoader;

/// Returns a [LocaleLoader] with the English bundle already loaded. Cached
/// across tests so loading the asset (≈4ms) only happens once per run.
Future<LocaleLoader> primedLocaleLoader() async {
  if (_cachedLoader != null) return _cachedLoader!;
  TestWidgetsFlutterBinding.ensureInitialized();
  final LocaleLoader loader = LocaleLoader();
  await loader.load('en');
  _cachedLoader = loader;
  return loader;
}

/// Pumps [child] (which must contain a [ProviderScope] / [MaterialApp]) and
/// waits for any pending frame work to settle so `context.t(...)` resolves
/// keys instead of returning the raw key string.
///
/// Pair this with [wrapWithTheme] which overrides the locale loader to a
/// pre-loaded instance — without that override, the loader's async hop can
/// outrace `pumpAndSettle` and leave the tree in the loading state.
Future<void> pumpWithI18n(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(child);
  await tester.pumpAndSettle();
}

/// Wraps [child] in a [ProviderScope] + [MaterialApp] with the brand theme
/// and forces the locale loader to hydrate before any `context.t` reads.
///
/// `localeLoaderProvider` is overridden with a pre-loaded singleton so
/// `context.t(...)` works synchronously on the first frame — no need for
/// the consumer to watch `localeReadyProvider`.
Future<Widget> wrapWithTheme({
  required Widget child,
  List<Override> overrides = const <Override>[],
}) async {
  final LocaleLoader loader = await primedLocaleLoader();
  return ProviderScope(
    overrides: <Override>[
      localeLoaderProvider.overrideWithValue(loader),
      ...overrides,
    ],
    child: MaterialApp(
      theme: buildAppTheme(Brightness.light),
      home: child,
    ),
  );
}
