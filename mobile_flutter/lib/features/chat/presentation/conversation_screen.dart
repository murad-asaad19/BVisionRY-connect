import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/analytics/analytics_events.dart';
import '../../../core/i18n/i18n.dart';
import '../../../core/routing/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/widgets.dart';
import '../../auth/providers/session_provider.dart';
import '../../discovery/domain/role_label.dart';
import '../../intros/providers/intros_providers.dart';
import '../../media/data/media_service.dart';
import '../../meetings/presentation/meeting_card_bubble.dart';
import '../../meetings/presentation/meeting_review_prompt.dart';
import '../../meetings/presentation/propose_meeting_sheet.dart';
import '../../meetings/providers/meeting_proposals_provider.dart';
import '../../privacy/privacy.dart';
import '../../profile/providers/peer_profile_provider.dart';
import '../data/chat_service.dart';
import '../domain/conversation_overview.dart';
import '../domain/message.dart';
import '../domain/message_kind.dart';
import '../providers/active_conversation_provider.dart';
import '../providers/conversation_overview_provider.dart';
import '../providers/messages_provider.dart';
import '../providers/typing_provider.dart';
import '../providers/unread_counts_provider.dart';
import 'widgets/conversation_app_bar.dart';
import 'widgets/image_bubble.dart';
import 'widgets/message_actions_sheet.dart';
import 'widgets/message_input_bar.dart';
import 'widgets/message_timestamp.dart';
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
  bool _paginating = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(activeConversationProvider.notifier).state =
          widget.conversationId;
      Analytics.log(AppEvent.conversationOpened);
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
      // Refresh only the lightweight unread-counts provider (the badge
      // source) — NOT the heavyweight conversationOverviewProvider RPC,
      // which the _onScroll handler would otherwise refetch on every
      // scroll-to-bottom tick. The overview list still stays current via
      // its own messageStreamProvider Realtime listener.
      ref.invalidate(unreadCountsProvider);
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
      _loadOlder();
    }
    // Scrolled back to the newest row → mark read again so the unread
    // badge clears even when new messages stream in via Realtime.
    if (pos.extentBefore < 50) {
      _markRead();
    }
  }

  /// Loads the next older page and surfaces a visible spinner at the top of
  /// the thread while the fetch is in flight. The notifier itself gates
  /// re-entrancy / end-of-history, so a redundant call here is harmless.
  Future<void> _loadOlder() async {
    final notifier = _messages;
    if (_paginating || !notifier.hasMore) return;
    setState(() => _paginating = true);
    try {
      await notifier.loadMore();
    } finally {
      if (mounted) setState(() => _paginating = false);
    }
  }

  MessagesNotifier get _messages =>
      ref.read(messagesProvider(widget.conversationId).notifier);

  Future<void> _sendText(String body) async {
    Haptics.light();
    try {
      await _messages.sendText(body);
      ref.invalidate(conversationOverviewProvider);
    } catch (_) {
      // The failure is surfaced inline on the optimistic bubble (FAILED +
      // retry); no transient toast needed.
    }
  }

  Future<void> _retryText(Message m) async {
    try {
      await _messages.retryText(clientId: m.id, body: m.body ?? '');
      ref.invalidate(conversationOverviewProvider);
    } catch (_) {
      // Stays in the FAILED state; the bubble keeps its retry affordance.
    }
  }

  /// Picks + resizes an image, prepends an optimistic bubble with the local
  /// bytes, then uploads + sends. The upload/RPC reuse the client message id
  /// so the server row reconciles by id.
  Future<void> _pickAndSendImage() async {
    final media = ref.read(mediaServiceProvider);
    final file = await media.pickImage();
    if (file == null) return;
    Uint8List bytes;
    try {
      bytes = await media.resizeImage(file);
      media.validateImageBytes(bytes, mime: 'image/jpeg');
    } catch (_) {
      // Pre-flight failure (too large / unsupported) before any bubble was
      // shown — surface via toast since there is nothing to retry inline.
      if (mounted) {
        ref.read(toastServiceProvider.notifier).showToast(
              title: context.t('chat.send.failed'),
              intent: AppIntent.danger,
            );
      }
      return;
    }
    Haptics.light();
    final messageId = media.generateMessageId();
    final session = ref.read(currentSessionProvider);
    await _runImageSend(
      messageId: messageId,
      bytes: bytes,
      optimistic: Message.optimisticImage(
        messageId: messageId,
        conversationId: widget.conversationId,
        senderId: session?.user.id ?? '',
        createdAt: DateTime.now().toUtc(),
        localBytes: bytes,
      ),
      isRetry: false,
    );
  }

  Future<void> _retryImage(Message m) async {
    final bytes = m.localImageBytes;
    if (bytes == null) {
      // Local bytes are gone (e.g. after a cold reconcile) — drop the stale
      // failed bubble rather than retry with nothing to upload.
      _messages.discardPending(m.id);
      return;
    }
    await _runImageSend(
      messageId: m.id,
      bytes: bytes,
      optimistic: m,
      isRetry: true,
    );
  }

  Future<void> _runImageSend({
    required String messageId,
    required Uint8List bytes,
    required Message optimistic,
    required bool isRetry,
  }) async {
    final media = ref.read(mediaServiceProvider);
    Future<Message> send() async {
      final path = await media.uploadChatMedia(
        conversationId: widget.conversationId,
        messageId: messageId,
        fileName: 'photo.jpg',
        bytes: bytes,
        mime: 'image/jpeg',
      );
      return media.sendImageMessage(
        conversationId: widget.conversationId,
        mediaPath: path,
        mediaMime: 'image/jpeg',
        mediaSizeBytes: bytes.lengthInBytes,
      );
    }

    try {
      if (isRetry) {
        await _messages.retryMedia(messageId: messageId, send: send);
      } else {
        await _messages.sendMedia(
          messageId: messageId,
          optimistic: optimistic,
          send: send,
        );
      }
      ref.invalidate(conversationOverviewProvider);
    } catch (_) {
      // Inline FAILED state on the bubble already reflects this.
    }
  }

  Future<void> _openVoiceSheet() async {
    await VoiceRecorderSheet.show(
      context,
      conversationId: widget.conversationId,
    );
    ref.invalidate(conversationOverviewProvider);
  }

  /// Voice retry: the captured clip no longer exists once the recorder sheet
  /// closed, so discard the failed bubble and re-open the recorder.
  Future<void> _retryVoice(Message m) async {
    _messages.discardPending(m.id);
    await _openVoiceSheet();
  }

  Future<void> _openProposeMeetingSheet({
    String? peerName,
    String? peerHandle,
    String? peerPhotoUrl,
    String? peerHeadline,
  }) async {
    await showAppBottomSheet<void>(
      context: context,
      child: ProposeMeetingSheet(
        conversationId: widget.conversationId,
        peerName: peerName,
        peerHandle: peerHandle,
        peerPhotoUrl: peerPhotoUrl,
        peerHeadline: peerHeadline,
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

  /// Confirms then blocks the peer. Mirrors [BlockButton]'s flow:
  /// destructive confirm dialog → block_user RPC → invalidate dependent
  /// providers (server-side auto-declines any active delivered intros).
  Future<void> _blockPeer({
    required String userId,
    required String name,
    required String handle,
  }) async {
    final confirm = ref.read(confirmServiceProvider);
    final svc = ref.read(privacyServiceProvider);
    final toast = ref.read(toastServiceProvider.notifier);
    final actionFailed = context.t('chat.mute.actionFailed');
    final ok = await confirm.confirm(
      context,
      title: context.t(
        'privacy.blockConfirm.title',
        vars: <String, Object>{'handle': handle.isNotEmpty ? handle : name},
      ),
      body: context.t('privacy.blockConfirm.body'),
      confirmLabel: context.t('privacy.blockUser'),
      destructive: true,
    );
    if (!ok) return;
    try {
      await svc.blockUser(userId);
      ref.invalidate(blocksProvider);
      ref.invalidate(receivedIntrosProvider);
      ref.invalidate(sentIntrosProvider);
      ref.invalidate(conversationOverviewProvider);
    } catch (_) {
      toast.showToast(title: actionFailed, intent: AppIntent.danger);
    }
  }

  /// Returns true when `rows[i]` is the oldest message of its 5-min
  /// cluster — meaning the timestamp header should render above it. In a
  /// `reverse: true` ListView, `rows[i+1]` is older than `rows[i]`, so the
  /// boundary is at the index where the gap to the next-older message
  /// exceeds 5 minutes (or no older message exists).
  bool _isClusterStart(List<Message> rows, int i) {
    if (i == rows.length - 1) return true;
    final gap = rows[i].createdAt.difference(rows[i + 1].createdAt);
    return gap > const Duration(minutes: 5);
  }

  Widget _buildBubble(Message m, String selfId) {
    final variant =
        m.senderId == selfId ? BubbleVariant.me : BubbleVariant.them;
    if (m.isTombstone) {
      return TombstoneBubble(variant: variant);
    }
    final canOpenActions = m.senderId == selfId;
    final longPress = canOpenActions
        ? () {
            // Selection tick on long-press — confirms the actions sheet is
            // opening before it animates in.
            Haptics.selection();
            MessageActionsSheet.show(
              context,
              message: m,
              currentUserId: selfId,
            );
          }
        : null;
    // Optimistic placeholders can't be long-pressed for actions (no server
    // row yet) — gate the actions sheet on a confirmed message.
    final effectiveLongPress = m.isOptimistic ? null : longPress;
    switch (m.kind) {
      case MessageKind.text:
        return TextBubble(
          body: m.body ?? '',
          variant: variant,
          isEdited: m.isEdited,
          onLongPress: effectiveLongPress,
          sendStatus: m.sendStatus,
          onRetry: m.isFailed ? () => _retryText(m) : null,
        );
      case MessageKind.image:
        return ImageBubble(
          mediaPath: m.mediaPath ?? '',
          variant: variant,
          onLongPress: effectiveLongPress,
          localBytes: m.localImageBytes,
          sendStatus: m.sendStatus,
          onRetry: m.isFailed ? () => _retryImage(m) : null,
        );
      case MessageKind.voice:
        return VoiceBubble(
          messageId: m.id,
          mediaPath: m.mediaPath ?? '',
          durationMs: m.mediaDurationMs ?? 0,
          variant: variant,
          transcript: m.transcript,
          transcriptStatus: m.transcriptStatus,
          onLongPress: effectiveLongPress,
          sendStatus: m.sendStatus,
          // Voice retry re-opens the recorder (the local clip is gone once
          // the sheet closed), so the failed bubble is discarded and a fresh
          // recording flow is started.
          onRetry: m.isFailed ? () => _retryVoice(m) : null,
        );
      case MessageKind.meeting:
        return _buildMeetingBubble(m, selfId);
    }
  }

  Widget _buildMeetingBubble(Message m, String selfId) {
    final id = m.meetingProposalId;
    if (id == null) return const SizedBox.shrink();
    // Select ONLY this bubble's proposal so a change to one proposal doesn't
    // rebuild every meeting bubble in the thread (freezed value-equality on
    // the selected proposal gates the rebuild).
    final proposal = ref.watch(
      meetingProposalsProvider(widget.conversationId).select((asyncProposals) {
        final list = asyncProposals.valueOrNull;
        if (list == null) return null;
        for (final p in list) {
          if (p.id == id) return p;
        }
        return null;
      }),
    );
    // Realtime row not yet arrived — render nothing so the list keeps its
    // layout; the proposal's arrival/UPDATE re-triggers this select.
    if (proposal == null) return const SizedBox.shrink();
    return MeetingCardBubble(proposal: proposal, viewerId: selfId);
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

    return PopScope(
      // A conversation reached via context.go (accept_intro / deep-link) has
      // an empty back stack, so the OS back gesture would otherwise exit the
      // app. Mirror the app-bar chevron's fallback to the Inbox hub.
      canPop: context.canPop(),
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (!didPop) context.go(Routes.inbox);
      },
      child: Scaffold(
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
            if (overview == null) return;
            unawaited(
              showReportSheet(
                context,
                targetType: ReportTargetType.profile,
                targetId: overview.peerId,
              ),
            );
          },
          onBlock: overview == null
              ? null
              : () => _blockPeer(
                    userId: overview!.peerId,
                    name: overview.peerName,
                    handle: overview.peerHandle,
                  ),
        ),
        body: Column(
          children: <Widget>[
            Expanded(
              child: QueryState<List<Message>>(
                value: messagesAsync,
                // Default error UI is already localized via messageForError
                // (no raw toString) and scrollable; just wire retry.
                onRetry: () =>
                    ref.invalidate(messagesProvider(widget.conversationId)),
                data: (rows) {
                  if (rows.isEmpty) {
                    return EmptyState(
                      icon: LucideIcons.messageSquare,
                      title: context.t('chat.noMessages'),
                    );
                  }
                  // Reverse list → the older-history end is the TOP, so the
                  // extra trailing indices render above the oldest message:
                  //   index rows.length      → pagination spinner (while a
                  //                             fetch is in flight), then
                  //   the next index up      → the connection-context header,
                  //                             shown only once all history is
                  //                             loaded (`!hasMore`) so it marks
                  //                             the true start of the thread.
                  final showContextHeader = !_messages.hasMore;
                  final itemCount = rows.length +
                      (_paginating ? 1 : 0) +
                      (showContextHeader ? 1 : 0);
                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: itemCount,
                    itemBuilder: (ctx, i) {
                      // Highest index = top of the reverse list = thread start.
                      if (showContextHeader && i == itemCount - 1) {
                        return _ConnectionContextHeader(
                          peerName: overview?.peerName ?? peer?.name ?? '',
                          peerPhotoUrl:
                              overview?.peerPhotoUrl ?? peer?.photoUrl,
                          peerRole: peer?.primaryRole,
                        );
                      }
                      if (i >= rows.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        );
                      }
                      final showTimestamp = _isClusterStart(rows, i);
                      final bubble = _buildBubble(rows[i], selfId);
                      if (!showTimestamp) return bubble;
                      return Column(
                        children: <Widget>[
                          MessageTimestamp(at: rows[i].createdAt),
                          bubble,
                        ],
                      );
                    },
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
                peerHeadline: peer?.headline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Connection-context card pinned to the oldest end (top) of the thread once
/// all history is loaded — frames the conversation with the peer's identity
/// and the "connected via intro" provenance so the thread always opens with a
/// reminder of how the two are connected. No date is shown (the relationship,
/// not its start, is what matters here).
class _ConnectionContextHeader extends StatelessWidget {
  const _ConnectionContextHeader({
    required this.peerName,
    this.peerPhotoUrl,
    this.peerRole,
  });

  final String peerName;
  final String? peerPhotoUrl;
  final String? peerRole;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final typo = Theme.of(context).extension<AppTypography>()!;
    final hasRole = peerRole != null && peerRole!.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Avatar(
            name: peerName,
            photoUrl: peerPhotoUrl,
            size: 56,
            tone: AvatarTone.featured,
          ),
          const SizedBox(height: 10),
          Text(
            peerName,
            textAlign: TextAlign.center,
            style: typo.displayMd.copyWith(color: colors.navy),
          ),
          if (hasRole) ...<Widget>[
            const SizedBox(height: 2),
            Text(
              roleLabel(context, peerRole!),
              textAlign: TextAlign.center,
              style: typo.bodySm.copyWith(color: colors.muted),
            ),
          ],
          const SizedBox(height: 10),
          Pill(
            label: context.t('chat.connectedViaIntro'),
            variant: PillVariant.success,
            icon: Icons.check,
          ),
        ],
      ),
    );
  }
}
