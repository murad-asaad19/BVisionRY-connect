import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/i18n/i18n.dart';
import '../../../core/widgets/query_state.dart';
import '../../../core/widgets/toast.dart';
import '../../../core/widgets/top_bar.dart';
import '../../../core/widgets/variants.dart';
import '../../push/domain/notification_channel.dart';
import '../../push/domain/notification_kind.dart';
import '../../push/domain/notification_preference.dart';
import '../../push/providers/notification_prefs_provider.dart';
import 'widgets/notification_matrix.dart';

/// `/settings/notifications` — kind × channel matrix surfaced from spec
/// §2.17 (the `notification_preferences` table).
///
/// Wires [notificationPrefsProvider] → [NotificationMatrix] →
/// [notificationPrefsServiceProvider.setPreference] for every cell toggle.
/// Provider invalidation re-fetches the rows after a successful write so
/// the UI stays in lock-step with the DB state. Failures surface as a
/// danger toast and the provider invalidation reverts the cell.
class NotificationsSettingsScreen extends ConsumerWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<NotificationPreference>> async =
        ref.watch(notificationPrefsProvider);
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: TopBar(title: context.t('settings.notifications'), back: true),
      ),
      body: QueryState<List<NotificationPreference>>(
        value: async,
        data: (List<NotificationPreference> rows) {
          // Map list -> kind:channel keyed map of enabled bools.
          final Map<String, bool> map = <String, bool>{
            for (final NotificationPreference r in rows)
              '${r.kind.dbValue}:${r.channel.dbValue}': r.enabled,
          };
          return SingleChildScrollView(
            child: NotificationMatrix(
              prefs: map,
              onChanged: (NotificationKind k, NotificationChannel c, bool e) =>
                  _onChanged(context, ref, k, c, e),
            ),
          );
        },
      ),
    );
  }

  Future<void> _onChanged(
    BuildContext context,
    WidgetRef ref,
    NotificationKind kind,
    NotificationChannel channel,
    bool enabled,
  ) async {
    try {
      await ref
          .read(notificationPrefsServiceProvider)
          .setPreference(kind: kind, channel: channel, enabled: enabled);
      ref.invalidate(notificationPrefsProvider);
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
              title: context.t('auth.errors.generic'),
            );
      }
    }
  }
}
