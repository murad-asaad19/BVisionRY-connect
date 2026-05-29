import 'package:flutter/material.dart';

import '../../../../core/i18n/i18n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/haptics.dart';
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
///   3. Footer: muted `settings.notif.decayFooter` note (gallery H3 /
///      spec §14) — "Activity-decay guilt nudges are not available — by
///      design." Replaces the previous mailer-status placeholder copy.
///
/// Switch values resolve through [prefs] — a `kind:channel` keyed map.
/// Absent entries default to enabled=true to mirror the `should_notify`
/// SQL default-open semantics (spec §17.13).
///
/// Each cell holds a short-lived optimistic override so a single toggle
/// flips that switch instantly (and disables it while the write is in
/// flight) without reloading the whole matrix. The override is dropped once
/// the parent's invalidation reseeds [prefs] with the persisted value, or
/// reverts to the persisted value if the write surfaced an error.
class NotificationMatrix extends StatefulWidget {
  const NotificationMatrix({
    super.key,
    required this.prefs,
    required this.onChanged,
  });

  /// `kind:channel` keyed map of persisted preferences. Absent cells
  /// render as `true` (default-open).
  final Map<String, bool> prefs;

  /// Fired when the user toggles any cell. Provider invalidation +
  /// optimistic update happen in the caller; this widget separately tracks a
  /// per-cell pending state so the toggled switch responds immediately.
  final NotificationPrefChanged onChanged;

  @override
  State<NotificationMatrix> createState() => _NotificationMatrixState();
}

class _NotificationMatrixState extends State<NotificationMatrix> {
  /// `kind:channel` keys with an in-flight optimistic value. The bool is the
  /// value the user just selected; the cell renders it (and stays disabled)
  /// until the parent reseeds [NotificationMatrix.prefs].
  final Map<String, bool> _pending = <String, bool>{};

  static String _cellKey(NotificationKind k, NotificationChannel c) =>
      '${k.dbValue}:${c.dbValue}';

  @override
  void didUpdateWidget(covariant NotificationMatrix oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The parent reseeds `prefs` after a write resolves (success → new value,
    // failure → reverted value). Clear any pending override whose persisted
    // value now matches what the user selected, so the switch re-enables.
    if (!identical(oldWidget.prefs, widget.prefs)) {
      _pending.removeWhere((String key, bool optimistic) {
        final bool persisted = widget.prefs[key] ?? true;
        return persisted == optimistic;
      });
    }
  }

  bool _value(NotificationKind k, NotificationChannel c) {
    final String key = _cellKey(k, c);
    return _pending[key] ?? widget.prefs[key] ?? true;
  }

  bool _isPending(NotificationKind k, NotificationChannel c) =>
      _pending.containsKey(_cellKey(k, c));

  void _onCellChanged(NotificationKind k, NotificationChannel c, bool v) {
    Haptics.selection();
    setState(() => _pending[_cellKey(k, c)] = v);
    widget.onChanged(k, c, v);
  }

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
              // Gallery H3 leaves the kind-column header blank; the channel
              // labels alone convey the matrix. Kept as a spacer so the
              // channel columns stay aligned with the rows below.
              const Expanded(flex: 4, child: SizedBox.shrink()),
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
            pushPending: _isPending(k, NotificationChannel.push),
            emailPending: _isPending(k, NotificationChannel.email),
            inAppPending: _isPending(k, NotificationChannel.inApp),
            onChanged: _onCellChanged,
          ),
        Padding(
          key: const Key('matrix.emailUnavailableNote'),
          padding: const EdgeInsets.all(12),
          child: Text(
            context.t('settings.notif.decayFooter'),
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
    required this.pushPending,
    required this.emailPending,
    required this.inAppPending,
    required this.onChanged,
  });

  final NotificationKind kind;
  final bool push;
  final bool email;
  final bool inApp;
  final bool pushPending;
  final bool emailPending;
  final bool inAppPending;
  final NotificationPrefChanged onChanged;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = Theme.of(context).extension<AppColors>()!;
    final AppTypography typo = Theme.of(context).extension<AppTypography>()!;
    final String kindLabel = context.t(kind.i18nLabelKey);
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
                Text(kindLabel, style: typo.displaySm),
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
                        context.t('common.comingSoon'),
                        style: typo.bodyXs.copyWith(color: colors.muted),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          _Cell(
            key: Key('matrix.switch.${kind.dbValue}.push'),
            kindLabel: kindLabel,
            channel: NotificationChannel.push,
            value: push,
            pending: pushPending,
            onChanged: (bool v) => onChanged(kind, NotificationChannel.push, v),
          ),
          _Cell(
            key: Key('matrix.switch.${kind.dbValue}.email'),
            kindLabel: kindLabel,
            channel: NotificationChannel.email,
            value: email,
            pending: emailPending,
            onChanged: (bool v) =>
                onChanged(kind, NotificationChannel.email, v),
          ),
          _Cell(
            key: Key('matrix.switch.${kind.dbValue}.in_app'),
            kindLabel: kindLabel,
            channel: NotificationChannel.inApp,
            value: inApp,
            pending: inAppPending,
            onChanged: (bool v) =>
                onChanged(kind, NotificationChannel.inApp, v),
          ),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    super.key,
    required this.kindLabel,
    required this.channel,
    required this.value,
    required this.pending,
    required this.onChanged,
  });

  /// Localized kind name (e.g. "Intro received") used to build the SR label.
  final String kindLabel;
  final NotificationChannel channel;
  final bool value;

  /// While `true` a write for this cell is in flight: the switch shows the
  /// optimistic value but is disabled so a rapid re-tap can't race the write.
  final bool pending;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final String channelLabel = context.t(channel.i18nLabelKey);
    return Expanded(
      flex: 2,
      child: Center(
        child: Semantics(
          label: '$kindLabel – $channelLabel',
          child: Switch(
            value: value,
            onChanged: pending ? null : onChanged,
          ),
        ),
      ),
    );
  }
}
