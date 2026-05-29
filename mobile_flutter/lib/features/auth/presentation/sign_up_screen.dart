import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/env.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/i18n/i18n.dart';
import '../../../core/routing/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/widgets.dart';
import '../../waitlist/data/invite_service.dart';
import '../data/auth_error_map.dart';
import '../providers/auth_service_provider.dart';
import '../providers/profile_provider.dart';
import 'auth_shell.dart';
import 'consent_fields.dart';
import 'password_field.dart';
import 'social_sign_in_buttons.dart';

/// Email + password sign-up form with a live 8-character hint indicator.
///
/// Gallery reference: A2. The card stacks SSO buttons (Google then Apple)
/// at the top, then an "or" divider, then the email + password fields, then
/// the primary Sign-up button, and finally an "Already have an account?"
/// link.
///
/// Submitting calls [AuthService.signUpWithPassword]; the underlying
/// service throws an [ArgumentError] when the password is shorter than 8
/// chars but the UI gates the button on the same predicate so that path is
/// only ever hit by a determined caller. The hint underneath the password
/// field flips from `pwd-hint-bad` (muted info icon) to `pwd-hint-ok`
/// (success check) as the user types past 7 characters.
class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key, this.initialInviteCode});

  /// Invite code captured from an invite deep link
  /// (`https://<host>/sign-up?invite=CODE` or the `connect-mobile://`
  /// variant). When present it pre-fills the invite field so a friend who
  /// followed an invite link doesn't have to re-key the code.
  final String? initialInviteCode;

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

