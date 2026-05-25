import 'package:connect_mobile/core/errors/app_exception.dart';
import 'package:connect_mobile/features/connections/data/connections_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../helpers/intros_fixtures.dart';

class _FakeConnectionsGateway extends Mock implements ConnectionsGateway {}

void main() {
  setUpAll(() => registerFallbackValue(<String, dynamic>{}));

  test('listConnections returns parsed rows', () async {
    final gateway = _FakeConnectionsGateway();
    final service = ConnectionsService(gateway);
    final c = buildConnection();
    when(
      () => gateway.rpc('list_connections', params: any(named: 'params')),
    ).thenAnswer((_) async => <Map<String, dynamic>>[c.toJson()]);

    final result = await service.listConnections();
    expect(result, hasLength(1));
    expect(result.single.userId, c.userId);
    expect(result.single.conversationId, c.conversationId);
  });

  test('listConnections returns empty list when RPC returns []', () async {
    final gateway = _FakeConnectionsGateway();
    final service = ConnectionsService(gateway);
    when(
      () => gateway.rpc('list_connections', params: any(named: 'params')),
    ).thenAnswer((_) async => <Map<String, dynamic>>[]);

    expect(await service.listConnections(), isEmpty);
  });

  test('listConnections maps 28000 -> UnauthenticatedException', () async {
    final gateway = _FakeConnectionsGateway();
    final service = ConnectionsService(gateway);
    when(
      () => gateway.rpc('list_connections', params: any(named: 'params')),
    ).thenThrow(const PostgrestException(message: '', code: '28000'));

    expect(
      () => service.listConnections(),
      throwsA(isA<UnauthenticatedException>()),
    );
  });
}
