import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_typography.dart';

/// Phase-7 placeholder for `MessageKind.meeting` rows.
///
/// Renders a goldPale card with a calendar icon and a static
/// "Meeting proposal (Phase 8)" label so the thread keeps scrolling
/// through mixed-media history without crashing on the meeting kind.
///
/// Phase 8 replaces this with the real `MeetingProposalCard` (propose /
/// accept / decline / confirm flows + office-hours integration).
class MeetingPlaceholderBubble extends StatelessWidget {
  const MeetingPlaceholderBubble({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final typo = Theme.of(context).extension<AppTypography>()!;
    final radii = Theme.of(context).extension<AppRadii>()!;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.goldPale,
        borderRadius: BorderRadius.circular(radii.card),
        border: Border.all(color: colors.goldLight),
      ),
      child: Row(
        children: <Widget>[
          Icon(LucideIcons.calendar, color: colors.navy, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Meeting proposal (Phase 8)',
              style: typo.bodyLg.copyWith(color: colors.navy),
            ),
          ),
        ],
      ),
    );
  }
}
