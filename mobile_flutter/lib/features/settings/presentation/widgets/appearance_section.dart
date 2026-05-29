import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/i18n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../core/widgets/segmented_control.dart';
import '../../providers/appearance_provider.dart';

/// Appearance control surfaced on the settings home screen — a
/// System / Light / Dark [SegmentedControl] bound to [appearanceProvider].
///
/// Selecting a segment persists the choice via [AppearanceController.setMode]
/// and drives the live `themeModeProvider`, so the whole app re-themes
/// immediately and the choice survives a cold start.
class AppearanceSection extends ConsumerWidget {
  const AppearanceSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppColors colors = Theme.of(context).extension<AppColors>()!;
    final AppSpacing spacing = Theme.of(context).extension<AppSpacing>()!;
    final AppTypography typo = Theme.of(context).extension<AppTypography>()!;
    // While the persisted value is still loading we fall back to the live
    // provider so the control never renders blank on a cold start.
    final ThemeMode current =
        ref.watch(appearanceProvider).valueOrNull ?? ThemeMode.system;

    return Container(
      key: const Key('settings.appearanceSection'),
      margin: EdgeInsets.symmetric(horizontal: spacing.md),
      padding: EdgeInsets.all(spacing.md),
      decoration: BoxDecoration(
        color: colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            context.t('settings.appearance.title'),
            style: typo.displaySm.copyWith(color: colors.navy),
          ),
          SizedBox(height: spacing.sm),
          SegmentedControl<ThemeMode>(
            key: const Key('settings.appearanceControl'),
            value: current,
            options: <SegmentedOption<ThemeMode>>[
              SegmentedOption<ThemeMode>(
                value: ThemeMode.system,
                label: context.t('settings.appearance.system'),
              ),
              SegmentedOption<ThemeMode>(
                value: ThemeMode.light,
                label: context.t('settings.appearance.light'),
              ),
              SegmentedOption<ThemeMode>(
                value: ThemeMode.dark,
                label: context.t('settings.appearance.dark'),
              ),
            ],
            onChange: (ThemeMode mode) {
              Haptics.selection();
              ref.read(appearanceProvider.notifier).setMode(mode);
            },
          ),
        ],
      ),
    );
  }
}
