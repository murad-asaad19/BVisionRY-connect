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
/// warm-forward) — wraps [AppInput] in multiline mode with the gallery's
/// label row (`Your note    160/400`) above the textarea and the
/// safety-check / 80-char-min hint as a small-note beneath. Stays purely
/// presentational so callers hold the controller state.
class IntroNoteField extends StatelessWidget {
  const IntroNoteField({
    super.key,
    required this.value,
    required this.onChanged,
    this.placeholderKey = 'intros.compose.placeholder',
    this.labelKey = 'intros.compose.noteLabel',
    this.hintKey = 'intros.compose.noteHint',
    this.showHint = true,
    this.enabled = true,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final String placeholderKey;
  final String labelKey;
  final String hintKey;
  final bool showHint;
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
        // Label row: "Your note            160/400" (counter right-aligned
        // inline with the label, gold-text colour per the gallery).
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                context.t(labelKey),
                style: typo.displayXs.copyWith(
                  color: colors.navy,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
            ),
            Text(
              context.t(
                'intros.compose.counterShort',
                vars: <String, Object>{
                  'count': trimmed,
                  'max': kIntroNoteMax,
                },
              ),
              style: typo.bodyXs.copyWith(
                color: inRange ? colors.gold : colors.danger,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        AppInput(
          key: const ValueKey('intro-note-field'),
          value: value,
          // Clamp typed values to [0, kIntroNoteMax]; the trimmed length
          // is what the server's `char_length(btrim(note))` check sees.
          onChanged: (String v) {
            onChanged(
              v.length > kIntroNoteMax ? v.substring(0, kIntroNoteMax) : v,
            );
          },
          placeholder: context.t(placeholderKey),
          multiline: true,
          minLines: 4,
          maxLines: 6,
          enabled: enabled,
        ),
        if (showHint) ...<Widget>[
          const SizedBox(height: 6),
          Text(
            context.t(hintKey),
            style: typo.bodyXs.copyWith(color: colors.muted),
          ),
        ],
      ],
    );
  }
}
