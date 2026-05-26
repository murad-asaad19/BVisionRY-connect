import 'package:connect_mobile/core/errors/app_exception.dart';
import 'package:connect_mobile/features/opportunities/data/opportunities_service.dart';
import 'package:connect_mobile/features/opportunities/domain/interested_user.dart';
import 'package:connect_mobile/features/opportunities/providers/interested_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _FakeService extends Mock implements OpportunitiesService {}

InterestedUser _user(String id) {
  return InterestedUser(
    userId: id,
    handle: 'sam',
    name: 'Sam',
    createdAt: DateTime.utc(2026, 5, 25, 10),
  );
}

void main() {
  test('interestedProvider(id) returns rows for the author', () async {
    final _FakeService fake = _FakeService();
    when(() => fake.listInterested('oid')).thenAnswer(
      (_) async => <InterestedUser>[_user('u1'), _user('u2')],
    );
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        opportunitiesServiceProvider.overrideWithValue(fake),
      ],
    );
    addTearDown(container.dispose);
    final r = await container.read(interestedProvider('oid').future);
    expect(r, hasLength(2));
  });

  test('interestedProvider surfaces ForbiddenException for non-authors',
      () async {
    final _FakeService fake = _FakeService();
    when(() => fake.listInterested('oid')).thenThrow(ForbiddenException());
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        opportunitiesServiceProvider.overrideWithValue(fake),
      ],
    );
    addTearDown(container.dispose);
    expect(
      () => container.read(interestedProvider('oid').future),
      throwsA(isA<ForbiddenException>()),
    );
  });
}
