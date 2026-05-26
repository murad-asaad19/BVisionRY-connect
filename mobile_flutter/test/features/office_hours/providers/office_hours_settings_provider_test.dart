import 'package:connect_mobile/features/office_hours/data/office_hours_service.dart';
import 'package:connect_mobile/features/office_hours/domain/office_hours_settings.dart';
import 'package:connect_mobile/features/office_hours/domain/office_hours_window.dart';
import 'package:connect_mobile/features/office_hours/providers/office_hours_settings_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSvc extends Mock implements OfficeHoursService {}

void main() {
  late _MockSvc svc;

  setUp(() {
    svc = _MockSvc();
    registerFallbackValue(<OfficeHoursWindow>[]);
  });

  test('initially reads from service', () async {
    when(svc.myOfficeHoursSettings).thenAnswer(
      (_) async => OfficeHoursSettings.defaults(userId: 'me'),
    );
    final container = ProviderContainer(
      overrides: <Override>[
        officeHoursServiceProvider.overrideWithValue(svc),
      ],
    );
    addTearDown(container.dispose);
    final s = await container.read(officeHoursSettingsProvider.future);
    expect(s.enabled, isFalse);
    verify(svc.myOfficeHoursSettings).called(1);
  });

  test('save() forwards args and refreshes provider', () async {
    final initial = OfficeHoursSettings.defaults(userId: 'me');
    final updated = initial.copyWith(enabled: true);
    when(svc.myOfficeHoursSettings).thenAnswer((_) async => initial);
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
    ).thenAnswer((_) async => updated);

    final container = ProviderContainer(
      overrides: <Override>[
        officeHoursServiceProvider.overrideWithValue(svc),
      ],
    );
    addTearDown(container.dispose);
    await container.read(officeHoursSettingsProvider.future);

    await container
        .read(officeHoursSettingsProvider.notifier)
        .save(updated);
    final after = container.read(officeHoursSettingsProvider).requireValue;
    expect(after.enabled, isTrue);
  });
}
