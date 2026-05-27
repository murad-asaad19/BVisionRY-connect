import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/i18n/i18n.dart';
import '../../../core/routing/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/widgets.dart';
import '../data/intros_service.dart';
import '../providers/intros_providers.dart';
import '_intro_note_field.dart';

/// Hard daily cap surfaced by `intros_today_count()` for the *recipient*
/// inbound flow — server-side P0001 fires at 20 inbound intros per day.
/// The sender-side cap is tier-aware; see
/// [introsDailyCapForTier] in `providers/intros_providers.dart`.
const int kIntrosDailyCapHard = 20;

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
  });

  final String id;
  final String name;
  final String? handle;
  final String? photoUrl;
  final bool verified;
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
/// matching `char_length(btrim(note))` server-side. Surfaces the caller's
/// `intros_today_count()` underneath the field as a heads-up before the
/// hard P0001 cap fires.
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
      ref
        ..invalidate(sentIntrosProvider)
        ..invalidate(todayCountProvider);
      if (!mounted) return;
      ref.read(toastServiceProvider.notifier).showToast(
            title: context.t('profile.introSent'),
            intent: AppIntent.success,
          );
      Navigator.of(context).pop(true);
    } on AppException catch (e) {
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
          const SizedBox(height: 14),
          AppButton(
            key: const ValueKey('send-intro-sheet-send'),
            label: context.t('intros.compose.sendIntro'),
            variant: AppButtonVariant.gold,
            loading: _sending,
            // Surface the disabled visual when the note is too short —
            // otherwise the button looks tappable but no-ops, which the
            // user reads as a broken Send.
            disabled: !valid,
            onPressed: (valid && !_sending) ? _send : null,
          ),
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: _TodayStatusLine(),
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
                        style:
                            typo.displaySm.copyWith(color: colors.navy),
                      ),
                    ),
                    if (recipient.verified) ...[
                      const SizedBox(width: 6),
                      Icon(
                        Icons.verified,
                        size: 16,
                        color: colors.gold,
                      ),
                    ],
                  ],
                ),
                if (handle != null && handle.isNotEmpty)
                  Text(
                    '@$handle',
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

/// `Today's intros: X / cap` heads-up line shown beneath the field. Hidden
/// while the count is loading so the layout doesn't jitter. The cap is
/// tier-aware via [dailyIntroCapProvider].
class _TodayStatusLine extends ConsumerWidget {
  const _TodayStatusLine();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final typo = Theme.of(context).extension<AppTypography>()!;
    final asyncCount = ref.watch(todayCountProvider);
    final int cap = ref.watch(dailyIntroCapProvider);
    final IntrosTier tier = ref.watch(accountTierProvider);
    return asyncCount.maybeWhen(
      data: (int count) {
        final atCap = count >= cap;
        // Surface an upgrade affordance when the user is within 1 of the
        // cap *and* still has headroom on the next tier. Pro users have
        // no higher tier, so no nudge is shown.
        final nearCap = count >= cap - 1;
        final canUpgrade = tier != IntrosTier.pro;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Flexible(
              child: Text(
                context.t(
                  'intros.compose.todaysIntros',
                  vars: <String, Object>{
                    'count': count,
                    'cap': cap,
                  },
                ),
                textAlign: TextAlign.center,
                style: typo.bodyXs.copyWith(
                  color: atCap ? colors.danger : colors.muted,
                ),
              ),
            ),
            if (nearCap && canUpgrade) ...[
              const SizedBox(width: 8),
              GestureDetector(
                key: const Key('intros.compose.upgradePill'),
                onTap: () => context.push(Routes.settingsVerification),
                child: Pill(
                  label: context.t('intros.compose.upgradeForMore'),
                  variant: PillVariant.solid,
                ),
              ),
            ],
          ],
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}
