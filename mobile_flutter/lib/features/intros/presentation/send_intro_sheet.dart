import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/analytics/analytics_events.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/i18n/i18n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/widgets.dart';
import '../../auth/providers/session_provider.dart';
import '../data/intros_service.dart';
import '../providers/intros_providers.dart';
import '_intro_note_field.dart';

/// Recipient preview shape passed into [showSendIntroSheet]. Keeping this
/// small + typed avoids leaking the full Profile model through every call
/// site (Phase 4 publicProfile, Phase 5 daily-matches, Phase 9 search).
class SendIntroRecipient {
  const SendIntroRecipient({
    required this.id,
    required this.name,
    this.handle,
    this.photoUrl,
    this.verified = false,
    this.role,
    this.headline,
  });

  final String id;
  final String name;
  final String? handle;
  final String? photoUrl;
  final bool verified;

  /// Short role word shown inline as the verified badge label and, when the
  /// recipient isn't verified, leading the muted subtitle line (gallery E1
  /// line 1755: "Omar Daher · Builder").
  final String? role;

  /// Headline / "open to" tagline rendered as the muted subtitle line under
  /// the name (gallery E1 line 1756: "Senior backend · Open to fractional
  /// CTO").
  final String? headline;
}

/// Opens the direct-intro composer for [recipient]. Returns `true` when the
/// caller successfully sent an intro and the sheet dismissed itself; `null`
/// when the user backed out.
Future<bool?> showSendIntroSheet(
  BuildContext context, {
  required SendIntroRecipient recipient,
}) {
  return showAppBottomSheet<bool>(
    context: context,
    child: SendIntroSheet(recipient: recipient),
  );
}

/// Bottom-sheet composer for a direct (kind=`direct`) intro.
///
/// Drives `IntrosService.sendIntro` with 80-400 trimmed-length gating
/// matching `char_length(btrim(note))` server-side.
///
/// Surfaces a sender-side "Today's intros: used / cap" heads-up beneath the
/// Send button, backed by [sentTodayProvider] (`intros_sent_today_count()`).
/// The cap shown is the server-authoritative value returned by the RPC, not
/// the client tier guess, so the heads-up always matches what the server
/// enforces.
class SendIntroSheet extends ConsumerStatefulWidget {
  const SendIntroSheet({super.key, required this.recipient});

  final SendIntroRecipient recipient;

  @override
  ConsumerState<SendIntroSheet> createState() => _SendIntroSheetState();
}

class _SendIntroSheetState extends ConsumerState<SendIntroSheet> {
  String _note = '';
  bool _sending = false;
  String? _errorKey;

