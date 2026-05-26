/// Mirrors the Postgres enum `public.notification_channel` (spec §2.17):
///   `('push', 'email', 'in_app')`.
///
/// Each value carries a `dbValue` (the literal sent on the wire) and an
/// `i18nLabelKey` resolvable via `context.t(...)` against the
/// `settings.notif.channel.*` namespace in `en.json` / `es.json`.
enum NotificationChannel {
  push('push'),
  email('email'),
  inApp('in_app');

  const NotificationChannel(this.dbValue);
  final String dbValue;

  String get i18nLabelKey => 'settings.notif.channel.$dbValue';

  static NotificationChannel? fromDb(String? value) {
    if (value == null) return null;
    for (final NotificationChannel c in NotificationChannel.values) {
      if (c.dbValue == value) return c;
    }
    return null;
  }
}
