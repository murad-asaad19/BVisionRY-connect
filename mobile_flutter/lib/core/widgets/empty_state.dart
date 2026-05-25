import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'app_button.dart';

/// Pairs an icon + label + tap handler for [EmptyState.action]. Only the
/// `primary` and `gold` button variants are exposed on purpose — empty
/// states never need destructive or outline CTAs.
class EmptyStateAction {
  const EmptyStateAction({
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
  });

  final String label;
  final VoidCallback onPressed;
  final AppButtonVariant variant;
}

/// Branded empty-list placeholder.
///
/// Visual mirrors the existing RN `EmptyState` treatment: a 80px gold-pale
/// halo around a Material icon, navy title, optional muted body, optional
/// CTA. Use for every "no rows yet" surface — inbox, opportunity board,
/// office-hours queue, etc.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.body,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? body;
  final EmptyStateAction? action;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final typo = Theme.of(context).extension<AppTypography>()!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colors.goldPale,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: colors.gold, size: 32),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: typo.displayLg.copyWith(color: colors.navy, fontSize: 17),
          ),
          if (body != null) ...[
            const SizedBox(height: 6),
            Text(
              body!,
              textAlign: TextAlign.center,
              style: typo.bodyMd.copyWith(color: colors.muted),
            ),
          ],
          if (action != null) ...[
            const SizedBox(height: 16),
            AppButton(
              label: action!.label,
              onPressed: action!.onPressed,
              variant: action!.variant,
            ),
          ],
        ],
      ),
    );
  }
}
