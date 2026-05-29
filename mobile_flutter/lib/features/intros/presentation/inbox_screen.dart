import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/i18n/i18n.dart';
import '../../../core/routing/routes.dart';
import '../../../core/widgets/widgets.dart';
import '../../chat/presentation/widgets/chats_list_body.dart';
import '../domain/intro.dart';
import '../providers/intros_providers.dart';
import 'intro_list_row.dart';

/// Unified inbox / communication hub.
///
/// Tabs are driven by a local [_InboxTab] enum + [SegmentedControl] so the
/// state is local to this screen (no global provider needed):
///   * Received — incoming intro requests (shows the today's-cap banner).
///   * Chats — the conversation list (folded in from the former standalone
///     Chats tab; chats don't warrant their own bottom-nav destination).
///   * Sent — outgoing intro requests.
///
/// Established connections moved to the Network tab ("your people"), so the
/// Inbox stays focused on the intro → chat flow.
///
/// Each tab supports pull-to-refresh that invalidates its underlying
/// provider — pulled together so the badge count is also refreshed.
class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key});

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

enum _InboxTab { received, chats, sent }

/// Threshold above which the Inbox shows the daily-cap heads-up banner.
/// Matches the `intros_today_count` recipient-side cap.
const int kIntrosDailyCap = 20;

class _InboxScreenState extends ConsumerState<InboxScreen> {
  _InboxTab _tab = _InboxTab.received;

  @override
  Widget build(BuildContext context) {
    // Live counts power the gallery's `Received (N) / Sent (N)` tab labels.
    // We read these as AsyncValues and fall back to the bare label while a
    // fetch is in flight so the tab strip never collapses to a different
    // height between states.
    final AsyncValue<List<Intro>> receivedAsync =
        ref.watch(receivedIntrosProvider);
    final AsyncValue<List<Intro>> sentAsync = ref.watch(sentIntrosProvider);
    final String receivedLabel = receivedAsync.maybeWhen(
      data: (List<Intro> list) => context.t(
        'intros.tab.receivedCount',
        vars: <String, Object>{'count': list.length},
      ),
      orElse: () => context.t('intros.tab.received'),
    );
    final String sentLabel = sentAsync.maybeWhen(
      data: (List<Intro> list) => context.t(
        'intros.tab.sentCount',
        vars: <String, Object>{'count': list.length},
      ),
      orElse: () => context.t('intros.tab.sent'),
    );

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: TopBar(title: context.t('intros.inboxTitle')),
      ),
      body: Column(
        children: [
          // SegmentedControl is always first so its vertical position stays
          // stable across tab switches; the cap banner renders below it
          // (Received tab only) instead of pushing the control down.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: SegmentedControl<_InboxTab>(
              value: _tab,
              onChange: (v) => setState(() => _tab = v),
              options: <SegmentedOption<_InboxTab>>[
                SegmentedOption<_InboxTab>(
                  value: _InboxTab.received,
                  label: receivedLabel,
                ),
                SegmentedOption<_InboxTab>(
                  value: _InboxTab.chats,
                  label: context.t('common.tabs.chats'),
                ),
                SegmentedOption<_InboxTab>(
                  value: _InboxTab.sent,
                  label: sentLabel,
                ),
              ],
            ),
          ),
          if (_tab == _InboxTab.received) const _TodayCapBanner(),
          Expanded(
            child: switch (_tab) {
              _InboxTab.received => const _ReceivedTab(),
              _InboxTab.chats => const ChatsListBody(),
              _InboxTab.sent => const _SentTab(),
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
            // Gallery I3 (lines 2351-2353): count-bearing title + body that
            // names the 4 AM refresh and the sender-side "queued" semantics.
            title: context.t(
              'intros.banner.dailyCapTitle',
              vars: <String, Object>{'count': count, 'cap': kIntrosDailyCap},
            ),
            child: Text(
              context.t(
                'intros.banner.dailyCapReceived',
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
      child: QueryState<List<Intro>>(
        value: async,
        loading: const _LoadingList(),
        onRetry: () {
          ref.invalidate(receivedIntrosProvider);
          ref.invalidate(todayCountProvider);
        },
        data: (list) {
          if (list.isEmpty) {
            return const _EmptyInbox(
              icon: LucideIcons.mailOpen,
              bodyKey: 'intros.empty.received',
              showBrowseCta: true,
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
      child: QueryState<List<Intro>>(
        value: async,
        loading: const _LoadingList(),
        onRetry: () => ref.invalidate(sentIntrosProvider),
        data: (list) {
          if (list.isEmpty) {
            return const _EmptyInbox(
              icon: LucideIcons.send,
              bodyKey: 'intros.empty.sent',
              showBrowseCta: true,
            );
          }
          return _IntroListView(intros: list, viewerIsRecipient: false);
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
  const _EmptyInbox({
    required this.icon,
    required this.bodyKey,
    this.showBrowseCta = false,
  });

  final IconData icon;
  final String bodyKey;

  /// When true, surfaces the gallery's E4 "Browse today's matches" gold
  /// button so the empty state isn't a dead end. Routes to `/home`.
  final bool showBrowseCta;

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
          action: showBrowseCta
              ? EmptyStateAction(
                  label: context.t('intros.empty.browse'),
                  onPressed: () => context.go(Routes.home),
                )
              : null,
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
