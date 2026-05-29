import 'package:flutter/foundation.dart';

/// One row of `ensure_invite_codes(p_count)` — a shareable invite code owned
/// by the caller (migration `20260612030000_invite_waitlist.sql`).
///
/// Plain immutable value type (no codegen) — the shape is small and stable, so
/// a hand-written `fromJson` keeps the feature self-contained without dragging
/// in a build_runner pass.
@immutable
class InviteCode {
  const InviteCode({
    required this.code,
    required this.maxUses,
    required this.usedCount,
    this.expiresAt,
    required this.createdAt,
  });

  /// The shareable code string (8-char Crockford base32).
  final String code;

  /// How many times this code may be redeemed.
  final int maxUses;

  /// How many times it has been redeemed so far.
  final int usedCount;

  /// Optional expiry; null means the code never expires.
  final DateTime? expiresAt;

  final DateTime createdAt;

  /// Remaining redemptions (never negative).
  int get remainingUses => (maxUses - usedCount).clamp(0, maxUses);

  /// True when the code can still be redeemed (uses left and not past expiry).
  bool get isActive {
    if (remainingUses <= 0) return false;
    final DateTime? exp = expiresAt;
    if (exp != null && !exp.isAfter(DateTime.now())) return false;
    return true;
  }

  factory InviteCode.fromJson(Map<String, dynamic> json) {
    final Object? exp = json['expires_at'];
    return InviteCode(
      code: json['code'] as String,
      maxUses: (json['max_uses'] as num).toInt(),
      usedCount: (json['used_count'] as num).toInt(),
      expiresAt: exp == null ? null : DateTime.parse(exp as String).toUtc(),
      createdAt: DateTime.parse(json['created_at'] as String).toUtc(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InviteCode &&
          other.code == code &&
          other.maxUses == maxUses &&
          other.usedCount == usedCount &&
          other.expiresAt == expiresAt &&
          other.createdAt == createdAt);

  @override
  int get hashCode =>
      Object.hash(code, maxUses, usedCount, expiresAt, createdAt);
}
