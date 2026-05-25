import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/connections_service.dart';
import '../domain/connection.dart';

/// All confirmed mutual connections of the caller, newest-first
/// (server-sorted). Drives the Connections tab of the Inbox and the
/// dedicated `/connections` screen (Chunk B).
final FutureProvider<List<Connection>> connectionsProvider =
    FutureProvider<List<Connection>>((ref) async {
  return ref.watch(connectionsServiceProvider).listConnections();
});
