import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_typography.dart';

/// Branded text field with built-in label + inline error.
///
/// The 1.5px border tracks three states: default (`border`), focused
/// (`navy`), and errored (`dangerBorder`). Pass an [errorText] to switch
/// to the error state; the message renders below the field, announced by
/// screen readers as a live region.
class AppInput extends StatefulWidget {
  const AppInput({
    super.key,
    required this.value,
    this.label,
    this.placeholder,
    this.onChanged,
    this.errorText,
    this.multiline = false,
    this.minLines,
    this.maxLines,
    this.maxLength,
    this.obscureText = false,
    this.keyboardType,
    this.autocorrect = true,
    this.autofillHints,
    this.textInputAction,
    this.onSubmitted,
    this.enabled = true,
    this.trailing,
    this.onBlur,
  });

  final String value;
  final String? label;
  final String? placeholder;
  final ValueChanged<String>? onChanged;
  final String? errorText;
  final bool multiline;
  final int? minLines;
  final int? maxLines;
  final int? maxLength;
  final bool obscureText;
  final TextInputType? keyboardType;
  final bool autocorrect;
  final Iterable<String>? autofillHints;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;

  /// Optional trailing widget rendered inside the input frame on the right —
  /// typically an availability indicator (check / X / spinner).
  final Widget? trailing;

  /// Fires when the field loses focus. Used by the onboarding Identity step
  /// to debounce the `check_handle_available` RPC on blur rather than on
  /// every keystroke.
  final VoidCallback? onBlur;

  @override
  State<AppInput> createState() => _AppInputState();
}

class _AppInputState extends State<AppInput> {
  late final FocusNode _focusNode;
  late final TextEditingController _controller;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()..addListener(_onFocusChange);
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant AppInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Keep the controller in sync with external value changes — but don't
    // clobber the user's selection if they're actively typing.
    if (widget.value != _controller.text) {
      final selection = _controller.selection;
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: selection.isValid &&
                selection.end <= widget.value.length
            ? selection
            : TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    final bool hadFocus = _focused;
    final bool hasFocus = _focusNode.hasFocus;
    if (mounted) setState(() => _focused = hasFocus);
    // Fire onBlur on the focus → unfocus transition so callers can debounce
    // expensive checks (e.g. handle availability RPC) at the right moment.
    if (hadFocus && !hasFocus) {
      widget.onBlur?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final radii = Theme.of(context).extension<AppRadii>()!;
    final typo = Theme.of(context).extension<AppTypography>()!;
    final hasError = widget.errorText != null;
    final borderColor = hasError
        ? colors.dangerBorder
        : _focused
            ? colors.navy
            : colors.border;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.label != null) ...[
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
          key: const ValueKey('app-input-frame'),
          decoration: BoxDecoration(
            color: colors.white,
            borderRadius: BorderRadius.circular(radii.input),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            crossAxisAlignment: widget.multiline
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  enabled: widget.enabled,
                  onChanged: widget.onChanged,
                  onSubmitted: widget.onSubmitted,
                  keyboardType: widget.keyboardType ??
                      (widget.multiline ? TextInputType.multiline : null),
                  textInputAction: widget.textInputAction,
                  autocorrect: widget.autocorrect,
                  autofillHints: widget.autofillHints,
                  obscureText: widget.obscureText,
                  maxLength: widget.maxLength,
                  minLines:
                      widget.minLines ?? (widget.multiline ? 3 : null),
                  maxLines: widget.multiline ? widget.maxLines : 1,
                  style: typo.bodyLg.copyWith(color: colors.body),
                  cursorColor: colors.navy,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isCollapsed: true,
                    hintText: widget.placeholder,
                    hintStyle: typo.bodyLg.copyWith(color: colors.muted),
                    counterText: '',
                  ),
                  inputFormatters: widget.maxLength != null
                      ? [LengthLimitingTextInputFormatter(widget.maxLength)]
                      : null,
                ),
              ),
              if (widget.trailing != null) ...<Widget>[
                const SizedBox(width: 8),
                widget.trailing!,
              ],
            ],
          ),
        ),
        if (widget.errorText != null) ...[
          const SizedBox(height: 4),
          Semantics(
            liveRegion: true,
            child: Text(
              widget.errorText!,
              style: typo.bodyXs.copyWith(color: colors.danger),
            ),
          ),
        ],
        if (widget.maxLength != null) ...[
          const SizedBox(height: 2),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${widget.value.length}/${widget.maxLength}',
              style: typo.bodyXs.copyWith(color: colors.muted),
            ),
          ),
        ],
      ],
    );
  }
}
