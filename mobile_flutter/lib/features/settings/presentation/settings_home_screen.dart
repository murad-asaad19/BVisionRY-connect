import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/i18n/i18n.dart';
import '../../../core/routing/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/settings_group.dart';
import '../../../core/widgets/settings_row.dart';
import '../../../core/widgets/top_bar.dart';
import '../../auth/providers/auth_service_provider.dart';
import '../../privacy/providers/blocks_provider.dart';
import 'widgets/appearance_section.dart';

/// `/settings` — root settings list.
///
/// Spec §6.11 / gallery section H1: two grouped cards. The primary card
/// holds the seven canonical rows from the gallery (Account, Privacy,
/// Notifications, Verification, Blocked users, Help). The forward-evolution
/// rows (Profile, Office hours, Legal, Language) live in a secondary card
/// below so they don't crowd the primary list.
///
/// Sign-out renders as an outline AppButton (red border + text) at the
/// bottom, replacing the destructive plain row in the prior layout.
class SettingsHomeScreen extends ConsumerWidget {
  const SettingsHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int blockedCount = ref.watch(blocksProvider).maybeWhen(
          data: (List<dynamic> xs) => xs.length,
          orElse: () => 0,
        );
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: TopBar(title: context.t('settings.title'), back: true),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: <Widget>[
          SettingsGroupEyebrow(label: context.t('settings.groups.accountSafety')),
          _GroupedCard(
            children: <Widget>[
              SettingsRow(
                key: const Key('settings.row.account'),
                icon: LucideIcons.lockKeyhole,
                label: context.t('settings.account'),
                description: context.t('settings.accountDesc'),
                onTap: () => context.push(Routes.settingsAccount),
              ),
              SettingsRow(
                key: const Key('settings.row.privacy'),
                icon: LucideIcons.eyeOff,
                label: context.t('settings.privacy'),
                description: context.t('settings.privacyDesc'),
                onTap: () => context.push(Routes.settingsPrivacy),
              ),
              SettingsRow(
                key: const Key('settings.row.notifications'),
                icon: LucideIcons.bell,
                label: context.t('settings.notifications'),
                description: context.t('settings.notificationsDesc'),
                onTap: () => context.push(Routes.settingsNotifications),
              ),
              SettingsRow(
                key: const Key('settings.row.verification'),
                icon: LucideIcons.badgeCheck,
                label: context.t('settings.verification'),
                description: context.t('settings.verificationDesc'),
                onTap: () => context.push(Routes.settingsVerification),
              ),
              SettingsRow(
                key: const Key('settings.row.blockedUsers'),
                icon: LucideIcons.shieldOff,
                label: context.t('settings.blockedUsers'),
                description: blockedCount > 0
                    ? context.t(
                        'settings.blockedUsersDesc',
                        vars: <String, Object>{'count': blockedCount},
                      )
                    : null,
                onTap: () => context.push(Routes.settingsBlocked),
              ),
              SettingsRow(
                key: const Key('settings.row.help'),
                icon: LucideIcons.lifeBuoy,
                label: context.t('settings.help'),
                description: context.t('settings.helpDesc'),
                onTap: () => context.push(Routes.settingsHelp),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SettingsGroupEyebrow(label: context.t('settings.groups.yourProfile')),
          _GroupedCard(
            children: <Widget>[
              SettingsRow(
                key: const Key('settings.row.profile'),
                icon: LucideIcons.user,
                label: context.t('settings.profile'),
                description: context.t('settings.profileDesc'),
                onTap: () => context.push(Routes.profileEdit),
              ),
              SettingsRow(
                key: const Key('settings.row.invite'),
                icon: LucideIcons.ticket,
                label: context.t('invite.title'),
                description: context.t('invite.settingsRowDesc'),
                onTap: () => context.push(Routes.inviteFriends),
              ),
              SettingsRow(
                key: const Key('settings.row.officeHours'),
                icon: LucideIcons.calendarClock,
                label: context.t('officeHours.settings.title'),
                onTap: () => context.push(Routes.settingsOfficeHours),
              ),
              SettingsRow(
                key: const Key('settings.row.legal'),
                icon: LucideIcons.fileText,
                label: context.t('settings.legal'),
                onTap: () => context.push(Routes.legalPrivacy),
              ),
              SettingsRow(
                key: const Key('settings.row.language'),
                icon: LucideIcons.languages,
                label: context.t('settings.language.title'),
                onTap: () => context.push(Routes.settingsLanguage),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SettingsGroupEyebrow(label: context.t('settings.groups.appearance')),
          const AppearanceSection(),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: AppButton(
              key: const Key('settings.row.signOut'),
              label: context.t('settings.signOut'),
              variant: AppButtonVariant.outlineDanger,
              onPressed: () async {
                final bool ok = await ref.read(confirmServiceProvider).confirm(
                      context,
                      title: context.t('settings.signOutConfirm.title'),
                      body: context.t('settings.signOutConfirm.body'),
                      confirmLabel: context.t('settings.signOut'),
                      destructive: true,
                    );
                if (!ok) return;
                await ref.read(authServiceProvider).signOut();
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Rounded white card wrapping a stack of `SettingsRow`s. Matches the
/// gallery's grouped card pattern: 10px radius, 12px horizontal margin,
/// 1px border. Each row inside renders flush so the only visible chrome
/// is the surrounding card.
class _GroupedCard extends StatelessWidget {
  const _GroupedCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = Theme.of(context).extension<AppColors>()!;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}
