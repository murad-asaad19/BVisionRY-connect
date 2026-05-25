import 'package:flutter/foundation.dart';

/// Minimal profile shape consumed by the auth gate (`routeGuardProvider`).
///
/// Carries only the fields the post-auth routing state machine needs —
/// `onboarded`, `suspended_at`, plus a handful of display niceties. Phase 4
/// will replace this hand-written class with a generated freezed model
/// covering every `profiles.*` column.
@immutable
class Profile {
  const Profile({
    required this.id,
    required this.onboarded,
    required this.suspendedAt,
    this.handle,
    this.name,
    this.privateMode = false,
  });

  final String id;
  final bool onboarded;
  final DateTime? suspendedAt;
  final String? handle;
  final String? name;
  final bool privateMode;

  /// True when the row carries a non-null `suspended_at` timestamp.
  bool get isSuspended => suspendedAt != null;

  /// Parses a Supabase row map into a [Profile]. Tolerates missing optional
  /// columns (defaults: `onboarded=false`, `private_mode=false`).
  factory Profile.fromMap(Map<String, dynamic> m) {
    final sus = m['suspended_at'];
    return Profile(
      id: m['id'] as String,
      onboarded: (m['onboarded'] as bool?) ?? false,
      suspendedAt: sus is String ? DateTime.tryParse(sus) : null,
      handle: m['handle'] as String?,
      name: m['name'] as String?,
      privateMode: (m['private_mode'] as bool?) ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Profile &&
      other.id == id &&
      other.onboarded == onboarded &&
      other.suspendedAt == suspendedAt &&
      other.handle == handle &&
      other.name == name &&
      other.privateMode == privateMode;

  @override
  int get hashCode =>
      Object.hash(id, onboarded, suspendedAt, handle, name, privateMode);
}
