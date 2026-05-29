import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/i18n/i18n.dart';
import '../../../core/widgets/widgets.dart';

/// Password [AppInput] with a built-in show/hide visibility toggle.
///
/// Wraps the design-system [AppInput], obscuring the text by default and
/// rendering a trailing [AppIconButton] that flips the obscure state. The
/// toggle's screen-reader label tracks the current state via the shared
/// `common.showPassword` / `common.hidePassword` keys.
class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.value,
    required this.label,
    this.inputKey,
    this.placeholder,
    this.onChanged,
    this.errorText,
    this.autofillHints,
    this.textInputAction,
    this.onSubmitted,
    this.enabled = true,
  });

  /// Key forwarded to the inner [AppInput] so existing widget-test finders
  /// (e.g. `Key('password-input')`) keep resolving after the wrap.
  final Key? inputKey;

  final String value;
  final String label;
  final String? placeholder;
  final ValueChanged<String>? onChanged;
  final String? errorText;
  final Iterable<String>? autofillHints;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscured = true;

  void _toggle() {
    HapticFeedback.selectionClick();
    setState(() => _obscured = !_obscured);
  }

  @override
  Widget build(BuildContext context) {
    return AppInput(
      key: widget.inputKey,
      label: widget.label,
      placeholder: widget.placeholder,
      value: widget.value,
      onChanged: widget.onChanged,
      errorText: widget.errorText,
      obscureText: _obscured,
      autocorrect: false,
      autofillHints: widget.autofillHints,
      textInputAction: widget.textInputAction,
      onSubmitted: widget.onSubmitted,
      enabled: widget.enabled,
      trailing: AppIconButton(
        icon: _obscured
            ? Icons.visibility_outlined
            : Icons.visibility_off_outlined,
        label: context.t(
          _obscured ? 'common.showPassword' : 'common.hidePassword',
        ),
        size: AppIconButtonSize.sm,
        onPressed: widget.enabled ? _toggle : null,
      ),
    );
  }
}
