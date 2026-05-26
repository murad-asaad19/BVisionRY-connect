import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/i18n/i18n.dart';
import '../../../core/routing/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_input.dart';
import '../../../core/widgets/query_state.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/segmented_control.dart';
import '../../../core/widgets/settings_row.dart';
import '../../../core/widgets/app_stepper.dart';
import '../../../core/widgets/toast.dart';
import '../../../core/widgets/top_bar.dart';
import '../../../core/widgets/variants.dart';
import '../domain/office_hours_settings.dart';
import '../domain/office_hours_window.dart';
import '../providers/office_hours_settings_provider.dart';
import 'widgets/window_list_tile.dart';
import 'window_editor_sheet.dart';

/// Host-side Office Hours configuration screen at `/settings/office-hours`.
///
/// Sections, top to bottom:
/// 1. Enable toggle (re-saves the whole row with the new `enabled` flag).
/// 2. Weekly availability — list of `WindowListTile` + "Add window" button
///    that opens `WindowEditorSheet`. Each tile supports edit/delete.
/// 3. Slot duration — `SegmentedControl` over `allowedSlotDurations`.
/// 4. Buffer minutes — `AppStepper` 0..60.
/// 5. Max bookings per week — `AppStepper` 1..50.
/// 6. Meeting link template — `AppInput` with `{slot_id}` hint.
/// 7. Notes template — multiline `AppInput`.
/// 8. My Bookings entry row at the bottom.
///
/// Every field change calls [_save] which re-issues `set_office_hours` and
/// shows a success/error toast based on the returned [AppException] key.
class OfficeHoursSettingsScreen extends ConsumerWidget {
  const OfficeHoursSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(officeHoursSettingsProvider);
    final colors = Theme.of(context).extension<AppColors>()!;
    return Scaffold(
      backgroundColor: colors.surface,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: TopBar(
          title: context.t('officeHours.settings.title'),
          back: Navigator.of(context).canPop(),
        ),
      ),
      body: QueryState<OfficeHoursSettings>(
        value: async,
        onRetry: () => ref.invalidate(officeHoursSettingsProvider),
        data: (s) => _Body(initial: s),
      ),
    );
  }
}

class _Body extends ConsumerStatefulWidget {
  const _Body({required this.initial});
  final OfficeHoursSettings initial;
  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  late OfficeHoursSettings _draft;

  @override
  void initState() {
    super.initState();
    _draft = widget.initial;
  }

