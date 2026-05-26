import 'package:flutter/material.dart';

import '../../../core/i18n/i18n.dart';
import '../../../core/widgets/app_filter_chip.dart';
import '../domain/opportunity_kind.dart';

/// Single-select Wrap of [AppFilterChip]s — one chip per [OpportunityKind].
///
/// Selected chip uses the active style (navy bg / white text); others use
/// the inactive style (white bg / navy border). Calls [onChanged] with the
/// newly-selected kind.
class KindPicker extends StatelessWidget {
  const KindPicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  /// Currently-selected kind, or `null` when no choice has been made yet.
  final OpportunityKind? value;
  final ValueChanged<OpportunityKind> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        for (final OpportunityKind k in OpportunityKind.values)
          AppFilterChip(
            label: context.t(k.i18nKey),
            active: k == value,
            onTap: () => onChanged(k),
          ),
      ],
    );
  }
}
