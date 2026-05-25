import 'package:connect_mobile/features/auth/providers/auth_service_provider.dart';
import 'package:connect_mobile/features/auth/providers/session_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../helpers/fake_supabase.dart';

void main() {
  test('seeds with currentSession on first read (no AsyncLoading flash)',
      () async {
    final FakeAuthGateway auth = FakeAuthGateway();
    // Seed the gateway's synchronous currentSession before subscribing.
    auth.pushAuthState(
      AuthChangeEvent.initialSession,
      fakeSession(id: 'u-1'),
    );

    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[authGatewayProvider.overrideWithValue(auth)],
    );
    addTearDown(container.dispose);

    // First read resolves to the synchronous seed.
    final Session? first = await container.read(sessionProvider.future);
    expect(first?.user.id, 'u-1');
  });

  test('forwards subsequent auth-state transitions through the stream',
      () async {
    final FakeAuthGateway auth = FakeAuthGateway();
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[authGatewayProvider.overrideWithValue(auth)],
    );
    addTearDown(container.dispose);

    // Subscribe BEFORE first read so we capture every emission.
    final List<Session?> emissions = <Session?>[];
    final ProviderSubscription<AsyncValue<Session?>> sub = container.listen(
      sessionProvider,
      (AsyncValue<Session?>? _, AsyncValue<Session?> n) {
        n.whenData(emissions.add);
      },
      fireImmediately: true,
    );
    addTearDown(sub.close);

    // Let the async* yield the seed.
    await container.read(sessionProvider.future);

    auth.pushAuthState(AuthChangeEvent.signedIn, fakeSession(id: 'u-3'));
    // Pump until the broadcast stream forwards into the provider.
    for (int i = 0; i < 10; i++) {
      await Future<void>.delayed(Duration.zero);
      if (emissions.any((Session? s) => s?.user.id == 'u-3')) break;
    }

    expect(emissions.any((Session? s) => s?.user.id == 'u-3'), isTrue);
  });

  test('emits null seed when no current session', () async {
    final FakeAuthGateway auth = FakeAuthGateway();
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[authGatewayProvider.overrideWithValue(auth)],
    );
    addTearDown(container.dispose);

    final Session? first = await container.read(sessionProvider.future);
    expect(first, isNull);
  });

  test('currentSessionProvider tracks the latest stream value', () async {
    final FakeAuthGateway auth = FakeAuthGateway();
    auth.pushAuthState(AuthChangeEvent.initialSession, fakeSession(id: 'u-2'));
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[authGatewayProvider.overrideWithValue(auth)],
    );
    addTearDown(container.dispose);

    await container.read(sessionProvider.future);
    expect(container.read(currentSessionProvider)?.user.id, 'u-2');
  });
}
