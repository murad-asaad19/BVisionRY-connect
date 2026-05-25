import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'app_icon_button.dart';

/// Numeric +/- stepper.
///
/// Named `AppStepper` to avoid colliding with Flutter's Material
/// `Stepper` widget (which is a multi-step wizard, not a number bumper).
class AppStepper extends StatelessWidget {
  const AppStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 99,
    this.step = 1,
    this.suffix,
  });

  /// Current numeric value.
  final int value;

  /// Fires with the new value when +/- is pressed.
  final ValueChanged<int> onChanged;

  /// Lower bound (inclusive). Default 0.
  final int min;

  /// Upper bound (inclusive). Default 99.
  final int max;

  /// Increment applied per tap. Default 1.
  final int step;

  /// Optional unit suffix appended to the value (e.g. ` min`, `%`).
  final String? suffix;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    final typo = Theme.of(context).extension<AppTypography>()!;
    final atMin = value <= min;
    final atMax = value >= max;

    return Semantics(
      container: true,
      value: '$value${suffix ?? ''}',
      increasedValue: '${(value + step).clamp(min, max)}${suffix ?? ''}',
      decreasedValue: '${(value - step).clamp(min, max)}${suffix ?? ''}',
      child: Row(
        key: const ValueKey('app-stepper-frame'),
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIconButton(
            icon: Icons.remove,
            label: 'Decrement',
            size: AppIconButtonSize.sm,
            variant: AppIconButtonVariant.subtle,
            disabled: atMin,
            onPressed: atMin
                ? null
                : () => onChanged((value - step).clamp(min, max)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: SizedBox(
              width: 48,
              child: Text(
                '$value${suffix ?? ''}',
                key: const ValueKey('app-stepper-value'),
                textAlign: TextAlign.center,
                style: typo.displayMd.copyWith(color: c.navy),
              ),
            ),
          ),
          AppIconButton(
            icon: Icons.add,
            label: 'Increment',
            size: AppIconButtonSize.sm,
            variant: AppIconButtonVariant.subtle,
            disabled: atMax,
            onPressed: atMax
                ? null
                : () => onChanged((value + step).clamp(min, max)),
          ),
        ],
      ),
    );
  }
}
