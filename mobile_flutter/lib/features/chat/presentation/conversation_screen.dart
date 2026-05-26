import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/i18n/i18n.dart';
import '../../../core/routing/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/widgets.dart';
import '../../auth/providers/session_provider.dart';
import '../../media/data/media_service.dart';
import '../../meetings/presentation/meeting_card_bubble.dart';
import '../../meetings/presentation/meeting_review_prompt.dart';
import '../../meetings/presentation/propose_meeting_sheet.dart';
import '../../meetings/providers/meeting_proposals_provider.dart';
import '../../profile/providers/peer_profile_provider.dart';
import '../data/chat_service.dart';
import '../domain/conversation_overview.dart';
import '../domain/message.dart';
import '../domain/message_kind.dart';
import '../providers/active_conversation_provider.dart';
import '../providers/conversation_overview_provider.dart';
import '../providers/messages_provider.dart';
import '../providers/typing_provider.dart';
import 'widgets/conversation_app_bar.dart';
import 'widgets/image_bubble.dart';
import 'widgets/message_actions_sheet.dart';
import 'widgets/message_input_bar.dart';
import 'widgets/text_bubble.dart';
import 'widgets/tombstone_bubble.dart';
import 'widgets/typing_indicator.dart';
import 'widgets/voice_bubble.dart';
import 'widgets/voice_recorder_sheet.dart';

/// Conversation thread screen (route `/chats/:id`, gallery F3).
///
/// Responsibilities:
/// - Renders the peer-aware [ConversationAppBar].
/// - Drives a `reverse: true` [ListView] off [messagesProvider] (newest at
///   bottom). When the user scrolls to within 100dp of the top, loads the
///   next older page via [MessagesNotifier.loadMore].
/// - Picks the right bubble widget per [MessageKind] (text, image, voice,
///   meeting placeholder) and toggles to [TombstoneBubble] for deleted
///   rows. Long-press on own text → [MessageActionsSheet].
/// - Shows [TypingIndicator] above the input bar when the peer is typing.
/// - Hosts the [MessageInputBar] at the bottom — wires text/image/voice
///   send flows.
/// - Sets [activeConversationProvider] on mount (cleared on dispose) so
///   Phase 12 push handlers can suppress in-thread toasts.
/// - Calls `mark_conversation_read` on mount and again whenever the user
///   scrolls back to the bottom of the thread.
class ConversationScreen extends ConsumerStatefulWidget {
  const ConversationScreen({super.key, required this.conversationId});

  final String conversationId;

