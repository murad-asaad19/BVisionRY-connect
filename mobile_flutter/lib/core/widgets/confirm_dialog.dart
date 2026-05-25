import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_typography.dart';
import 'app_button.dart';

/// Imperative confirmation prompt presented as a bottom sheet.
///
/// Consumed via `ref.read(confirmServiceProvider).confirm(context, ...)` — the
/// returned `Future<bool>` resolves `true` when the user confirms (and any
/// async `onConfirm` work completes successfully), `false` otherwise.
class ConfirmService {
  /// Opens the confirmation sheet anchored to [context] and returns a
  /// future that resolves to the user's choice. If [onConfirm] throws, the
  /// promise still resolves `false` and the sheet closes — surface the
  /// failure via a Toast / Banner at the call site.
  Future<bool> confirm(
    BuildContext context, {
    required String title,
    String? body,
    String confirmLabel = 'OK',
    String cancelLabel = 'Cancel',
    bool destructive = false,
    Future<void> Function()? onConfirm,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x800F3460), // navy/50
      builder: (sheetCtx) {
        return _ConfirmSheet(
          title: title,
          body: body,
          confirmLabel: confirmLabel,
          cancelLabel: cancelLabel,
          destructive: destructive,
          onConfirm: onConfirm,
        );
      },
    );
    return result ?? false;
  }
}

/// Riverpod handle to the singleton [ConfirmService].
///
/// Pattern: `ref.read(confirmServiceProvider).confirm(ctx, ...)`.
final confirmServiceProvider = Provider<ConfirmService>((ref) {
  return ConfirmService();
});

class _ConfirmSheet extends StatefulWidget {
  const _ConfirmSheet({
    required this.title,
    required this.body,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.destructive,
    required this.onConfirm,
  });

  final String title;
  final String? body;
  final String confirmLabel;
  final String cancelLabel;
  final bool destructive;
  final Future<void> Function()? onConfirm;

  @override
  State<_ConfirmSheet> createState() => _ConfirmSheetState();
}

class _ConfirmSheetState extends State<_ConfirmSheet> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final radii = Theme.of(context).extension<AppRadii>()!;
    final typo = Theme.of(context).extension<AppTypography>()!;

    return PopScope(
      canPop: !_busy,
      child: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(radii.modalTop),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: colors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                widget.title,
                style: typo.displayLg.copyWith(color: colors.navy),
              ),
              if (widget.body != null) ...[
                const SizedBox(height: 8),
                Text(
                  widget.body!,
                  style: typo.bodyMd.copyWith(color: colors.body),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: widget.cancelLabel,
                      variant: AppButtonVariant.outline,
                      onPressed:
                          _busy ? null : () => Navigator.of(context).pop(false),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton(
                      label: widget.confirmLabel,
                      variant: widget.destructive
                          ? AppButtonVariant.danger
                          : AppButtonVariant.primary,
                      loading: _busy,
                      onPressed: _busy ? null : _handleConfirm,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleConfirm() async {
    final onConfirm = widget.onConfirm;
    if (onConfirm == null) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() => _busy = true);
    try {
      await onConfirm();
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      // Surface failure via the caller's own toast/banner — close the sheet
      // with `false` so awaiting code can branch on the result.
      if (mounted) Navigator.of(context).pop(false);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
