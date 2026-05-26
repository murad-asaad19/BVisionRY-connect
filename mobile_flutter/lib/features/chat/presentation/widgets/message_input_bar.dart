import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/i18n/i18n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/widgets.dart';
import '../../providers/typing_provider.dart';

/// Bottom composer toolbar (gallery F1/F3).
///
/// Layout (matches gallery F1): mic icon (left), multiline text field
/// (center), optional calendar icon (between input and send), send button
/// rendered as a filled navy 44px circle with a white arrow icon (right).
/// The text field grows up to 5 lines as the user types. Typing emits a
/// throttled `typing` broadcast (debounced inside [TypingBroadcaster]) so
/// the peer sees the typing indicator without spamming the channel.
///
/// The parent owns the actual send / image-pick / voice-record flows —
/// this widget only exposes callbacks and a busy state. Note: per the
/// gallery there is no attach-image affordance in the composer; image
/// sending is reached through the message-actions sheet instead.
class MessageInputBar extends ConsumerStatefulWidget {
  const MessageInputBar({
    super.key,
    required this.conversationId,
    required this.onSendText,
    required this.onPickImage,
    required this.onRecordVoice,
    this.onProposeMeeting,
  });

  final String conversationId;
  final Future<void> Function(String body) onSendText;

  /// Retained for backward compatibility — the composer no longer renders
  /// an attach button per the gallery, but the parent screen still wires
  /// an image-pick path through the message-actions sheet.
  final Future<void> Function() onPickImage;
  final Future<void> Function() onRecordVoice;

  /// Optional — when supplied, renders a calendar-icon button that opens
  /// the propose-meeting sheet. Phase 7 leaves this null; Phase 8 wires
  /// it via [ConversationScreen].
  final Future<void> Function()? onProposeMeeting;

  @override
  ConsumerState<MessageInputBar> createState() => _MessageInputBarState();
}

class _MessageInputBarState extends ConsumerState<MessageInputBar> {
  final TextEditingController _controller = TextEditingController();
  bool _sending = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final has = _controller.text.trim().isNotEmpty;
    if (has != _hasText) setState(() => _hasText = has);
  }

  Future<void> _send() async {
    final body = _controller.text.trim();
    if (body.isEmpty || _sending) return;
    setState(() => _sending = true);
    final toast = ref.read(toastServiceProvider.notifier);
    final failedTitle = context.t('chat.send.failed');
    try {
      await widget.onSendText(body);
      if (mounted) _controller.clear();
    } catch (_) {
      toast.showToast(title: failedTitle, intent: AppIntent.danger);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final typo = Theme.of(context).extension<AppTypography>()!;
    final radii = Theme.of(context).extension<AppRadii>()!;
    final canSend = !_sending && _hasText;
    return Container(
      decoration: BoxDecoration(
        color: colors.white,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 4, 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              AppIconButton(
                icon: LucideIcons.mic,
                label: 'Record voice',
                size: AppIconButtonSize.md,
                onPressed: _sending ? null : () => widget.onRecordVoice(),
                disabled: _sending,
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(radii.input),
                    border: Border.all(color: colors.border),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: TextField(
                    key: const ValueKey('chat-input-field'),
                    controller: _controller,
                    enabled: !_sending,
                    minLines: 1,
                    maxLines: 5,
                    keyboardType: TextInputType.multiline,
                    textCapitalization: TextCapitalization.sentences,
                    style: typo.bodyLg.copyWith(color: colors.body),
                    decoration: InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      hintText: context.t('chat.composerPlaceholder'),
                      hintStyle: typo.bodyLg.copyWith(color: colors.muted),
                    ),
                    onChanged: (_) {
                      ref
                          .read(typingBroadcasterProvider)
                          .ping(widget.conversationId);
                    },
                  ),
                ),
              ),
              if (widget.onProposeMeeting != null)
                AppIconButton(
                  key: const ValueKey('chat-propose-meeting'),
                  icon: LucideIcons.calendar,
                  label: 'Propose meeting',
                  size: AppIconButtonSize.md,
                  onPressed: _sending ? null : () => widget.onProposeMeeting!(),
                  disabled: _sending,
                ),
              _SendCircleButton(
                canSend: canSend,
                sending: _sending,
                onTap: _send,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Filled navy 44px circle send button (gallery F1/F3).
///
/// Renders a white up-arrow on a navy background; falls back to a reduced
/// opacity when the composer is empty so the button stays visible but
/// clearly disabled. While sending we swap the arrow for a small white
/// progress spinner.
class _SendCircleButton extends StatelessWidget {
  const _SendCircleButton({
    required this.canSend,
    required this.sending,
    required this.onTap,
  });

  final bool canSend;
  final bool sending;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final Widget child = sending
        ? const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
        : Icon(LucideIcons.arrowUp, size: 20, color: colors.white);
    return Padding(
      padding: const EdgeInsets.only(left: 4, right: 2),
      child: Semantics(
        button: true,
        enabled: canSend,
        label: 'Send',
        child: Opacity(
          opacity: canSend || sending ? 1.0 : 0.45,
          child: Material(
            color: colors.navy,
            shape: const CircleBorder(),
            child: InkWell(
              key: const ValueKey('chat-send-button'),
              customBorder: const CircleBorder(),
              onTap: canSend ? onTap : null,
              child: SizedBox(
                width: 44,
                height: 44,
                child: Center(child: child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
