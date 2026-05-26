import 'package:connect_mobile/features/auth/data/profile_repository.dart';
import 'package:connect_mobile/features/auth/providers/auth_service_provider.dart';
import 'package:connect_mobile/features/office_hours/data/office_hours_service.dart';
import 'package:connect_mobile/features/office_hours/domain/my_booking.dart';
import 'package:connect_mobile/features/office_hours/domain/office_hours_settings.dart';
import 'package:connect_mobile/features/office_hours/domain/office_hours_slot.dart';
import 'package:connect_mobile/features/office_hours/domain/office_hours_window.dart';
import 'package:connect_mobile/features/office_hours/presentation/office_hours_section_on_profile.dart';
import 'package:connect_mobile/features/profile/data/public_profile_service.dart';
import 'package:connect_mobile/features/profile/presentation/public_profile_screen.dart';
import 'package:connect_mobile/features/profile/providers/public_profile_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../helpers/fake_supabase.dart';
import '../../../helpers/pump.dart';

class _NoRowRunner implements ProfileQueryRunner {
  @override
  Future<Map<String, dynamic>?> selectById(String id) async => null;
}

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

PublicProfile _omar() => const PublicProfile(
      id: 'u-1',
      handle: 'omar-d',
      name: 'Omar Daher',
      headline: 'Senior backend, ex-Stripe',
      primaryRole: 'builder',
      roles: <String>['builder'],
      city: 'London',
      country: 'United Kingdom',
      // verified_github_username is present in the RPC payload but the screen
      // MUST NOT surface a verified badge per spec §17.2.
      verifiedGithubUsername: 'omar-d',
      photoUrl: null,
      bio: 'Bio text long enough to render.',
    );

Future<Widget> _renderPublicProfile({
  required PublicProfile? data,
  bool authed = false,
}) async {
  final FakeAuthGateway auth = FakeAuthGateway();
  if (authed) {
    auth.pushAuthState(AuthChangeEvent.initialSession, fakeSession(id: 'me'));
  }
  return wrapWithTheme(
    child: const PublicProfileScreen(handle: 'omar-d'),
    overrides: <Override>[
      authGatewayProvider.overrideWithValue(auth),
      profileRepositoryProvider
          .overrideWithValue(ProfileRepository(_NoRowRunner())),
      publicProfileProvider('omar-d').overrideWith(
        (Ref<AsyncValue<PublicProfile?>> _) async => data,
      ),
      officeHoursServiceProvider.overrideWithValue(_FakeOfficeHoursService()),
    ],
  );
}

void main() {
  group('PublicProfileScreen', () {
    testWidgets('renders name, headline, location for a returning handle', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(await _renderPublicProfile(data: _omar()));
      await tester.pumpAndSettle();
      expect(find.text('Omar Daher'), findsOneWidget);
      expect(find.textContaining('Senior backend'), findsOneWidget);
      expect(find.textContaining('London'), findsWidgets);
    });

    testWidgets('NEVER renders the verified badge (spec §17.2)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(await _renderPublicProfile(data: _omar()));
      await tester.pumpAndSettle();
      // The hero is built with `verified: false` here — neither the avatar
      // nor any sibling should render a verification chip.
      expect(find.byIcon(Icons.verified), findsNothing);
    });

    testWidgets('shows sign-in CTA when not authenticated', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(await _renderPublicProfile(data: _omar()));
      await tester.pumpAndSettle();
      final Finder cta = find.byKey(
        const Key('publicProfile.cta'),
        skipOffstage: false,
      );
      expect(cta, findsOneWidget);
      expect(find.textContaining('Sign in to connect'), findsWidgets);
    });

    testWidgets(
      'shows private-profile state when the RPC returns null for a valid handle',
      (WidgetTester tester) async {
        await tester.pumpWidget(await _renderPublicProfile(data: null));
        await tester.pumpAndSettle();
        // `get_public_profile` collapses suspended/private/missing rows into
        // a single null response; when the requested handle is non-empty we
        // treat that as "private" per spec §17.2 (hide-rather-than-leak).
        expect(find.byKey(const Key('publicProfile.private')), findsOneWidget);
      },
    );

    testWidgets(
      'mounts OfficeHoursSectionOnProfile for an authed viewer',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(420, 2400);
        tester.view.devicePixelRatio = 1;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
        await tester.pumpWidget(
          await _renderPublicProfile(data: _omar(), authed: true),
        );
        await tester.pumpAndSettle();
        expect(
          find.byType(OfficeHoursSectionOnProfile),
          findsOneWidget,
        );
      },
    );
  });
}
