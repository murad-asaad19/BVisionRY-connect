import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/errors/error_messages.dart';
import '../../../core/i18n/i18n.dart';
import '../../../core/routing/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/widgets.dart';
import '../../auth/presentation/auth_shell.dart';
import '../data/invite_service.dart';

/// Join-the-waitlist screen — the public entry for people without access.
///
/// Reachable pre-auth from the sign-in screen ("Don't have access? Join the
/// waitlist"). Collects an email and calls `join_waitlist` (idempotent on the
/// server). On success it swaps to a confirmation state ("You're on the list").
class WaitlistScreen extends ConsumerStatefulWidget {
  const WaitlistScreen({super.key});

  @override
  ConsumerState<WaitlistScreen> createState() => _WaitlistScreenState();
}

class _WaitlistScreenState extends ConsumerState<WaitlistScreen> {
  String _email = '';
  bool _busy = false;
  bool _joined = false;
  String? _emailError;
  String? _bannerError;

  bool get _emailLooksValid => _email.contains('@') && _email.contains('.');

  Future<void> _submit() async {
    if (_busy) return;
    final String email = _email.trim();
    if (email.isEmpty || !_emailLooksValid) {
      setState(() {
        _bannerError = null;
        _emailError = context.t('waitlist.errors.invalidEmail');
      });
      return;
    }
    Haptics.light();
    setState(() {
      _busy = true;
      _emailError = null;
      _bannerError = null;
    });
    try {
      await ref.read(inviteServiceProvider).joinWaitlist(email);
      if (!mounted) return;
      setState(() => _joined = true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _bannerError = messageForError(context, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      tagline: context.t('waitlist.tagline'),
      child: _joined ? _buildSuccess(context) : _buildForm(context),
    );
  }

  Widget _buildForm(BuildContext context) {
    final AppSpacing spacing = Theme.of(context).extension<AppSpacing>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          context.t('waitlist.title'),
          style: Theme.of(context).textTheme.displayMedium,
        ),
        const SizedBox(height: 8),
        Text(
          context.t('waitlist.subtitle'),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        SizedBox(height: spacing.section),
        if (_bannerError != null) ...<Widget>[
          AppBanner(
            key: const Key('waitlist-error-banner'),
            intent: AppIntent.danger,
            title: context.t('errors.title'),
            onClose: () => setState(() => _bannerError = null),
            child: Text(_bannerError!),
          ),
          SizedBox(height: spacing.gutter),
        ],
        AppInput(
          key: const Key('waitlist-email-input'),
          label: context.t('auth.email'),
          placeholder: context.t('auth.emailPlaceholder'),
          value: _email,
          onChanged: (String v) => setState(() => _email = v),
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          autofillHints: const <String>[AutofillHints.email],
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
          errorText: _emailError,
        ),
        SizedBox(height: spacing.section),
        AppButton(
          key: const Key('waitlist-submit'),
          label: context.t('waitlist.joinCta'),
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
              key: const Key('waitlist-back-to-sign-in'),
              onPressed: _busy ? null : () => context.go(Routes.signIn),
              child: Text(context.t('auth.signInCta')),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSuccess(BuildContext context) {
    final AppColors colors = Theme.of(context).extension<AppColors>()!;
    final AppSpacing spacing = Theme.of(context).extension<AppSpacing>()!;
    return Column(
      key: const Key('waitlist-success'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Center(
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: colors.goldPale,
              shape: BoxShape.circle,
            ),
            child: Icon(LucideIcons.check, color: colors.success, size: 30),
          ),
        ),
        SizedBox(height: spacing.gutter),
        Text(
          context.t('waitlist.successTitle'),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.displayMedium,
        ),
        const SizedBox(height: 8),
        Text(
          context.t('waitlist.successBody'),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        SizedBox(height: spacing.section),
        AppButton(
          key: const Key('waitlist-success-back'),
          label: context.t('waitlist.backToSignIn'),
          variant: AppButtonVariant.outline,
          onPressed: () => context.go(Routes.signIn),
        ),
      ],
    );
  }
}
