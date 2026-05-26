import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/i18n/i18n.dart';
import '../../../core/widgets/query_state.dart';
import '../../../core/widgets/toast.dart';
import '../../../core/widgets/top_bar.dart';
import '../../../core/widgets/variants.dart';
import '../../auth/providers/profile_provider.dart';
import '../../profile/domain/profile.dart';
import '../data/settings_service.dart';
import 'widgets/coming_soon_card.dart';

/// `/settings/privacy` — toggle row group for the three privacy-controls
/// the spec recognises (§2.2 + §6.11).
///
/// Behaviour per row:
///   1. **Private mode** — writes via `set_private_mode(p_value)` RPC.
///      Column-level UPDATE on `private_mode` is revoked from
///      `authenticated`, so the RPC is the only path.
///   2. **Read receipts** — writes via direct UPDATE on
///      `profiles.read_receipts_enabled`. The column is NOT in the §2.2
///      revoke list so the table operation is allowed.
///   3. **Public investor page** — calls
///      `SettingsService.setPublicInvestorPage(value)` which throws
///      [UnimplementedRpcException] because the server RPC has not yet
///      shipped (§17.2). The UI catches that exception and surfaces a
///      [ComingSoonCard] under the row.
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
          return ListView(
            children: <Widget>[
              SwitchListTile(
                key: const Key('privacy.privateMode'),
                title: Text(context.t('settings.privacy')),
                subtitle: Text(context.t('settings.privacyDesc')),
                value: profile.privateMode,
                onChanged: (bool v) => _togglePrivateMode(v),
              ),
              SwitchListTile(
                key: const Key('privacy.readReceipts'),
                title: const Text('Read receipts'),
                value: profile.readReceiptsEnabled,
                onChanged: (bool v) => _toggleReadReceipts(v),
              ),
              SwitchListTile(
                key: const Key('privacy.publicInvestorPage'),
                title: Text(
                  context.t('settings.publicInvestorPage.title'),
                ),
                subtitle: Text(
                  context.t(
                    'settings.publicInvestorPage.subtitle',
                    vars: <String, Object>{'handle': profile.handle ?? '—'},
                  ),
                ),
                value: profile.publicInvestorPage,
                onChanged: (bool v) => _togglePublicInvestorPage(v),
              ),
              if (_publicInvestorComingSoon)
                ComingSoonCard(
                  title: context.t('settings.publicInvestorPage.title'),
                  body: context.t('settings.publicInvestorPage.comingSoon'),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _togglePrivateMode(bool v) async {
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
    try {
      await ref.read(settingsServiceProvider).setPublicInvestorPage(v);
      ref.invalidate(profileProvider);
    } on UnimplementedRpcException {
      setState(() => _publicInvestorComingSoon = true);
    } on AppException catch (e) {
      if (mounted) {
        ref.read(toastServiceProvider.notifier).showToast(
              intent: AppIntent.danger,
              title: context.t(e.i18nKey),
            );
      }
    }
  }
}
