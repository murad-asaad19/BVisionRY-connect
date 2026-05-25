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

/// Identifier-or-email + password sign-in form.
///
/// Three auth paths converge here:
///
/// 1. Tap **Sign in** → `authService.signInWithIdentifier(...)` (routes to
///    `signInWithPassword` for emails, or the `auth-handle-login` edge
///    function for `@handle`).
/// 2. Tap **Send magic link** → `authService.sendMagicLink(...)`, only if
///    the identifier looks like a full email (`a@b.c` shape).
/// 3. Tap an SSO button → `SocialAuthService.signInWithApple|Google`.
///
/// On success, the session changes propagate through `sessionProvider` and
/// `routeGuardProvider` triggers the navigator to redirect — this screen
/// never calls `context.go(...)` itself except for the SignUp link.
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
    await _runGuard(() async {
      await ref
          .read(authServiceProvider)
          .signInWithIdentifier(identifier: id, password: pwd);
    }, AuthMode.signIn);
  }

  Future<void> _onMagicLink() async {
    final String email = _identifier.trim();
    if (email.isEmpty || !_looksLikeEmail) {
      setState(() => _error = context.t('auth.errors.magicLinkNeedsEmail'));
      return;
    }
    await _runGuard(() async {
      await ref.read(authServiceProvider).sendMagicLink(email);
      if (!mounted) return;
      ref
          .read(toastServiceProvider.notifier)
          .showToast(
            title: context.t('auth.magicLinkSent'),
            intent: AppIntent.success,
          );
    }, AuthMode.signIn);
  }

  Future<void> _onApple() => _runGuard(
    () async => ref.read(socialAuthServiceProvider).signInWithApple(),
    AuthMode.signIn,
  );

  Future<void> _onGoogle() => _runGuard(
    () async => ref.read(socialAuthServiceProvider).signInWithGoogle(),
    AuthMode.signIn,
  );

  Future<void> _onForgot() async {
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
          const SizedBox(height: 6),
          Text(
            context.t('auth.signInTagline'),
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: colors.muted),
          ),
          SizedBox(height: spacing.section),
          AppInput(
            key: const Key('identifier-input'),
            label: context.t('auth.emailOrUsername'),
            placeholder: context.t('auth.identifierPlaceholder'),
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
          const SizedBox(height: 8),
          AppButton(
            key: const Key('magic-link-button'),
            label: context.t('auth.magicLinkSubmit'),
            onPressed: _busy ? null : _onMagicLink,
            variant: AppButtonVariant.outline,
          ),
          SizedBox(height: spacing.section),
          AppDivider(label: context.t('signIn.or')),
          SizedBox(height: spacing.gutter),
          SocialSignInButtons(
            onApple: _busy ? null : _onApple,
            onGoogle: _busy ? null : _onGoogle,
          ),
          SizedBox(height: spacing.section),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(context.t('auth.noAccount')),
              const SizedBox(width: 6),
              TextButton(
                key: const Key('go-to-sign-up'),
                onPressed: _busy ? null : () => context.push(Routes.signUp),
                child: Text(context.t('auth.signUpCta')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
