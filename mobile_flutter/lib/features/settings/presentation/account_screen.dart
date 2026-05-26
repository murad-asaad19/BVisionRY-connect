import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/i18n/i18n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/settings_row.dart';
import '../../../core/widgets/toast.dart';
import '../../../core/widgets/top_bar.dart';
import '../../../core/widgets/variants.dart';
import '../../auth/providers/auth_service_provider.dart';
import '../../profile/data/profile_service.dart';
import '../../telemetry/stub_telemetry_store.dart';
import '../data/settings_service.dart';
import 'widgets/change_password_sheet.dart';
import 'widgets/delete_account_sheet.dart';
import 'widgets/export_data_tile.dart';

/// `/settings/account` — second-level settings panel.
///
/// Sections:
///   * Email (read-only — sourced from `auth.currentUser?.email`).
///   * Change password (opens [ChangePasswordSheet]).
///   * Telemetry (analytics + crash-reports switches → [TelemetryStore]).
///   * Data export ([ExportDataTile]).
///   * Delete account (danger row → [DeleteAccountSheet] → `deleteMyAccount`
///     edge function → sign-out + storage reset). Router auto-redirects to
///     `/sign-in` once the session clears.
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppColors colors = Theme.of(context).extension<AppColors>()!;
    final AppTypography typo = Theme.of(context).extension<AppTypography>()!;
    final String? email = Supabase.instance.client.auth.currentUser?.email;
    final TelemetryState telemetry = ref.watch(telemetryStoreProvider);
    final TelemetryStore telemetryStore =
        ref.read(telemetryStoreProvider.notifier);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: TopBar(title: context.t('settings.account'), back: true),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: <Widget>[
          // Email section.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: SectionCard(
              title: 'Email',
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  (email == null || email.isEmpty) ? '—' : email,
                  style: typo.bodyLg.copyWith(color: colors.body),
                ),
              ),
            ),
          ),
          // Password.
          SettingsRow(
            key: const Key('account.changePasswordRow'),
            icon: LucideIcons.keyRound,
            label: context.t('settings.changePassword.title'),
            onTap: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              builder: (_) => ChangePasswordSheet(
                onSubmit: (String pw) async {
                  try {
                    await ref.read(settingsServiceProvider).changePassword(pw);
                    if (context.mounted) {
                      Navigator.of(context).pop();
                      ref.read(toastServiceProvider.notifier).showToast(
                            intent: AppIntent.success,
                            title: context.t('settings.changePassword.success'),
                          );
                    }
                  } on AppException catch (e) {
                    if (context.mounted) {
                      ref.read(toastServiceProvider.notifier).showToast(
                            intent: AppIntent.danger,
                            title: context.t(e.i18nKey),
                          );
                    }
                  }
                },
              ),
            ),
          ),
          // Telemetry section.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: SectionCard(
              title: context.t('settings.telemetry'),
              padding: EdgeInsets.zero,
              child: Column(
                children: <Widget>[
                  SwitchListTile(
                    key: const Key('account.telemetry.analytics'),
                    title: Text(context.t('settings.analytics')),
                    value: telemetry.analyticsEnabled,
                    onChanged: telemetryStore.setAnalyticsEnabled,
                  ),
                  SwitchListTile(
                    key: const Key('account.telemetry.crashReports'),
                    title: Text(context.t('settings.crashReports')),
                    value: telemetry.crashReportsEnabled,
                    onChanged: telemetryStore.setCrashReportsEnabled,
                  ),
                ],
              ),
            ),
          ),
          ExportDataTile(),
          SettingsRow(
            key: const Key('account.deleteRow'),
            icon: LucideIcons.trash2,
            label: context.t('settings.deleteAccount'),
            destructive: true,
            onTap: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              builder: (_) => DeleteAccountSheet(
                onConfirm: () async {
                  try {
                    await ref.read(profileServiceProvider).deleteMyAccount();
                    await ref.read(authServiceProvider).signOut();
                    if (context.mounted) Navigator.of(context).pop();
                  } on AppException catch (e) {
                    if (context.mounted) {
                      ref.read(toastServiceProvider.notifier).showToast(
                            intent: AppIntent.danger,
                            title: context.t(e.i18nKey),
                          );
                    }
                  } catch (_) {
                    if (context.mounted) {
                      ref.read(toastServiceProvider.notifier).showToast(
                            intent: AppIntent.danger,
                            title: context.t('settings.deleteFailed'),
                          );
                    }
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
