@Tags(<String>['integration'])
library;

import 'package:connect_mobile/core/i18n/locale_loader.dart';
import 'package:connect_mobile/core/i18n/locale_notifier.dart';
import 'package:connect_mobile/core/theme/app_theme.dart';
import 'package:connect_mobile/features/office_hours/data/office_hours_service.dart';
import 'package:connect_mobile/features/office_hours/domain/my_booking.dart';
import 'package:connect_mobile/features/office_hours/domain/office_hours_settings.dart';
import 'package:connect_mobile/features/office_hours/domain/office_hours_slot.dart';
import 'package:connect_mobile/features/office_hours/domain/office_hours_window.dart';
import 'package:connect_mobile/features/office_hours/presentation/my_bookings_screen.dart';
import 'package:connect_mobile/features/office_hours/presentation/office_hours_section_on_profile.dart';
import 'package:connect_mobile/features/office_hours/presentation/office_hours_settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mocktail/mocktail.dart';

/// Lightweight Phase 9 smoke test.
///
/// Mirrors the meetings smoke: boots each Office Hours screen against an
/// in-memory fake of [OfficeHoursService] and asserts the tree renders
/// without throwing. A fuller end-to-end host→booker round-trip requires
/// two authenticated Supabase sessions plus a fresh `set_office_hours +
/// materialize_office_hours_slots` cycle — that lives in the CI workflow
/// where local Supabase + supabase db reset fixtures are available, and
/// is out of scope for this smoke.
///
/// Tagged `integration` so the default `flutter test` run skips it; CI
/// invokes `flutter test --tags integration` on a connected device.
class _FakeSvc extends Mock implements OfficeHoursService {}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() => registerFallbackValue(<OfficeHoursWindow>[]));

  testWidgets('OfficeHoursSettingsScreen boots cleanly', (tester) async {
    final loader = LocaleLoader();
    await loader.load('en');
    final svc = _FakeSvc();
    when(svc.myOfficeHoursSettings).thenAnswer(
      (_) async => OfficeHoursSettings.defaults(userId: 'me'),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localeLoaderProvider.overrideWithValue(loader),
          officeHoursServiceProvider.overrideWithValue(svc),
        ],
        child: MaterialApp(
          theme: buildAppTheme(Brightness.light),
          home: const OfficeHoursSettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.byType(OfficeHoursSettingsScreen), findsOneWidget);
  });

  testWidgets('OfficeHoursSectionOnProfile boots with two slots',
      (tester) async {
    final loader = LocaleLoader();
    await loader.load('en');
    final svc = _FakeSvc();
    when(() => svc.listUpcomingSlots('h1')).thenAnswer(
      (_) async => <OfficeHoursSlot>[
        OfficeHoursSlot(
          id: 's1',
          hostId: 'h1',
          startsAt: DateTime.utc(2030, 6, 1, 15, 0),
          endsAt: DateTime.utc(2030, 6, 1, 15, 30),
        ),
        OfficeHoursSlot(
          id: 's2',
          hostId: 'h1',
          startsAt: DateTime.utc(2030, 6, 2, 15, 0),
          endsAt: DateTime.utc(2030, 6, 2, 15, 30),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localeLoaderProvider.overrideWithValue(loader),
          officeHoursServiceProvider.overrideWithValue(svc),
        ],
        child: MaterialApp(
          theme: buildAppTheme(Brightness.light),
          home: const Scaffold(
            body: SingleChildScrollView(
              child: OfficeHoursSectionOnProfile(hostId: 'h1'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.byType(OfficeHoursSectionOnProfile), findsOneWidget);
  });

  testWidgets('MyBookingsScreen boots cleanly with one booking',
      (tester) async {
    final loader = LocaleLoader();
    await loader.load('en');
    final svc = _FakeSvc();
    when(svc.myBookings).thenAnswer(
      (_) async => <MyBooking>[
        MyBooking(
          slotId: 's1',
          hostId: 'h1',
          hostHandle: 'rida',
          hostName: 'Rida G',
          startsAt: DateTime.utc(2030, 6, 1, 15, 0),
          endsAt: DateTime.utc(2030, 6, 1, 15, 30),
          topic: 'A topic',
          meetingProposalId: 'mp1',
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localeLoaderProvider.overrideWithValue(loader),
          officeHoursServiceProvider.overrideWithValue(svc),
        ],
        child: MaterialApp(
          theme: buildAppTheme(Brightness.light),
          home: const MyBookingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.byType(MyBookingsScreen), findsOneWidget);
  });
}
