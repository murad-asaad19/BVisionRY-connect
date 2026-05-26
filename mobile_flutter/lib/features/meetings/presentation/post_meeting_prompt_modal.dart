import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/i18n/i18n.dart';
import '../../../core/routing/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/widgets.dart';
import '../data/meetings_service.dart';
import '../domain/meeting_review.dart';

/// G2 — full-screen "Did this meeting happen?" prompt.
///
/// Three actions:
///  - "Yes — it happened"  → pushes the G3 [MeetingReviewScreen] for the
///    same meeting (no review submitted yet).
///  - "Rescheduled to a new time" → submits a review with
///    [MeetingReviewOutcome.rescheduled] and pops.
///  - "No-show" → submits a review with [MeetingReviewOutcome.noShow]
///    and pops.
///
/// Triggered 30 min after a confirmed meeting's scheduled end via a
/// `meeting_review_pending` push (spec §16) — the navigator lands here
/// from `/meetings/:id/review`.
class PostMeetingPromptModal extends ConsumerStatefulWidget {
  const PostMeetingPromptModal({
    super.key,
    required this.meetingId,
    this.peerHandle,
    this.whenLabel,
  });

  final String meetingId;
  final String? peerHandle;
  final String? whenLabel;

  @override
  ConsumerState<PostMeetingPromptModal> createState() =>
      _PostMeetingPromptModalState();
}

class _PostMeetingPromptModalState
    extends ConsumerState<PostMeetingPromptModal> {
  bool _busy = false;

  Future<void> _submitOutcome(MeetingReviewOutcome outcome) async {
    if (_busy) return;
    setState(() => _busy = true);
    final toast = ref.read(toastServiceProvider.notifier);
    final navigator = Navigator.of(context);
    final translator = context.t;
    final submitted = translator('meetings.review.submitted');
    final failed = translator('meetings.review.submitFailed');
    try {
      await ref.read(meetingsServiceProvider).submitMeetingReview(
            meetingId: widget.meetingId,
            outcome: outcome,
            note: null,
          );
      toast.showToast(title: submitted, intent: AppIntent.success);
      if (mounted) navigator.pop();
    } on AppException catch (e) {
      toast.showToast(title: translator(e.i18nKey), intent: AppIntent.danger);
    } catch (_) {
      toast.showToast(title: failed, intent: AppIntent.danger);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _openReviewScreen() {
    if (_busy) return;
    final uri = Uri(
      path: Routes.meetingReviewFull(widget.meetingId),
      queryParameters: <String, String>{
        if (widget.peerHandle != null) 'handle': widget.peerHandle!,
        if (widget.whenLabel != null) 'when': widget.whenLabel!,
      },
    );
    // Replace this screen so the user lands on G3 with a back-stack that
    // doesn't include the "Did it happen?" prompt (they answered yes —
    // bouncing back to it would be confusing).
    context.pushReplacement(uri.toString());
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final typo = Theme.of(context).extension<AppTypography>()!;
    final peerName = widget.peerHandle ?? '';
    return Scaffold(
      backgroundColor: colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 50, 22, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 64px centered gold avatar + peer name row.
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Avatar(
                    name: peerName,
                    size: 48,
                    tone: AvatarTone.featured,
                  ),
                  const SizedBox(width: 10),
                  if (peerName.isNotEmpty)
                    Flexible(
                      child: Text(
                        peerName,
                        style: typo.displayMd.copyWith(color: colors.navy),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                context.t('meetings.prompt.title'),
                textAlign: TextAlign.center,
                style: typo.displayLg.copyWith(color: colors.navy),
              ),
              const SizedBox(height: 8),
              Text(
                widget.whenLabel != null
                    ? '${widget.whenLabel}. ${context.t('meetings.prompt.subtitle')}'
                    : context.t('meetings.prompt.subtitle'),
                textAlign: TextAlign.center,
                style: typo.bodyMd.copyWith(color: colors.muted),
              ),
              const SizedBox(height: 30),
              AppButton(
                key: const Key('post-prompt-yes'),
                label: context.t('meetings.prompt.yes'),
                variant: AppButtonVariant.gold,
                onPressed: _busy ? null : _openReviewScreen,
              ),
              const SizedBox(height: 10),
              AppButton(
                key: const Key('post-prompt-rescheduled'),
                label: context.t('meetings.prompt.rescheduled'),
                variant: AppButtonVariant.outline,
                onPressed: _busy
                    ? null
                    : () => _submitOutcome(MeetingReviewOutcome.rescheduled),
              ),
              const SizedBox(height: 10),
              AppButton(
                key: const Key('post-prompt-no-show'),
                label: context.t('meetings.prompt.noShow'),
                variant: AppButtonVariant.outlineDanger,
                onPressed: _busy
                    ? null
                    : () => _submitOutcome(MeetingReviewOutcome.noShow),
              ),
              const SizedBox(height: 16),
              Text(
                context.t('meetings.prompt.fallback'),
                textAlign: TextAlign.center,
                style: typo.bodyXs.copyWith(color: colors.muted, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
