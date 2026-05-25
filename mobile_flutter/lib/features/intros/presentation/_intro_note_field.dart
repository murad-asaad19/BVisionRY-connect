import 'package:flutter/material.dart';

import '../../../core/i18n/i18n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/widgets.dart';

/// Min trimmed length the server's `char_length(btrim(note))` check
/// enforces for every intro / warm-request / warm-forward note.
const int kIntroNoteMin = 80;

/// Max trimmed length the server's `char_length(btrim(note))` check
/// enforces.
const int kIntroNoteMax = 400;

/// Returns the trimmed length of an intro note — matches the server's
/// `char_length(btrim(note))` semantics so the client preview matches
/// what the SQL function evaluates.
int trimmedNoteLength(String value) => value.trim().length;

/// `true` when [value] satisfies the server's 80-400 trimmed-length
/// check. Compose / forward sheets use this to gate their Send buttons.
bool isIntroNoteInRange(String value) {
  final int len = trimmedNoteLength(value);
  return len >= kIntroNoteMin && len <= kIntroNoteMax;
}

/// Composer field used by the three intro sheets (direct, warm-request,
/// warm-forward) — wraps [AppInput] in multiline mode with the X / max
/// (min) counter line beneath, turning red when the trimmed length
/// falls outside `[80, 400]`. Stays purely presentational so callers
/// hold the controller state.
class IntroNoteField extends StatelessWidget {
  const IntroNoteField({
    super.key,
    required this.value,
    required this.onChanged,
    this.placeholderKey = 'intros.compose.placeholder',
    this.enabled = true,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final String placeholderKey;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final typo = Theme.of(context).extension<AppTypography>()!;
    final int trimmed = trimmedNoteLength(value);
    final bool inRange = isIntroNoteInRange(value);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppInput(
          key: const ValueKey('intro-note-field'),
          value: value,
          onChanged: onChanged,
          placeholder: context.t(placeholderKey),
          multiline: true,
          minLines: 4,
          maxLines: 8,
          maxLength: kIntroNoteMax,
          enabled: enabled,
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            context.t(
              'intros.compose.counter',
              vars: <String, Object>{
                'count': trimmed,
                'max': kIntroNoteMax,
                'min': kIntroNoteMin,
              },
            ),
            style: typo.bodyXs.copyWith(
              color: inRange ? colors.muted : colors.danger,
            ),
          ),
        ),
      ],
    );
  }
}
