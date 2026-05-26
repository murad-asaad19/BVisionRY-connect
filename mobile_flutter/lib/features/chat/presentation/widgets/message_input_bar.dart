import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/i18n/i18n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/widgets.dart';
import '../../providers/typing_provider.dart';

/// Bottom composer toolbar (gallery F3).
///
/// Layout: image-attach icon, mic icon, multiline text field, send icon.
/// The text field grows up to 5 lines as the user types. Typing emits a
/// throttled `typing` broadcast (debounced inside [TypingBroadcaster]) so
/// the peer sees the typing indicator without spamming the channel.
///
/// The parent owns the actual send / image-pick / voice-record flows —
/// this widget only exposes callbacks and a busy state.
class MessageInputBar extends ConsumerStatefulWidget {
  const MessageInputBar({
    super.key,
    required this.conversationId,
    required this.onSendText,
    required this.onPickImage,
    required this.onRecordVoice,
  });

  final String conversationId;
  final Future<void> Function(String body) onSendText;
  final Future<void> Function() onPickImage;
  final Future<void> Function() onRecordVoice;

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
                icon: LucideIcons.image,
                label: 'Attach image',
                size: AppIconButtonSize.md,
                onPressed: _sending ? null : () => widget.onPickImage(),
                disabled: _sending,
              ),
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
              SizedBox(
                width: 44,
                height: 44,
                child: IconButton(
                  key: const ValueKey('chat-send-button'),
                  icon: _sending
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              colors.navy,
                            ),
                          ),
                        )
                      : Icon(
                          LucideIcons.send,
                          color: canSend ? colors.navy : colors.muted,
                        ),
                  onPressed: canSend ? _send : null,
                  tooltip: 'Send',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
