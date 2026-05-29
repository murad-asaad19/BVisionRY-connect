import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../i18n/i18n.dart';
import '../routing/routes.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'app_icon_button.dart';

/// Action surfaced in [TopBar.actions].
@immutable
class TopBarAction {
  const TopBarAction({
    required this.icon,
    required this.onPressed,
    required this.label,
    this.key,
  });

  final IconData icon;
  final VoidCallback onPressed;

  /// Required for screen-readers — never derived implicitly.
  final String label;

  /// Optional key forwarded onto the rendered [AppIconButton]. Surfaces
  /// for widget tests that need to target a specific action by key.
  final Key? key;
}

/// AppBar replacement matching the gallery / RN `TopBar` treatment.
///
/// Visual: white background, bottom 1px border, title in [AppTypography]
/// `displayMd`. Uses SafeArea top inset (capped at 64dp to defend against
/// stale provider values) plus 6dp.
class TopBar extends StatelessWidget {
  const TopBar({
    super.key,
    required this.title,
    this.subtitle,
    this.back = false,
    this.onBack,
    this.leading,
    this.actions,
  });

  final String title;
  final String? subtitle;

  /// When true, renders a ChevronLeft icon button on the left that calls
  /// [onBack] (or `Navigator.maybePop` when omitted).
  final bool back;

  /// Custom back handler. Only used when [back] is true.
  final VoidCallback? onBack;

  /// Arbitrary node rendered left of the title block (e.g. an Avatar).
  final Widget? leading;

  /// Trailing icon-buttons. Each action is a 44dp [AppIconButton].
  final List<TopBarAction>? actions;

  static const _maxStatusBarInset = 64.0;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    final typo = Theme.of(context).extension<AppTypography>()!;
    final mq = MediaQuery.maybeOf(context);
    final topInset = (mq?.padding.top ?? 0).clamp(0.0, _maxStatusBarInset);

    return Container(
      key: const ValueKey('top-bar-frame'),
      padding: EdgeInsets.fromLTRB(8, topInset + 6, 8, 8),
      decoration: BoxDecoration(
        color: c.white,
        border: Border(bottom: BorderSide(color: c.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (back)
            AppIconButton(
              icon: Icons.chevron_left,
              label: context.t('common.back'),
              size: AppIconButtonSize.md,
              onPressed: onBack ?? () => _defaultBack(context),
            ),
          if (leading != null) ...[
            if (!back) const SizedBox(width: 4),
            leading!,
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: back || leading != null ? 4 : 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: typo.displayMd.copyWith(color: c.navy),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: typo.bodySm.copyWith(color: c.muted),
                    ),
                ],
              ),
            ),
          ),
          if (actions != null)
            for (final a in actions!)
              AppIconButton(
                key: a.key,
                icon: a.icon,
                label: a.label,
                size: AppIconButtonSize.md,
                onPressed: a.onPressed,
              ),
        ],
      ),
    );
  }

  /// Fallback back-button handler.
  ///
  /// A screen reached via `context.push` has Navigator history → `pop()`
  /// succeeds. A screen reached via `context.go` (route replacement, common
  /// after auth/intro-accept/deep-link) has none → `pop()` is a no-op. In
  /// the latter case we land the user on `/home` which the route guard
  /// then resolves appropriately for their auth/onboarding state.
  static void _defaultBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(Routes.home);
    }
  }
}
