import 'package:connect_mobile/features/auth/providers/profile_provider.dart';
import 'package:connect_mobile/features/office_hours/data/office_hours_service.dart';
import 'package:connect_mobile/features/office_hours/domain/my_booking.dart';
import 'package:connect_mobile/features/office_hours/domain/office_hours_settings.dart';
import 'package:connect_mobile/features/office_hours/domain/office_hours_slot.dart';
import 'package:connect_mobile/features/office_hours/domain/office_hours_window.dart';
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

/// Inert office-hours service so the embedded section settles to an empty
/// state without hitting Supabase during widget tests.
class _FakeOfficeHoursService implements OfficeHoursService {
  @override
  Future<List<OfficeHoursSlot>> listUpcomingSlots(String hostId) async =>
      const <OfficeHoursSlot>[];

  @override
  Future<OfficeHoursSettings> myOfficeHoursSettings() async =>
      OfficeHoursSettings.defaults(userId: 'me');

  @override
  Future<List<MyBooking>> myBookings() async => const <MyBooking>[];

  @override
  Future<String> bookSlot({
    required String slotId,
    required String topic,
  }) async =>
      'mp';

  @override
  Future<void> cancelBooking(String slotId) async {}

  @override
  Future<OfficeHoursSettings> setOfficeHours({
    required bool enabled,
    required List<OfficeHoursWindow> windows,
    required int slotDurationMinutes,
    required int maxBookingsPerWeek,
    required int bufferMinutes,
    String? meetingLinkTemplate,
    String? notesTemplate,
  }) async =>
      OfficeHoursSettings.defaults(userId: 'me');

  @override
  Future<String> conversationIdForProposal(String proposalId) async => 'c';
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
            officeHoursServiceProvider
                .overrideWithValue(_FakeOfficeHoursService()),
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
      tester.view.physicalSize = const Size(420, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(
        await wrapWithTheme(
          child: const ProfileScreen(),
          overrides: <Override>[
            profileProvider.overrideWith(
              (Ref<AsyncValue<Profile?>> _) async => omarProfile(),
            ),
            profileSignalsServiceProvider
                .overrideWithValue(_FakeSignalsService()),
            officeHoursServiceProvider
                .overrideWithValue(_FakeOfficeHoursService()),
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
            officeHoursServiceProvider
                .overrideWithValue(_FakeOfficeHoursService()),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Profile not found'), findsOneWidget);
    });
  });
}
