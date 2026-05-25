import 'package:flutter/material.dart';

import '../../../core/i18n/i18n.dart';
import '../../../core/utils/countries.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_filter_chip.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../domain/feed_filters.dart';

const List<String> _kRoles = <String>['founder', 'leader', 'builder', 'investor'];
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
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            context.t('discovery.filtersTitle'),
            style: t.displayMd.copyWith(color: c.navy),
          ),
          const SizedBox(height: 16),
          Text(
            context.t('discovery.filtersRoles'),
            style: t.displaySm.copyWith(color: c.navy),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
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
          const SizedBox(height: 16),
          Text(
            context.t('discovery.filtersGoals'),
            style: t.displaySm.copyWith(color: c.navy),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
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
          const SizedBox(height: 16),
          Text(
            context.t('discovery.filtersCountry'),
            style: t.displaySm.copyWith(color: c.navy),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String?>(
            value: _country,
            isExpanded: true,
            hint: Text(context.t('discovery.countryPlaceholder')),
            items: <DropdownMenuItem<String?>>[
              DropdownMenuItem<String?>(
                value: null,
                child: Text(context.t('discovery.filterAll')),
              ),
              for (final c in CountryOption.all)
                DropdownMenuItem<String?>(value: c.name, child: Text(c.name)),
            ],
            onChanged: (v) => setState(() => _country = v),
          ),
          const SizedBox(height: 24),
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
              const SizedBox(width: 12),
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
