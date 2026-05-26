import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/i18n/i18n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/widgets.dart';
import '../data/meetings_service.dart';
import '../domain/meeting_review.dart';
import '../providers/pending_reviews_provider.dart';

/// Inline strip mounted above the chat input bar (gallery G3).
///
/// Renders ONLY when [pendingMeetingReviewsProvider] returns ≥1 row for
/// the conversation. Shows three buttons (Useful / Not useful / No-show)
/// for the most-recent pending review. On tap, calls
/// `submit_meeting_review` and refetches the pending list so the next
/// review (if any) takes its place.
class MeetingReviewPrompt extends ConsumerWidget {
  const MeetingReviewPrompt({super.key, required this.conversationId});

  final String conversationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(pendingMeetingReviewsProvider(conversationId));
    return pending.maybeWhen(
      data: (list) {
        if (list.isEmpty) return const SizedBox.shrink();
        final proposal = list.first;
        final colors = Theme.of(context).extension<AppColors>()!;
        final typo = Theme.of(context).extension<AppTypography>()!;
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
          child: AppCard(
            variant: AppCardVariant.featured,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.t('meetings.prompt.title'),
                  style: typo.displaySm.copyWith(color: colors.navy),
                ),
                const SizedBox(height: 4),
                Text(
                  context.t('meetings.prompt.subtitle'),
                  style: typo.bodyMd.copyWith(color: colors.muted),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    AppButton(
                      key: const Key('review-useful'),
                      label: context.t('meetings.review.useful'),
                      variant: AppButtonVariant.outline,
                      fullWidth: false,
                      size: AppButtonSize.small,
                      onPressed: () => _submit(
                        context,
                        ref,
                        proposal.id,
                        MeetingReviewOutcome.useful,
                      ),
                    ),
                    AppButton(
                      key: const Key('review-not-useful'),
                      label: context.t('meetings.review.notUseful'),
                      variant: AppButtonVariant.outline,
                      fullWidth: false,
                      size: AppButtonSize.small,
                      onPressed: () => _submit(
                        context,
                        ref,
                        proposal.id,
                        MeetingReviewOutcome.notUseful,
                      ),
                    ),
                    AppButton(
                      key: const Key('review-no-show'),
                      label: context.t('meetings.review.noShow'),
                      variant: AppButtonVariant.outline,
                      fullWidth: false,
                      size: AppButtonSize.small,
                      onPressed: () => _submit(
                        context,
                        ref,
                        proposal.id,
                        MeetingReviewOutcome.noShow,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }

  Future<void> _submit(
    BuildContext context,
    WidgetRef ref,
    String meetingId,
    MeetingReviewOutcome outcome,
  ) async {
    final toast = ref.read(toastServiceProvider.notifier);
    final translator = context.t;
    final submitted = translator('meetings.review.submitted');
    final failed = translator('meetings.review.submitFailed');
    try {
      await ref.read(meetingsServiceProvider).submitMeetingReview(
            meetingId: meetingId,
            outcome: outcome,
            note: null,
          );
      toast.showToast(title: submitted, intent: AppIntent.success);
    } on AppException catch (e) {
      toast.showToast(title: translator(e.i18nKey), intent: AppIntent.danger);
    } catch (_) {
      toast.showToast(title: failed, intent: AppIntent.danger);
    } finally {
      ref.invalidate(pendingMeetingReviewsProvider(conversationId));
    }
  }
}
