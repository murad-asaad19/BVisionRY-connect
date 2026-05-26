import 'package:freezed_annotation/freezed_annotation.dart';

import 'notification_channel.dart';
import 'notification_kind.dart';

part 'notification_preference.freezed.dart';

/// One row of `notification_preferences` (spec §2.17). The composite primary
/// key is `(user_id, kind, channel)`; absent rows default to `enabled = true`
/// to mirror the `should_notify` server-side default-open semantics.
@freezed
class NotificationPreference with _$NotificationPreference {
  const factory NotificationPreference({
    required String userId,
    required NotificationKind kind,
    required NotificationChannel channel,
    required bool enabled,
  }) = _NotificationPreference;

  /// Convenience constructor for the matrix UI's initial state, where a row
  /// is yet to be persisted — semantically equivalent to no row at all.
  factory NotificationPreference.defaultEnabled({
    required String userId,
    required NotificationKind kind,
    required NotificationChannel channel,
  }) =>
      NotificationPreference(
        userId: userId,
        kind: kind,
        channel: channel,
        enabled: true,
      );

  /// Parses a row read via `select() from notification_preferences`.
  /// Throws [FormatException] if the (kind, channel) tuple is unknown so
  /// stale rows do not silently drop out of the matrix.
  factory NotificationPreference.fromJson(Map<String, dynamic> json) {
    final NotificationKind? kind =
        NotificationKind.fromDb(json['kind'] as String?);
    final NotificationChannel? channel =
        NotificationChannel.fromDb(json['channel'] as String?);
    if (kind == null || channel == null) {
      throw FormatException('Unknown notification preference row: $json');
    }
    return NotificationPreference(
      userId: json['user_id'] as String,
      kind: kind,
      channel: channel,
      enabled: (json['enabled'] as bool?) ?? true,
    );
  }
}
