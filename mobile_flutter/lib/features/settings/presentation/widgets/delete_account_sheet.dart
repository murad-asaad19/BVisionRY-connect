import 'package:flutter/material.dart';

import '../../../../core/i18n/i18n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Modal bottom sheet that gates account deletion behind a literal "DELETE"
/// confirmation typed into a text field.
///
/// The confirm button stays disabled until the input matches `DELETE`
/// exactly (case-sensitive). The sheet is presented via
/// `showModalBottomSheet` from `AccountScreen`; on confirm we call the
/// caller-supplied [onConfirm] which is responsible for the actual
/// `deleteMyAccount()` invocation, sign-out, and routing back to /sign-in.
///
/// The sheet does NOT pop itself — let the caller decide whether to dismiss
/// before navigating away (we don't want the sheet popping back into view
/// during the post-delete navigation transition).
class DeleteAccountSheet extends StatefulWidget {
  const DeleteAccountSheet({super.key, required this.onConfirm});

  /// Called when the user taps "Delete" after typing DELETE. Awaited so
  /// the sheet can keep the confirm button in a busy state until the
  /// caller's future resolves.
  final Future<void> Function() onConfirm;

  @override
  State<DeleteAccountSheet> createState() => _DeleteAccountSheetState();
}

class _DeleteAccountSheetState extends State<DeleteAccountSheet> {
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
    final bool matches = _ctrl.text == 'DELETE';
    final bool enabled = matches && !_busy;
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
              context.t('settings.deleteConfirm.title'),
              style: typo.displayLg,
            ),
            const SizedBox(height: 8),
            Text(
              context.t('settings.deleteConfirm.body'),
              style: typo.bodyLg.copyWith(color: colors.muted),
            ),
            const SizedBox(height: 16),
            Text(
              context.t('settings.deleteConfirm.typeWord'),
              style: typo.bodyMd.copyWith(color: colors.muted),
            ),
            const SizedBox(height: 6),
            TextField(
              key: const Key('deleteSheet.confirmInput'),
              controller: _ctrl,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton(
                    onPressed: _busy ? null : () => Navigator.of(context).pop(),
                    child: Text(context.t('settings.deleteConfirm.cancel')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    key: const Key('deleteSheet.confirmBtn'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: enabled
                          ? colors.danger
                          : colors.danger.withValues(alpha: 0.5),
                    ),
                    onPressed: enabled
                        ? () async {
                            setState(() => _busy = true);
                            try {
                              await widget.onConfirm();
                            } finally {
                              if (mounted) setState(() => _busy = false);
                            }
                          }
                        : null,
                    child: Text(
                      context.t('settings.deleteConfirm.action'),
                      style: TextStyle(color: colors.white),
                    ),
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
