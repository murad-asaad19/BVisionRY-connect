import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/i18n/i18n.dart';
import '../../../core/routing/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/app_banner.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_input.dart';
import '../../../core/widgets/app_stepper.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/gap.dart';
import '../../../core/widgets/query_state.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/segmented_control.dart';
import '../../../core/widgets/settings_row.dart';
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
///    Enabling is blocked while there are zero windows — an enabled-but-empty
///    schedule is unbookable, so we keep the host on `false` and surface
///    inline guidance instead.
/// 2. Weekly availability — list of `WindowListTile` + "Add window" button
///    that opens `WindowEditorSheet`. Each tile supports edit/delete.
/// 3. Slot duration — `SegmentedControl` over `allowedSlotDurations`.
/// 4. Buffer minutes — `AppStepper` 0..60.
/// 5. Max bookings per week — `AppStepper` 1..50.
/// 6. Meeting link template — `AppInput` (saved on blur, not per keystroke).
/// 7. Notes template — multiline `AppInput` (saved on blur).
/// 8. My Bookings entry row at the bottom.
///
/// Field changes mutate a local [OfficeHoursSettings] draft and schedule a
/// debounced `set_office_hours`. A success toast is shown only on the
/// trailing committed save (text fields commit on blur), so a burst of
/// stepper taps or keystrokes no longer fires a toast per change. When
/// office hours are disabled the configuration sections collapse to a
/// greyed, non-interactive state.
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

  /// Last value that was successfully sent to the server. Lets us skip a
  /// redundant `set_office_hours` (and its toast) when a text field is
  /// blurred without an actual edit.
  late OfficeHoursSettings _lastSaved;

  @override
  void initState() {
    super.initState();
    _draft = widget.initial;
    _lastSaved = widget.initial;
  }

  /// Updates the local draft now but does NOT persist — used by the text
  /// fields on every keystroke. The matching `onBlur` commits via [_commit],
  /// so typing no longer fires a `set_office_hours` + "Saved" toast per key.
  void _updateDraft(OfficeHoursSettings next) {
    setState(() => _draft = next);
  }

  /// Persists [next] immediately and shows a single success toast on
  /// completion. Used by committed actions: stepper/segmented changes,
  /// text-field blur, window add/edit/delete, and the enable toggle. Each is
  /// one discrete user action, so it produces exactly one save + one toast.
  Future<void> _commit(OfficeHoursSettings next) async {
    setState(() => _draft = next);
    await _persist(next);
  }

  Future<void> _persist(OfficeHoursSettings next) async {
    // No-op when nothing actually changed (e.g. focus/blur without edits).
    if (next == _lastSaved) return;
    final toast = ref.read(toastServiceProvider.notifier);
    final translator = context.t;
    try {
      await ref.read(officeHoursSettingsProvider.notifier).save(next);
      _lastSaved = next;
      if (!mounted) return;
      toast.showToast(
        title: translator('officeHours.settings.saved'),
        intent: AppIntent.success,
      );
    } on AppException catch (e) {
      if (!mounted) return;
      toast.showToast(
        title: translator(e.i18nKey),
        intent: AppIntent.danger,
      );
    }
  }

  /// Toggles the enabled flag. Enabling with zero windows is blocked because
  /// the schedule would be unbookable — we keep `enabled = false`, nudge the
  /// host with a toast, and let the inline banner point them at "Add window".
  void _onToggle(bool value) {
    if (value && _draft.windows.isEmpty) {
      Haptics.error();
      ref.read(toastServiceProvider.notifier).showToast(
            title: context.t('officeHours.settings.enableNeedsWindow'),
            intent: AppIntent.warning,
          );
      return;
    }
    Haptics.selection();
    _commit(_draft.copyWith(enabled: value));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final typo = Theme.of(context).extension<AppTypography>()!;
    final spacing = Theme.of(context).extension<AppSpacing>()!;
    final bool configEnabled = _draft.enabled;
    return ListView(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.md,
        vertical: spacing.lg,
      ),
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
            onChanged: _onToggle,
          ),
        ),
        Gap(spacing.lg),
        // Weekly availability is always editable — the host needs to add the
        // first window before they can enable office hours.
        SectionCard(
          title: context.t('officeHours.settings.windowsTitle'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (_draft.windows.isEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: spacing.sm),
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
                        onEdit: () => _editWindow(i),
                        onDelete: () => _deleteWindow(i),
                      ),
                      if (i < _draft.windows.length - 1) Gap(spacing.sm),
                    ],
                  ],
                ),
              Gap(spacing.md),
              AppButton(
                key: const ValueKey<String>('oh-add-window'),
                label: context.t('officeHours.settings.addWindow'),
                variant: AppButtonVariant.outline,
                onPressed: _addWindow,
              ),
            ],
          ),
        ),
        Gap(spacing.lg),
        // When office hours are off, the rest of the config has no effect, so
        // collapse it into a greyed, non-interactive block with a hint.
        _DisabledConfigGate(
          enabled: configEnabled,
          hint: context.t('officeHours.settings.disabledHint'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
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
                  onChange: (d) {
                    Haptics.selection();
                    _commit(_draft.copyWith(slotDurationMinutes: d));
                  },
                ),
              ),
              Gap(spacing.lg),
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
                    onChanged: (v) =>
                        _commit(_draft.copyWith(bufferMinutes: v)),
                  ),
                ),
              ),
              Gap(spacing.lg),
              SectionCard(
                title: context.t('officeHours.settings.maxBookingsPerWeek'),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: AppStepper(
                    key: const ValueKey<String>('oh-cap-stepper'),
                    value: _draft.maxBookingsPerWeek,
                    min: 1,
                    max: 50,
                    onChanged: (v) =>
                        _commit(_draft.copyWith(maxBookingsPerWeek: v)),
                  ),
                ),
              ),
              Gap(spacing.lg),
              SectionCard(
                title: context.t('officeHours.settings.meetingLinkLabel'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    AppInput(
                      key: const ValueKey<String>('oh-link-input'),
                      value: _draft.meetingLinkTemplate ?? '',
                      placeholder: 'https://meet.example.com/{slot_id}',
                      onChanged: (v) => _updateDraft(
                        _draft.copyWith(
                          meetingLinkTemplate: v.isEmpty ? null : v,
                        ),
                      ),
                      onBlur: () => _commit(_draft),
                    ),
                    Gap(spacing.xs),
                    Text(
                      context.t('officeHours.settings.meetingLinkHelp'),
                      style: typo.bodySm.copyWith(color: colors.muted),
                    ),
                  ],
                ),
              ),
              Gap(spacing.lg),
              SectionCard(
                title: context.t('officeHours.settings.notesLabel'),
                child: AppInput(
                  key: const ValueKey<String>('oh-notes-input'),
                  value: _draft.notesTemplate ?? '',
                  multiline: true,
                  minLines: 3,
                  maxLines: 6,
                  onChanged: (v) => _updateDraft(
                    _draft.copyWith(notesTemplate: v.isEmpty ? null : v),
                  ),
                  onBlur: () => _commit(_draft),
                ),
              ),
            ],
          ),
        ),
        Gap(spacing.section),
        SectionCard(
          child: SettingsRow(
            key: const ValueKey<String>('oh-my-bookings-row'),
            icon: Icons.event_note,
            label: context.t('officeHours.bookings.title'),
            onTap: () => context.push(Routes.myBookings),
          ),
        ),
        Gap(spacing.section),
      ],
    );
  }

  Future<void> _addWindow() async {
    final w = await WindowEditorSheet.show(
      context,
      existing: _draft.windows,
    );
    if (w != null) {
      await _commit(
        _draft.copyWith(
          windows: <OfficeHoursWindow>[..._draft.windows, w],
        ),
      );
    }
  }

  Future<void> _editWindow(int i) async {
    final w = await WindowEditorSheet.show(
      context,
      initial: _draft.windows[i],
      existing: _draft.windows,
      editingIndex: i,
    );
    if (w != null) {
      await _commit(
        _draft.copyWith(
          windows: <OfficeHoursWindow>[..._draft.windows]..[i] = w,
        ),
      );
    }
  }

  Future<void> _deleteWindow(int i) async {
    final confirmed = await ref.read(confirmServiceProvider).confirm(
          context,
          title: context.t('officeHours.settings.removeWindow'),
          body: context.t('officeHours.settings.removeWindowBody'),
          confirmLabel: context.t('common.remove'),
          cancelLabel: context.t('common.cancel'),
          destructive: true,
        );
    if (!confirmed) return;
    // Destructive confirm accepted — buzz to acknowledge removing the window.
    Haptics.error();
    final next = _draft.copyWith(
      windows: <OfficeHoursWindow>[..._draft.windows]..removeAt(i),
    );
    // Removing the last window makes an enabled schedule unbookable, so turn
    // office hours off in the same save rather than leaving a broken state.
    await _commit(
      next.windows.isEmpty ? next.copyWith(enabled: false) : next,
    );
  }
}

/// Wraps the configuration sections so that, when office hours are disabled,
/// they collapse to a greyed, non-interactive block with a short hint. Keeps
/// the host from tweaking settings that have no effect while OH is off.
class _DisabledConfigGate extends StatelessWidget {
  const _DisabledConfigGate({
    required this.enabled,
    required this.hint,
    required this.child,
  });

  final bool enabled;
  final String hint;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final spacing = Theme.of(context).extension<AppSpacing>()!;
    final colors = Theme.of(context).extension<AppColors>()!;
    if (enabled) return child;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppBanner(
          intent: AppIntent.info,
          leadingIcon: Icon(Icons.info_outline, size: 20, color: colors.info),
          child: Text(hint),
        ),
        Gap(spacing.md),
        // Grey + block interaction so the disabled config reads as inactive
        // but stays visible for context.
        IgnorePointer(
          child: ExcludeSemantics(
            child: Opacity(opacity: 0.4, child: child),
          ),
        ),
      ],
    );
  }
}
