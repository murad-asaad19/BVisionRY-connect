import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/i18n/i18n.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/widgets.dart';
import '../../data/chat_service.dart';
import '../../domain/conversation_overview.dart';
import '../../providers/conversation_overview_provider.dart';
import '../../providers/unread_counts_provider.dart';
import 'conversation_overview_tile.dart';

/// Conversation list (gallery F0) — the pull-to-refresh list of
/// [ConversationOverview] rows, extracted from the former standalone Chats
/// screen so it can be embedded as the "Chats" segment of the Inbox hub.
///
/// Renders `conversationOverviewProvider`; tapping a row pushes
/// `/chats/:id`; long-pressing opens the mute / unmute action sheet.
class ChatsListBody extends ConsumerWidget {
  const ChatsListBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final AsyncValue<List<ConversationOverview>> async =
        ref.watch(conversationOverviewProvider);
    return QueryState<List<ConversationOverview>>(
      value: async,
      onRetry: () => ref.invalidate(conversationOverviewProvider),
      data: (List<ConversationOverview> rows) => RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(conversationOverviewProvider);
          ref.invalidate(unreadCountsProvider);
          await ref.read(conversationOverviewProvider.future);
        },
        child: rows.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(top: 80),
                    child: EmptyState(
                      icon: LucideIcons.messageCircle,
                      title: context.t('chat.empty.title'),
                      body: context.t('chat.empty.body'),
                    ),
                  ),
                ],
              )
            : ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: rows.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  // Indent past the 44px avatar (16 pad + 44 avatar + 12 gap)
                  // so the rule starts under the name/preview column.
                  indent: 72,
                  color: colors.border,
                ),
                itemBuilder: (_, int i) => ConversationOverviewTile(
                  overview: rows[i],
                  onTap: () => context.push(Routes.chat(rows[i].conversationId)),
                  onLongPress: () => _showMuteSheet(context, ref, rows[i]),
                ),
              ),
      ),
    );
  }

  Future<void> _showMuteSheet(
    BuildContext context,
    WidgetRef ref,
    ConversationOverview row,
  ) async {
    final chatService = ref.read(chatServiceProvider);
    final toast = ref.read(toastServiceProvider.notifier);
    final isMuted = row.isMuted;
    // Snapshot localised strings BEFORE the async gap so we never touch
    // BuildContext across awaits.
    final muteLabel = context.t('chat.mute.menuMute');
    final unmuteLabel = context.t('chat.mute.menuUnmute');
    final muteOkBody = context.t('chat.mute.muteSuccess');
    final unmuteOkBody = context.t('chat.mute.unmuteSuccess');
    final errBody = context.t('chat.mute.actionFailed');
    await showAppBottomSheet<void>(
      context: context,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: Icon(
                  isMuted ? LucideIcons.bell : LucideIcons.bellOff,
                ),
                title: Text(isMuted ? unmuteLabel : muteLabel),
                onTap: () async {
                  Navigator.of(context).pop();
                  try {
                    if (isMuted) {
                      await chatService.unmuteConversation(row.conversationId);
                      toast.showToast(title: unmuteOkBody);
                    } else {
                      await chatService.muteConversation(row.conversationId);
                      toast.showToast(title: muteOkBody);
                    }
                    ref.invalidate(conversationOverviewProvider);
                  } catch (_) {
                    toast.showToast(
                      title: errBody,
                      intent: AppIntent.danger,
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
