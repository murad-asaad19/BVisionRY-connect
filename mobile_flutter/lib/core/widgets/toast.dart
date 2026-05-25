import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_radii.dart';
import '../theme/app_typography.dart';
import 'variants.dart';

/// A pending toast item shown by [ToastHost].
@immutable
class ToastItem {
  const ToastItem({
    required this.id,
    required this.title,
    required this.intent,
    this.body,
  });

  final String id;
  final String title;
  final String? body;
  final AppIntent intent;
}

/// Imperative toast handle. Exposes the canonical [showToast] surface
/// callable from anywhere (event handlers, Riverpod notifiers, …) and
/// drives the in-host [items] stream-of-state for [ToastHost] to render.
class ToastService extends StateNotifier<List<ToastItem>> {
  ToastService() : super(const []);

  static const Duration _autoDismiss = Duration(milliseconds: 3500);
  final Map<String, Timer> _timers = {};

  /// Pushes a toast onto the queue. Auto-dismisses after 3.5s.
  String showToast({
    required String title,
    String? body,
    AppIntent intent = AppIntent.info,
  }) {
    final id = 'toast-${DateTime.now().microsecondsSinceEpoch}';
    state = [
      ...state,
      ToastItem(id: id, title: title, body: body, intent: intent),
    ];
    _timers[id] = Timer(_autoDismiss, () => dismiss(id));
    return id;
  }

  /// Removes a toast from the queue immediately (e.g. on tap).
  void dismiss(String id) {
    _timers.remove(id)?.cancel();
    if (!mounted) return;
    state = state.where((t) => t.id != id).toList(growable: false);
  }

  @override
  void dispose() {
    for (final t in _timers.values) {
      t.cancel();
    }
    _timers.clear();
    super.dispose();
  }
}

/// Singleton Riverpod handle. Read from a screen widget to call:
/// `ref.read(toastServiceProvider.notifier).showToast(title: '...')`.
final toastServiceProvider =
    StateNotifierProvider<ToastService, List<ToastItem>>((ref) {
  return ToastService();
});

/// Mount once at the app root (above the navigator). Renders each pending
/// toast in a top-anchored stack; auto-dismiss and tap-to-dismiss are
/// handled by the underlying [ToastService].
class ToastHost extends ConsumerWidget {
  const ToastHost({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toasts = ref.watch(toastServiceProvider);
    if (toasts.isEmpty) return const SizedBox.shrink();
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final t in toasts) _ToastRow(item: t),
          ],
        ),
      ),
    );
  }
}

class _ToastRow extends ConsumerWidget {
  const _ToastRow({required this.item});

  final ToastItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = intentColors(context, item.intent);
    final radii = Theme.of(context).extension<AppRadii>()!;
    final typo = Theme.of(context).extension<AppTypography>()!;
    final icon = _iconFor(item.intent);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: ValueKey('toast-row-${item.id}'),
          borderRadius: BorderRadius.circular(radii.button),
          onTap: () => ref.read(toastServiceProvider.notifier).dismiss(item.id),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: c.bg,
              borderRadius: BorderRadius.circular(radii.button),
              border: Border.all(color: c.border, width: 1),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: c.text, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.title,
                        style: typo.displaySm.copyWith(color: c.text),
                      ),
                      if (item.body != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          item.body!,
                          style: typo.bodyMd.copyWith(color: c.text),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _iconFor(AppIntent intent) {
    return switch (intent) {
      AppIntent.success => Icons.check_circle_outline,
      AppIntent.danger => Icons.cancel_outlined,
      AppIntent.warning => Icons.warning_amber_rounded,
      AppIntent.info => Icons.info_outline,
      AppIntent.neutral => Icons.info_outline,
    };
  }
}
