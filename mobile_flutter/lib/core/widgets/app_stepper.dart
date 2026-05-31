import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_typography.dart';

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
    final radii = Theme.of(context).extension<AppRadii>()!;
    final typo = Theme.of(context).extension<AppTypography>()!;
    final atMin = value <= min;
    final atMax = value >= max;

    // 46px-wide InkWell tap zone showing a +/- glyph in navy. Disabled at
    // the bound — the glyph mutes and the tap handler clears.
    Widget tapZone({
      required IconData icon,
      required String label,
      required bool disabled,
      required VoidCallback onTap,
    }) {
      return Semantics(
        button: true,
        label: label,
        enabled: !disabled,
        child: InkWell(
          onTap: disabled ? null : onTap,
          child: SizedBox(
            width: 46,
            height: double.infinity,
            child: Center(
              child: Icon(
                icon,
                size: 18,
                color: disabled ? c.muted : c.navy,
              ),
            ),
          ),
        ),
      );
    }

    return Semantics(
      container: true,
      value: '$value${suffix ?? ''}',
      increasedValue: '${(value + step).clamp(min, max)}${suffix ?? ''}',
      decreasedValue: '${(value - step).clamp(min, max)}${suffix ?? ''}',
      child: Container(
        key: const ValueKey('app-stepper-frame'),
        height: 46,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: c.white,
          border: Border.all(color: c.border, width: 1.5),
          borderRadius: BorderRadius.circular(radii.input),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            tapZone(
              icon: Icons.remove,
              label: 'Decrement',
              disabled: atMin,
              onTap: () => onChanged((value - step).clamp(min, max)),
            ),
            Container(
              constraints: const BoxConstraints(minWidth: 56),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: c.border),
                  right: BorderSide(color: c.border),
                ),
              ),
              child: Text(
                '$value${suffix ?? ''}',
                key: const ValueKey('app-stepper-value'),
                textAlign: TextAlign.center,
                style: typo.displayMd.copyWith(color: c.navy),
              ),
            ),
            tapZone(
              icon: Icons.add,
              label: 'Increment',
              disabled: atMax,
              onTap: () => onChanged((value + step).clamp(min, max)),
            ),
          ],
        ),
      ),
    );
  }
}