/// The SSO provider whose request is currently in flight, if any — drives
/// the per-button spinner so only the tapped button shows progress.
enum _SsoInFlight { apple, google }

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  String _email = '';
  String _password = '';
  late String _inviteCode;
  DateTime? _dob;
  bool _consent = false;
  bool _busy = false;
  _SsoInFlight? _ssoInFlight;

  /// Top-of-form banner message key (network / rate-limit / cancellation /
  /// generic). Field-specific failures use [_emailError] / [_passwordError].
  String? _bannerError;
  String? _emailError;
  String? _passwordError;
  String? _dobError;
  String? _consentError;
  String? _inviteError;

  @override
  void initState() {
    super.initState();
    // Seed the invite field from an invite deep link, if any.
    _inviteCode = widget.initialInviteCode?.trim() ?? '';
  }

  bool get _passwordOk => _password.length >= 8;
  bool get _emailLooksValid => _email.contains('@') && _email.contains('.');

  /// The age gate clears only when a DOB is set AND it puts the user at or
  /// above the minimum age. The server RPC re-validates this on submit.
  bool get _ageOk => _dob != null && ageFromDob(_dob!) >= kMinSignupAge;

  /// When the app is invite-gated ([Env.inviteOnly]) a non-empty invite code
  /// is required to submit; otherwise the field is optional.
  bool get _inviteOk => !Env.inviteOnly || _inviteCode.trim().isNotEmpty;

  /// All gate predicates the primary Sign-up button hinges on.
  bool get _gateSatisfied => _ageOk && _consent && _inviteOk;

  void _clearErrors() {
    _bannerError = null;
    _emailError = null;
    _passwordError = null;
    _dobError = null;
    _consentError = null;
    _inviteError = null;
  }

  /// Routes a mapped error key to the right surface: credential problems
  /// highlight the offending field; everything else lands in the banner.
  void _surfaceError(String mappedKey) {
    final String msg = context.t(mappedKey);
    switch (authErrorField(mappedKey)) {
      case AuthErrorField.identifier:
        _emailError = msg;
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
      // Invite redemption raises typed AppExceptions (invalid / expired /
      // exhausted code). Those carry their own i18n key and belong on the
      // invite field; everything else flows through the auth error map.
      if (e is AppException && e.i18nKey.startsWith('invite.')) {
        setState(() => _inviteError = context.t(e.i18nKey));
      } else {
        setState(() => _surfaceError(mapAuthError(e, mode)));
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _ssoInFlight = null;
        });
      }
    }
  }

  Future<void> _submit() async {
    if (_busy) return;
    if (_email.trim().isEmpty) {
      setState(() {
        _clearErrors();
        _emailError = context.t('auth.errors.emailRequired');
      });
      return;
    }
    if (!_emailLooksValid) {
      setState(() {
        _clearErrors();
        _emailError = context.t('auth.errors.invalidEmail');
      });
      return;
    }
    if (!_passwordOk) {
      setState(() {
        _clearErrors();
        _passwordError = context.t('auth.errors.passwordTooShort');
      });
      return;
    }
    // Age gate + legal consent (launch compliance). The button is also
    // disabled until these clear, so this is the belt-and-braces path.
    if (!_ageOk) {
      setState(() {
        _clearErrors();
        _dobError = context.t('auth.consent.underAgeError');
      });
      return;
    }
    if (!_consent) {
      setState(() {
        _clearErrors();
        _consentError = context.t('auth.consent.consentRequired');
      });
      return;
    }
    // Invite-gated launch: a code is mandatory before submit when invite-only.
    if (!_inviteOk) {
      setState(() {
        _clearErrors();
        _inviteError = context.t('invite.errors.required');
      });
      return;
    }
    Haptics.light();
    final DateTime dob = _dob!;
    final String code = _inviteCode.trim();
    await _runGuard(
      () async {
        final AuthResponse res = await ref
            .read(authServiceProvider)
            .signUpWithPassword(email: _email, password: _password);
        // The age-gate + consent and the invite are auth.uid()-scoped RPCs, so
        // they can only run once a session exists. With email confirmation
        // disabled signUp returns an immediate session and we persist both
        // now; with confirmation enabled there is no session yet, so we defer
        // to the post-confirmation /consent route-guard gate instead of calling
        // RPCs that would fail unauthenticated.
        if (res.session != null) {
          // The server RPC re-validates age + that both flags are true and is
          // the source of truth; we surface a failure rather than swallow it.
          await ref.read(authServiceProvider).recordSignupConsent(
                dateOfBirth: dob,
                acceptTos: true,
                acceptPrivacy: true,
              );
          // Best-effort invite redemption: only when a code was entered, and
          // after consent has landed. A bad/expired/exhausted code surfaces
          // through the same error path (banner / field) — it does not undo the
          // account that was just created.
          try {
            if (code.isNotEmpty) {
              await ref.read(inviteServiceProvider).redeemInvite(code);
            }
          } finally {
            // Consent is recorded regardless of the invite outcome — refetch
            // the profile so the route guard's consent gate clears and the new
            // account advances into onboarding instead of the /consent gate.
            ref.invalidate(profileProvider);
          }
          // Signed in: the guard navigates onward, so no "check your email"
          // toast (which would be misleading).
          return;
        }
        // Email-confirmation pending (no session): consent is captured by the
        // /consent gate after the user confirms and signs in. (If invite-only
        // launches enable email confirmation, invite redemption should be
        // deferred to first session too — currently confirmation is off.)
        if (!mounted) return;
        ref.read(toastServiceProvider.notifier).showToast(
              title: context.t('auth.magicLinkSent'),
              intent: AppIntent.success,
            );
      },
      AuthMode.signUp,
    );
  }

  Future<void> _onApple() => _runGuard(
        () async => ref.read(socialAuthServiceProvider).signInWithApple(),
        AuthMode.signUp,
        sso: _SsoInFlight.apple,
      );

  Future<void> _onGoogle() => _runGuard(
        () async => ref.read(socialAuthServiceProvider).signInWithGoogle(),
        AuthMode.signUp,
        sso: _SsoInFlight.google,
      );

  @override
  Widget build(BuildContext context) {
    final AppColors colors = Theme.of(context).extension<AppColors>()!;
    final AppSpacing spacing = Theme.of(context).extension<AppSpacing>()!;
    final bool hintOk = _passwordOk;
    return AuthShell(
      tagline: context.t('auth.signUpTagline'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            context.t('auth.signUpTitle'),
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
              key: const Key('sign-up-error-banner'),
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
                  key: const Key('email-input'),
                  label: context.t('auth.email'),
                  placeholder: context.t('auth.emailPlaceholder'),
                  value: _email,
                  onChanged: (String v) => setState(() => _email = v),
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  autofillHints: const <String>[AutofillHints.email],
                  textInputAction: TextInputAction.next,
                  errorText: _emailError,
                ),
                const SizedBox(height: 12),
                PasswordField(
                  inputKey: const Key('password-input'),
                  label: context.t('auth.password'),
                  placeholder: context.t('auth.passwordPlaceholder'),
                  value: _password,
                  onChanged: (String v) => setState(() => _password = v),
                  autofillHints: const <String>[AutofillHints.newPassword],
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  errorText: _passwordError,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Cross-fade the hint as it flips between the unmet / met states so
          // the icon + color change reads as a smooth confirmation rather than
          // a hard swap. The per-state Key drives the switch (and keeps the
          // existing pwd-hint-ok / pwd-hint-bad finders intact).
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeOut,
            child: Row(
              key: Key(hintOk ? 'pwd-hint-ok' : 'pwd-hint-bad'),
              children: <Widget>[
                Icon(
                  hintOk ? LucideIcons.circleCheck : LucideIcons.info,
                  size: 14,
                  color: hintOk ? colors.success : colors.muted,
                ),
                const SizedBox(width: 6),
                Text(
                  hintOk
                      ? context.t('auth.passwordHint8Met')
                      : context.t('auth.passwordHint8'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: hintOk ? colors.success : colors.muted,
                      ),
                ),
              ],
            ),
          ),
          SizedBox(height: spacing.gutter),
          DateOfBirthField(
            value: _dob,
            enabled: !_busy,
            errorText: _dobError,
            onChanged: (DateTime v) => setState(() {
              _dob = v;
              _dobError = _ageOk ? null : context.t('auth.consent.underAgeError');
            }),
          ),
          SizedBox(height: spacing.gutter),
          ConsentCheckbox(
            value: _consent,
            enabled: !_busy,
            errorText: _consentError,
            onChanged: (bool v) => setState(() {
              _consent = v;
              if (v) _consentError = null;
            }),
          ),
          SizedBox(height: spacing.gutter),
          // Invite code — optional by default, required when invite-gated.
          AppInput(
            key: const Key('invite-code-input'),
            label: Env.inviteOnly
                ? context.t('invite.codeFieldLabelRequired')
                : context.t('invite.codeFieldLabel'),
            placeholder: context.t('invite.codeFieldPlaceholder'),
            value: _inviteCode,
            onChanged: (String v) => setState(() {
              _inviteCode = v;
              _inviteError = null;
            }),
            autocorrect: false,
            textInputAction: TextInputAction.done,
            errorText: _inviteError,
          ),
          SizedBox(height: spacing.section),
          AppButton(
            key: const Key('signup-submit'),
            label: context.t('auth.submitSignUp'),
            onPressed: (_busy || !_gateSatisfied) ? null : _submit,
            loading: _busy,
          ),
          SizedBox(height: spacing.gutter),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(context.t('auth.haveAccount')),
              const SizedBox(width: 6),
              TextButton(
                onPressed: _busy ? null : () => Navigator.of(context).pop(),
                child: Text(context.t('auth.signInCta')),
              ),
            ],
          ),
          // When invite-gated, point users without a code to the waitlist.
          if (Env.inviteOnly) ...<Widget>[
            SizedBox(height: spacing.xs),
            Center(
              child: TextButton(
                key: const Key('sign-up-waitlist-link'),
                onPressed: _busy ? null : () => context.go(Routes.waitlist),
                child: Text(context.t('waitlist.noAccessLink')),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
