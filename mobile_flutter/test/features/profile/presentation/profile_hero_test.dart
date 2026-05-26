import 'package:connect_mobile/features/profile/presentation/profile_hero.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump.dart';

void main() {
  group('ProfileHero', () {
    testWidgets('renders name, headline, location, and role pills', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        await wrapWithTheme(
          child: const ProfileHero(
            data: ProfileHeroData(
              name: 'Omar Daher',
              headline: 'Senior backend, ex-Stripe',
              city: 'London',
              country: 'UK',
              roles: <String>['builder', 'advisor'],
              primaryRole: 'builder',
              photoUrl: null,
              verified: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Omar Daher'), findsOneWidget);
      expect(find.text('Senior backend, ex-Stripe'), findsOneWidget);
      expect(find.textContaining('London'), findsOneWidget);
      // "Builder" appears in both the verified-badge pill (next to the
      // name) and the role pills row — both are correct per gallery D1.
      expect(find.text('Builder'), findsNWidgets(2));
      expect(find.text('Advisor'), findsOneWidget);
      // Verified badge pill carries a check icon next to the role label.
      expect(
        find.byKey(const ValueKey<String>('profile-hero-verified-badge')),
        findsOneWidget,
      );
    });

    testWidgets('renders without headline / location / roles', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        await wrapWithTheme(
          child: const ProfileHero(
            data: ProfileHeroData(
              name: 'Solo',
              headline: null,
              city: null,
              country: null,
              roles: <String>[],
              primaryRole: null,
              photoUrl: null,
              verified: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Solo'), findsOneWidget);
    });
  });
}