  Future<void> _send() async {
    if (!isIntroNoteInRange(_note)) return;
    setState(() {
      _sending = true;
      _errorKey = null;
    });
    try {
      final IntrosService svc = ref.read(introsServiceProvider);
      await svc.sendIntro(recipientId: widget.recipient.id, note: _note);
      Analytics.log(
        AppEvent.introSent,
        const <String, Object>{'via_warm': false},
      );
      ref
        ..invalidate(sentIntrosProvider)
        ..invalidate(todayCountProvider)
        ..invalidate(sentTodayProvider);
      if (!mounted) return;
      // Medium impact — confirms the intro left the device.
      Haptics.medium();
      ref.read(toastServiceProvider.notifier).showToast(
            title: context.t('profile.introSent'),
            intent: AppIntent.success,
          );
      // Defer the pop one frame so the toast's enter animation kicks off
      // before the sheet tears down its render subtree. Without this gap
      // the user sees the sheet vanish with no confirmation (T-INTRO-SEND-
      // TOAST-RACE).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop(true);
      });
    } on AppException catch (e) {
      Analytics.log(
        AppEvent.introSendFailed,
        const <String, Object>{'via_warm': false},
      );
      if (!mounted) return;
      setState(() => _errorKey = _resolveErrorKey(e));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  /// Map known exceptions to their compose-context i18n key. Falls back to
  /// the generic compose-failure copy for anything we don't recognise.
  String _resolveErrorKey(AppException e) {
    if (e is IntroCooldownException) return 'intros.compose.errorCooldown';
    if (e is DailyCapException) return 'intros.compose.errorRateLimit';
    if (e is DuplicateException) return 'intros.compose.errorDuplicate';
    if (e is IntroNoteRangeException) return 'intros.compose.errorRange';
    return 'intros.compose.errorGeneric';
  }

  @override
  Widget build(BuildContext context) {
    final bool valid = isIntroNoteInRange(_note);
    final colors = Theme.of(context).extension<AppColors>()!;
    final typo = Theme.of(context).extension<AppTypography>()!;
    // Email soft-gate (spec §13 / gallery B5): a viewer may browse + compose,
    // but the Send-intro CTA stays locked until their email is verified. We
    // read `emailConfirmedAt` straight off the live session so the lock
    // clears the moment the user taps the link (auth state change rebuilds).
    final session = ref.watch(currentSessionProvider);
    final bool emailUnverified =
        session != null && session.user.emailConfirmedAt == null;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Sheet title — mirrors the gallery's "Send intro to Omar" header.
          Text(
            context.t(
              'intros.compose.sheetTitle',
              vars: <String, Object>{'name': widget.recipient.name},
            ),
            style: typo.displayLg.copyWith(color: colors.navy, fontSize: 17),
          ),
          const SizedBox(height: 10),
          _RecipientPreview(recipient: widget.recipient),
          const SizedBox(height: 14),
          IntroNoteField(
            value: _note,
            onChanged: (v) => setState(() => _note = v),
            enabled: !_sending,
          ),
          if (_errorKey != null) ...[
            const SizedBox(height: 12),
            AppBanner(
              intent: AppIntent.danger,
              child: Text(context.t(_errorKey!)),
            ),
          ],
          if (emailUnverified) ...[
            const SizedBox(height: 12),
            AppBanner(
              key: const ValueKey('send-intro-email-gate'),
              intent: AppIntent.warning,
              child: Text(
                context.t(
                  'intros.compose.verifyEmailFirst',
                  vars: <String, Object>{
                    'email': session.user.email ?? '',
                  },
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          AppButton(
            key: const ValueKey('send-intro-sheet-send'),
            label: emailUnverified
                ? context.t('intros.compose.verifyEmailCta')
                : context.t('intros.compose.sendIntro'),
            variant: AppButtonVariant.gold,
            loading: _sending,
            onPressed: (valid && !_sending && !emailUnverified) ? _send : null,
          ),
          // Sender-side "Today's intros: used / cap" heads-up. The cap is the
          // server-authoritative value from the RPC (sentTodayProvider), not
          // the client tier guess. Render nothing while loading/erroring so the
          // sheet never flashes a placeholder count.
          ...ref.watch(sentTodayProvider).maybeWhen(
                data: (count) => <Widget>[
                  const SizedBox(height: 10),
                  Text(
                    context.t(
                      'intros.compose.todaysIntros',
                      vars: <String, Object>{
                        'count': count.used,
                        'cap': count.cap,
                      },
                    ),
                    key: const ValueKey('send-intro-today-counter'),
                    textAlign: TextAlign.center,
                    style: typo.bodyMd.copyWith(color: colors.muted),
                  ),
                ],
                orElse: () => const <Widget>[],
              ),
        ],
      ),
    );
  }
}

class _RecipientPreview extends StatelessWidget {
  const _RecipientPreview({required this.recipient});

  final SendIntroRecipient recipient;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final typo = Theme.of(context).extension<AppTypography>()!;
    final handle = recipient.handle;
    final role = recipient.role;
    final headline = recipient.headline;
    // Muted subtitle line under the name (gallery E1 line 1756). Prefer the
    // headline/"open to" tagline; fall back to the @handle so the card never
    // loses its secondary identifier when no headline is set. When the role
    // word isn't folded into the verified badge, lead the subtitle with it.
    final List<String> subtitleParts = <String>[
      if (!recipient.verified && role != null && role.isNotEmpty) role,
      if (headline != null && headline.isNotEmpty)
        headline
      else if (handle != null && handle.isNotEmpty)
        '@$handle',
    ];
    final String? subtitle =
        subtitleParts.isEmpty ? null : subtitleParts.join(' · ');
    // Gold-pale rounded rectangle chrome mirrors `.ucard.featured` from the
    // gallery so the recipient block reads as a quick-reference card rather
    // than a bare name.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: colors.goldPale,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: <Widget>[
          Avatar(
            name: recipient.name,
            photoUrl: recipient.photoUrl,
            size: 32,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        recipient.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: typo.displaySm.copyWith(color: colors.navy),
                      ),
                    ),
                    if (recipient.verified) ...[
                      const SizedBox(width: 6),
                      // Role-text verified badge ("✓ Builder") matching the
                      // gallery's `.verified-badge` rather than a bare check.
                      Pill(
                        key: const ValueKey('send-intro-verified'),
                        label: (role != null && role.isNotEmpty)
                            ? role
                            : context.t('verification.verifiedPill'),
                        variant: PillVariant.success,
                        icon: Icons.check,
                      ),
                    ],
                  ],
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: typo.bodyMd.copyWith(color: colors.muted),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
