import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/i18n/i18n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/widgets.dart';
import '../data/meetings_service.dart';
import '../domain/meeting_review.dart';

/// Full-screen variant of the review prompt (gallery G2). Opened by
/// `/meetings/:id/review` deep link (Phase 12 will dispatch this from a
/// `meeting_review_pending` push tap).
///
/// Same outcomes as [MeetingReviewPrompt] but rendered as three large
/// outcome cards + a Skip CTA at the bottom — useful when the user
/// hasn't yet seen the conversation context.
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

  Future<void> _submit(MeetingReviewOutcome outcome) async {
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

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final typo = Theme.of(context).extension<AppTypography>()!;
    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.white,
        elevation: 0,
        title: Text(context.t('meetings.review.title')),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.t('meetings.review.subtitle'),
                style: typo.bodyLg.copyWith(color: colors.body),
              ),
              if (widget.whenLabel != null) ...[
                const SizedBox(height: 8),
                Text(
                  widget.whenLabel!,
                  style: typo.bodyMd.copyWith(color: colors.muted),
                ),
              ],
              const SizedBox(height: 24),
              _OutcomeCard(
                key: const Key('post-review-useful'),
                icon: LucideIcons.thumbsUp,
                label: context.t('meetings.review.useful'),
                onTap:
                    _busy ? null : () => _submit(MeetingReviewOutcome.useful),
              ),
              const SizedBox(height: 8),
              _OutcomeCard(
                key: const Key('post-review-not-useful'),
                icon: LucideIcons.thumbsDown,
                label: context.t('meetings.review.notUseful'),
                onTap: _busy
                    ? null
                    : () => _submit(MeetingReviewOutcome.notUseful),
              ),
              const SizedBox(height: 8),
              _OutcomeCard(
                key: const Key('post-review-no-show'),
                icon: LucideIcons.userX,
                label: context.t('meetings.review.noShow'),
                onTap:
                    _busy ? null : () => _submit(MeetingReviewOutcome.noShow),
              ),
              const Spacer(),
              AppButton(
                key: const Key('post-review-skip'),
                label: context.t('meetings.review.skip'),
                variant: AppButtonVariant.outline,
                onPressed:
                    _busy ? null : () => Navigator.of(context).maybePop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OutcomeCard extends StatelessWidget {
  const _OutcomeCard({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final typo = Theme.of(context).extension<AppTypography>()!;
    final radii = Theme.of(context).extension<AppRadii>()!;
    return Material(
      color: colors.white,
      borderRadius: BorderRadius.circular(radii.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(radii.card),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radii.card),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              Icon(icon, color: colors.navy, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: typo.bodyLg.copyWith(color: colors.body),
                ),
              ),
              Icon(LucideIcons.chevronRight, color: colors.muted, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
