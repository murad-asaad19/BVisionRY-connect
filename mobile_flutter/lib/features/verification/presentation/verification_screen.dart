import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/errors/error_messages.dart';
import '../../../core/i18n/i18n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/widgets.dart';
import '../../auth/providers/profile_provider.dart';
import '../../profile/domain/profile.dart';
import '../data/verification_service.dart';
import '../domain/verification_request.dart';
import '../providers/my_verifications_provider.dart';

/// Settings → Verification screen.
///
/// Mirrors spec §15 / §17.3 + gallery section H4. The screen opens with the
/// "+15% ranking boost" intro paragraph, then surfaces the role catalog as
/// grouped 10px cards (matching the gallery's per-group white containers):
///
///   * **Builder** — the GitHub proof is functional in this release. When
///     granted, the row shows a green "Verified" pill beside the label
///     ([Pill] with `verification.verifiedPill`) and a Disconnect button.
///   * **Founder** — proofs render as disabled "Coming soon" rows until the
///     domain-email + /team-page flows ship (deferred per drift H4).
///   * **Investor — pick one** — three proof rows (Domain-verified email,
///     Crunchbase, Portfolio companies) under an uppercase eyebrow, followed
///     by the "Any one proof unlocks the badge" footer note conveying the
///     OR-semantics from the mockup.
///
/// The GitHub "Verify" button opens GitHub's authorize URL in an external
/// browser via [url_launcher]. The full OAuth code-exchange flow is wired
/// in the deep-link callback (Phase 12) — for this chunk we surface the
/// entry point + a "coming in next release" toast.
class VerificationScreen extends ConsumerWidget {
  const VerificationScreen({super.key});

