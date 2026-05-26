import 'package:flutter/material.dart';

import '../../../../core/i18n/i18n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../push/domain/notification_channel.dart';
import '../../../push/domain/notification_kind.dart';

typedef NotificationPrefChanged = void Function(
  NotificationKind kind,
  NotificationChannel channel,
  bool enabled,
);

/// 10×3 (kind × channel) preferences grid surfaced in
/// `NotificationsSettingsScreen`.
///
/// Layout:
///   1. Header row: kind column label + 3 channel labels (Push / Email /
///      In-app).
///   2. Body: one row per [NotificationKind.uiMatrixOrder] entry. Rows
///      whose kind has `hasEmitter == false` (spec §17.4) render a
///      "coming soon" chip below the label so users understand toggling
///      is purely declarative until the server-side emitter ships.
///   3. Footer: muted `settings.notif.emailUnavailable` note (spec §17.1)
///      because the email channel has no mailer yet.
///
/// Switch values resolve through [prefs] — a `kind:channel` keyed map.
/// Absent entries default to enabled=true to mirror the `should_notify`
/// SQL default-open semantics (spec §17.13).
class NotificationMatrix extends StatelessWidget {
  const NotificationMatrix({
    super.key,
    required this.prefs,
    required this.onChanged,
  });

  /// `kind:channel` keyed map of persisted preferences. Absent cells
  /// render as `true` (default-open).
  final Map<String, bool> prefs;

  /// Fired when the user toggles any cell. Provider invalidation +
  /// optimistic update happen in the caller.
  final NotificationPrefChanged onChanged;

  bool _value(NotificationKind k, NotificationChannel c) =>
      prefs['${k.dbValue}:${c.dbValue}'] ?? true;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = Theme.of(context).extension<AppColors>()!;
    final AppTypography typo = Theme.of(context).extension<AppTypography>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: <Widget>[
              Expanded(
                flex: 4,
                child: Text(
                  context.t('settings.notif.header'),
                  style: typo.displayXs.copyWith(color: colors.muted),
                ),
              ),
              for (final NotificationChannel ch in NotificationChannel.values)
                Expanded(
                  flex: 2,
                  child: Center(
                    child: Text(
                      context.t(ch.i18nLabelKey),
                      style: typo.displayXs.copyWith(color: colors.muted),
                    ),
                  ),
                ),
            ],
          ),
        ),
        for (final NotificationKind k in NotificationKind.uiMatrixOrder)
          _MatrixRow(
            kind: k,
            push: _value(k, NotificationChannel.push),
            email: _value(k, NotificationChannel.email),
            inApp: _value(k, NotificationChannel.inApp),
            onChanged: onChanged,
          ),
        Padding(
          key: const Key('matrix.emailUnavailableNote'),
          padding: const EdgeInsets.all(12),
          child: Text(
            context.t('settings.notif.emailUnavailable'),
            style: typo.bodySm.copyWith(color: colors.muted),
          ),
        ),
      ],
    );
  }
}

class _MatrixRow extends StatelessWidget {
  const _MatrixRow({
    required this.kind,
    required this.push,
    required this.email,
    required this.inApp,
    required this.onChanged,
  });

  final NotificationKind kind;
  final bool push;
  final bool email;
  final bool inApp;
  final NotificationPrefChanged onChanged;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = Theme.of(context).extension<AppColors>()!;
    final AppTypography typo = Theme.of(context).extension<AppTypography>()!;
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: <Widget>[
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(context.t(kind.i18nLabelKey), style: typo.displaySm),
                if (!kind.hasEmitter)
                  Padding(
                    key: Key('matrix.noEmitterChip.${kind.dbValue}'),
                    padding: const EdgeInsets.only(top: 2),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: colors.slate100,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'coming soon',
                        style: typo.bodyXs.copyWith(color: colors.muted),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          _Cell(
            key: Key('matrix.switch.${kind.dbValue}.push'),
            value: push,
            onChanged: (bool v) => onChanged(kind, NotificationChannel.push, v),
          ),
          _Cell(
            key: Key('matrix.switch.${kind.dbValue}.email'),
            value: email,
            onChanged: (bool v) =>
                onChanged(kind, NotificationChannel.email, v),
          ),
          _Cell(
            key: Key('matrix.switch.${kind.dbValue}.in_app'),
            value: inApp,
            onChanged: (bool v) =>
                onChanged(kind, NotificationChannel.inApp, v),
          ),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({super.key, required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Expanded(
        flex: 2,
        child: Center(
          child: Switch(value: value, onChanged: onChanged),
        ),
      );
}
