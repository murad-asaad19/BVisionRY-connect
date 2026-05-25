import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/i18n/i18n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/widgets.dart';
import '../data/auth_error_map.dart';
import '../providers/auth_service_provider.dart';
import 'auth_shell.dart';

/// Email + password sign-up form with a live 8-character hint indicator.
///
/// Submitting calls [AuthService.signUpWithPassword]; the underlying
/// service throws an [ArgumentError] when the password is shorter than 8
/// chars but the UI gates the button on the same predicate so that path is
/// only ever hit by a determined caller. The hint underneath the password
/// field flips from `pwd-hint-bad` (muted info icon) to `pwd-hint-ok`
/// (success check) as the user types past 7 characters.
class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  String _email = '';
  String _password = '';
  bool _busy = false;
  String? _error;

  bool get _passwordOk => _password.length >= 8;
  bool get _emailLooksValid => _email.contains('@') && _email.contains('.');

  Future<void> _submit() async {
    if (_busy) return;
    setState(() => _error = null);
    if (_email.trim().isEmpty) {
      setState(() => _error = context.t('auth.errors.emailRequired'));
      return;
    }
    if (!_emailLooksValid) {
      setState(() => _error = context.t('auth.errors.invalidEmail'));
      return;
    }
    if (!_passwordOk) {
      setState(() => _error = context.t('auth.errors.passwordTooShort'));
      return;
    }
    setState(() => _busy = true);
    try {
      await ref
          .read(authServiceProvider)
          .signUpWithPassword(email: _email, password: _password);
      if (!mounted) return;
      ref.read(toastServiceProvider.notifier).showToast(
            title: context.t('auth.magicLinkSent'),
            intent: AppIntent.success,
          );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = context.t(mapAuthError(e, AuthMode.signUp)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

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
          const SizedBox(height: 6),
          Text(
            context.t('auth.signUpTagline'),
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: colors.muted),
          ),
          SizedBox(height: spacing.section),
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
          ),
          const SizedBox(height: 12),
          AppInput(
            key: const Key('password-input'),
            label: context.t('auth.password'),
            placeholder: context.t('auth.passwordPlaceholder'),
            value: _password,
            onChanged: (String v) => setState(() => _password = v),
            obscureText: true,
            autofillHints: const <String>[AutofillHints.newPassword],
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 8),
          Row(
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
          if (_error != null) ...<Widget>[
            const SizedBox(height: 10),
            Text(_error!, style: TextStyle(color: colors.danger)),
          ],
          SizedBox(height: spacing.section),
          AppButton(
            key: const Key('signup-submit'),
            label: context.t('auth.submitSignUp'),
            onPressed: _busy ? null : _submit,
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
        ],
      ),
    );
  }
}
