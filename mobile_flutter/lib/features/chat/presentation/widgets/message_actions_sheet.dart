import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/i18n/i18n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../core/widgets/widgets.dart';
import '../../data/chat_service.dart';
import '../../domain/message.dart';
import '../../domain/message_kind.dart';
import '../../providers/messages_provider.dart';

/// One row in the message-actions sheet. Encoded as an enum so the show()
/// helper can return a typed selection and the caller can branch without
/// stringly-typed switches.
enum MessageAction { reply, edit, delete, copy, report }

/// Bottom-sheet of actions for a long-pressed message.
///
/// Available actions depend on the message's [Message.canEditBy] /
/// [Message.canDeleteBy] gates plus the message kind:
/// - Reply: always shown (placeholder — pops a "Coming soon" toast)
/// - Edit: only when [Message.canEditBy] is true (own text, within 15 min)
/// - Delete: only when [Message.canDeleteBy] is true (own, not deleted)
/// - Copy: only when [Message.kind] is `text` and body is non-null
/// - Report: always shown (placeholder — Phase 11 wires the report flow)
///
/// Edit opens an inline editor sheet on top; Delete runs through the
/// branded [ConfirmService]. Both routes go through the chat service +
/// [MessagesNotifier.mergeUpdated] for optimistic UI.
class MessageActionsSheet extends ConsumerWidget {
  const MessageActionsSheet({
    super.key,
    required this.message,
    required this.currentUserId,
  });

  final Message message;
  final String currentUserId;

  /// Convenience launcher — opens the sheet via [showAppBottomSheet].
  static Future<void> show(
    BuildContext context, {
    required Message message,
    required String currentUserId,
  }) {
    return showAppBottomSheet<void>(
      context: context,
      child: MessageActionsSheet(
        message: message,
        currentUserId: currentUserId,
      ),
    );
  }

  Future<void> _handle(
    BuildContext context,
    WidgetRef ref,
    MessageAction action,
  ) async {
    final toast = ref.read(toastServiceProvider.notifier);
    final chat = ref.read(chatServiceProvider);
    final confirm = ref.read(confirmServiceProvider);
    final notifier = ref.read(
      messagesProvider(message.conversationId).notifier,
    );
    final navigator = Navigator.of(context);
    // Capture localized copy up-front — several branches pop the sheet first,
    // which unmounts `context` before any post-await `context.t` call.
    final comingSoon = context.t('chat.actions.comingSoon');
    final copied = context.t('chat.actions.copied');
    final editFailed = context.t('chat.edit.failed');
    final deleteFailed = context.t('chat.delete.failed');
    switch (action) {
      case MessageAction.reply:
        unawaited(navigator.maybePop());
        toast.showToast(title: comingSoon);
      case MessageAction.copy:
        unawaited(navigator.maybePop());
        if (message.body != null) {
          await Clipboard.setData(ClipboardData(text: message.body!));
          // Explicit feedback — clipboard writes are otherwise silent.
          Haptics.selection();
          toast.showToast(title: copied, intent: AppIntent.success);
        }
      case MessageAction.edit:
        await navigator.maybePop();
        if (!context.mounted) return;
        final newBody = await _MessageEditSheet.show(
          context,
          initial: message.body ?? '',
        );
        if (newBody == null || newBody.isEmpty) return;
        try {
          final updated = await chat.editMessage(message.id, newBody);
          notifier.mergeUpdated(updated);
        } catch (_) {
          toast.showToast(title: editFailed, intent: AppIntent.danger);
        }
      case MessageAction.delete:
        final titleLabel = context.t('chat.delete.confirmTitle');
        final bodyLabel = context.t('chat.delete.confirmBody');
        final confirmLabel = context.t('chat.actions.delete');
        final cancelLabel = context.t('chat.recording.cancel');
        await navigator.maybePop();
        if (!context.mounted) return;
        final confirmed = await confirm.confirm(
          context,
          title: titleLabel,
          body: bodyLabel,
          confirmLabel: confirmLabel,
          cancelLabel: cancelLabel,
          destructive: true,
        );
        if (!confirmed) return;
        Haptics.medium();
        try {
          final tombstoned = await chat.deleteMessage(message.id);
          notifier.mergeUpdated(tombstoned);
        } catch (_) {
          toast.showToast(title: deleteFailed, intent: AppIntent.danger);
        }
      case MessageAction.report:
        unawaited(navigator.maybePop());
        toast.showToast(title: comingSoon);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canEdit = message.canEditBy(userId: currentUserId);
    final canDelete = message.canDeleteBy(userId: currentUserId);
    final canCopy =
        message.kind == MessageKind.text && (message.body?.isNotEmpty ?? false);

    final actions = <_ActionRow>[
      _ActionRow(
        icon: LucideIcons.cornerUpLeft,
        label: context.t('chat.actions.reply'),
        onTap: () => _handle(context, ref, MessageAction.reply),
      ),
      if (canEdit)
        _ActionRow(
          icon: LucideIcons.pencil,
          label: context.t('chat.actions.edit'),
          onTap: () => _handle(context, ref, MessageAction.edit),
        ),
      if (canCopy)
        _ActionRow(
          icon: LucideIcons.copy,
          label: context.t('chat.actions.copy'),
          onTap: () => _handle(context, ref, MessageAction.copy),
        ),
      if (canDelete)
        _ActionRow(
          icon: LucideIcons.trash2,
          label: context.t('chat.actions.delete'),
          destructive: true,
          onTap: () => _handle(context, ref, MessageAction.delete),
        ),
      _ActionRow(
        icon: LucideIcons.flag,
        label: context.t('chat.actions.report'),
        onTap: () => _handle(context, ref, MessageAction.report),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (final a in actions) a,
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final typo = Theme.of(context).extension<AppTypography>()!;
    final color = destructive ? colors.danger : colors.body;
    return ListTile(
      leading: Icon(icon, color: color, size: 20),
      title: Text(label, style: typo.bodyLg.copyWith(color: color)),
      onTap: onTap,
    );
  }
}

/// Inline editor for message bodies — shown on top of the
/// [MessageActionsSheet] when the user picks Edit.
class _MessageEditSheet extends StatefulWidget {
  const _MessageEditSheet({required this.initial});

  final String initial;

  static Future<String?> show(BuildContext context, {required String initial}) {
    return showAppBottomSheet<String>(
      context: context,
      child: _MessageEditSheet(initial: initial),
    );
  }

  @override
  State<_MessageEditSheet> createState() => _MessageEditSheetState();
}

class _MessageEditSheetState extends State<_MessageEditSheet> {
  late String _value = widget.initial;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final typo = Theme.of(context).extension<AppTypography>()!;
    final insets = MediaQuery.of(context).viewInsets;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + insets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            context.t('chat.edit.title'),
            style: typo.displayLg.copyWith(color: colors.navy),
          ),
          const SizedBox(height: 12),
          AppInput(
            value: _value,
            multiline: true,
            minLines: 3,
            maxLines: 6,
            onChanged: (v) => setState(() => _value = v),
            textInputAction: TextInputAction.newline,
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: AppButton(
                  label: context.t('chat.edit.cancel'),
                  variant: AppButtonVariant.outline,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  label: context.t('chat.edit.save'),
                  variant: AppButtonVariant.primary,
                  onPressed: _value.trim().isEmpty
                      ? null
                      : () => Navigator.of(context).pop(_value.trim()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
