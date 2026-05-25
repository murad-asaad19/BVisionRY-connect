import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/i18n/i18n.dart';
import '../../../core/widgets/widgets.dart';
import '../domain/connection.dart';
import '../providers/connections_provider.dart';
import 'connection_row.dart';

/// Full-screen `/connections` route (gallery E5).
///
/// Wraps `connectionsProvider` in a [QueryState] for loading / error /
/// empty handling, then renders [ConnectionRow]s with pull-to-refresh.
class ConnectionsScreen extends ConsumerWidget {
  const ConnectionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Connection>> async = ref.watch(connectionsProvider);
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: TopBar(
          title: context.t('connections.title'),
          back: Navigator.of(context).canPop(),
        ),
      ),
      body: QueryState<List<Connection>>(
        value: async,
        onRetry: () => ref.invalidate(connectionsProvider),
        data: (List<Connection> rows) {
          if (rows.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(connectionsProvider);
                await ref.read(connectionsProvider.future);
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(top: 80),
                    child: EmptyState(
                      icon: LucideIcons.users,
                      title: context.t('connections.title'),
                      body: context.t('connections.empty.body'),
                    ),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(connectionsProvider);
              await ref.read(connectionsProvider.future);
            },
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: rows.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                color: Theme.of(context).dividerColor,
              ),
              itemBuilder: (_, i) => ConnectionRow(connection: rows[i]),
            ),
          );
        },
      ),
    );
  }
}
