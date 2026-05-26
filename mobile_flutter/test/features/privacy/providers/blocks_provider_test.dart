import 'package:connect_mobile/features/privacy/data/privacy_service.dart';
import 'package:connect_mobile/features/privacy/domain/blocked_user.dart';
import 'package:connect_mobile/features/privacy/providers/blocks_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _FakeService extends Mock implements PrivacyService {}

BlockedUser _block(String id, {String name = 'A', String handle = 'a'}) {
  return BlockedUser(
    blockedId: id,
    handle: handle,
    name: name,
    createdAt: DateTime.utc(2026, 5, 20),
  );
}

void main() {
  test('blocksProvider returns rows from service', () async {
    final _FakeService svc = _FakeService();
    when(svc.listBlockedUsers).thenAnswer(
      (_) async => <BlockedUser>[_block('a'), _block('b', name: 'B')],
    );
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[privacyServiceProvider.overrideWithValue(svc)],
    );
    addTearDown(container.dispose);

    final List<BlockedUser> out = await container.read(blocksProvider.future);
    expect(out, hasLength(2));
    expect(out.first.blockedId, 'a');
  });

  test('isBlockedProvider returns true for an id in the list', () async {
    final _FakeService svc = _FakeService();
    when(svc.listBlockedUsers)
        .thenAnswer((_) async => <BlockedUser>[_block('a')]);
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[privacyServiceProvider.overrideWithValue(svc)],
    );
    addTearDown(container.dispose);

    await container.read(blocksProvider.future);
    expect(container.read(isBlockedProvider('a')), isTrue);
    expect(container.read(isBlockedProvider('b')), isFalse);
  });

  test('isBlockedProvider returns false while the list is loading', () {
    final _FakeService svc = _FakeService();
    when(svc.listBlockedUsers).thenAnswer((_) async => <BlockedUser>[]);
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[privacyServiceProvider.overrideWithValue(svc)],
    );
    addTearDown(container.dispose);
    // Read isBlockedProvider before awaiting blocksProvider — should be false.
    expect(container.read(isBlockedProvider('a')), isFalse);
  });

  test('isBlockedProvider returns false on error state', () async {
    final _FakeService svc = _FakeService();
    when(svc.listBlockedUsers).thenThrow(StateError('boom'));
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[privacyServiceProvider.overrideWithValue(svc)],
    );
    addTearDown(container.dispose);
    // Trigger the load (and catch the rejection so the container is healthy).
    await expectLater(
      container.read(blocksProvider.future),
      throwsA(isA<StateError>()),
    );
    expect(container.read(isBlockedProvider('a')), isFalse);
  });
}
