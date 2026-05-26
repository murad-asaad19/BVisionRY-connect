import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_typography.dart';
import '../domain/tag_input.dart';

/// Tag chip input — Wrap of dismissible chips + trailing text field.
///
/// Behavior:
///   - On `space` / `comma` / `enter` in the text field → append the trimmed
///     lowercase value via [TagInput.add] and clear the input.
///   - On `Backspace` in an empty text field → drop the last tag.
///   - Renders a `{n}/8` counter aligned right.
///   - Disables the text field when 8 tags are present.
class TagChipInput extends StatefulWidget {
  const TagChipInput({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.placeholder,
    this.errorText,
  });

  final TagInput value;
  final ValueChanged<TagInput> onChanged;
  final String? label;
  final String? placeholder;
  final String? errorText;

  @override
  State<TagChipInput> createState() => _TagChipInputState();
}

class _TagChipInputState extends State<TagChipInput> {
  late final FocusNode _focusNode;
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _commitFromText() {
    final String raw = _controller.text;
    if (raw.isEmpty) return;
    final TagInput next = widget.value.add(raw);
    _controller.clear();
    if (next != widget.value) widget.onChanged(next);
  }

  void _onChanged(String raw) {
    // Auto-commit on `,` or trailing whitespace (space typed after the tag).
    if (raw.endsWith(',') || raw.endsWith(' ')) {
      final String stripped = raw.substring(0, raw.length - 1);
      _controller.value = TextEditingValue(text: stripped);
      _commitFromText();
    }
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.backspace &&
        _controller.text.isEmpty &&
        widget.value.value.isNotEmpty) {
      final String last = widget.value.value.last;
      widget.onChanged(widget.value.remove(last));
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter) {
      _commitFromText();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = Theme.of(context).extension<AppColors>()!;
    final AppRadii radii = Theme.of(context).extension<AppRadii>()!;
    final AppTypography typo =
        Theme.of(context).extension<AppTypography>()!;
    final bool capped = widget.value.value.length >= TagInput.maxTags;
    final bool hasError = widget.errorText != null;
    final Color borderColor =
        hasError ? colors.dangerBorder : colors.border;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (widget.label != null) ...<Widget>[
          Text(
            widget.label!.toUpperCase(),
            style: typo.bodyXs.copyWith(
              color: colors.muted,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
        ],
        Container(
          decoration: BoxDecoration(
            color: colors.white,
            borderRadius: BorderRadius.circular(radii.input),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              for (final String tag in widget.value.value)
                _RemovableChip(
                  label: tag,
                  onRemove: () =>
                      widget.onChanged(widget.value.remove(tag)),
                ),
              SizedBox(
                width: 140,
                child: Focus(
                  onKeyEvent: _onKey,
                  child: TextField(
                    focusNode: _focusNode,
                    controller: _controller,
                    enabled: !capped,
                    onChanged: _onChanged,
                    onSubmitted: (_) => _commitFromText(),
                    style: typo.bodyLg.copyWith(color: colors.body),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      isCollapsed: true,
                      contentPadding: EdgeInsets.zero,
                      hintText: capped ? '' : widget.placeholder,
                      hintStyle:
                          typo.bodyLg.copyWith(color: colors.muted),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (widget.errorText != null) ...<Widget>[
          const SizedBox(height: 4),
          Semantics(
            liveRegion: true,
            child: Text(
              widget.errorText!,
              style: typo.bodyXs.copyWith(color: colors.danger),
            ),
          ),
        ],
        const SizedBox(height: 2),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '${widget.value.value.length}/${TagInput.maxTags}',
            style: typo.bodyXs.copyWith(color: colors.muted),
          ),
        ),
      ],
    );
  }
}

class _RemovableChip extends StatelessWidget {
  const _RemovableChip({required this.label, required this.onRemove});

  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = Theme.of(context).extension<AppColors>()!;
    final AppRadii radii = Theme.of(context).extension<AppRadii>()!;
    final AppTypography typo =
        Theme.of(context).extension<AppTypography>()!;
    return Container(
      padding: const EdgeInsets.fromLTRB(9, 3, 4, 3),
      decoration: BoxDecoration(
        color: colors.goldPale,
        borderRadius: BorderRadius.circular(radii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            label,
            style: typo.displayXs.copyWith(
              color: colors.navy,
              fontSize: 11,
              height: 1.1,
            ),
          ),
          const SizedBox(width: 4),
          InkResponse(
            radius: 14,
            onTap: onRemove,
            child: Icon(LucideIcons.x, size: 12, color: colors.navy),
          ),
        ],
      ),
    );
  }
}
