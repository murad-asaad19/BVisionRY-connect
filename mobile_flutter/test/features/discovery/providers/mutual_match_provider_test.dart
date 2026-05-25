import 'package:connect_mobile/features/discovery/data/discovery_service.dart';
import 'package:connect_mobile/features/discovery/providers/mutual_match_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fake_discovery_service.dart';

void main() {
  test('delegates to service.isMutualMatch', () async {
    final fake = FakeDiscoveryService();
    when(() => fake.isMutualMatch(any())).thenAnswer((_) async => true);
    final container = ProviderContainer(
      overrides: <Override>[discoveryServiceProvider.overrideWithValue(fake)],
    );
    addTearDown(container.dispose);
    expect(await container.read(mutualMatchProvider('x').future), isTrue);
    verify(() => fake.isMutualMatch('x')).called(1);
  });
}
