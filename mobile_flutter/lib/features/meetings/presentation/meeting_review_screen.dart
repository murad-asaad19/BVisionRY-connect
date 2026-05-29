import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/i18n/i18n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/widgets.dart';
import '../data/meetings_service.dart';
import '../domain/meeting_review.dart';

/// G3 — full-screen post-connection meeting review.
///
/// Three outcomes:
///  - Useful (success-styled button — the recommended action)
///  - Not useful (outline)
///  - No-show (outline danger)
///
/// After submit, pops back to whatever pushed this screen — typically the
/// `meeting_review_pending` push deep-link path.
class MeetingReviewScreen extends ConsumerStatefulWidget {
  const MeetingReviewScreen({
    super.key,
    required this.meetingId,
    this.peerHandle,
  });

  final String meetingId;
  final String? peerHandle;

  @override
  ConsumerState<MeetingReviewScreen> createState() =>
      _MeetingReviewScreenState();
}

class _MeetingReviewScreenState extends ConsumerState<MeetingReviewScreen> {
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
    final peerName = widget.peerHandle ?? '';
    final hasName = peerName.isNotEmpty;
    // Focused full-screen prompt (mockup G3): no TopBar chrome — back
    // navigation stays reachable via the OS/system back gesture. Slim
    // ~60px avatar instead of the prior 96px.
    return Scaffold(
      backgroundColor: colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 40, 22, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Avatar(
                  name: peerName,
                  size: 60,
                  tone: AvatarTone.featured,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                hasName
                    ? context.t(
                        'meetings.review.titleWithName',
                        vars: {'name': peerName},
                      )
                    : context.t('meetings.review.title'),
                textAlign: TextAlign.center,
                style: typo.displayLg.copyWith(color: colors.navy),
              ),
              const SizedBox(height: 8),
              Text(
                context.t('meetings.review.subtitle'),
                textAlign: TextAlign.center,
                style: typo.bodyMd.copyWith(color: colors.muted),
              ),
              const SizedBox(height: 30),
              // "Useful" uses success styling (mockup G3): success-bg fill,
              // success-text label + 1.5px success-text border. AppButton has
              // no success variant and lives outside this feature, so this is
              // a one-off styled button matching AppButton's shape/sizing.
              _SuccessButton(
                key: const Key('review-screen-useful'),
                label: context.t('meetings.review.useful'),
                onPressed:
                    _busy ? null : () => _submit(MeetingReviewOutcome.useful),
              ),
              const SizedBox(height: 10),
              AppButton(
                key: const Key('review-screen-not-useful'),
                label: context.t('meetings.review.notUseful'),
                variant: AppButtonVariant.outline,
                onPressed: _busy
                    ? null
                    : () => _submit(MeetingReviewOutcome.notUseful),
              ),
              const SizedBox(height: 10),
              AppButton(
                key: const Key('review-screen-no-show'),
                label: context.t('meetings.review.noShow'),
                variant: AppButtonVariant.outlineDanger,
                onPressed:
                    _busy ? null : () => _submit(MeetingReviewOutcome.noShow),
              ),
              const SizedBox(height: 18),
              Text(
                context.t('meetings.review.aggregateNote'),
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

/// Full-width "Useful" button styled with the success palette (mockup G3:
/// success-bg fill, success-text label, 1.5px success-text border). Mirrors
/// [AppButton]'s 10-radius shape, min-height, padding, and label sizing so it
/// sits flush with the outline buttons beneath it.
class _SuccessButton extends StatelessWidget {
  const _SuccessButton({super.key, required this.label, this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final radii = Theme.of(context).extension<AppRadii>()!;
    final typo = Theme.of(context).extension<AppTypography>()!;
    final disabled = onPressed == null;
    final bg = disabled ? colors.slate300 : colors.successBg;
    final fg = disabled ? colors.white : colors.success;
    return Semantics(
      button: true,
      enabled: !disabled,
      label: label,
      child: ExcludeSemantics(
        child: SizedBox(
          width: double.infinity,
          child: Material(
            color: bg,
            borderRadius: BorderRadius.circular(radii.button),
            child: InkWell(
              borderRadius: BorderRadius.circular(radii.button),
              onTap: onPressed,
              child: Container(
                constraints: const BoxConstraints(minHeight: 48),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(radii.button),
                  border: Border.all(color: fg, width: 1.5),
                ),
                child: Text(
                  label,
                  style: typo.displaySm.copyWith(color: fg, fontSize: 13),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
