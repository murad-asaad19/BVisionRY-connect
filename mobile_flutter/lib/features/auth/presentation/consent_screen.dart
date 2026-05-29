import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/error_map.dart';
import '../../../core/i18n/i18n.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/widgets.dart';
import '../providers/auth_service_provider.dart';
import '../providers/profile_provider.dart';
import 'auth_shell.dart';
import 'consent_fields.dart';

/// Post-auth age-gate + legal-consent interstitial.
///
/// The route guard sends any authenticated user whose profile carries no
/// recorded consent here — chiefly OAuth / magic-link / handle sign-ups, which
/// never pass through the sign-up form's inline consent fields. Email+password
/// sign-ups normally record consent inline and skip this screen, but it is the
/// single guaranteed enforcement point regardless of auth method.
///
/// On submit it calls the same `record_signup_consent` RPC (the server is the
/// source of truth, re-validating age + both acceptances) then invalidates
/// [profileProvider] so the guard re-resolves and advances the user to
/// onboarding. There is no explicit navigation — the guard owns routing. A
/// sign-out affordance guarantees an under-age (or unwilling) user is never
/// trapped on the gate with no way out.
class ConsentScreen extends ConsumerStatefulWidget {
  const ConsentScreen({super.key});

  @override
  ConsumerState<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends ConsumerState<ConsentScreen> {
  DateTime? _dob;
  bool _consent = false;
  bool _busy = false;

  String? _bannerError;
  String? _dobError;
  String? _consentError;

  /// Clears only when a DOB is set AND it puts the user at or above the
  /// minimum age. The server RPC re-validates this on submit.
  bool get _ageOk => _dob != null && ageFromDob(_dob!) >= kMinSignupAge;
  bool get _gateSatisfied => _ageOk && _consent;

  Future<void> _submit() async {
    if (_busy) return;
    if (!_ageOk) {
      setState(() {
        _bannerError = null;
        _dobError = context.t('auth.consent.underAgeError');
      });
      return;
    }
    if (!_consent) {
      setState(() {
        _bannerError = null;
        _consentError = context.t('auth.consent.consentRequired');
      });
      return;
    }
    Haptics.light();
    setState(() {
      _busy = true;
      _bannerError = null;
      _dobError = null;
      _consentError = null;
    });
    try {
      await ref.read(authServiceProvider).recordSignupConsent(
            dateOfBirth: _dob!,
            acceptTos: true,
            acceptPrivacy: true,
          );
      // Re-fetch the profile so [consentRecorded] flips true and the route
      // guard moves the user on to onboarding / home — the guard owns the
      // navigation, we never push from here. Awaiting the refetch surfaces a
      // transient failure inline instead of leaving the button spinning
      // forever (the guard returns null while the profile is in error, which
      // would otherwise keep the user pinned on /consent). On success the
      // guard navigates away and this widget unmounts before we resume.
      ref.invalidate(profileProvider);
      await ref.read(profileProvider.future);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        // record_signup_consent raises Postgrest errors (e.g. server-side
        // under-age / consent hints); map them so the banner shows the
        // specific reason rather than a generic auth-flow fallback.
        _bannerError = mapPostgrestError(e).i18nKey;
      });
    }
  }

  Future<void> _signOut() async {
    if (_busy) return;
    Haptics.light();
    await ref.read(authServiceProvider).signOut();
  }

  @override
  Widget build(BuildContext context) {
    final AppSpacing spacing = Theme.of(context).extension<AppSpacing>()!;
    return AuthShell(
      tagline: context.t('auth.consent.tagline'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            context.t('auth.consent.gateTitle'),
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: 8),
          Text(
            context.t('auth.consent.gateSubtitle'),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          SizedBox(height: spacing.section),
          if (_bannerError != null) ...<Widget>[
            AppBanner(
              key: const Key('consent-error-banner'),
              intent: AppIntent.danger,
              title: context.t('errors.title'),
              onClose: () => setState(() => _bannerError = null),
              child: Text(context.t(_bannerError!)),
            ),
            SizedBox(height: spacing.gutter),
          ],
          DateOfBirthField(
            value: _dob,
            enabled: !_busy,
            errorText: _dobError,
            onChanged: (DateTime v) => setState(() {
              _dob = v;
              _dobError =
                  _ageOk ? null : context.t('auth.consent.underAgeError');
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
          SizedBox(height: spacing.section),
          AppButton(
            key: const Key('consent-submit'),
            label: context.t('auth.consent.gateSubmit'),
            onPressed: (_busy || !_gateSatisfied) ? null : _submit,
            loading: _busy,
          ),
          SizedBox(height: spacing.gutter),
          AppButton(
            key: const Key('consent-sign-out'),
            label: context.t('settings.signOut'),
            variant: AppButtonVariant.outline,
            onPressed: _busy ? null : _signOut,
          ),
        ],
      ),
    );
  }
}
