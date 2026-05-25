import 'package:connect_mobile/features/auth/providers/auth_lifecycle.dart';
import 'package:connect_mobile/features/auth/providers/auth_service_provider.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_supabase.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('init() starts auto-refresh; dispose() stops it', () async {
    final FakeAuthGateway auth = FakeAuthGateway();
    final AuthLifecycle lc = AuthLifecycle(auth);

    lc.init();
    await Future<void>.delayed(Duration.zero);
    expect(auth.autoRefreshStarted, 1);

    lc.dispose();
    await Future<void>.delayed(Duration.zero);
    expect(auth.autoRefreshStopped, 1);
  });

  test('resumed -> startAutoRefresh; paused -> stopAutoRefresh', () async {
    final FakeAuthGateway auth = FakeAuthGateway();
    final AuthLifecycle lc = AuthLifecycle(auth);
    lc.init();
    // Reset the started counter to isolate the lifecycle-driven behaviour.
    final int baselineStarted = auth.autoRefreshStarted;
    final int baselineStopped = auth.autoRefreshStopped;

    lc.handleState(AppLifecycleState.resumed);
    await Future<void>.delayed(Duration.zero);
    expect(auth.autoRefreshStarted, baselineStarted + 1);

    lc.handleState(AppLifecycleState.paused);
    await Future<void>.delayed(Duration.zero);
    expect(auth.autoRefreshStopped, baselineStopped + 1);

    lc.handleState(AppLifecycleState.inactive);
    lc.handleState(AppLifecycleState.detached);
    lc.handleState(AppLifecycleState.hidden);
    await Future<void>.delayed(Duration.zero);
    // inactive/detached/hidden also call stopAutoRefresh.
    expect(auth.autoRefreshStopped, baselineStopped + 4);

    lc.dispose();
  });

  test('authLifecycleProvider builds, registers observer, and disposes cleanly', () async {
    final FakeAuthGateway auth = FakeAuthGateway();
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[authGatewayProvider.overrideWithValue(auth)],
    );

    final AuthLifecycle lc = container.read(authLifecycleProvider);
    expect(lc, isA<AuthLifecycle>());
    await Future<void>.delayed(Duration.zero);
    expect(auth.autoRefreshStarted, greaterThanOrEqualTo(1));

    container.dispose();
    await Future<void>.delayed(Duration.zero);
    expect(auth.autoRefreshStopped, greaterThanOrEqualTo(1));
  });
}
