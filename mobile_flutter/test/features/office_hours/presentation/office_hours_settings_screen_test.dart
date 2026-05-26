import 'package:connect_mobile/features/office_hours/data/office_hours_service.dart';
import 'package:connect_mobile/features/office_hours/domain/office_hours_settings.dart';
import 'package:connect_mobile/features/office_hours/domain/office_hours_window.dart';
import 'package:connect_mobile/features/office_hours/presentation/office_hours_settings_screen.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/pump.dart';

class _MockSvc extends Mock implements OfficeHoursService {}

void main() {
  late _MockSvc svc;

  setUp(() {
    svc = _MockSvc();
    registerFallbackValue(<OfficeHoursWindow>[]);
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    final tree = await wrapWithTheme(
      child: const OfficeHoursSettingsScreen(),
      overrides: <Override>[
        officeHoursServiceProvider.overrideWithValue(svc),
      ],
    );
    await pumpWithI18n(tester, tree);
  }

  testWidgets('toggling enable calls setOfficeHours with enabled=true',
      (tester) async {
    when(svc.myOfficeHoursSettings).thenAnswer(
      (_) async => OfficeHoursSettings.defaults(userId: 'me'),
    );
    when(
      () => svc.setOfficeHours(
        enabled: any(named: 'enabled'),
        windows: any(named: 'windows'),
        slotDurationMinutes: any(named: 'slotDurationMinutes'),
        maxBookingsPerWeek: any(named: 'maxBookingsPerWeek'),
        bufferMinutes: any(named: 'bufferMinutes'),
        meetingLinkTemplate: any(named: 'meetingLinkTemplate'),
        notesTemplate: any(named: 'notesTemplate'),
      ),
    ).thenAnswer(
      (_) async =>
          OfficeHoursSettings.defaults(userId: 'me').copyWith(enabled: true),
    );

    await pumpScreen(tester);
    await tester.tap(find.byKey(const ValueKey<String>('oh-enable-switch')));
    await tester.pumpAndSettle();

    verify(
      () => svc.setOfficeHours(
        enabled: true,
        windows: any(named: 'windows'),
        slotDurationMinutes: any(named: 'slotDurationMinutes'),
        maxBookingsPerWeek: any(named: 'maxBookingsPerWeek'),
        bufferMinutes: any(named: 'bufferMinutes'),
        meetingLinkTemplate: any(named: 'meetingLinkTemplate'),
        notesTemplate: any(named: 'notesTemplate'),
      ),
    ).called(1);
  });

  testWidgets('changing slot duration saves slot_duration_minutes',
      (tester) async {
    when(svc.myOfficeHoursSettings).thenAnswer(
      (_) async => OfficeHoursSettings.defaults(userId: 'me'),
    );
    when(
      () => svc.setOfficeHours(
        enabled: any(named: 'enabled'),
        windows: any(named: 'windows'),
        slotDurationMinutes: any(named: 'slotDurationMinutes'),
        maxBookingsPerWeek: any(named: 'maxBookingsPerWeek'),
        bufferMinutes: any(named: 'bufferMinutes'),
        meetingLinkTemplate: any(named: 'meetingLinkTemplate'),
        notesTemplate: any(named: 'notesTemplate'),
      ),
    ).thenAnswer(
      (_) async => OfficeHoursSettings.defaults(userId: 'me')
          .copyWith(slotDurationMinutes: 30),
    );
    await pumpScreen(tester);
    // Tap the "30m" segment.
    await tester.tap(find.text('30m'));
    await tester.pumpAndSettle();
    verify(
      () => svc.setOfficeHours(
        enabled: any(named: 'enabled'),
        windows: any(named: 'windows'),
        slotDurationMinutes: 30,
        maxBookingsPerWeek: any(named: 'maxBookingsPerWeek'),
        bufferMinutes: any(named: 'bufferMinutes'),
        meetingLinkTemplate: any(named: 'meetingLinkTemplate'),
        notesTemplate: any(named: 'notesTemplate'),
      ),
    ).called(1);
  });
}
