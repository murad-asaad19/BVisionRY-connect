import 'package:connect_mobile/features/intros/data/intros_service.dart';
import 'package:connect_mobile/features/intros/domain/intro.dart';
import 'package:connect_mobile/features/intros/domain/intro_enums.dart';
import 'package:connect_mobile/features/intros/providers/intros_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/intros_fixtures.dart';

class _FakeIntrosService extends Mock implements IntrosService {}

void main() {
  setUpAll(() => registerFallbackValue(<String, dynamic>{}));

  test('receivedIntrosProvider passes viewer id to the service', () async {
    final fake = _FakeIntrosService();
    when(
      () => fake.listReceivedIntros(viewerId: any(named: 'viewerId')),
    ).thenAnswer((_) async => <Intro>[buildIntro()]);

    final container = ProviderContainer(
      overrides: <Override>[
        introsServiceProvider.overrideWithValue(fake),
        currentUserIdProvider.overrideWithValue('me'),
      ],
    );
    addTearDown(container.dispose);

    final list = await container.read(receivedIntrosProvider.future);
    expect(list, hasLength(1));
    verify(() => fake.listReceivedIntros(viewerId: 'me')).called(1);
  });

  test('receivedIntrosProvider returns empty when signed-out', () async {
    final fake = _FakeIntrosService();
    final container = ProviderContainer(
      overrides: <Override>[
        introsServiceProvider.overrideWithValue(fake),
        currentUserIdProvider.overrideWithValue(null),
      ],
    );
    addTearDown(container.dispose);

    final list = await container.read(receivedIntrosProvider.future);
    expect(list, isEmpty);
    verifyNever(
      () => fake.listReceivedIntros(viewerId: any(named: 'viewerId')),
    );
  });

  test('sentIntrosProvider passes viewer id to the service', () async {
    final fake = _FakeIntrosService();
    when(
      () => fake.listSentIntros(viewerId: any(named: 'viewerId')),
    ).thenAnswer((_) async => <Intro>[buildIntro(senderId: 'me')]);

    final container = ProviderContainer(
      overrides: <Override>[
        introsServiceProvider.overrideWithValue(fake),
        currentUserIdProvider.overrideWithValue('me'),
      ],
    );
    addTearDown(container.dispose);

    final list = await container.read(sentIntrosProvider.future);
    expect(list, hasLength(1));
    verify(() => fake.listSentIntros(viewerId: 'me')).called(1);
  });

  test('todayCountProvider returns service value', () async {
    final fake = _FakeIntrosService();
    when(() => fake.introsTodayCount()).thenAnswer((_) async => 7);

    final container = ProviderContainer(
      overrides: <Override>[
        introsServiceProvider.overrideWithValue(fake),
        currentUserIdProvider.overrideWithValue('me'),
      ],
    );
    addTearDown(container.dispose);

    expect(await container.read(todayCountProvider.future), 7);
  });

  test(
    'unreadIntrosCountProvider counts only delivered receivedIntros',
    () async {
      final fake = _FakeIntrosService();
      when(
        () => fake.listReceivedIntros(viewerId: any(named: 'viewerId')),
      ).thenAnswer((_) async => <Intro>[
            buildIntro(id: 'a', state: IntroState.delivered),
            buildIntro(id: 'b', state: IntroState.accepted),
            buildIntro(id: 'c', state: IntroState.connected),
            buildIntro(id: 'd', state: IntroState.declined),
            buildIntro(id: 'e', state: IntroState.expired),
          ],);

      final container = ProviderContainer(
        overrides: <Override>[
          introsServiceProvider.overrideWithValue(fake),
          currentUserIdProvider.overrideWithValue('me'),
        ],
      );
      addTearDown(container.dispose);

      final unread = await container.read(unreadIntrosCountProvider.future);
      expect(unread, equals(1));
    },
  );
}
