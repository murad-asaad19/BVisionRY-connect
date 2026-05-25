import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/i18n/i18n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/widgets.dart';
import '../data/intros_service.dart';
import '../providers/intros_providers.dart';
import '_intro_note_field.dart';

/// Hard daily cap surfaced by `intros_today_count()` — the sender-side
/// limit kicks in at 20 and is enforced server-side via P0001/daily_cap.
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
    return Padding(
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
          _RecipientPreview(recipient: widget.recipient),
          const SizedBox(height: 16),
          _ComposeHint(),
          const SizedBox(height: 12),
          IntroNoteField(
            value: _note,
            onChanged: (v) => setState(() => _note = v),
            enabled: !_sending,
          ),
          const _TodayStatusLine(),
          if (_errorKey != null) ...[
            const SizedBox(height: 12),
            AppBanner(
              intent: AppIntent.danger,
              child: Text(context.t(_errorKey!)),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: AppButton(
                  label: context.t('intros.compose.cancel'),
                  variant: AppButtonVariant.outline,
                  onPressed: _sending
                      ? null
                      : () => Navigator.of(context).maybePop(false),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  key: const ValueKey('send-intro-sheet-send'),
                  label: context.t('intros.compose.send'),
                  loading: _sending,
                  onPressed: (valid && !_sending) ? _send : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ComposeHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final typo = Theme.of(context).extension<AppTypography>()!;
    return Text(
      context.t('intros.compose.hint'),
      style: typo.bodyMd.copyWith(color: colors.muted),
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
    return Row(
      children: <Widget>[
        Avatar(
          name: recipient.name,
          photoUrl: recipient.photoUrl,
          size: 32,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
    );
  }
}

/// `Today's intros: X/20` heads-up line shown beneath the field. Hidden
/// while the count is loading so the layout doesn't jitter.
class _TodayStatusLine extends ConsumerWidget {
  const _TodayStatusLine();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final typo = Theme.of(context).extension<AppTypography>()!;
    final asyncCount = ref.watch(todayCountProvider);
    return asyncCount.maybeWhen(
      data: (int count) {
        final atCap = count >= kIntrosDailyCapHard;
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            context.t(
              'intros.compose.todaysIntros',
              vars: <String, Object>{
                'count': count,
                'cap': kIntrosDailyCapHard,
              },
            ),
            style: typo.bodyXs.copyWith(
              color: atCap ? colors.danger : colors.muted,
            ),
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}
