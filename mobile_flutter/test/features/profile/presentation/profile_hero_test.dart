import 'package:connect_mobile/features/profile/presentation/profile_hero.dart';
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
      expect(find.text('Builder'), findsOneWidget);
      expect(find.text('Advisor'), findsOneWidget);
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
