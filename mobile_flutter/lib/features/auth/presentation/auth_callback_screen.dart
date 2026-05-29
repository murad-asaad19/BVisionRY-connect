import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/i18n.dart';
import '../../../core/routing/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/widgets.dart';
import '../data/auth_error_map.dart';
import '../providers/auth_service_provider.dart';

/// Catches the OAuth / magic-link deep-link redirect at `connect-mobile://auth`.
///
/// Pure transition surface: while [AuthService.createSessionFromUrl] runs we
/// show a centred spinner; on success we render nothing more — the session
/// change emits through `sessionProvider` and `routeGuardProvider` fires the
/// real navigation. On failure the screen surfaces the mapped error message
/// plus two recovery actions (retry the exchange, or bounce back to
/// `/sign-in`).
class AuthCallbackScreen extends ConsumerStatefulWidget {
  const AuthCallbackScreen({super.key, required this.uri});

  /// The full deep-link URL — either `?code=...` (PKCE) or `#access_token=...`
  /// (implicit). Forwarded as-is to [AuthService.createSessionFromUrl].
  final Uri uri;

  @override
  ConsumerState<AuthCallbackScreen> createState() => _AuthCallbackScreenState();
}

class _AuthCallbackScreenState extends ConsumerState<AuthCallbackScreen> {
  bool _busy = true;
  String? _errorKey;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  Future<void> _run() async {
    if (!mounted) return;
    setState(() {
      _busy = true;
      _errorKey = null;
    });
    try {
      await ref.read(authServiceProvider).createSessionFromUrl(widget.uri);
      // Session change emits via sessionProvider; routeGuardProvider
      // will redirect to /home or /onboarding/goal as appropriate.
    } catch (e) {
      if (mounted) {
        setState(() => _errorKey = mapAuthError(e, AuthMode.signIn));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _backToSignIn() {
    final GoRouter? router = GoRouter.maybeOf(context);
    if (router != null) {
      router.go(Routes.signIn);
    } else if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = Theme.of(context).extension<AppColors>()!;
    return Scaffold(
      backgroundColor: colors.navy,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: (_busy || _errorKey == null)
                ? CircularProgressIndicator(color: colors.white)
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        context.t(_errorKey ?? 'auth.errors.signInFailed'),
                        style: TextStyle(
                          color: colors.white,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      AppButton(
                        key: const Key('callback-retry'),
                        label: context.t('common.retry'),
                        variant: AppButtonVariant.gold,
                        onPressed: _run,
                      ),
                      const SizedBox(height: 8),
                      AppButton(
                        key: const Key('callback-back-to-signin'),
                        label: context.t('auth.signInCta'),
                        variant: AppButtonVariant.outline,
                        onPressed: _backToSignIn,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