  Future<void> _save(OfficeHoursSettings next) async {
    setState(() => _draft = next);
    final toast = ref.read(toastServiceProvider.notifier);
    final translator = context.t;
    try {
      await ref.read(officeHoursSettingsProvider.notifier).save(next);
      if (!mounted) return;
      toast.showToast(
        title: translator('officeHours.settings.saved'),
        intent: AppIntent.success,
      );
    } on AppException catch (e) {
      toast.showToast(
        title: translator(e.i18nKey),
        intent: AppIntent.danger,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final typo = Theme.of(context).extension<AppTypography>()!;
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      children: <Widget>[
        SectionCard(
          title: context.t('officeHours.settings.title'),
          child: SwitchListTile(
            key: const ValueKey<String>('oh-enable-switch'),
            contentPadding: EdgeInsets.zero,
            title: Text(
              context.t('officeHours.settings.enableLabel'),
              style: typo.displaySm.copyWith(color: colors.navy),
            ),
            subtitle: Text(
              context.t('officeHours.settings.enableHelp'),
              style: typo.bodySm.copyWith(color: colors.muted),
            ),
            value: _draft.enabled,
            onChanged: (v) => _save(_draft.copyWith(enabled: v)),
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: context.t('officeHours.settings.windowsTitle'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (_draft.windows.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    context.t('officeHours.settings.windowsEmpty'),
                    style: typo.bodyMd.copyWith(color: colors.muted),
                  ),
                )
              else
                Column(
                  children: <Widget>[
                    for (var i = 0; i < _draft.windows.length; i++) ...<Widget>[
                      WindowListTile(
                        window: _draft.windows[i],
                        onEdit: () async {
                          final w = await WindowEditorSheet.show(
                            context,
                            initial: _draft.windows[i],
                          );
                          if (w != null) {
                            final next = _draft.copyWith(
                              windows: <OfficeHoursWindow>[
                                ..._draft.windows,
                              ]..[i] = w,
                            );
                            await _save(next);
                          }
                        },
                        onDelete: () async {
                          final next = _draft.copyWith(
                            windows: <OfficeHoursWindow>[
                              ..._draft.windows,
                            ]..removeAt(i),
                          );
                          await _save(next);
                        },
                      ),
                      if (i < _draft.windows.length - 1)
                        const SizedBox(height: 8),
                    ],
                  ],
                ),
              const SizedBox(height: 12),
              AppButton(
                key: const ValueKey<String>('oh-add-window'),
                label: context.t('officeHours.settings.addWindow'),
                variant: AppButtonVariant.outline,
                onPressed: () async {
                  final w = await WindowEditorSheet.show(context);
                  if (w != null) {
                    final next = _draft.copyWith(
                      windows: <OfficeHoursWindow>[..._draft.windows, w],
                    );
                    await _save(next);
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: context.t('officeHours.settings.slotDuration'),
          child: SegmentedControl<int>(
            value: _draft.slotDurationMinutes,
            options: <SegmentedOption<int>>[
              for (final d in OfficeHoursSettings.allowedSlotDurations)
                SegmentedOption<int>(
                  value: d,
                  label: context.t(
                    'officeHours.settings.slotDurationOption',
                    vars: <String, Object>{'minutes': d},
                  ),
                ),
            ],
            onChange: (d) => _save(_draft.copyWith(slotDurationMinutes: d)),
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: context.t('officeHours.settings.bufferMinutes'),
          child: Align(
            alignment: Alignment.centerLeft,
            child: AppStepper(
              key: const ValueKey<String>('oh-buffer-stepper'),
              value: _draft.bufferMinutes,
              min: 0,
              max: 60,
              suffix: ' min',
              onChanged: (v) => _save(_draft.copyWith(bufferMinutes: v)),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: context.t('officeHours.settings.maxBookingsPerWeek'),
          child: Align(
            alignment: Alignment.centerLeft,
            child: AppStepper(
              key: const ValueKey<String>('oh-cap-stepper'),
              value: _draft.maxBookingsPerWeek,
              min: 1,
              max: 50,
              onChanged: (v) => _save(_draft.copyWith(maxBookingsPerWeek: v)),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: context.t('officeHours.settings.meetingLinkLabel'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AppInput(
                key: const ValueKey<String>('oh-link-input'),
                value: _draft.meetingLinkTemplate ?? '',
                placeholder: 'https://meet.example.com/{slot_id}',
                onChanged: (v) => _save(
                  _draft.copyWith(meetingLinkTemplate: v.isEmpty ? null : v),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                context.t('officeHours.settings.meetingLinkHelp'),
                style: typo.bodySm.copyWith(color: colors.muted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: context.t('officeHours.settings.notesLabel'),
          child: AppInput(
            key: const ValueKey<String>('oh-notes-input'),
            value: _draft.notesTemplate ?? '',
            multiline: true,
            minLines: 3,
            maxLines: 6,
            onChanged: (v) => _save(
              _draft.copyWith(notesTemplate: v.isEmpty ? null : v),
            ),
          ),
        ),
        const SizedBox(height: 24),
        SectionCard(
          child: SettingsRow(
            key: const ValueKey<String>('oh-my-bookings-row'),
            icon: Icons.event_note,
            label: context.t('officeHours.bookings.title'),
            onTap: () => context.push(Routes.myBookings),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}