  @override
  ConsumerState<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<ConversationScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _markingRead = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(activeConversationProvider.notifier).state =
          widget.conversationId;
      _markRead();
    });
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    // Newer flutter_riverpod versions disallow `ref` access in dispose;
    // wrap defensively so the cleanup is best-effort and never throws.
    try {
      final currentActive = ref.read(activeConversationProvider);
      if (currentActive == widget.conversationId) {
        ref.read(activeConversationProvider.notifier).state = null;
      }
    } catch (_) {
      // ref already disposed — Phase 12 push routing tolerates a stale
      // active-conversation state until the next mount.
    }
    super.dispose();
  }

  Future<void> _markRead() async {
    if (_markingRead) return;
    _markingRead = true;
    try {
      await ref
          .read(chatServiceProvider)
          .markConversationRead(widget.conversationId);
      ref.invalidate(conversationOverviewProvider);
    } catch (_) {
      // Soft-fail; the badge will refresh on next list invalidation.
    } finally {
      _markingRead = false;
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    // Reverse list → top of the visible thread is `extentAfter` (oldest
    // rows haven't been fetched yet). Trigger pagination on approach.
    if (pos.extentAfter < 100) {
      ref.read(messagesProvider(widget.conversationId).notifier).loadMore();
    }
    // Scrolled back to the newest row → mark read again so the unread
    // badge clears even when new messages stream in via Realtime.
    if (pos.extentBefore < 50) {
      _markRead();
    }
  }

  Future<void> _sendText(String body) async {
    await ref
        .read(messagesProvider(widget.conversationId).notifier)
        .sendText(body);
    ref.invalidate(conversationOverviewProvider);
  }

  Future<void> _pickAndSendImage() async {
    final media = ref.read(mediaServiceProvider);
    final toast = ref.read(toastServiceProvider.notifier);
    final failedTitle = context.t('chat.send.failed');
    try {
      final file = await media.pickImage();
      if (file == null) return;
      final bytes = await media.resizeImage(file);
      media.validateImageBytes(bytes, mime: 'image/jpeg');
      final messageId = media.generateMessageId();
      final path = await media.uploadChatMedia(
        conversationId: widget.conversationId,
        messageId: messageId,
        fileName: 'photo.jpg',
        bytes: bytes,
        mime: 'image/jpeg',
      );
      await media.sendImageMessage(
        conversationId: widget.conversationId,
        mediaPath: path,
        mediaMime: 'image/jpeg',
        mediaSizeBytes: bytes.lengthInBytes,
      );
      ref.invalidate(conversationOverviewProvider);
    } catch (_) {
      toast.showToast(title: failedTitle, intent: AppIntent.danger);
    }
  }

  Future<void> _openVoiceSheet() async {
    await VoiceRecorderSheet.show(
      context,
      conversationId: widget.conversationId,
    );
    ref.invalidate(conversationOverviewProvider);
  }

  Future<void> _openProposeMeetingSheet({
    String? peerName,
    String? peerHandle,
    String? peerPhotoUrl,
  }) async {
    await showAppBottomSheet<void>(
      context: context,
      child: ProposeMeetingSheet(
        conversationId: widget.conversationId,
        peerName: peerName,
        peerHandle: peerHandle,
        peerPhotoUrl: peerPhotoUrl,
      ),
    );
  }

  Future<void> _toggleMute(ConversationOverview overview) async {
    final svc = ref.read(chatServiceProvider);
    final toast = ref.read(toastServiceProvider.notifier);
    final muteOk = context.t('chat.mute.muteSuccess');
    final unmuteOk = context.t('chat.mute.unmuteSuccess');
    final actionFailed = context.t('chat.mute.actionFailed');
    try {
      if (overview.isMuted) {
        await svc.unmuteConversation(widget.conversationId);
        toast.showToast(title: unmuteOk);
      } else {
        await svc.muteConversation(widget.conversationId);
        toast.showToast(title: muteOk);
      }
      ref.invalidate(conversationOverviewProvider);
    } catch (_) {
      toast.showToast(title: actionFailed, intent: AppIntent.danger);
    }
  }

  Widget _buildBubble(Message m, String selfId) {
    final variant =
        m.senderId == selfId ? BubbleVariant.me : BubbleVariant.them;
    if (m.isTombstone) {
      return TombstoneBubble(variant: variant);
    }
    final canOpenActions = m.senderId == selfId;
    final longPress = canOpenActions
        ? () => MessageActionsSheet.show(
              context,
              message: m,
              currentUserId: selfId,
            )
        : null;
    switch (m.kind) {
      case MessageKind.text:
        return TextBubble(
          body: m.body ?? '',
          variant: variant,
          isEdited: m.isEdited,
          onLongPress: longPress,
        );
      case MessageKind.image:
        return ImageBubble(
          mediaPath: m.mediaPath ?? '',
          variant: variant,
          onLongPress: longPress,
        );
      case MessageKind.voice:
        return VoiceBubble(
          messageId: m.id,
          mediaPath: m.mediaPath ?? '',
          durationMs: m.mediaDurationMs ?? 0,
          variant: variant,
          transcript: m.transcript,
          transcriptStatus: m.transcriptStatus,
          onLongPress: longPress,
        );
      case MessageKind.meeting:
        return _buildMeetingBubble(m, selfId);
    }
  }

  Widget _buildMeetingBubble(Message m, String selfId) {
    final id = m.meetingProposalId;
    if (id == null) return const SizedBox.shrink();
    final proposals = ref
            .watch(meetingProposalsProvider(widget.conversationId))
            .valueOrNull ??
        const [];
    for (final p in proposals) {
      if (p.id == id) {
        return MeetingCardBubble(proposal: p, viewerId: selfId);
      }
    }
    // Realtime row not yet arrived — render nothing so the list keeps
    // its layout; an UPDATE on `meeting_proposals` will invalidate the
    // messages provider and re-trigger the build.
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(currentSessionProvider);
    final selfId = session?.user.id ?? '';
    final messagesAsync = ref.watch(messagesProvider(widget.conversationId));
    final typingSet =
        ref.watch(typingProvider(widget.conversationId)).valueOrNull ??
            const <String>{};
    final overviews = ref.watch(conversationOverviewProvider).valueOrNull ??
        const <ConversationOverview>[];
    ConversationOverview? overview;
    for (final o in overviews) {
      if (o.conversationId == widget.conversationId) {
        overview = o;
        break;
      }
    }
    final peerAsync = overview != null
        ? ref.watch(peerProfileProvider(overview.peerId))
        : null;
    final peer = peerAsync?.valueOrNull;
    final isTyping = typingSet.isNotEmpty;
    final colors = Theme.of(context).extension<AppColors>()!;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: ConversationAppBar(
        peerName: overview?.peerName ?? peer?.name ?? '',
        peerHandle: overview?.peerHandle ?? peer?.handle ?? '',
        peerPhotoUrl: overview?.peerPhotoUrl ?? peer?.photoUrl,
        peerHeadline: peer?.headline,
        isMuted: overview?.isMuted ?? false,
        isVerified: peer?.isVerified ?? false,
        peerRole: peer?.primaryRole,
        isTyping: isTyping,
        onTapProfile: () {
          final handle = overview?.peerHandle ?? peer?.handle;
          if (handle != null && handle.isNotEmpty) {
            context.push(Routes.publicProfile(handle));
          }
        },
        onToggleMute: () {
          if (overview != null) _toggleMute(overview);
        },
        onReport: () {
          ref
              .read(toastServiceProvider.notifier)
              .showToast(title: 'Coming soon');
        },
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    e.toString(),
                    style: Theme.of(
                      context,
                    ).extension<AppTypography>()!.bodyMd.copyWith(
                          color: colors.danger,
                        ),
                  ),
                ),
              ),
              data: (rows) {
                if (rows.isEmpty) {
                  return EmptyState(
                    icon: LucideIcons.messageSquare,
                    title: context.t('chat.noMessages'),
                  );
                }
                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: rows.length,
                  itemBuilder: (ctx, i) => _buildBubble(rows[i], selfId),
                );
              },
            ),
          ),
          if (isTyping) TypingIndicator(peerName: overview?.peerName),
          MeetingReviewPrompt(conversationId: widget.conversationId),
          MessageInputBar(
            conversationId: widget.conversationId,
            onSendText: _sendText,
            onPickImage: _pickAndSendImage,
            onRecordVoice: _openVoiceSheet,
            onProposeMeeting: () => _openProposeMeetingSheet(
              peerName: overview?.peerName ?? peer?.name,
              peerHandle: overview?.peerHandle ?? peer?.handle,
              peerPhotoUrl: overview?.peerPhotoUrl ?? peer?.photoUrl,
            ),
          ),
        ],
      ),
    );
  }
}
