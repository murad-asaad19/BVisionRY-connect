import 'package:flutter/material.dart';

import '../../../../core/i18n/i18n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Modal bottom sheet wrapping a single obscured text field for changing
/// the user's password.
///
/// The submit button stays disabled until the input is ≥ 8 characters,
/// matching the server-side validation in `SettingsService.changePassword`.
/// On submit we forward the new password to [onSubmit] and surface a
/// busy-button state for the duration of the future.
class ChangePasswordSheet extends StatefulWidget {
  const ChangePasswordSheet({super.key, required this.onSubmit});

  /// Caller-owned password change handler. Receives the validated
  /// password and is responsible for calling the auth update + closing
  /// the sheet / showing a success toast on the way out.
  final Future<void> Function(String newPassword) onSubmit;

  @override
  State<ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<ChangePasswordSheet> {
  final TextEditingController _ctrl = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = Theme.of(context).extension<AppColors>()!;
    final AppTypography typo = Theme.of(context).extension<AppTypography>()!;
    final bool valid = _ctrl.text.length >= 8;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              context.t('settings.changePassword.title'),
              style: typo.displayLg,
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('changePw.input'),
              controller: _ctrl,
              obscureText: true,
              decoration: InputDecoration(
                labelText: context.t('settings.changePassword.newPassword'),
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            if (_ctrl.text.isNotEmpty && !valid)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  context.t('settings.changePassword.tooShort'),
                  style: typo.bodySm.copyWith(color: colors.danger),
                ),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                key: const Key('changePw.submit'),
                onPressed: (valid && !_busy)
                    ? () async {
                        setState(() => _busy = true);
                        try {
                          await widget.onSubmit(_ctrl.text);
                        } finally {
                          if (mounted) setState(() => _busy = false);
                        }
                      }
                    : null,
                child: Text(context.t('settings.changePassword.confirm')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
