import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/i18n/i18n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/widgets.dart';
import '../data/meetings_service.dart';

/// Bottom-sheet used by the proposer to draft + send a meeting offer.
///
/// Layout (gallery G1):
/// - 3 slot rows (slot 1 required, 2/3 optional). Each row launches a
///   date + time picker; the result is shown formatted in the row label.
/// - Duration stepper: default 30, ±15, range 15–240.
/// - Meeting URL `AppInput` (https-only — server enforces; client also
///   blocks non-https before round-trip).
/// - Timezone hint: auto-detected via [FlutterTimezone.getLocalTimezone];
///   user can't override in v1 (the value is sent to the server so it can
///   render times in the proposer's tz for the recipient).
class ProposeMeetingSheet extends ConsumerStatefulWidget {
  const ProposeMeetingSheet({super.key, required this.conversationId});

  final String conversationId;

  @override
  ConsumerState<ProposeMeetingSheet> createState() =>
      _ProposeMeetingSheetState();
}

class _ProposeMeetingSheetState extends ConsumerState<ProposeMeetingSheet> {
  final List<DateTime?> _slots = [null, null, null];
  int _duration = 30;
  String _url = '';
  String _tz = 'UTC';
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _resolveTimezone();
  }

  Future<void> _resolveTimezone() async {
    try {
      final tz = await FlutterTimezone.getLocalTimezone();
      if (mounted) setState(() => _tz = tz);
    } catch (_) {
      // Keep UTC fallback — non-fatal.
    }
  }

  Future<void> _pickSlot(int index) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
    );
    if (time == null) return;
    setState(() {
      _slots[index] = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _submit() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final navigator = Navigator.of(context);
    final selected = _slots.whereType<DateTime>().toList();
    try {
      await ref.read(meetingsServiceProvider).proposeMeeting(
            conversationId: widget.conversationId,
            slots: selected,
            durationMinutes: _duration,
            meetingUrl: _url.isEmpty ? null : _url,
            timezone: _tz,
          );
      navigator.pop();
    } on AppException catch (e) {
      if (mounted) setState(() => _error = context.t(e.i18nKey));
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = context.t('meetings.propose.errors.submitFailed'),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final typo = Theme.of(context).extension<AppTypography>()!;
    final radii = Theme.of(context).extension<AppRadii>()!;
    final fmt = DateFormat.MMMd().add_jm();
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.t('meetings.propose.title'),
                style: typo.displayMd.copyWith(color: colors.navy),
              ),
              const SizedBox(height: 4),
              Text(
                context.t('meetings.propose.subtitle'),
                style: typo.bodyMd.copyWith(color: colors.muted),
              ),
              const SizedBox(height: 16),
              for (var i = 0; i < 3; i++) ...[
                _SlotRow(
                  key: Key('propose-slot-$i'),
                  index: i,
                  value: _slots[i],
                  fmt: fmt,
                  onTap: _busy ? null : () => _pickSlot(i),
                ),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      context.t('meetings.propose.durationLabel'),
                      style: typo.bodyLg.copyWith(color: colors.body),
                    ),
                  ),
                  IconButton(
                    key: const Key('propose-duration-minus'),
                    onPressed: (_busy || _duration <= 15)
                        ? null
                        : () => setState(() => _duration -= 15),
                    icon: const Icon(Icons.remove),
                  ),
                  Text(
                    context.t(
                      'meetings.propose.durationOption',
                      vars: {'minutes': _duration},
                    ),
                    style: typo.bodyLg.copyWith(color: colors.body),
                  ),
                  IconButton(
                    key: const Key('propose-duration-plus'),
                    onPressed: (_busy || _duration >= 240)
                        ? null
                        : () => setState(() => _duration += 15),
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AppInput(
                key: const Key('propose-url'),
                value: _url,
                label: context.t('meetings.propose.urlLabel'),
                placeholder: context.t('meetings.propose.urlPlaceholder'),
                keyboardType: TextInputType.url,
                autocorrect: false,
                enabled: !_busy,
                onChanged: (v) => _url = v,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(radii.pill),
                  border: Border.all(color: colors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.globe, size: 14, color: colors.muted),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        context.t(
                          'meetings.propose.inputTimeZoneHint',
                          vars: {'tz': _tz},
                        ),
                        style: typo.bodyXs.copyWith(color: colors.muted),
                      ),
                    ),
                  ],
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: typo.bodyMd.copyWith(color: colors.danger),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppButton(
                    label: context.t('meetings.propose.cancel'),
                    variant: AppButtonVariant.outline,
                    fullWidth: false,
                    size: AppButtonSize.small,
                    onPressed: _busy ? null : () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  AppButton(
                    key: const Key('propose-submit'),
                    label: context.t('meetings.propose.send'),
                    fullWidth: false,
                    size: AppButtonSize.small,
                    loading: _busy,
                    onPressed: _busy ? null : _submit,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SlotRow extends StatelessWidget {
  const _SlotRow({
    super.key,
    required this.index,
    required this.value,
    required this.fmt,
    required this.onTap,
  });

  final int index;
  final DateTime? value;
  final DateFormat fmt;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final typo = Theme.of(context).extension<AppTypography>()!;
    final radii = Theme.of(context).extension<AppRadii>()!;
    final defaultLabel = context.t('meetings.propose.slot${index + 1}Label');
    return Material(
      color: colors.white,
      borderRadius: BorderRadius.circular(radii.button),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radii.button),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radii.button),
            border: Border.all(color: colors.border, width: 1.5),
          ),
          child: Row(
            children: [
              Icon(LucideIcons.calendar, size: 18, color: colors.navy),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  value == null ? defaultLabel : fmt.format(value!),
                  style: typo.bodyLg.copyWith(
                    color: value == null ? colors.muted : colors.body,
                  ),
                ),
              ),
              Icon(LucideIcons.chevronRight, size: 16, color: colors.muted),
            ],
          ),
        ),
      ),
    );
  }
}
