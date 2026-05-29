import 'package:flutter/material.dart';

import '../../../core/i18n/i18n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/countries.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_filter_chip.dart';
import '../../../core/widgets/gap.dart';
import '../domain/feed_filters.dart';

const List<String> _kRoles = <String>[
  'founder',
  'leader',
  'builder',
  'investor',
];
const List<String> _kGoals = <String>[
  'hire',
  'be_hired',
  'co_found',
  'invest',
  'take_investment',
  'advise',
  'find_advisor',
  'peer_connect',
];

/// Opens the multi-select filter sheet (roles + goal types + country).
///
/// Resolves with the user-selected [FeedFilters] when Apply is tapped, or
/// `null` when the sheet is dismissed via backdrop / swipe.
Future<FeedFilters?> showFilterSheet(
  BuildContext context, {
  required FeedFilters initial,
}) {
  return showAppBottomSheet<FeedFilters>(
    context: context,
    child: _FilterSheetBody(initial: initial),
  );
}

class _FilterSheetBody extends StatefulWidget {
  const _FilterSheetBody({required this.initial});

  final FeedFilters initial;

  @override
  State<_FilterSheetBody> createState() => _FilterSheetBodyState();
}

class _FilterSheetBodyState extends State<_FilterSheetBody> {
  late final Set<String> _roles = widget.initial.roles.toSet();
  late final Set<String> _goalTypes = widget.initial.goalTypes.toSet();
  String? _country;

  @override
  void initState() {
    super.initState();
    _country = widget.initial.country;
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    final t = Theme.of(context).extension<AppTypography>()!;
    final spacing = Theme.of(context).extension<AppSpacing>()!;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        spacing.lg,
        spacing.xs,
        spacing.lg,
        spacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            context.t('discovery.filtersTitle'),
            style: t.displayMd.copyWith(color: c.navy),
          ),
          Gap(spacing.lg),
          Text(
            context.t('discovery.filtersRoles'),
            style: t.displaySm.copyWith(color: c.navy),
          ),
          Gap(spacing.sm),
          Wrap(
            spacing: spacing.sm,
            runSpacing: spacing.sm,
            children: <Widget>[
              for (final r in _kRoles)
                AppFilterChip(
                  label: context.t('discovery.roles.$r'),
                  active: _roles.contains(r),
                  onTap: () => setState(() {
                    if (_roles.contains(r)) {
                      _roles.remove(r);
                    } else {
                      _roles.add(r);
                    }
                  }),
                ),
            ],
          ),
          Gap(spacing.lg),
          Text(
            context.t('discovery.filtersGoals'),
            style: t.displaySm.copyWith(color: c.navy),
          ),
          Gap(spacing.sm),
          Wrap(
            spacing: spacing.sm,
            runSpacing: spacing.sm,
            children: <Widget>[
              for (final g in _kGoals)
                AppFilterChip(
                  label: context.t('discovery.goals.$g'),
                  active: _goalTypes.contains(g),
                  onTap: () => setState(() {
                    if (_goalTypes.contains(g)) {
                      _goalTypes.remove(g);
                    } else {
                      _goalTypes.add(g);
                    }
                  }),
                ),
            ],
          ),
          Gap(spacing.lg),
          Text(
            context.t('discovery.filtersCountry'),
            style: t.displaySm.copyWith(color: c.navy),
          ),
          Gap(spacing.sm),
          _CountryField(
            value: _country,
            onChanged: (String? v) => setState(() => _country = v),
          ),
          Gap(spacing.xxl),
          Row(
            children: <Widget>[
              Expanded(
                child: AppButton(
                  label: context.t('discovery.filtersReset'),
                  variant: AppButtonVariant.outline,
                  onPressed: () => setState(() {
                    _roles.clear();
                    _goalTypes.clear();
                    _country = null;
                  }),
                ),
              ),
              Gap(spacing.md),
              Expanded(
                child: AppButton(
                  label: context.t('discovery.filtersApply'),
                  onPressed: () => Navigator.of(context).pop(
                    FeedFilters(
                      roles: _roles.toList()..sort(),
                      goalTypes: _goalTypes.toList()..sort(),
                      country: _country,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Themed country selector styled to match [AppInput]: a tappable framed
/// field showing the current selection (or the "All" placeholder) that opens
/// [_CountryPickerSheet]. Replaces the off-design `DropdownButtonFormField`.
class _CountryField extends StatelessWidget {
  const _CountryField({required this.value, required this.onChanged});

  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    final radii = Theme.of(context).extension<AppRadii>()!;
    final typo = Theme.of(context).extension<AppTypography>()!;
    final spacing = Theme.of(context).extension<AppSpacing>()!;
    final bool hasValue = value != null && value!.isNotEmpty;
    final String display = hasValue ? value! : context.t('discovery.filterAll');

    return Semantics(
      button: true,
      label: context.t('discovery.filtersCountry'),
      value: display,
      child: Material(
        color: c.white,
        borderRadius: BorderRadius.circular(radii.input),
        child: InkWell(
          borderRadius: BorderRadius.circular(radii.input),
          onTap: () async {
            final result = await showAppBottomSheet<_CountrySelection>(
              context: context,
              child: _CountryPickerSheet(selected: value),
            );
            if (result != null) onChanged(result.value);
          },
          child: Container(
            key: const ValueKey('filter-country-field'),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radii.input),
              border: Border.all(color: c.border, width: 1.5),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: spacing.md,
              vertical: spacing.md,
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    display,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: typo.bodyLg.copyWith(
                      color: hasValue ? c.body : c.muted,
                    ),
                  ),
                ),
                Icon(Icons.expand_more, color: c.muted, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Wrapper so the sheet can resolve with an explicit `null` (= "All") vs.
/// being dismissed (= no change).
class _CountrySelection {
  const _CountrySelection(this.value);
  final String? value;
}

class _CountryPickerSheet extends StatelessWidget {
  const _CountryPickerSheet({required this.selected});

  final String? selected;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    final typo = Theme.of(context).extension<AppTypography>()!;
    final spacing = Theme.of(context).extension<AppSpacing>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.fromLTRB(
            spacing.lg,
            spacing.xs,
            spacing.lg,
            spacing.sm,
          ),
          child: Text(
            context.t('discovery.filtersCountry'),
            style: typo.displayMd.copyWith(color: c.navy),
          ),
        ),
        Flexible(
          child: ListView(
            shrinkWrap: true,
            padding: EdgeInsets.only(bottom: spacing.sm),
            children: <Widget>[
              _CountryTile(
                label: context.t('discovery.filterAll'),
                selected: selected == null || selected!.isEmpty,
                onTap: () =>
                    Navigator.of(context).pop(const _CountrySelection(null)),
              ),
              for (final CountryOption o in CountryOption.all)
                _CountryTile(
                  label: o.name,
                  selected: selected == o.name,
                  onTap: () =>
                      Navigator.of(context).pop(_CountrySelection(o.name)),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CountryTile extends StatelessWidget {
  const _CountryTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    final typo = Theme.of(context).extension<AppTypography>()!;
    final spacing = Theme.of(context).extension<AppSpacing>()!;
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: spacing.lg,
            vertical: spacing.md,
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  label,
                  style: typo.bodyLg.copyWith(
                    color: selected ? c.navy : c.body,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
              if (selected) Icon(Icons.check, color: c.navy, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
