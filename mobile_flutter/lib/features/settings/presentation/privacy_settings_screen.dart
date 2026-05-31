import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/i18n/i18n.dart';
import '../../../core/routing/routes.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/query_state.dart';
import '../../../core/widgets/settings_group.dart';
import '../../../core/widgets/settings_row.dart';
import '../../../core/widgets/toast.dart';
import '../../../core/widgets/top_bar.dart';
import '../../../core/widgets/variants.dart';
import '../../auth/providers/profile_provider.dart';
import '../../privacy/domain/blocked_user.dart';
import '../../privacy/providers/blocks_provider.dart';
import '../../profile/domain/profile.dart';
import '../data/settings_service.dart';
import 'widgets/coming_soon_card.dart';

/// `/settings/privacy` — gallery section H2 layout.
///
/// Toggles + chevron rows are grouped under three uppercase eyebrows:
///   * DISCOVERY — Private mode, Public web page
///   * CHAT — Read receipts
///   * SAFETY — Blocked users, Reported by you
///
/// Eyebrow style: navy uppercase, 11px, letter-spacing 0.5, matches the
/// gallery's `.gh` class. Each group is one rounded card with the rows
/// stacked inside so the visual hierarchy mirrors the static gallery.
///
/// Behaviour per toggle:
///   1. **Private mode** — writes via `set_private_mode(p_value)` RPC.
///   2. **Read receipts** — direct UPDATE on `read_receipts_enabled`.
///   3. **Public investor page** — calls
///      `SettingsService.setPublicInvestorPage(value)` which throws
///      [UnimplementedRpcException] today; the UI catches that and
///      surfaces a [ComingSoonCard] under the row.
///
/// All toggles save-on-change; failures surface as a danger toast and the
/// switch reverts (via provider invalidation).
class PrivacySettingsScreen extends ConsumerStatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  ConsumerState<PrivacySettingsScreen> createState() =>
      _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends ConsumerState<PrivacySettingsScreen> {
  bool _publicInvestorComingSoon = false;

  @override
  Widget build(BuildContext context) {
    final AsyncValue<Profile?> profileAsync = ref.watch(profileProvider);
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: TopBar(title: context.t('settings.privacy'), back: true),
      ),
      body: QueryState<Profile?>(
        value: profileAsync,
        data: (Profile? profile) {
          if (profile == null) return const SizedBox.shrink();
          final int blockedCount = ref.watch(blocksProvider).maybeWhen(
                data: (List<BlockedUser> xs) => xs.length,
                orElse: () => 0,
              );
          return ListView(
            padding: const EdgeInsets.only(top: 8, bottom: 24),
            children: <Widget>[
              SettingsGroupEyebrow(
                label: context.t('settings.groups.discovery'),
              ),
              SettingsGroupCard(
                children: <Widget>[
                  SwitchListTile(
                    key: const Key('privacy.privateMode'),
                    title: Text(context.t('settings.privateMode.title')),
                    subtitle: Text(context.t('settings.privateMode.subtitle')),
                    value: profile.privateMode,
                    onChanged: (bool v) => _togglePrivateMode(v),
                  ),
                  SwitchListTile(
                    key: const Key('privacy.publicInvestorPage'),
                    title: Text(
                      context.t('settings.publicPage.title'),
                    ),
                    subtitle: Text(
                      context.t(
                        'settings.publicPage.subtitle',
                        vars: <String, Object>{'handle': profile.handle ?? '—'},
                      ),
                    ),
                    value: profile.publicInvestorPage,
                    onChanged: (bool v) => _togglePublicInvestorPage(v),
                  ),
                ],
              ),
              if (_publicInvestorComingSoon)
                ComingSoonCard(
                  title: context.t('settings.publicInvestorPage.title'),
                  body: context.t('settings.publicInvestorPage.comingSoon'),
                ),
              SettingsGroupEyebrow(label: context.t('settings.groups.chat')),
              SettingsGroupCard(
                children: <Widget>[
                  SwitchListTile(
                    key: const Key('privacy.readReceipts'),
                    title: Text(context.t('settings.readReceipts.title')),
                    subtitle: Text(context.t('settings.readReceipts.subtitle')),
                    value: profile.readReceiptsEnabled,
                    onChanged: (bool v) => _toggleReadReceipts(v),
                  ),
                ],
              ),
              SettingsGroupEyebrow(label: context.t('settings.groups.safety')),
              SettingsGroupCard(
                children: <Widget>[
                  SettingsRow(
                    key: const Key('privacy.row.blockedUsers'),
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
                    key: const Key('privacy.row.reportedByYou'),
                    label: context.t('settings.reportedByYou.title'),
                    description: context.t('settings.reportedByYou.subtitle'),
                    onTap: () => context.push(Routes.reportsHistory),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _togglePrivateMode(bool v) async {
    Haptics.selection();
    try {
      await ref.read(settingsServiceProvider).setPrivateMode(v);
      ref.invalidate(profileProvider);
    } on AppException catch (e) {
      if (mounted) {
        ref.read(toastServiceProvider.notifier).showToast(
              intent: AppIntent.danger,
              title: context.t(e.i18nKey),
            );
      }
    }
  }

  Future<void> _toggleReadReceipts(bool v) async {
    Haptics.selection();
    try {
      await ref.read(settingsServiceProvider).setReadReceiptsEnabled(v);
      ref.invalidate(profileProvider);
    } on AppException catch (e) {
      if (mounted) {
        ref.read(toastServiceProvider.notifier).showToast(
              intent: AppIntent.danger,
              title: context.t(e.i18nKey),
            );
      }
    }
  }

  Future<void> _togglePublicInvestorPage(bool v) async {
    Haptics.selection();
    try {
      await ref.read(settingsServiceProvider).setPublicInvestorPage(v);
      ref.invalidate(profileProvider);
    } on UnimplementedRpcException {
      // The write never landed. Force a rebuild so the controlled switch
      // re-asserts the persisted (OFF) value instead of sitting visually ON,
      // and surface the coming-soon card. We deliberately don't invalidate
      // profileProvider — the persisted value is unchanged, so a refetch would
      // only flash the whole screen's loading skeleton.
      if (mounted) setState(() => _publicInvestorComingSoon = true);
    } on AppException catch (e) {
      // Same: the write failed and the persisted value is unchanged, so a
      // rebuild reverts the controlled switch. Surface the localized error.
      if (mounted) {
        setState(() {});
        ref.read(toastServiceProvider.notifier).showToast(
              intent: AppIntent.danger,
              title: context.t(e.i18nKey),
            );
      }
    }
  }
}
