import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/i18n.dart';
import '../../../core/routing/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/widgets.dart';
import '../data/auth_error_map.dart';
import '../providers/auth_service_provider.dart';
import 'auth_shell.dart';
import 'social_sign_in_buttons.dart';

/// Email + password sign-in form, aligned with gallery A3.
///
/// Three auth paths converge here:
///
/// 1. Tap **Sign in** → `authService.signInWithIdentifier(...)` (routes to
///    `signInWithPassword` for emails, or the `auth-handle-login` edge
///    function for `@handle`). The visible label is "Email" — the
///    controller still accepts a handle if a user types one, but the
///    gallery surface promises email only.
/// 2. Tap **Forgot password?** → `authService.sendMagicLink(...)`. This is
///    the only entry point for the magic-link path now that the standalone
///    button is gone (gallery has no separate "Send magic link" CTA).
/// 3. Tap an SSO button → `SocialAuthService.signInWithApple|Google`.
///
/// On success, the session changes propagate through `sessionProvider` and
/// `routeGuardProvider` triggers the navigator to redirect — this screen
/// never calls `context.go(...)` itself.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  String _identifier = '';
  String _password = '';
  bool _busy = false;
  String? _error;

  bool get _looksLikeEmail {
    final String s = _identifier.trim();
    if (s.startsWith('@')) return false;
    return s.contains('@') && s.contains('.');
  }

  Future<void> _runGuard(
    Future<void> Function() body,
    AuthMode mode,
  ) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await body();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = context.t(mapAuthError(e, mode)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _onSubmit() async {
    final String id = _identifier.trim();
    final String pwd = _password;
    if (id.isEmpty) {
      setState(() => _error = context.t('auth.errors.identifierRequired'));
      return;
    }
    if (pwd.isEmpty) {
      setState(() => _error = context.t('auth.errors.passwordRequired'));
      return;
    }
    await _runGuard(
      () async {
        await ref
            .read(authServiceProvider)
            .signInWithIdentifier(identifier: id, password: pwd);
      },
      AuthMode.signIn,
    );
  }

  Future<void> _onApple() => _runGuard(
        () async => ref.read(socialAuthServiceProvider).signInWithApple(),
        AuthMode.signIn,
      );

  Future<void> _onGoogle() => _runGuard(
        () async => ref.read(socialAuthServiceProvider).signInWithGoogle(),
        AuthMode.signIn,
      );

  /// Forgot-password tap → sends a magic link to the entered email. If the
  /// field is empty or doesn't look like an email, surfaces an inline
  /// instruction dialog instead of firing the request.
  Future<void> _onForgot() async {
    final String email = _identifier.trim();
    if (email.isEmpty || !_looksLikeEmail) {
      await showDialog<void>(
        context: context,
        builder: (BuildContext ctx) => AlertDialog(
          title: Text(ctx.t('auth.forgotPassword')),
          content: Text(ctx.t('auth.forgotPwdInstructions')),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }
    await _runGuard(
      () async {
        await ref.read(authServiceProvider).sendMagicLink(email);
        if (!mounted) return;
        ref.read(toastServiceProvider.notifier).showToast(
              title: context.t('auth.magicLinkSent'),
              intent: AppIntent.success,
            );
      },
      AuthMode.signIn,
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = Theme.of(context).extension<AppColors>()!;
    final AppSpacing spacing = Theme.of(context).extension<AppSpacing>()!;
    return AuthShell(
      tagline: context.t('auth.signInTagline'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            context.t('auth.signInTitle'),
            style: Theme.of(context).textTheme.displayMedium,
          ),
          SizedBox(height: spacing.section),
          SocialSignInButtons(
            onApple: _busy ? null : _onApple,
            onGoogle: _busy ? null : _onGoogle,
          ),
          SizedBox(height: spacing.gutter),
          AppDivider(label: context.t('signIn.or')),
          SizedBox(height: spacing.gutter),
          AppInput(
            key: const Key('identifier-input'),
            label: context.t('auth.email'),
            placeholder: context.t('auth.emailPlaceholder'),
            value: _identifier,
            onChanged: (String v) => setState(() => _identifier = v),
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            autofillHints: const <String>[AutofillHints.username],
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          AppInput(
            key: const Key('password-input'),
            label: context.t('auth.password'),
            placeholder: context.t('auth.passwordPlaceholder'),
            value: _password,
            onChanged: (String v) => setState(() => _password = v),
            obscureText: true,
            autofillHints: const <String>[AutofillHints.password],
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _onSubmit(),
          ),
          if (_error != null) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              _error!,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: colors.danger),
            ),
          ],
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              key: const Key('forgot-password-link'),
              onPressed: _busy ? null : _onForgot,
              child: Text(context.t('auth.forgotPassword')),
            ),
          ),
          AppButton(
            key: const Key('submit-button'),
            label: context.t('auth.submitSignIn'),
            onPressed: _busy ? null : _onSubmit,
            loading: _busy,
          ),
          // Sign-up entry — without this net-new users have no path
          // to /sign-up after the previous footer removal. The gallery
          // strips the link on the sign-up card, not the sign-in card.
          SizedBox(height: spacing.gutter),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                context.t('auth.noAccount'),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.muted,
                    ),
              ),
              TextButton(
                key: const Key('sign-up-link'),
                onPressed: _busy ? null : () => context.go(Routes.signUp),
                child: Text(context.t('auth.signUpCta')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