  static const String _kGithubAuthorizeUrl = 'https://github.com/';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppColors colors = Theme.of(context).extension<AppColors>()!;
    final AppTypography typo = Theme.of(context).extension<AppTypography>()!;
    final AsyncValue<Profile?> async = ref.watch(profileProvider);
    final Profile? profile = async.valueOrNull;
    final String? github = profile?.verifiedGithubUsername;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: TopBar(
          title: context.t('verification.title'),
          back: true,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 32),
        children: <Widget>[
          // "+15% ranking boost" intro paragraph (gallery line 2240).
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 8, 2, 12),
            child: Text(
              context.t('verification.rankingBoost'),
              style: typo.bodySm.copyWith(color: colors.muted, height: 1.5),
            ),
          ),
          _GroupEyebrow(label: context.t('verification.builderSection')),
          _GroupCard(child: _GithubRow(github: github)),
          const SizedBox(height: 8),
          _GroupEyebrow(label: context.t('verification.founderSection')),
          _GroupCard(
            child: Column(
              children: <Widget>[
                _ProofRow(
                  rowKey: const Key('verification.row.domain'),
                  kind: VerificationKind.founderDomainEmail,
                  label: context.t('verification.proofs.founder.domain.label'),
                  description: context
                      .t('verification.proofs.founder.domain.description'),
                ),
                _ProofRow(
                  rowKey: const Key('verification.row.team_page'),
                  kind: VerificationKind.founderTeamPage,
                  label:
                      context.t('verification.proofs.founder.team_page.label'),
                  description: context
                      .t('verification.proofs.founder.team_page.description'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _GroupEyebrow(label: context.t('verification.investorPickOne')),
          _GroupCard(
            child: Column(
              children: <Widget>[
                _ProofRow(
                  rowKey: const Key('verification.row.investor_domain'),
                  kind: VerificationKind.investorDomainEmail,
                  label: context.t('verification.proofs.investor.domain.label'),
                  description: context
                      .t('verification.proofs.investor.domain.description'),
                ),
                _ProofRow(
                  rowKey: const Key('verification.row.crunchbase'),
                  kind: VerificationKind.investorCrunchbase,
                  label: context
                      .t('verification.proofs.investor.crunchbase.label'),
                  description: context.t(
                    'verification.proofs.investor.crunchbase.description',
                  ),
                ),
                _ProofRow(
                  rowKey: const Key('verification.row.portfolio'),
                  kind: VerificationKind.investorPortfolio,
                  label:
                      context.t('verification.proofs.investor.portfolio.label'),
                  description: context
                      .t('verification.proofs.investor.portfolio.description'),
                ),
              ],
            ),
          ),
          Padding(
            key: const Key('verification.investorFooter'),
            padding: const EdgeInsets.fromLTRB(2, 14, 2, 0),
            child: Text(
              context.t('verification.investorFooter'),
              style: typo.bodySm.copyWith(color: colors.muted, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

/// Uppercase eyebrow above a verification group. Matches the gallery's
/// per-section label (Dosis-style uppercase, navy, 11px, letter-spacing 0.5).
class _GroupEyebrow extends StatelessWidget {
  const _GroupEyebrow({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = Theme.of(context).extension<AppColors>()!;
    final AppTypography typo = Theme.of(context).extension<AppTypography>()!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 14, 4, 8),
      child: Text(
        label.toUpperCase(),
        style: typo.displayXs.copyWith(
          color: colors.navy,
          fontSize: 11,
          letterSpacing: 0.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Rounded white card wrapping a group of verification rows. 10px radius
/// mirrors the gallery's per-group container (drift H4: verification cards
/// are 10px, not the 14px SectionCard token).
class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = Theme.of(context).extension<AppColors>()!;
    return Container(
      decoration: BoxDecoration(
        color: colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _GithubRow extends ConsumerStatefulWidget {
  const _GithubRow({required this.github});
  final String? github;

  @override
  ConsumerState<_GithubRow> createState() => _GithubRowState();
}

class _GithubRowState extends ConsumerState<_GithubRow> {
  bool _disconnecting = false;

  Future<void> _stubLaunch() async {
    final Uri uri = Uri.parse(VerificationScreen._kGithubAuthorizeUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _disconnect() async {
    final bool confirmed = await ref.read(confirmServiceProvider).confirm(
          context,
          title: context.t('verification.disconnectConfirm.title'),
          body: context.t('verification.disconnectConfirm.body'),
          confirmLabel: context.t('verification.disconnect'),
          cancelLabel: context.t('common.cancel'),
          destructive: true,
        );
    if (!confirmed || !mounted) return;
    Haptics.medium();
    setState(() => _disconnecting = true);
    try {
      await ref.read(verificationServiceProvider).clearGithubVerification();
      ref.invalidate(profileProvider);
    } catch (e) {
      if (!mounted) return;
      Haptics.error();
      ref.read(toastServiceProvider.notifier).showToast(
            title: messageForError(context, e),
            intent: AppIntent.danger,
          );
    } finally {
      if (mounted) setState(() => _disconnecting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? github = widget.github;
    if (github != null) {
      // Granted state — a green "Verified" pill sits beside the label
      // (gallery's `.verified-badge`). SettingsRow has no label-adjacent
      // slot, so the granted row is composed locally to match the mockup.
      final AppColors colors = Theme.of(context).extension<AppColors>()!;
      final AppTypography typo = Theme.of(context).extension<AppTypography>()!;
      return Padding(
        key: const Key('verification.row.github'),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.code, color: colors.navy, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          context.t('verification.github'),
                          style: typo.displaySm.copyWith(color: colors.body),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Pill(
                        key: const Key('verification.github.verifiedPill'),
                        label: context.t('verification.verifiedPill'),
                        variant: PillVariant.success,
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '@$github',
                    style: typo.bodySm.copyWith(color: colors.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            AppButton(
              key: const Key('verification.github.disconnect'),
              label: context.t('verification.disconnect'),
              variant: AppButtonVariant.outlineDanger,
              size: AppButtonSize.small,
              fullWidth: false,
              loading: _disconnecting,
              onPressed: _disconnecting ? null : _disconnect,
            ),
          ],
        ),
      );
    }
    return SettingsRow(
      key: const Key('verification.row.github'),
      icon: Icons.code,
      label: context.t('verification.github'),
      description: context.t('verification.githubVerifyBody'),
      trailing: AppButton(
        key: const Key('verification.github.verify'),
        label: context.t('verification.verify'),
        variant: AppButtonVariant.gold,
        size: AppButtonSize.small,
        fullWidth: false,
        onPressed: () async {
          // Resolve the localized copy + notifier before the async gap so we
          // don't touch the BuildContext after awaiting the external launch.
          final String stubMessage = context.t('verification.githubStub');
          final toast = ref.read(toastServiceProvider.notifier);
          Haptics.medium();
          await _stubLaunch();
          if (!mounted) return;
          toast.showToast(title: stubMessage, intent: AppIntent.info);
        },
      ),
    );
  }
}

/// A single actionable proof row driven by [myVerificationsProvider].
///
/// One reusable widget covers every Founder/Investor proof kind — the trailing
/// slot flips through the submission lifecycle:
///
///   * **no submission** → a "Request verification" button. Tapping opens
///     [_ProofInputSheet] to capture the evidence (a work email or a URL) into
///     the `payload`, then submits.
///   * **pending** → a muted "Pending review" pill.
///   * **approved** → a green "Verified" pill.
///   * **rejected** → a "Not verified — try again" button plus the reviewer's
///     note, so the user can re-submit.
class _ProofRow extends ConsumerStatefulWidget {
  const _ProofRow({
    required this.rowKey,
    required this.kind,
    required this.label,
    required this.description,
  });

  final Key rowKey;
  final VerificationKind kind;
  final String label;
  final String description;

  @override
  ConsumerState<_ProofRow> createState() => _ProofRowState();
}

class _ProofRowState extends ConsumerState<_ProofRow> {
  bool _submitting = false;

  /// Domain-email kinds capture the caller's work email; the rest capture a
  /// URL (team page / Crunchbase / portfolio listings). Every kind needs one
  /// free-text evidence value for the manual reviewer, so the input sheet
  /// always opens before submission.
  bool get _isEmailKind =>
      widget.kind == VerificationKind.founderDomainEmail ||
      widget.kind == VerificationKind.investorDomainEmail;

  Future<void> _request() async {
    Haptics.medium();
    final String? value = await showAppBottomSheet<String>(
      context: context,
      child: _ProofInputSheet(isEmail: _isEmailKind),
    );
    if (value == null || !mounted) return; // user dismissed the sheet
    final Map<String, dynamic> payload = <String, dynamic>{
      _isEmailKind ? 'email' : 'url': value,
    };
    setState(() => _submitting = true);
    try {
      await ref
          .read(verificationServiceProvider)
          .submitVerification(widget.kind, payload: payload);
      ref.invalidate(myVerificationsProvider);
    } catch (e) {
      if (!mounted) return;
      Haptics.error();
      ref.read(toastServiceProvider.notifier).showToast(
            title: messageForError(context, e),
            intent: AppIntent.danger,
          );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = Theme.of(context).extension<AppColors>()!;
    final AppTypography typo = Theme.of(context).extension<AppTypography>()!;
    final AsyncValue<Map<VerificationKind, VerificationRequest>> async =
        ref.watch(myVerificationsProvider);
    final VerificationRequest? submission =
        async.valueOrNull?[widget.kind];
    final VerificationStatus? status = submission?.status;
    final bool rejected = status == VerificationStatus.rejected;

    return Padding(
      key: widget.rowKey,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  widget.label,
                  style: typo.displaySm.copyWith(color: colors.body),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.description,
                  style: typo.bodySm.copyWith(color: colors.muted),
                ),
                if (rejected &&
                    (submission?.note?.isNotEmpty ?? false)) ...<Widget>[
                  const SizedBox(height: 4),
                  Text(
                    context.t(
                      'verification.rejectedNote',
                      vars: <String, Object>{'note': submission!.note!},
                    ),
                    style: typo.bodyXs.copyWith(color: colors.danger),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          _trailing(status),
        ],
      ),
    );
  }

  Widget _trailing(VerificationStatus? status) {
    // Derive per-state child keys off the row key so widget tests can target
    // each lifecycle state without coupling to the localized label text.
    final String base = (widget.rowKey as ValueKey<String>).value;
    switch (status) {
      case VerificationStatus.approved:
        return Pill(
          key: Key('$base.verified'),
          label: context.t('verification.verifiedBadge'),
          variant: PillVariant.success,
        );
      case VerificationStatus.pending:
        return Pill(
          key: Key('$base.pending'),
          label: context.t('verification.pendingReview'),
          variant: PillVariant.muted,
        );
      case VerificationStatus.rejected:
        return AppButton(
          key: Key('$base.retry'),
          label: context.t('verification.rejectedRetry'),
          variant: AppButtonVariant.outlineDanger,
          size: AppButtonSize.small,
          fullWidth: false,
          loading: _submitting,
          onPressed: _submitting ? null : _request,
        );
      case null:
        return AppButton(
          key: Key('$base.request'),
          label: context.t('verification.requestVerification'),
          variant: AppButtonVariant.gold,
          size: AppButtonSize.small,
          fullWidth: false,
          loading: _submitting,
          onPressed: _submitting ? null : _request,
        );
    }
  }
}

/// Bottom sheet that captures the single evidence value a proof kind needs
/// (a work email or a URL) and pops it back to [_ProofRow]. Returns `null`
/// when the user dismisses without submitting.
class _ProofInputSheet extends StatefulWidget {
  const _ProofInputSheet({required this.isEmail});

  final bool isEmail;

  @override
  State<_ProofInputSheet> createState() => _ProofInputSheetState();
}

class _ProofInputSheetState extends State<_ProofInputSheet> {
  String _value = '';
  bool _showError = false;

  String get _scope => widget.isEmail
      ? 'verification.inputSheet.email'
      : 'verification.inputSheet.url';

  bool get _valid {
    final String v = _value.trim();
    if (v.isEmpty) return false;
    return widget.isEmail ? v.contains('@') && v.contains('.') : true;
  }

  void _submit() {
    if (!_valid) {
      setState(() => _showError = true);
      return;
    }
    Haptics.medium();
    Navigator.of(context).pop(_value.trim());
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = Theme.of(context).extension<AppColors>()!;
    final AppTypography typo = Theme.of(context).extension<AppTypography>()!;
    return Padding(
      key: const Key('verification.inputSheet'),
      padding: EdgeInsets.fromLTRB(
        16,
        4,
        16,
        16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              context.t('$_scope.title'),
              style: typo.displayLg.copyWith(color: colors.navy),
            ),
            const SizedBox(height: 6),
            Text(
              context.t('$_scope.body'),
              style: typo.bodySm.copyWith(color: colors.muted, height: 1.4),
            ),
            const SizedBox(height: 12),
            AppInput(
              key: const Key('verification.inputSheet.field'),
              label: context.t('$_scope.label'),
              placeholder: context.t('$_scope.placeholder'),
              value: _value,
              keyboardType: widget.isEmail
                  ? TextInputType.emailAddress
                  : TextInputType.url,
              autocorrect: false,
              errorText: _showError ? context.t('$_scope.invalid') : null,
              onChanged: (String v) => setState(() {
                _value = v;
                if (_showError) _showError = false;
              }),
            ),
            const SizedBox(height: 12),
            AppButton(
              key: const Key('verification.inputSheet.submit'),
              label: context.t('verification.inputSheet.submit'),
              variant: AppButtonVariant.gold,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
