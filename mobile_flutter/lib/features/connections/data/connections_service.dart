import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/error_map.dart';
import '../../../core/supabase/supabase_client.dart';
import '../domain/connection.dart';

/// Test-seam abstraction over `list_connections` (spec §3.3).
abstract class ConnectionsGateway {
  Future<Object?> rpc(String name, {Map<String, dynamic>? params});
}

class SupabaseConnectionsGateway implements ConnectionsGateway {
  SupabaseConnectionsGateway(this._client);

  final SupabaseClient _client;

  @override
  Future<Object?> rpc(String name, {Map<String, dynamic>? params}) =>
      _client.rpc(name, params: params);
}

final Provider<ConnectionsService> connectionsServiceProvider =
    Provider<ConnectionsService>((Ref<ConnectionsService> ref) {
  return ConnectionsService(
    SupabaseConnectionsGateway(ref.watch(supabaseClientProvider)),
  );
});

/// Thin wrapper around `list_connections`.
///
/// RPC returns the caller's confirmed mutual connections newest-first
/// (sort handled server-side), each row carrying the bridging
/// `conversation_id` so the UI can deep-link straight into the existing
/// 1:1 chat.
class ConnectionsService {
  ConnectionsService(this._gateway);

  final ConnectionsGateway _gateway;

  Future<List<Connection>> listConnections() async {
    try {
      final raw = await _gateway.rpc('list_connections');
      final rows = (raw as List<dynamic>? ?? const <dynamic>[])
          .cast<Map<String, dynamic>>();
      return rows.map(Connection.fromJson).toList(growable: false);
    } on PostgrestException catch (e) {
      throw mapPostgrestError(e);
    }
  }
}
