import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/i18n/i18n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_input.dart';
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
    final local = widget.slot.startsAt.toLocal();
    final dateLabel = DateFormat.MMMEd().add_jm().format(local);
    final duration = widget.slot.durationMinutes;

    return AppCard(
      padding: const EdgeInsets.all(12),
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
          if ((widget.slot.hostNotesTemplate ?? '').isNotEmpty) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              widget.slot.hostNotesTemplate!,
              style: typo.bodySm.copyWith(color: colors.muted),
            ),
          ],
          const SizedBox(height: 8),
          AppInput(
            label: context.t('officeHours.book.topicLabel'),
            placeholder: context.t('officeHours.book.topicPlaceholder'),
            value: _topic,
            multiline: true,
            maxLength: 280,
            onChanged: (v) => setState(() => _topic = v),
          ),
          const SizedBox(height: 8),
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
    );
  }
}
