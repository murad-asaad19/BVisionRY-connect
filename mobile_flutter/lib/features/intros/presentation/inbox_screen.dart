import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/i18n/i18n.dart';
import '../../../core/widgets/widgets.dart';
import '../../connections/presentation/connection_row.dart';
import '../../connections/providers/connections_provider.dart';
import '../domain/intro.dart';
import '../providers/intros_providers.dart';
import 'intro_list_row.dart';

/// Three-tab inbox surface that replaces `InboxScreenStub` from Phase 5.
///
/// Tabs are driven by a local [_InboxTab] enum + [SegmentedControl] so the
/// state is local to this screen (no global provider needed). The
/// Received tab shows a today's-cap banner when the caller has been
/// flooded; the Sent and Connections tabs omit it because that banner is
/// recipient-side context only.
///
/// Each tab supports pull-to-refresh that invalidates its underlying
/// provider — pulled together so the badge count is also refreshed.
class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key});

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

enum _InboxTab { received, sent, connections }

/// Threshold above which the Inbox shows the daily-cap heads-up banner.
/// Matches the `intros_today_count` recipient-side cap.
const int kIntrosDailyCap = 20;

class _InboxScreenState extends ConsumerState<InboxScreen> {
  _InboxTab _tab = _InboxTab.received;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: TopBar(title: context.t('intros.inboxTitle')),
      ),
      body: Column(
        children: [
          if (_tab == _InboxTab.received) const _TodayCapBanner(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: SegmentedControl<_InboxTab>(
              value: _tab,
              onChange: (v) => setState(() => _tab = v),
              options: <SegmentedOption<_InboxTab>>[
                SegmentedOption<_InboxTab>(
                  value: _InboxTab.received,
                  label: context.t('intros.tab.received'),
                ),
                SegmentedOption<_InboxTab>(
                  value: _InboxTab.sent,
                  label: context.t('intros.tab.sent'),
                ),
                SegmentedOption<_InboxTab>(
                  value: _InboxTab.connections,
                  label: context.t('intros.tab.connections'),
                ),
              ],
            ),
          ),
          Expanded(
            child: switch (_tab) {
              _InboxTab.received => const _ReceivedTab(),
              _InboxTab.sent => const _SentTab(),
              _InboxTab.connections => const _ConnectionsTab(),
            },
          ),
        ],
      ),
    );
  }
}

class _TodayCapBanner extends ConsumerWidget {
  const _TodayCapBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayCountProvider);
    return today.maybeWhen(
      data: (count) {
        if (count < kIntrosDailyCap) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: AppBanner(
            intent: AppIntent.info,
            title: context.t('intros.banner.dailyCapTitle'),
            child: Text(
              context.t(
                'intros.todayBannerCapped',
                vars: <String, Object>{'count': count, 'cap': kIntrosDailyCap},
              ),
            ),
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _ReceivedTab extends ConsumerWidget {
  const _ReceivedTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(receivedIntrosProvider);
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(receivedIntrosProvider);
        ref.invalidate(todayCountProvider);
        await ref.read(receivedIntrosProvider.future);
      },
      child: async.when(
        loading: () => const _LoadingList(),
        error: (e, _) => _ListError(message: e.toString()),
        data: (list) {
          if (list.isEmpty) {
            return const _EmptyInbox(
              icon: LucideIcons.mailOpen,
              bodyKey: 'intros.empty.received',
            );
          }
          return _IntroListView(intros: list, viewerIsRecipient: true);
        },
      ),
    );
  }
}

class _SentTab extends ConsumerWidget {
  const _SentTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(sentIntrosProvider);
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(sentIntrosProvider);
        await ref.read(sentIntrosProvider.future);
      },
      child: async.when(
        loading: () => const _LoadingList(),
        error: (e, _) => _ListError(message: e.toString()),
        data: (list) {
          if (list.isEmpty) {
            return const _EmptyInbox(
              icon: LucideIcons.send,
              bodyKey: 'intros.empty.sent',
            );
          }
          return _IntroListView(intros: list, viewerIsRecipient: false);
        },
      ),
    );
  }
}

class _ConnectionsTab extends ConsumerWidget {
  const _ConnectionsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(connectionsProvider);
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(connectionsProvider);
        await ref.read(connectionsProvider.future);
      },
      child: async.when(
        loading: () => const _LoadingList(),
        error: (e, _) => _ListError(message: e.toString()),
        data: (rows) {
          if (rows.isEmpty) {
            return const _EmptyInbox(
              icon: LucideIcons.users,
              bodyKey: 'intros.empty.connections',
            );
          }
          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: rows.length,
            itemBuilder: (_, i) => ConnectionRow(connection: rows[i]),
          );
        },
      ),
    );
  }
}

class _IntroListView extends StatelessWidget {
  const _IntroListView({required this.intros, required this.viewerIsRecipient});

  final List<Intro> intros;
  final bool viewerIsRecipient;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: intros.length,
      separatorBuilder: (_, __) =>
          Divider(height: 1, color: Theme.of(context).dividerColor),
      itemBuilder: (_, i) {
        return IntroListRow(
          intro: intros[i],
          viewerIsRecipient: viewerIsRecipient,
        );
      },
    );
  }
}

class _EmptyInbox extends StatelessWidget {
  const _EmptyInbox({required this.icon, required this.bodyKey});

  final IconData icon;
  final String bodyKey;

  @override
  Widget build(BuildContext context) {
    // ListView wrapper keeps pull-to-refresh active on empty states.
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        EmptyState(
          icon: icon,
          title: context.t('intros.empty.title'),
          body: context.t(bodyKey),
        ),
      ],
    );
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: 6,
      itemBuilder: (_, __) => const SkeletonListRow(),
    );
  }
}

class _ListError extends StatelessWidget {
  const _ListError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }
}
