import 'package:connect_mobile/features/intros/domain/intro_enums.dart';
import 'package:connect_mobile/features/intros/presentation/intro_list_row.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/intros_fixtures.dart';
import '../../../helpers/pump.dart';

void main() {
  testWidgets('renders peer name + delivered badge', (tester) async {
    final widget = await wrapWithTheme(
      child: IntroListRow(
        intro: buildIntro(),
        peerName: 'Alice',
        peerHandle: 'alice',
        peerPhotoUrl: null,
      ),
    );
    await pumpWithI18n(tester, widget);
    expect(find.text('Alice'), findsOneWidget);
    expect(find.byKey(const ValueKey('intro-badge-delivered')), findsOneWidget);
  });

  testWidgets('expired row shows expired badge', (tester) async {
    final widget = await wrapWithTheme(
      child: IntroListRow(
        intro: buildIntro(state: IntroState.expired),
        peerName: 'Bob',
        peerHandle: 'bob',
        peerPhotoUrl: null,
      ),
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
        peerName: 'Alice',
        peerHandle: 'alice',
        peerPhotoUrl: null,
      ),
    );
    await pumpWithI18n(tester, widget);
    expect(find.textContaining('…'), findsOneWidget);
  });
}
