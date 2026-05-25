import 'package:connect_mobile/features/auth/providers/profile_provider.dart';
import 'package:connect_mobile/features/profile/data/profile_signals_service.dart';
import 'package:connect_mobile/features/profile/domain/profile.dart';
import 'package:connect_mobile/features/profile/domain/profile_signals.dart';
import 'package:connect_mobile/features/profile/presentation/profile_screen.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump.dart';

class _FakeSignalsService implements ProfileSignalsService {
  @override
  Future<ProfileSignals> fetchSignals(String targetUserId) async =>
      ProfileSignals.empty;
}

Profile omarProfile() => Profile.fromJson(<String, dynamic>{
      'id': 'u-1',
      'handle': 'omar-d',
      'name': 'Omar Daher',
      'headline': 'Senior backend, ex-Stripe',
      'bio': 'Pre-seed founder building B2B fintech for SMEs.',
      'roles': <String>['builder', 'advisor'],
      'primary_role': 'builder',
      'city': 'London',
      'country': 'UK',
      'goal_type': 'hire',
      'goal_text': 'Co-found or join a pre-seed B2B SaaS as fractional CTO.',
      'goal_updated_at': DateTime.now().toUtc().toIso8601String(),
      'photo_url': null,
      'onboarded': true,
      'verified_github_username': 'omar-d',
      'verified_github_id': 1,
      'verified_at': '2026-01-01T09:00:00Z',
      'suspended_at': null,
      'private_mode': false,
      'read_receipts_enabled': false,
      'public_investor_page': false,
      'created_at': '2026-01-01T09:00:00Z',
      'updated_at': '2026-04-01T09:00:00Z',
    });

void main() {
  group('ProfileScreen', () {
    testWidgets('renders hero, goal section, and bio for an onboarded profile',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        await wrapWithTheme(
          child: const ProfileScreen(),
          overrides: <Override>[
            profileProvider.overrideWith(
              (Ref<AsyncValue<Profile?>> _) async => omarProfile(),
            ),
            profileSignalsServiceProvider
                .overrideWithValue(_FakeSignalsService()),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Omar Daher'), findsOneWidget);
      expect(find.textContaining('Co-found or join'), findsOneWidget);
      expect(find.textContaining('Pre-seed founder'), findsOneWidget);
    });

    testWidgets('renders Edit / Share / Sign out actions', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        await wrapWithTheme(
          child: const ProfileScreen(),
          overrides: <Override>[
            profileProvider.overrideWith(
              (Ref<AsyncValue<Profile?>> _) async => omarProfile(),
            ),
            profileSignalsServiceProvider
                .overrideWithValue(_FakeSignalsService()),
          ],
        ),
      );
      await tester.pumpAndSettle();
      // Buttons live near the bottom of a long ListView — assert they exist
      // in the tree without requiring them to be on-screen. `findsOne` against
      // skipOffstage=false matches off-screen-but-rendered children.
      expect(
        find.byKey(const Key('profileScreen.editButton'), skipOffstage: false),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('profileScreen.shareButton'), skipOffstage: false),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const Key('profileScreen.signOutButton'),
          skipOffstage: false,
        ),
        findsOneWidget,
      );
    });

    testWidgets('shows not-found message when profile is null', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        await wrapWithTheme(
          child: const ProfileScreen(),
          overrides: <Override>[
            profileProvider.overrideWith(
              (Ref<AsyncValue<Profile?>> _) async => null,
            ),
            profileSignalsServiceProvider
                .overrideWithValue(_FakeSignalsService()),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Profile not found'), findsOneWidget);
    });
  });
}
