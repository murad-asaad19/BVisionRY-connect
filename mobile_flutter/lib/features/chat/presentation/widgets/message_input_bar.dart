import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/i18n/i18n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/widgets.dart';
import '../../providers/typing_provider.dart';

/// Bottom composer toolbar.
///
/// Layout: mic icon, paperclip (attach image), multiline text field
/// (center), optional calendar icon (between input and send), send button
/// rendered as a filled navy 44px circle with a white arrow icon (right).
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
    this.onProposeMeeting,
  });

  final String conversationId;
  final Future<void> Function(String body) onSendText;

  /// Triggered when the user taps the attach (paperclip) icon. The parent
  /// owns the image-pick flow (permission request, picker UI, upload).
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
    // Optimistic send: clear the field right away so the composer is
    // immediately ready for the next message. The bubble carries its own
    // sending/failed state + retry, so no toast and no composer lockout.
    _controller.clear();
    setState(() => _sending = true);
    try {
      await widget.onSendText(body);
    } catch (_) {
      // Failure is surfaced on the optimistic bubble (FAILED + retry).
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
              // Attach / record / propose stay enabled during a text send —
              // a text round-trip must not lock out other compose actions.
              // The mockup renders these leading actions as gold-pale chips
              // with navy glyphs (`.chat-input .ico`) — the `subtle` variant
              // at `sm` (32px chip, 44dp hit) is the closest token match.
              AppIconButton(
                icon: LucideIcons.mic,
                label: context.t('media.recordVoice'),
                size: AppIconButtonSize.sm,
                variant: AppIconButtonVariant.subtle,
                onPressed: () => widget.onRecordVoice(),
              ),
              AppIconButton(
                key: const ValueKey('chat-attach-image'),
                icon: LucideIcons.paperclip,
                label: context.t('media.sendPhoto'),
                size: AppIconButtonSize.sm,
                variant: AppIconButtonVariant.subtle,
                onPressed: () => widget.onPickImage(),
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
                  label: context.t('chat.actions.proposeMeeting'),
                  size: AppIconButtonSize.sm,
                  variant: AppIconButtonVariant.subtle,
                  onPressed: () => widget.onProposeMeeting!(),
                ),
              _SendCircleButton(
                canSend: canSend,
                sending: _sending,
                label: context.t('chat.actions.send'),
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
    required this.label,
    required this.onTap,
  });

  final bool canSend;
  final bool sending;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final bool active = canSend || sending;
    final Color bg = active ? colors.navyFill : colors.slate100;
    final Color fg = active ? colors.onNavy : colors.muted;
    final Widget child = sending
        ? SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(fg),
            ),
          )
        : Icon(LucideIcons.arrowUp, size: 20, color: fg);
    return Padding(
      padding: const EdgeInsets.only(left: 4, right: 2),
      child: Semantics(
        button: true,
        enabled: canSend,
        label: label,
        // Solid navy when active, light-slate when waiting for text —
        // gives a clearer "available vs disabled" cue than fading the
        // navy fill (which read as gray over a white bg). The fill colour
        // and a subtle scale ease between states so the button "wakes up"
        // when the composer becomes sendable — short, standard-curve, no
        // layout shift (the 44px hit box is constant).
        child: AnimatedScale(
          scale: active ? 1.0 : 0.92,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Material(
              color: Colors.transparent,
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
      ),
    );
  }
}
