import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/env.dart';
import '../../../core/i18n/i18n.dart';
import '../../../core/routing/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/widgets.dart';
import '../data/auth_error_map.dart';
import '../providers/auth_service_provider.dart';
import 'auth_shell.dart';
import 'password_field.dart';
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

/// The SSO provider whose request is currently in flight, if any — drives
/// the per-button spinner so only the tapped button shows progress.
enum _SsoInFlight { apple, google }

class _SignInScreenState extends ConsumerState<SignInScreen> {
  String _identifier = '';
  String _password = '';
  bool _busy = false;
  _SsoInFlight? _ssoInFlight;

  /// Top-of-form banner message key (network / rate-limit / cancellation /
  /// generic). Field-specific failures live in [_identifierError] /
  /// [_passwordError] instead.
  String? _bannerError;
  String? _identifierError;
  String? _passwordError;

  bool get _looksLikeEmail {
    final String s = _identifier.trim();
    if (s.startsWith('@')) return false;
    return s.contains('@') && s.contains('.');
  }

  void _clearErrors() {
    _bannerError = null;
    _identifierError = null;
    _passwordError = null;
  }

  /// Routes a mapped error key to the right surface: credential problems
  /// highlight the offending field(s); everything else lands in the banner.
  void _surfaceError(String mappedKey) {
    final String msg = context.t(mappedKey);
    switch (authErrorField(mappedKey)) {
      case AuthErrorField.identifier:
        // "Incorrect username, email, or password" is ambiguous across both
        // credential fields; the message names both, so anchoring it on the
        // labelled identifier field is enough to point the user at the fix.
        _identifierError = msg;
      case AuthErrorField.password:
        _passwordError = msg;
      case AuthErrorField.banner:
        _bannerError = mappedKey;
    }
  }

  Future<void> _runGuard(
    Future<void> Function() body,
    AuthMode mode, {
    _SsoInFlight? sso,
  }) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _ssoInFlight = sso;
      _clearErrors();
    });
    try {
      await body();
    } catch (e) {
      if (!mounted) return;
      setState(() => _surfaceError(mapAuthError(e, mode)));
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _ssoInFlight = null;
        });
      }
    }
  }

  Future<void> _onSubmit() async {
    final String id = _identifier.trim();
    final String pwd = _password;
    if (id.isEmpty) {
      setState(() {
        _clearErrors();
        _identifierError = context.t('auth.errors.identifierRequired');
      });
      return;
    }
    if (pwd.isEmpty) {
      setState(() {
        _clearErrors();
        _passwordError = context.t('auth.errors.passwordRequired');
      });
      return;
    }
    Haptics.light();
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
        sso: _SsoInFlight.apple,
      );

  Future<void> _onGoogle() => _runGuard(
        () async => ref.read(socialAuthServiceProvider).signInWithGoogle(),
        AuthMode.signIn,
        sso: _SsoInFlight.google,
      );

  /// Forgot-password tap → emails a one-tap sign-in (magic) link to the
  /// entered email. If the field is empty or doesn't look like an email,
  /// surfaces a localized instruction dialog instead of firing the request.
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
              child: Text(ctx.t('common.ok')),
            ),
          ],
        ),
      );
      return;
    }
    Haptics.light();
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
      // Mockup A3: the wordmark sub-line reads "Welcome back" and the card
      // heading reads "Sign in" — the inverse of how the copy was wired.
      tagline: context.t('auth.signInTagline'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            context.t('auth.signInHeading'),
            style: Theme.of(context).textTheme.displayMedium,
          ),
          SizedBox(height: spacing.section),
          SocialSignInButtons(
            onApple: _busy ? null : _onApple,
            onGoogle: _busy ? null : _onGoogle,
            appleLoading: _ssoInFlight == _SsoInFlight.apple,
            googleLoading: _ssoInFlight == _SsoInFlight.google,
          ),
          SizedBox(height: spacing.gutter),
          AppDivider(label: context.t('signIn.or')),
          SizedBox(height: spacing.gutter),
          if (_bannerError != null) ...<Widget>[
            AppBanner(
              key: const Key('sign-in-error-banner'),
              intent: AppIntent.danger,
              title: context.t('auth.errors.socialSignInTitle'),
              onClose: () => setState(() => _bannerError = null),
              child: Text(context.t(_bannerError!)),
            ),
            SizedBox(height: spacing.gutter),
          ],
          AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                AppInput(
                  key: const Key('identifier-input'),
                  label: context.t('auth.email'),
                  placeholder: context.t('auth.emailPlaceholder'),
                  value: _identifier,
                  onChanged: (String v) => setState(() => _identifier = v),
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  autofillHints: const <String>[AutofillHints.email],
                  textInputAction: TextInputAction.next,
                  errorText: _identifierError,
                ),
                const SizedBox(height: 12),
                PasswordField(
                  inputKey: const Key('password-input'),
                  label: context.t('auth.password'),
                  // Mockup A3 uses a masked-dots placeholder on sign-in; the
                  // "At least 8 characters" hint belongs to sign-up only.
                  placeholder: context.t('auth.signInPasswordPlaceholder'),
                  value: _password,
                  onChanged: (String v) => setState(() => _password = v),
                  autofillHints: const <String>[AutofillHints.password],
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _onSubmit(),
                  errorText: _passwordError,
                ),
              ],
            ),
          ),
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
          // Waitlist entry. When the app is invite-gated this is surfaced
          // prominently (a bordered card) so users without access know what
          // to do; otherwise it's a subtle text link.
          SizedBox(height: spacing.gutter),
          if (Env.inviteOnly)
            AppBanner(
              key: const Key('sign-in-waitlist-card'),
              intent: AppIntent.info,
              title: context.t('waitlist.gateTitle'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(context.t('waitlist.gateBody')),
                  const SizedBox(height: 8),
                  AppButton(
                    key: const Key('sign-in-waitlist-cta'),
                    label: context.t('waitlist.joinCta'),
                    variant: AppButtonVariant.outline,
                    onPressed:
                        _busy ? null : () => context.go(Routes.waitlist),
                  ),
                ],
              ),
            )
          else
            Center(
              child: TextButton(
                key: const Key('sign-in-waitlist-link'),
                onPressed: _busy ? null : () => context.go(Routes.waitlist),
                child: Text(context.t('waitlist.noAccessLink')),
              ),
            ),
        ],
      ),
    );
  }
}
