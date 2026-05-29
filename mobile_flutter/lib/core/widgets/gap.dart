import 'package:flutter/widgets.dart';

/// A blank square spacer used between children of a Row/Column.
///
/// Prefer feeding it a spacing token at the call site, e.g. `Gap(spacing.md)`,
/// instead of `SizedBox(height: 12)`. Because it is empty, setting both
/// dimensions is harmless and the helper works in both axes.
class Gap extends StatelessWidget {
  const Gap(this.size, {super.key});

  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(dimension: size);
}
