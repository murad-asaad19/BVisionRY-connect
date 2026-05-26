import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

import '../../../core/i18n/i18n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_input.dart';
import '../domain/office_hours_window.dart';

/// Modal sheet used to add or edit a single [OfficeHoursWindow].
///
/// Inputs: weekday `DropdownButtonFormField<int>` (0=Sun..6=Sat with
/// localized labels), start/end via [_TimeField] (tap → `showTimePicker`),
/// IANA timezone via dropdown sourced from `FlutterTimezone`. Save is
/// disabled while [OfficeHoursWindow.validate] returns a non-null error
/// key; the localized error renders inline above the button.
///
/// The [timezones] / [deviceTimezone] parameters are injection seams for
/// tests so we can avoid the async hop to the platform channel during a
/// widget-test pump.
class WindowEditorSheet extends StatefulWidget {
  const WindowEditorSheet({
    super.key,
    this.initial,
    required this.onSave,
    this.timezones,
    this.deviceTimezone,
  });

  final OfficeHoursWindow? initial;
  final ValueChanged<OfficeHoursWindow> onSave;
  // Injection seams for tests.
  final List<String>? timezones;
  final String? deviceTimezone;

  /// Shows the sheet anchored to [context]. Resolves with the saved
  /// window (or null if the user dismissed without saving).
  static Future<OfficeHoursWindow?> show(
    BuildContext context, {
    OfficeHoursWindow? initial,
  }) {
    return showAppBottomSheet<OfficeHoursWindow>(
      context: context,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: WindowEditorSheet(
          initial: initial,
          onSave: (w) => Navigator.of(context).pop(w),
        ),
      ),
    );
  }

  @override
  State<WindowEditorSheet> createState() => _WindowEditorSheetState();
}

class _WindowEditorSheetState extends State<WindowEditorSheet> {
  late int _weekday;
  late int _start;
  late int _end;
  late String _tz;
  List<String> _availableTzs = const <String>['UTC'];

  @override
  void initState() {
    super.initState();
    _weekday = widget.initial?.weekday ?? 1;
    _start = widget.initial?.startMinute ?? 540;
    _end = widget.initial?.endMinute ?? 660;
    _tz = widget.initial?.timezone ?? widget.deviceTimezone ?? 'UTC';
    _availableTzs = widget.timezones ?? const <String>['UTC'];
    if (widget.timezones == null) {
      // Lazy-load the IANA list + device tz on first render.
      Future<void>.microtask(() async {
        final list = await FlutterTimezone.getAvailableTimezones();
        final local = await FlutterTimezone.getLocalTimezone();
        if (!mounted) return;
        setState(() {
          _availableTzs = List<String>.of(list)..sort();
          if (widget.initial == null && _tz == 'UTC') _tz = local;
        });
      });
    }
  }

  OfficeHoursWindow get _draft => OfficeHoursWindow(
        weekday: _weekday,
        startMinute: _start,
        endMinute: _end,
        timezone: _tz,
      );

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final typo = Theme.of(context).extension<AppTypography>()!;
    final error = _draft.validate();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            widget.initial == null
                ? context.t('officeHours.settings.addWindow')
                : context.t('officeHours.settings.editWindow'),
            style: typo.displayLg.copyWith(color: colors.navy),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            key: const ValueKey<String>('weekday'),
            initialValue: _weekday,
            items: List<DropdownMenuItem<int>>.generate(
              7,
              (i) => DropdownMenuItem<int>(
                value: i,
                child: Text(context.t('officeHours.settings.weekday_$i')),
              ),
            ),
            onChanged: (v) {
              if (v != null) setState(() => _weekday = v);
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: _TimeField(
                  key: const ValueKey<String>('start-time'),
                  rawKey: const ValueKey<String>('start-time-raw'),
                  value: _start,
                  onChanged: (m) => setState(() => _start = m),
                  label: context.t('officeHours.settings.startTime'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TimeField(
                  key: const ValueKey<String>('end-time'),
                  rawKey: const ValueKey<String>('end-time-raw'),
                  value: _end,
                  onChanged: (m) => setState(() => _end = m),
                  label: context.t('officeHours.settings.endTime'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            key: const ValueKey<String>('timezone'),
            initialValue:
                _availableTzs.contains(_tz) ? _tz : _availableTzs.first,
            items: _availableTzs
                .map(
                  (z) => DropdownMenuItem<String>(value: z, child: Text(z)),
                )
                .toList(growable: false),
            onChanged: (v) {
              if (v != null) setState(() => _tz = v);
            },
          ),
          if (error != null) ...<Widget>[
            const SizedBox(height: 8),
            Text(context.t(error), style: TextStyle(color: colors.danger)),
          ],
          const SizedBox(height: 16),
          AppButton(
            key: const ValueKey<String>('window-save'),
            label: context.t('officeHours.settings.save'),
            onPressed: error != null ? null : () => widget.onSave(_draft),
          ),
        ],
      ),
    );
  }
}

class _TimeField extends StatefulWidget {
  const _TimeField({
    required this.value,
    required this.onChanged,
    required this.label,
    required this.rawKey,
    super.key,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final String label;
  final ValueKey<String> rawKey;

  @override
  State<_TimeField> createState() => _TimeFieldState();
}

class _TimeFieldState extends State<_TimeField> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        AppInput(
          label: widget.label,
          value: OfficeHoursWindow.minuteToHhmm(widget.value),
          enabled: false,
          onChanged: null,
        ),
        Positioned.fill(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay(
                    hour: widget.value ~/ 60,
                    minute: widget.value % 60,
                  ),
                );
                if (picked != null) {
                  widget.onChanged(picked.hour * 60 + picked.minute);
                }
              },
            ),
          ),
        ),
        // Hidden test seam — `enterText` on `rawKey` drives the value
        // without invoking the platform time picker channel.
        Opacity(
          opacity: 0,
          child: SizedBox(
            width: 1,
            height: 1,
            child: TextField(
              key: widget.rawKey,
              onSubmitted: (v) {
                try {
                  widget.onChanged(OfficeHoursWindow.hhmmToMinute(v));
                } catch (_) {
                  // ignore malformed input from the test seam
                }
              },
              onChanged: (v) {
                if (RegExp(r'^\d{2}:\d{2}$').hasMatch(v)) {
                  widget.onChanged(OfficeHoursWindow.hhmmToMinute(v));
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}
