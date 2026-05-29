import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/i18n/i18n.dart';
import '../../../core/routing/routes.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/query_state.dart';
import '../../../core/widgets/skeleton.dart';
import '../providers/connections_provider.dart';
import 'connection_row.dart';

/// The signed-in user's established connections — a pull-to-refresh vertical
/// list of [ConnectionRow]s.
///
/// Lives on the Network tab ("your people"). Tapping a row opens the chat with
/// that connection (handled inside [ConnectionRow]). Empty state nudges the
/// user to browse matches, since connections are formed by accepting intros.
class ConnectionsListBody extends ConsumerWidget {
  const ConnectionsListBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(connectionsProvider);
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(connectionsProvider);
        await ref.read(connectionsProvider.future);
      },
      child: QueryState(
        value: async,
        loading: const _LoadingList(),
        onRetry: () => ref.invalidate(connectionsProvider),
        data: (rows) {
          if (rows.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(top: 64),
                  child: EmptyState(
                    icon: LucideIcons.users,
                    title: context.t('intros.empty.title'),
                    body: context.t('intros.empty.connections'),
                    action: EmptyStateAction(
                      label: context.t('intros.empty.browse'),
                      onPressed: () => context.go(Routes.home),
                    ),
                  ),
                ),
              ],
            );
          }
          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: rows.length,
            itemBuilder: (_, int i) => ConnectionRow(connection: rows[i]),
          );
        },
      ),
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
