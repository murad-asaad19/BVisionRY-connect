import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/i18n/locale_notifier.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/toast.dart';

/// Root widget. Reads the router and active locale from Riverpod, awaits
/// the locale bundle through `localeReadyProvider`, and renders the
/// `MaterialApp.router` with the brand theme registered.
class ConnectApp extends ConsumerWidget {
  const ConnectApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final locale = ref.watch(localeProvider);
    // Subscribe so locale changes trigger a reload of the JSON bundle.
    ref.watch(localeReadyProvider);
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'BVisionry Connect',
      theme: buildAppTheme(Brightness.light),
      routerConfig: router,
      locale: locale,
      supportedLocales: const <Locale>[Locale('en'), Locale('es')],
      localizationsDelegates: const <LocalizationsDelegate<Object>>[
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      // Overlay the global ToastHost above the routed content so toasts
      // surfaced via `toastServiceProvider` from any screen are rendered.
      // The host paints a top-anchored Column that collapses to a
      // zero-size SizedBox when the queue is empty, so it never steals
      // hit-testing from the route below.
      builder: (BuildContext context, Widget? child) {
        return Stack(
          children: <Widget>[
            if (child != null) child,
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ToastHost(),
            ),
          ],
        );
      },
    );
  }
}
