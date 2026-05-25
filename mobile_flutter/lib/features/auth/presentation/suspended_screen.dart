import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/i18n/i18n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/widgets.dart';
import '../providers/auth_service_provider.dart';

/// Static destination for users whose `profiles.suspended_at` is set.
///
/// Per spec §5.5 the screen is intentionally minimal: a single warning
/// glyph, a short explanation, a primary "Submit appeal" button that opens
/// the user's mail composer pre-addressed to support, and a secondary
/// "Sign out" button that delegates to [AuthService.signOut]. The route
/// guard delivers the user here and removes them once the suspension is
/// lifted.
class SuspendedScreen extends ConsumerWidget {
  const SuspendedScreen({super.key});

  Future<void> _openAppealMail() async {
    final Uri uri = Uri(
      scheme: 'mailto',
      path: 'support@bvisionry.com',
      query: 'subject=${Uri.encodeComponent('Account appeal')}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppColors colors = Theme.of(context).extension<AppColors>()!;
    final AppSpacing spacing = Theme.of(context).extension<AppSpacing>()!;
    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(spacing.gutter),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: colors.warningBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    LucideIcons.triangleAlert,
                    size: 36,
                    color: colors.warning,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  context.t('suspended.title'),
                  style: Theme.of(context).textTheme.displayMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  context.t('suspended.body'),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: colors.muted),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: spacing.section),
                AppButton(
                  key: const Key('appeal'),
                  label: context.t('suspended.submitAppeal'),
                  onPressed: _openAppealMail,
                ),
                const SizedBox(height: 10),
                AppButton(
                  key: const Key('sign-out'),
                  label: context.t('suspended.signOut'),
                  variant: AppButtonVariant.outlineDanger,
                  onPressed: () => ref.read(authServiceProvider).signOut(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
