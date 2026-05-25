import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'locale_loader.dart';
import 'locale_notifier.dart';

/// Convenience accessor for the active locale's translation table.
///
/// Reads the nearest [LocaleLoader] from the surrounding `ProviderScope`
/// without subscribing to rebuilds. Pair with `ref.watch(localeReadyProvider)`
/// at the top of the widget tree to ensure the loader has finished loading
/// the active locale before any `context.t(...)` call.
extension TranslateExt on BuildContext {
  String t(String key, {Map<String, Object>? vars}) {
    final ProviderContainer container =
        ProviderScope.containerOf(this, listen: false);
    final LocaleLoader loader = container.read(localeLoaderProvider);
    return loader.t(key, vars: vars);
  }
}
