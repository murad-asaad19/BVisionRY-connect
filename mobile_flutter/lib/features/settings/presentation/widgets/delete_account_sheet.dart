import 'package:flutter/material.dart';

import '../../../../core/i18n/i18n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_input.dart';

/// Body of the delete-account bottom sheet, gating deletion behind a literal
/// "DELETE" confirmation typed into the field. Presented inside the design
/// system [AppBottomSheet] chrome (see `AccountScreen`).
///
/// The confirm button stays disabled until the input matches `DELETE`
/// exactly (case-sensitive). On confirm we call the caller-supplied
/// [onConfirm] which owns the actual `deleteMyAccount()` invocation, sign-out,
/// and routing back to /sign-in.
///
/// The sheet does NOT pop itself — the caller decides whether to dismiss
/// before navigating away (so the sheet doesn't pop back into view during the
/// post-delete navigation transition).
class DeleteAccountSheet extends StatefulWidget {
  const DeleteAccountSheet({super.key, required this.onConfirm});

  /// Called when the user taps "Delete" after typing DELETE. Awaited so the
  /// sheet can keep the confirm button busy until the future resolves.
  final Future<void> Function() onConfirm;

  @override
  State<DeleteAccountSheet> createState() => _DeleteAccountSheetState();
}

class _DeleteAccountSheetState extends State<DeleteAccountSheet> {
  String _value = '';
  bool _busy = false;

  bool get _matches => _value == 'DELETE';

  Future<void> _confirm() async {
    Haptics.heavy();
    setState(() => _busy = true);
    try {
      await widget.onConfirm();
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
              context.t('settings.deleteConfirm.title'),
              style: typo.displayLg.copyWith(color: colors.navy),
            ),
            SizedBox(height: spacing.sm),
            Text(
              context.t('settings.deleteConfirm.body'),
              style: typo.bodyLg.copyWith(color: colors.muted),
            ),
            SizedBox(height: spacing.lg),
            AppInput(
              key: const Key('deleteSheet.confirmInput'),
              label: context.t('settings.deleteConfirm.typeWord'),
              value: _value,
              autocorrect: false,
              enabled: !_busy,
              onChanged: (String v) => setState(() => _value = v),
            ),
            SizedBox(height: spacing.lg),
            Row(
              children: <Widget>[
                Expanded(
                  child: AppButton(
                    label: context.t('settings.deleteConfirm.cancel'),
                    variant: AppButtonVariant.outline,
                    onPressed: _busy ? null : () => Navigator.of(context).pop(),
                  ),
                ),
                SizedBox(width: spacing.md),
                Expanded(
                  child: AppButton(
                    key: const Key('deleteSheet.confirmBtn'),
                    label: context.t('settings.deleteConfirm.action'),
                    variant: AppButtonVariant.danger,
                    loading: _busy,
                    onPressed: (_matches && !_busy) ? _confirm : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
