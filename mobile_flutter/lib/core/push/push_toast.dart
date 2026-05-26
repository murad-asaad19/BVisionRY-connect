import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../i18n/i18n.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Top-anchored card for foreground push notifications. Spec section 10.4 +
/// gallery section I6. Routed via [onTap]; dismissed via [onDismiss].
///
/// Rendered as a standalone widget so feature screens (or a future
/// PushToastHost) can compose it directly. Phase 12's runtime wiring goes
/// through the existing `ToastService` (`lib/core/widgets/toast.dart`) for
/// queue management - see `_PushBootstrap` in `lib/app.dart`.
class PushToast extends StatelessWidget {
  const PushToast({
    super.key,
    required this.title,
    required this.body,
    required this.onTap,
    required this.onDismiss,
  });

  final String title;
  final String body;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = Theme.of(context).extension<AppColors>()!;
    final AppTypography typography =
        Theme.of(context).extension<AppTypography>()!;
    final AppRadii radii = Theme.of(context).extension<AppRadii>()!;
    final AppSpacing spacing = Theme.of(context).extension<AppSpacing>()!;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radii.card),
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: EdgeInsets.symmetric(
            horizontal: spacing.cardLg,
            vertical: spacing.card,
          ),
          decoration: BoxDecoration(
            color: colors.navy,
            borderRadius: BorderRadius.circular(radii.card),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                blurRadius: 16,
                offset: Offset(0, 6),
                color: Color(0x33000000),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 6, right: 12),
                decoration: BoxDecoration(
                  color: colors.gold,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: typography.displaySm.copyWith(color: colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      body,
                      style: typography.bodyMd.copyWith(
                        color: colors.white.withValues(alpha: 0.86),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Semantics(
                label: context.t('push.toastDismissA11y'),
                button: true,
                child: IconButton(
                  tooltip: context.t('push.toastDismissA11y'),
                  onPressed: onDismiss,
                  icon: Icon(LucideIcons.x, color: colors.white, size: 18),
                  splashRadius: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
