import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart' as ul;

import '../../../core/i18n/i18n.dart';
import '../../../core/routing/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/settings_row.dart';
import '../../../core/widgets/top_bar.dart';

/// Test-injectable URL launcher signature so we can assert mailto / https
/// targets without invoking the platform channel during widget tests.
typedef LaunchUrlFn = Future<bool> Function(Uri uri);

/// `/settings/help` — contact + legal short-cuts + app version.
///
/// Rows:
///   1. Support email — taps open `mailto:support@bvisionry.com`.
///   2. Privacy policy — pushes `/legal/privacy`.
///   3. Terms of service — pushes `/legal/terms`.
///   4. Version footer — `{version}+{buildNumber}` from `PackageInfo`.
class HelpScreen extends StatelessWidget {
  // `launchUrl` resolves a function default at construction time so a
  // const ctor is impossible.
  // ignore: prefer_const_constructors_in_immutables
  HelpScreen({
    super.key,
    LaunchUrlFn? launchUrl,
    this.packageVersion,
  }) : launchUrl = launchUrl ?? _defaultLaunch;

  /// Injectable launcher seam.
  final LaunchUrlFn launchUrl;

  /// Optional override — tests inject a fixed string; production fetches
  /// via `PackageInfo.fromPlatform()`.
  final String? packageVersion;

  static Future<bool> _defaultLaunch(Uri uri) => ul.launchUrl(uri);

  @override
  Widget build(BuildContext context) {
    final AppColors colors = Theme.of(context).extension<AppColors>()!;
    final AppTypography typo = Theme.of(context).extension<AppTypography>()!;
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: TopBar(title: context.t('settings.help'), back: true),
      ),
      body: ListView(
        children: <Widget>[
          SettingsRow(
            key: const Key('help.email'),
            icon: LucideIcons.mail,
            label: context.t('settings.contactTitle'),
            description: context.t('settings.supportEmail'),
            onTap: () => launchUrl(
              Uri(
                scheme: 'mailto',
                path: context.t('settings.supportEmail'),
              ),
            ),
          ),
          SettingsRow(
            key: const Key('help.privacy'),
            icon: LucideIcons.shield,
            label: context.t('settings.privacyPolicy'),
            onTap: () => context.push(Routes.legalPrivacy),
          ),
          SettingsRow(
            key: const Key('help.terms'),
            icon: LucideIcons.scale,
            label: context.t('settings.termsOfService'),
            onTap: () => context.push(Routes.legalTerms),
          ),
          if (packageVersion != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '${context.t('settings.version')} $packageVersion',
                style: typo.bodySm.copyWith(color: colors.muted),
              ),
            )
          else
            FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (
                BuildContext context,
                AsyncSnapshot<PackageInfo> snap,
              ) {
                if (!snap.hasData) return const SizedBox.shrink();
                final PackageInfo info = snap.data!;
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    '${context.t('settings.version')} ${info.version}+${info.buildNumber}',
                    style: typo.bodySm.copyWith(color: colors.muted),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
