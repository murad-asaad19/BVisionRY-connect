import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/i18n/i18n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_input.dart';
import '../../../../core/widgets/gap.dart';
import '../../domain/office_hours_slot.dart';

/// Renders one upcoming slot on a host's public profile.
///
/// The booker enters a `topic` (5-280 chars) and taps "Confirm booking" to
/// trigger the parent's [onBook] callback. Parent is responsible for calling
/// `book_slot`, mapping errors to toasts, invalidating providers, and
/// navigating to the resulting chat.
class SlotCard extends StatefulWidget {
  const SlotCard({
    super.key,
    required this.slot,
    required this.onBook,
    this.loading = false,
  });

  final OfficeHoursSlot slot;
  final Future<void> Function(String slotId, String topic) onBook;
  final bool loading;

  @override
  State<SlotCard> createState() => _SlotCardState();
}

class _SlotCardState extends State<SlotCard> {
  String _topic = '';

  bool get _valid {
    final t = _topic.trim();
    return t.length >= 5 && t.length <= 280;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final typo = Theme.of(context).extension<AppTypography>()!;
    final spacing = Theme.of(context).extension<AppSpacing>()!;
    final local = widget.slot.startsAt.toLocal();
    final dateLabel = DateFormat.MMMEd().add_jm().format(local);
    final duration = widget.slot.durationMinutes;

    // While a booking is in flight, gently dim + settle the card so the slot
    // visibly reads as "being taken" before it drops out of the list.
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      opacity: widget.loading ? 0.6 : 1,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        scale: widget.loading ? 0.98 : 1,
        child: AppCard(
          padding: EdgeInsets.all(spacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(child: Text(dateLabel, style: typo.displaySm)),
                  Text(
                    context.t(
                      'officeHours.book.duration',
                      vars: <String, Object>{'minutes': duration},
                    ),
                    style: typo.bodyMd.copyWith(color: colors.muted),
                  ),
                ],
              ),
              Gap(spacing.xs),
              // Times above are rendered in the viewer's local zone — label it so
              // the slot isn't ambiguous across DST / travel.
              Text(
                context.t(
                  'officeHours.book.timezoneNote',
                  vars: <String, Object>{'timezone': local.timeZoneName},
                ),
                style: typo.bodyXs.copyWith(color: colors.muted),
              ),
              if ((widget.slot.hostNotesTemplate ?? '').isNotEmpty) ...<Widget>[
                Gap(spacing.sm),
                Text(
                  widget.slot.hostNotesTemplate!,
                  style: typo.bodySm.copyWith(color: colors.muted),
                ),
              ],
              Gap(spacing.sm),
              AppInput(
                label: context.t('officeHours.book.topicLabel'),
                placeholder: context.t('officeHours.book.topicPlaceholder'),
                value: _topic,
                multiline: true,
                maxLength: 280,
                enabled: !widget.loading,
                onChanged: (v) => setState(() => _topic = v),
              ),
              Gap(spacing.sm),
              AppButton(
                key: const ValueKey<String>('slot-book'),
                label: context.t('officeHours.book.submit'),
                loading: widget.loading,
                onPressed: _valid && !widget.loading
                    ? () => widget.onBook(widget.slot.id, _topic.trim())
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
