import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/i18n/i18n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_icon_button.dart';
import '../../../../core/widgets/gap.dart';
import '../../domain/office_hours_window.dart';

/// One row in the host's weekly-availability list.
///
/// Shows the localized weekday name, `HH:MM – HH:MM` range, and IANA tz
/// suffix; provides labeled Edit / Delete [AppIconButton]s that the parent
/// screen wires into the [OfficeHoursSettingsScreen] state machine.
class WindowListTile extends StatelessWidget {
  const WindowListTile({
    super.key,
    required this.window,
    required this.onEdit,
    required this.onDelete,
  });

  final OfficeHoursWindow window;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final typo = Theme.of(context).extension<AppTypography>()!;
    final spacing = Theme.of(context).extension<AppSpacing>()!;
    final range = '${OfficeHoursWindow.minuteToHhmm(window.startMinute)} – '
        '${OfficeHoursWindow.minuteToHhmm(window.endMinute)}';
    final weekdayLabel = context.t(
      'officeHours.settings.weekday_${window.weekday}',
    );
    return AppCard(
      padding: EdgeInsets.all(spacing.md),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(weekdayLabel, style: typo.displaySm),
                Gap(spacing.xs),
                Text(
                  '$range · ${window.timezone}',
                  style: typo.bodyMd.copyWith(color: colors.muted),
                ),
              ],
            ),
          ),
          AppIconButton(
            key: const ValueKey<String>('window-edit'),
            icon: LucideIcons.pencil,
            label: context.t('officeHours.settings.editWindow'),
            onPressed: onEdit,
          ),
          AppIconButton(
            key: const ValueKey<String>('window-delete'),
            icon: LucideIcons.trash2,
            label: context.t('officeHours.settings.removeWindow'),
            variant: AppIconButtonVariant.danger,
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
