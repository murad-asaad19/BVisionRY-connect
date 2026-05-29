import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/env.dart';
import 'core/i18n/locale_notifier.dart';
import 'core/push/background_tap_handler.dart';
import 'core/push/foreground_handler.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode.dart';
import 'core/widgets/toast.dart';
import 'core/widgets/variants.dart';
import 'features/auth/providers/authed_providers_registry.dart';
import 'features/auth/providers/session_provider.dart';
import 'features/push/providers/fcm_lifecycle_provider.dart';

/// Root widget. Reads the router and active locale from Riverpod, awaits
/// the locale bundle through `localeReadyProvider`, and renders the
/// `MaterialApp.router` with the brand theme registered.
///
/// Wraps the routed content in [_PushBootstrap] which, when
/// `Env.firebaseEnabled` is true, runs the FCM lifecycle bootstrap
/// (`fcmLifecycleProvider`) and attaches the foreground / background tap
/// handlers after the first frame.
class ConnectApp extends ConsumerWidget {
  const ConnectApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GoRouter router = ref.watch(appRouterProvider);
    final Locale locale = ref.watch(localeProvider);
    final ThemeMode themeMode = ref.watch(themeModeProvider);
    // Subscribe so locale changes trigger a reload of the JSON bundle.
    ref.watch(localeReadyProvider);
    return _LifecycleRefresh(
      child: _PushBootstrap(
        child: MaterialApp.router(
          debugShowCheckedModeBanner: false,
          title: 'BVisionry Connect',
          theme: buildAppTheme(Brightness.light),
          darkTheme: buildAppTheme(Brightness.dark),
          themeMode: themeMode,
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
        ),
      ),
    );
  }
}

/// Root-scope lifecycle observer that drops every authed Riverpod cache on
/// resume — closes T-LIFECYCLE so Inbox / Connections / Opportunities /
/// conversations don't render stale data after the app spent time in the
/// background. Realtime channels handle live updates while foregrounded;
/// this hook covers the gap when no live channel was open.
///
/// No-ops while signed-out so we don't churn an empty cache.
class _LifecycleRefresh extends ConsumerStatefulWidget {
  const _LifecycleRefresh({required this.child});
  final Widget child;

  @override
  ConsumerState<_LifecycleRefresh> createState() => _LifecycleRefreshState();
}

class _LifecycleRefreshState extends ConsumerState<_LifecycleRefresh>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final signedIn = ref.read(currentSessionProvider) != null;
    if (!signedIn) return;
    invalidateAuthedProvidersWithWidgetRef(ref);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Wires the FCM lifecycle + tap handlers after the first frame.
///
/// Why post-first-frame? `_kickoff` needs the [GoRouter] AND the
/// [ToastService] to be ready, plus must NOT block the initial paint.
/// Reading `fcmLifecycleProvider.future` here also surfaces any init
/// errors via the standard Riverpod error path.
class _PushBootstrap extends ConsumerStatefulWidget {
  const _PushBootstrap({required this.child});
  final Widget child;

  @override
  ConsumerState<_PushBootstrap> createState() => _PushBootstrapState();
}

class _PushBootstrapState extends ConsumerState<_PushBootstrap> {
  ForegroundHandler? _foreground;
  BackgroundTapHandler? _background;
  bool _kickedOff = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _kickoff());
  }

  Future<void> _kickoff() async {
    if (_kickedOff) return;
    _kickedOff = true;
    if (!Env.firebaseEnabled) return;

    // Wire lifecycle (init -> register -> onTokenRefresh). Best-effort:
    // a flaky init must never crash the app boot.
    try {
      await ref.read(fcmLifecycleProvider.future);
    } catch (_) {
      // Swallowed; FcmService also logs internally.
    }

    if (!mounted) return;

    final fcm = ref.read(fcmServiceProvider);
    final messaging = fcm.messaging;
    final ProviderContainer container =
        ProviderScope.containerOf(context, listen: false);
    final GoRouter router = ref.read(appRouterProvider);
    final ToastService toast = ref.read(toastServiceProvider.notifier);

    _foreground = ForegroundHandler(
      messaging: messaging,
      container: container,
      showToast: (String title, String body, String route) {
        toast.showToast(
          title: title,
          body: body,
          intent: AppIntent.info,
          onTap: () => router.go(route),
        );
      },
    )..subscribe();

    _background = BackgroundTapHandler(
      messaging: messaging,
      navigate: router.go,
    )..subscribe();
    await _background!.consumeInitialMessage();
  }

  @override
  void dispose() {
    _foreground?.dispose();
    _background?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
