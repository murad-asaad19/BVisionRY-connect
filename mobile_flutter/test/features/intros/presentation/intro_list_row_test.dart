import 'package:connect_mobile/features/intros/domain/intro_enums.dart';
import 'package:connect_mobile/features/intros/presentation/intro_list_row.dart';
import 'package:connect_mobile/features/profile/data/peer_profile_service.dart';
import 'package:connect_mobile/features/profile/domain/profile.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/intros_fixtures.dart';
import '../../../helpers/pump.dart';

class _FakePeerProfileService extends Mock implements PeerProfileService {}

void main() {
  _FakePeerProfileService stub({Profile? profile}) {
    final fake = _FakePeerProfileService();
    when(() => fake.fetchById(any())).thenAnswer((_) async => profile);
    return fake;
  }

  testWidgets('renders resolved peer name + delivered badge', (tester) async {
    final widget = await wrapWithTheme(
      child: IntroListRow(
        intro: buildIntro(),
        viewerIsRecipient: true,
      ),
      overrides: <Override>[
        peerProfileServiceProvider.overrideWithValue(
          stub(
            profile: const Profile(
              id: 'sender-1',
              handle: 'alice',
              name: 'Alice',
            ),
          ),
        ),
      ],
    );
    await pumpWithI18n(tester, widget);
    expect(find.text('Alice'), findsOneWidget);
    expect(find.byKey(const ValueKey('intro-badge-delivered')), findsOneWidget);
  });

  testWidgets('expired row shows expired badge', (tester) async {
    final widget = await wrapWithTheme(
      child: IntroListRow(
        intro: buildIntro(state: IntroState.expired),
        viewerIsRecipient: true,
      ),
      overrides: <Override>[
        peerProfileServiceProvider.overrideWithValue(
          stub(profile: const Profile(id: 'sender-1', name: 'Bob')),
        ),
      ],
    );
    await pumpWithI18n(tester, widget);
    expect(find.byKey(const ValueKey('intro-badge-expired')), findsOneWidget);
  });

  testWidgets('truncates notes longer than 80 chars with an ellipsis', (
    tester,
  ) async {
    final widget = await wrapWithTheme(
      child: IntroListRow(
        intro: buildIntro(note: 'a' * 120),
        viewerIsRecipient: true,
      ),
      overrides: <Override>[
        peerProfileServiceProvider.overrideWithValue(
          stub(profile: const Profile(id: 'sender-1', name: 'Alice')),
        ),
      ],
    );
    await pumpWithI18n(tester, widget);
    expect(find.textContaining('…'), findsOneWidget);
  });

  testWidgets('falls back to user id when profile lookup returns null', (
    tester,
  ) async {
    final widget = await wrapWithTheme(
      child: IntroListRow(
        intro: buildIntro(senderId: 'unknown-user'),
        viewerIsRecipient: true,
      ),
      overrides: <Override>[
        peerProfileServiceProvider.overrideWithValue(stub()),
      ],
    );
    await pumpWithI18n(tester, widget);
    expect(find.text('unknown-user'), findsOneWidget);
  });
}
