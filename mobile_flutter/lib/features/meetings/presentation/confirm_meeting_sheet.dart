import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/i18n/i18n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/widgets.dart';
import '../data/meetings_service.dart';
import '../domain/meeting_proposal.dart';

/// Bottom-sheet used by the recipient to confirm one of the 1-3 proposed
/// slots. Renders a radio list of [MeetingProposal.slots] (defaults to the
/// first one), a Confirm button, and surfaces server-side validation
/// failures via inline error text.
///
/// The proposer never sees this sheet — [MeetingCardBubble] hides the
/// Confirm button entirely on their side (spec §3.5).
class ConfirmMeetingSheet extends ConsumerStatefulWidget {
  const ConfirmMeetingSheet({super.key, required this.proposal});

  final MeetingProposal proposal;

  @override
  ConsumerState<ConfirmMeetingSheet> createState() =>
      _ConfirmMeetingSheetState();
}

class _ConfirmMeetingSheetState extends ConsumerState<ConfirmMeetingSheet> {
  DateTime? _selected;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selected = widget.proposal.slots.first;
  }

  Future<void> _submit() async {
    if (_selected == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(meetingsServiceProvider)
          .confirmMeeting(widget.proposal.id, _selected!);
      if (mounted) Navigator.of(context).pop();
    } on AppException catch (e) {
      if (mounted) setState(() => _error = context.t(e.i18nKey));
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = context.t('meetings.errors.actionFailed'),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final typo = Theme.of(context).extension<AppTypography>()!;
    final fmt = DateFormat.MMMd().add_jm();
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.t('meetings.confirmSheet.title'),
              style: typo.displayMd.copyWith(color: colors.navy),
            ),
            const SizedBox(height: 4),
            Text(
              context.t('meetings.confirmSheet.subtitle'),
              style: typo.bodyMd.copyWith(color: colors.muted),
            ),
            const SizedBox(height: 12),
            for (final s in widget.proposal.slots)
              // ignore: deprecated_member_use
              RadioListTile<DateTime>(
                key: ValueKey('confirm-slot-${s.toIso8601String()}'),
                value: s,
                // ignore: deprecated_member_use
                groupValue: _selected,
                // ignore: deprecated_member_use
                onChanged: _busy
                    ? null
                    : (v) => setState(() => _selected = v),
                title: Text(
                  fmt.format(s.toLocal()),
                  style: typo.bodyLg.copyWith(color: colors.body),
                ),
                contentPadding: EdgeInsets.zero,
                activeColor: colors.navy,
              ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: typo.bodyMd.copyWith(color: colors.danger),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AppButton(
                  label: context.t('common.cancel'),
                  variant: AppButtonVariant.outline,
                  fullWidth: false,
                  size: AppButtonSize.small,
                  onPressed: _busy ? null : () => Navigator.pop(context),
                ),
                const SizedBox(width: 8),
                AppButton(
                  key: const Key('confirm-submit'),
                  label: context.t('meetings.confirm'),
                  fullWidth: false,
                  size: AppButtonSize.small,
                  loading: _busy,
                  onPressed: _busy ? null : _submit,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
