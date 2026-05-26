import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/i18n/i18n.dart';
import '../../../core/routing/routes.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/settings_row.dart';
import '../../../core/widgets/top_bar.dart';
import '../../auth/providers/auth_service_provider.dart';

/// `/settings` — root settings list.
///
/// Spec §6.11 / gallery section H1: row groups for Profile, Account,
/// Privacy & visibility, Notifications, Office hours, Verification,
/// Blocked users, Help & support, Legal, Language, and a sign-out
/// danger row at the bottom.
///
/// Each row pushes its destination route; sign-out runs through
/// [ConfirmService] so a stray tap can't drop the session.
class SettingsHomeScreen extends ConsumerWidget {
  const SettingsHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: TopBar(title: context.t('settings.title'), back: true),
      ),
      body: ListView(
        children: <Widget>[
          SettingsRow(
            key: const Key('settings.row.profile'),
            icon: LucideIcons.user,
            label: context.t('settings.profile'),
            description: context.t('settings.profileDesc'),
            onTap: () => context.push(Routes.profileEdit),
          ),
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
            key: const Key('settings.row.officeHours'),
            icon: LucideIcons.calendarClock,
            label: context.t('officeHours.settings.title'),
            onTap: () => context.push(Routes.settingsOfficeHours),
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
            onTap: () => context.push(Routes.settingsBlocked),
          ),
          SettingsRow(
            key: const Key('settings.row.help'),
            icon: LucideIcons.lifeBuoy,
            label: context.t('settings.help'),
            description: context.t('settings.helpDesc'),
            onTap: () => context.push(Routes.settingsHelp),
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
          const SizedBox(height: 24),
          SettingsRow(
            key: const Key('settings.row.signOut'),
            icon: LucideIcons.logOut,
            label: context.t('settings.signOut'),
            destructive: true,
            onTap: () async {
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
        ],
      ),
    );
  }
}
