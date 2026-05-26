import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/i18n/i18n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/avatar.dart';
import '../../domain/my_booking.dart';

/// Renders one [MyBooking] on the My Bookings screen.
///
/// - Tap anywhere on the card body opens the canonical chat for this
///   booking via the parent's [onTap] callback.
/// - The outline-danger "Cancel" button calls [onCancel] — the parent
///   wraps it in a `ConfirmDialog` and routes to `cancel_booking`.
class BookingCard extends StatelessWidget {
  const BookingCard({
    super.key,
    required this.booking,
    required this.onCancel,
    required this.onTap,
  });

  final MyBooking booking;
  final VoidCallback onCancel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final typo = Theme.of(context).extension<AppTypography>()!;
    final dateLabel = DateFormat.MMMEd()
        .add_jm()
        .format(booking.startsAt.toLocal());
    return AppCard(
      onTap: onTap,
      child: Column(
        key: const ValueKey<String>('booking-tap'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              AvatarCircle(
                photoUrl: booking.hostPhotoUrl,
                name: booking.hostName,
                size: 40,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(booking.hostName, style: typo.displaySm),
                    Text(
                      dateLabel,
                      style: typo.bodyMd.copyWith(color: colors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (booking.topic != null && booking.topic!.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            Text(booking.topic!, style: typo.bodyLg),
          ],
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: AppButton(
              key: const ValueKey<String>('booking-cancel'),
              variant: AppButtonVariant.outlineDanger,
              size: AppButtonSize.small,
              fullWidth: false,
              label: context.t('officeHours.bookings.cancel'),
              onPressed: onCancel,
            ),
          ),
        ],
      ),
    );
  }
}
