import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/i18n/i18n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/widgets.dart';
import '../data/ics_service.dart';
import '../data/meetings_service.dart';
import '../domain/meeting_proposal.dart';
import '../domain/meeting_state.dart';
import 'confirm_meeting_sheet.dart';
import 'meeting_playbook_card.dart';

/// In-chat meeting bubble (gallery G1). Renders one of four state
/// variants:
///
/// - **proposed + viewer is proposer**: only "Cancel proposal" — server
///   raises `42501` if the proposer tries to confirm, so the Confirm
///   button is HIDDEN (not just disabled) per spec §3.5.
/// - **proposed + viewer is recipient**: Decline + Confirm. Confirm opens
///   [ConfirmMeetingSheet] to pick a slot.
/// - **confirmed**: Add to calendar (generates a `.ics`) + View playbook
///   (opens [MeetingPlaybookCard] in a bottom sheet).
/// - **declined / cancelled**: muted header only; slots crossed-out.
class MeetingCardBubble extends ConsumerWidget {
  const MeetingCardBubble({
    super.key,
    required this.proposal,
    required this.viewerId,
  });

  final MeetingProposal proposal;
  final String viewerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isProposer = proposal.isProposer(viewerId);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(
              state: proposal.state,
              durationMinutes: proposal.durationMinutes,
            ),
            const SizedBox(height: 10),
            _Slots(proposal: proposal),
            if (proposal.state == MeetingState.confirmed &&
                proposal.meetingUrl != null &&
                proposal.meetingUrl!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _MeetingUrl(url: proposal.meetingUrl!),
            ],
            if (proposal.note != null && proposal.note!.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              _ProposerNote(note: proposal.note!.trim()),
            ],
            if (proposal.hasEnded) ...[
              const SizedBox(height: 10),
              _EndedBanner(),
            ],
            const SizedBox(height: 12),
            _Actions(
              proposal: proposal,
              isProposer: isProposer,
              onConfirm: () => _openConfirmSheet(context),
              onDecline: () => _decline(context, ref),
              onCancel: () => _cancel(context, ref),
              onAddToCalendar: () => _addToCalendar(context, ref),
              onViewPlaybook: () => _viewPlaybook(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openConfirmSheet(BuildContext context) async {
    await showAppBottomSheet<void>(
      context: context,
      child: ConfirmMeetingSheet(proposal: proposal),
    );
  }

  Future<void> _decline(BuildContext context, WidgetRef ref) async {
    final confirmSvc = ref.read(confirmServiceProvider);
    final toast = ref.read(toastServiceProvider.notifier);
    final failedTitle = context.t('meetings.errors.actionFailed');
    // Resolve any i18n keys we'll need ahead of the await so we don't
    // touch [context] after an async gap.
    final translator = context.t;
    // Decline is terminal — gate it behind a destructive confirmation.
    final ok = await confirmSvc.confirm(
      context,
      title: translator('meetings.declineConfirm'),
      body: translator('meetings.declineConfirmBody'),
      confirmLabel: translator('meetings.decline'),
      cancelLabel: translator('common.cancel'),
      destructive: true,
    );
    if (!ok) return;
    // Destructive confirm accepted — buzz to acknowledge the terminal action.
    Haptics.error();
    try {
      await ref.read(meetingsServiceProvider).declineMeeting(proposal.id);
    } on AppException catch (e) {
      toast.showToast(title: translator(e.i18nKey), intent: AppIntent.danger);
    } catch (_) {
      toast.showToast(title: failedTitle, intent: AppIntent.danger);
    }
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final confirmSvc = ref.read(confirmServiceProvider);
    final toast = ref.read(toastServiceProvider.notifier);
    final failedTitle = context.t('meetings.errors.actionFailed');
    final translator = context.t;
    // Cancelling a proposal is terminal — gate it behind a destructive
    // confirmation (mirrors the my_bookings cancel flow).
    final ok = await confirmSvc.confirm(
      context,
      title: translator('meetings.cancelConfirm'),
      body: translator('meetings.cancelConfirmBody'),
      confirmLabel: translator('meetings.cancelProposal'),
      cancelLabel: translator('common.cancel'),
      destructive: true,
    );
    if (!ok) return;
    // Destructive confirm accepted — buzz to acknowledge the terminal action.
    Haptics.error();
    try {
      await ref.read(meetingsServiceProvider).cancelMeeting(proposal.id);
    } on AppException catch (e) {
      toast.showToast(title: translator(e.i18nKey), intent: AppIntent.danger);
    } catch (_) {
      toast.showToast(title: failedTitle, intent: AppIntent.danger);
    }
  }

  Future<void> _addToCalendar(BuildContext context, WidgetRef ref) async {
    final toast = ref.read(toastServiceProvider.notifier);
    // Resolve everything that touches [context] before the async gap.
    final title = context.t('meetings.title');
    String errorFor(Object e) => messageForError(context, e);
    final svc = IcsService();
    final start = proposal.confirmedSlot!.toUtc();
    final end = start.add(Duration(minutes: proposal.durationMinutes));
    try {
      Haptics.light();
      final file = await svc.generateIcsFile(
        meetingId: proposal.id,
        title: title,
        description: title,
        startUtc: start,
        endUtc: end,
        attendeesEmails: const [],
        location: proposal.meetingUrl,
      );
      await svc.shareIcs(file, subject: title);
    } catch (e) {
      // Generating or sharing the .ics can fail (temp-dir write error,
      // no share target). Surface it instead of failing silently.
      toast.showToast(title: errorFor(e), intent: AppIntent.danger);
    }
  }

  void _viewPlaybook(BuildContext context) {
    showAppBottomSheet<void>(
      context: context,
      child: MeetingPlaybookCard(meetingId: proposal.id),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.state, required this.durationMinutes});
  final MeetingState state;
  final int durationMinutes;

  @override
  Widget build(BuildContext context) {
    final typo = Theme.of(context).extension<AppTypography>()!;
    final colors = Theme.of(context).extension<AppColors>()!;
    final (label, variant) = switch (state) {
      MeetingState.proposed => (
          context.t('meetings.statusProposed'),
          PillVariant.info,
        ),
      MeetingState.confirmed => (
          context.t('meetings.statusConfirmed'),
          PillVariant.success,
        ),
      MeetingState.declined => (
          context.t('meetings.statusDeclined'),
          PillVariant.muted,
        ),
      MeetingState.cancelled => (
          context.t('meetings.statusCancelled'),
          PillVariant.muted,
        ),
    };
    return Row(
      children: [
        Icon(LucideIcons.calendar, color: colors.navy, size: 18),
        const SizedBox(width: 8),
        Text(
          context.t('meetings.title'),
          style: typo.displaySm.copyWith(color: colors.navy),
        ),
        const SizedBox(width: 8),
        // Cross-fade the status badge so a proposal flipping to "confirmed"
        // (or declined/cancelled) reads as a gentle state change, not a jump.
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeOut,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: ScaleTransition(scale: animation, child: child),
          ),
          child: Pill(
            key: ValueKey<MeetingState>(state),
            label: label,
            variant: variant,
          ),
        ),
        const Spacer(),
        Text(
          context.t(
            'meetings.durationLabel',
            vars: {'minutes': durationMinutes},
          ),
          style: typo.bodyMd.copyWith(color: colors.muted),
        ),
      ],
    );
  }
}

