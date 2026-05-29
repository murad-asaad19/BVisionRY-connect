import 'package:flutter/material.dart';

import '../../../../core/i18n/i18n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_icon_button.dart';
import '../../../../core/widgets/app_input.dart';

/// Body of the change-password bottom sheet. Presented inside the design
/// system [AppBottomSheet] chrome (see `AccountScreen`).
///
/// Two fields: the user's current password (so the change is gated behind
/// re-entering it) and the new password. The new-password field validates
/// ≥ 8 characters client-side, matching `SettingsService.changePassword`;
/// both fields carry a reveal toggle (`common.showPassword` /
/// `common.hidePassword`). On submit we forward `(current, next)` to
/// [onSubmit], surfacing a busy state on the confirm button for the duration.
class ChangePasswordSheet extends StatefulWidget {
  const ChangePasswordSheet({super.key, required this.onSubmit});

  /// Caller-owned password change handler. Receives the current + new
  /// passwords and is responsible for the auth update, closing the sheet, and
  /// showing the success toast on the way out.
  final Future<void> Function(String currentPassword, String newPassword)
      onSubmit;

  @override
  State<ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<ChangePasswordSheet> {
  String _current = '';
  String _next = '';
  bool _showCurrent = false;
  bool _showNext = false;
  bool _busy = false;

  bool get _nextValid => _next.length >= 8;
  bool get _canSubmit => _current.isNotEmpty && _nextValid && !_busy;

  Future<void> _submit() async {
    Haptics.light();
    setState(() => _busy = true);
    try {
      await widget.onSubmit(_current, _next);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = Theme.of(context).extension<AppColors>()!;
    final AppSpacing spacing = Theme.of(context).extension<AppSpacing>()!;
    final AppTypography typo = Theme.of(context).extension<AppTypography>()!;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        spacing.lg,
        spacing.xs,
        spacing.lg,
        spacing.lg + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              context.t('settings.changePassword.title'),
              style: typo.displayLg.copyWith(color: colors.navy),
            ),
            SizedBox(height: spacing.md),
            AppInput(
              key: const Key('changePw.currentInput'),
              label: context.t('settings.changePassword.currentPassword'),
              value: _current,
              obscureText: !_showCurrent,
              autocorrect: false,
              enabled: !_busy,
              trailing: _RevealToggle(
                visible: _showCurrent,
                onToggle: () => setState(() => _showCurrent = !_showCurrent),
              ),
              onChanged: (String v) => setState(() => _current = v),
            ),
            SizedBox(height: spacing.md),
            AppInput(
              key: const Key('changePw.input'),
              label: context.t('settings.changePassword.newPassword'),
              value: _next,
              obscureText: !_showNext,
              autocorrect: false,
              enabled: !_busy,
              errorText: (_next.isNotEmpty && !_nextValid)
                  ? context.t('settings.changePassword.tooShort')
                  : null,
              trailing: _RevealToggle(
                visible: _showNext,
                onToggle: () => setState(() => _showNext = !_showNext),
              ),
              onChanged: (String v) => setState(() => _next = v),
            ),
            SizedBox(height: spacing.lg),
            AppButton(
              key: const Key('changePw.submit'),
              label: context.t('settings.changePassword.confirm'),
              loading: _busy,
              onPressed: _canSubmit ? _submit : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// Eye / eye-off reveal toggle rendered inside an [AppInput]'s trailing slot.
class _RevealToggle extends StatelessWidget {
  const _RevealToggle({required this.visible, required this.onToggle});

  final bool visible;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return AppIconButton(
      icon: visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
      label: context.t(visible ? 'common.hidePassword' : 'common.showPassword'),
      size: AppIconButtonSize.sm,
      onPressed: onToggle,
    );
  }
}
