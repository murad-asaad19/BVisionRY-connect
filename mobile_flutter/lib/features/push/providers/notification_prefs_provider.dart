import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_client.dart';
import '../data/notification_preferences_service.dart';
import '../domain/notification_channel.dart';
import '../domain/notification_kind.dart';
import '../domain/notification_preference.dart';

/// The configured [NotificationPreferencesService] singleton, swappable in
/// tests via `notificationPrefsServiceProvider.overrideWithValue(fake)`.
final Provider<NotificationPreferencesService>
    notificationPrefsServiceProvider = Provider<NotificationPreferencesService>(
  (Ref<NotificationPreferencesService> ref) {
    final client = ref.watch(supabaseClientProvider);
    return NotificationPreferencesService(
      SupabaseNotificationPreferencesGateway(client),
      supabase: client,
    );
  },
);

/// Raw `notification_preferences` rows for the current user. Phase 13's
/// matrix UI watches this; absent (kind, channel) combos default to
/// enabled=true via [NotificationPrefsMatrix.isEnabled].
final FutureProvider<List<NotificationPreference>> notificationPrefsProvider =
    FutureProvider<List<NotificationPreference>>((ref) async {
  final NotificationPreferencesService service =
      ref.watch(notificationPrefsServiceProvider);
  return service.listMyPreferences();
});

/// Matrix view used by Phase 13's settings UI. Wraps the raw list with a
/// cheap `isEnabled(kind, channel)` lookup that returns `true` for missing
/// rows (mirrors `should_notify`'s default-open semantics).
final Provider<AsyncValue<NotificationPrefsMatrix>>
    notificationPrefsMatrixProvider =
    Provider<AsyncValue<NotificationPrefsMatrix>>((ref) {
  return ref.watch(notificationPrefsProvider).whenData(
    (List<NotificationPreference> rows) {
      final Map<String, bool> index = <String, bool>{
        for (final NotificationPreference r in rows)
          '${r.kind.dbValue}:${r.channel.dbValue}': r.enabled,
      };
      return NotificationPrefsMatrix(index);
    },
  );
});

/// Read-only matrix exposing the (kind, channel) -> enabled lookup with
/// default-open semantics. Cheap to construct (~10x10 entries max).
class NotificationPrefsMatrix {
  const NotificationPrefsMatrix(this._index);
  final Map<String, bool> _index;

  bool isEnabled(NotificationKind kind, NotificationChannel channel) {
    return _index['${kind.dbValue}:${channel.dbValue}'] ?? true;
  }
}