class _Slots extends StatelessWidget {
  const _Slots({required this.proposal});
  final MeetingProposal proposal;

  @override
  Widget build(BuildContext context) {
    final typo = Theme.of(context).extension<AppTypography>()!;
    final colors = Theme.of(context).extension<AppColors>()!;
    final fmt = DateFormat.MMMd().add_jm();
    final confirmed = proposal.confirmedSlot;
    final crossedOut = proposal.state == MeetingState.declined ||
        proposal.state == MeetingState.cancelled;
    final preferredIdx = proposal.preferredSlotIndex;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < proposal.slots.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Icon(
                  confirmed != null &&
                          proposal.slots[i].isAtSameMomentAs(confirmed)
                      ? LucideIcons.checkCircle2
                      : LucideIcons.clock,
                  size: 14,
                  color: crossedOut ? colors.muted : colors.navy,
                ),
                const SizedBox(width: 6),
                Text(
                  fmt.format(proposal.slots[i].toLocal()),
                  style: typo.bodyMd.copyWith(
                    color: crossedOut ? colors.muted : colors.body,
                    fontWeight: (confirmed != null &&
                                proposal.slots[i]
                                    .isAtSameMomentAs(confirmed)) ||
                            (confirmed == null && preferredIdx == i)
                        ? FontWeight.w700
                        : FontWeight.w400,
                    decoration: crossedOut ? TextDecoration.lineThrough : null,
                  ),
                ),
                // Highlight the proposer's preferred slot with a gold star
                // while the meeting is still pending — once confirmed, the
                // check-circle on the chosen slot carries that role.
                if (preferredIdx == i && confirmed == null && !crossedOut) ...[
                  const SizedBox(width: 6),
                  Icon(LucideIcons.star, size: 12, color: colors.gold),
                  const SizedBox(width: 4),
                  Text(
                    context.t('meetings.preferredSlot'),
                    style: typo.bodyXs.copyWith(
                      color: colors.gold,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _MeetingUrl extends StatelessWidget {
  const _MeetingUrl({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    final typo = Theme.of(context).extension<AppTypography>()!;
    final colors = Theme.of(context).extension<AppColors>()!;
    return Row(
      children: [
        Icon(LucideIcons.link, size: 14, color: colors.navy),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            url,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: typo.bodyMd.copyWith(color: colors.navy),
          ),
        ),
      ],
    );
  }
}

/// Quoted-block rendering of the proposer's optional note. Gold-pale fill
/// + navy left rule so it reads as a quoted excerpt and not part of the
/// slot list.
class _ProposerNote extends StatelessWidget {
  const _ProposerNote({required this.note});
  final String note;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final typo = Theme.of(context).extension<AppTypography>()!;
    return Container(
      decoration: BoxDecoration(
        color: colors.goldPale,
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: colors.gold, width: 3)),
      ),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      child: Text(
        note,
        style: typo.bodyMd.copyWith(color: colors.body, height: 1.35),
      ),
    );
  }
}

/// Inline label rendered when a confirmed meeting's slot + duration has
/// elapsed — replaces the "Add to calendar" CTA which would otherwise
/// generate an ICS for a past time. Pairs with the gating in [_Actions].
class _EndedBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final typo = Theme.of(context).extension<AppTypography>()!;
    return Row(
      children: [
        Icon(LucideIcons.checkCircle2, size: 14, color: colors.muted),
        const SizedBox(width: 6),
        Text(
          context.t('meetings.ended'),
          style: typo.bodyMd.copyWith(color: colors.muted),
        ),
      ],
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.proposal,
    required this.isProposer,
    required this.onConfirm,
    required this.onDecline,
    required this.onCancel,
    required this.onAddToCalendar,
    required this.onViewPlaybook,
  });

  final MeetingProposal proposal;
  final bool isProposer;
  final VoidCallback onConfirm;
  final VoidCallback onDecline;
  final VoidCallback onCancel;
  final VoidCallback onAddToCalendar;
  final VoidCallback onViewPlaybook;

  @override
  Widget build(BuildContext context) {
    if (proposal.state == MeetingState.proposed) {
      if (isProposer) {
        return Align(
          alignment: Alignment.centerRight,
          child: AppButton(
            label: context.t('meetings.cancelProposal'),
            variant: AppButtonVariant.outlineDanger,
            fullWidth: false,
            size: AppButtonSize.small,
            onPressed: onCancel,
          ),
        );
      }
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          AppButton(
            label: context.t('meetings.decline'),
            variant: AppButtonVariant.outline,
            fullWidth: false,
            size: AppButtonSize.small,
            onPressed: onDecline,
          ),
          const SizedBox(width: 8),
          AppButton(
            label: context.t('meetings.confirm'),
            fullWidth: false,
            size: AppButtonSize.small,
            onPressed: onConfirm,
          ),
        ],
      );
    }
    if (proposal.state == MeetingState.confirmed) {
      // Hide future-tense CTAs once the slot + duration has elapsed; the
      // ICS would be generated with start_time in the past and the
      // pre-meeting playbook copy would invite users to "prepare" for
      // something that already happened.
      if (proposal.hasEnded) return const SizedBox.shrink();
      return Wrap(
        alignment: WrapAlignment.end,
        spacing: 8,
        runSpacing: 8,
        children: [
          AppButton(
            label: context.t('meetings.addToCalendar'),
            variant: AppButtonVariant.outline,
            fullWidth: false,
            size: AppButtonSize.small,
            onPressed: onAddToCalendar,
          ),
          AppButton(
            label: context.t('meetings.playbook.title'),
            fullWidth: false,
            size: AppButtonSize.small,
            onPressed: onViewPlaybook,
          ),
        ],
      );
    }
    // declined / cancelled — no actions.
    return const SizedBox.shrink();
  }
}
