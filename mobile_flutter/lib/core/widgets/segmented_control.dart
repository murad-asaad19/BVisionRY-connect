import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// A single segment in a [SegmentedControl].
@immutable
class SegmentedOption<T> {
  const SegmentedOption({required this.value, required this.label});

  final T value;
  final String label;
}

/// Generic pill-bar selector used for filters / mode toggles.
///
/// Equal-flex segments sit on a `slate100` trough; the selected segment
/// flips to navy fill with white text. Generic over the value type so
/// call sites can use enum / string / int values interchangeably.
class SegmentedControl<T> extends StatelessWidget {
  const SegmentedControl({
    super.key,
    required this.options,
    required this.value,
    required this.onChange,
  });

  /// Available segments. Must contain at least one entry.
  final List<SegmentedOption<T>> options;

  /// Currently-selected value. Must be present in [options].
  final T value;

  /// Fired with the new value when a different segment is tapped.
  final ValueChanged<T> onChange;

  @override
  Widget build(BuildContext context) {
    assert(options.isNotEmpty, 'options must not be empty');
    final c = Theme.of(context).extension<AppColors>()!;
    final typo = Theme.of(context).extension<AppTypography>()!;

    return Container(
      key: const ValueKey('segmented-control-frame'),
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: c.slate100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          for (final option in options)
            Expanded(
              child: _Segment<T>(
                option: option,
                active: option.value == value,
                colors: c,
                typography: typo,
                onTap: () {
                  if (option.value != value) onChange(option.value);
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _Segment<T> extends StatelessWidget {
  const _Segment({
    required this.option,
    required this.active,
    required this.colors,
    required this.typography,
    required this.onTap,
  });

  final SegmentedOption<T> option;
  final bool active;
  final AppColors colors;
  final AppTypography typography;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: active,
      label: option.label,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: active ? colors.navy : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            // Shrink-to-fit so a wider set (e.g. 4 segments with count-bearing
            // labels) never overflows the equal-flex segment width.
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                option.label,
                maxLines: 1,
                style: typography.displaySm.copyWith(
                  color: active ? colors.white : colors.muted,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
