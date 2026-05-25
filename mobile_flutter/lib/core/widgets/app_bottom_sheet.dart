import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';

/// Opens a branded bottom sheet anchored to [context].
///
/// Renders [child] inside a rounded-top container with a centred 38×4
/// drag handle. Backdrop tap dismisses by default; pass `dismissible: false`
/// to require the caller to drive `Navigator.pop(...)`. The returned future
/// resolves with the pop result (or `null` when dismissed via backdrop).
Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required Widget child,
  bool safe = true,
  bool dismissible = true,
  bool isScrollControlled = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    isDismissible: dismissible,
    enableDrag: dismissible,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x800F3460), // navy/50
    builder: (sheetCtx) {
      return AppBottomSheet(safe: safe, child: child);
    },
  );
}

/// Visual shell used by [showAppBottomSheet]. Exposed directly so callers
/// who need to drive a sheet via `Navigator.push(... PageRoute(...))` or
/// embed a sheet inside a custom Scaffold can reuse the same chrome.
class AppBottomSheet extends StatelessWidget {
  const AppBottomSheet({
    super.key,
    required this.child,
    this.safe = true,
  });

  final Widget child;
  final bool safe;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final radii = Theme.of(context).extension<AppRadii>()!;

    final inner = Container(
      decoration: BoxDecoration(
        color: colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(radii.modalTop),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            key: const ValueKey('app-bottom-sheet-handle'),
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: colors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 8),
          Flexible(child: child),
        ],
      ),
    );

    return safe ? SafeArea(top: false, child: inner) : inner;
  }
}
