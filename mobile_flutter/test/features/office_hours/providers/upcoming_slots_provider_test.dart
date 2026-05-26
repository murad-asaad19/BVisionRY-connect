import 'package:connect_mobile/features/office_hours/data/office_hours_service.dart';
import 'package:connect_mobile/features/office_hours/domain/office_hours_slot.dart';
import 'package:connect_mobile/features/office_hours/providers/upcoming_slots_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSvc extends Mock implements OfficeHoursService {}

void main() {
  test('upcomingSlotsProvider returns slots for a host', () async {
    final svc = _MockSvc();
    when(() => svc.listUpcomingSlots('h1')).thenAnswer(
      (_) async => <OfficeHoursSlot>[
        OfficeHoursSlot(
          id: 's1',
          hostId: 'h1',
          startsAt: DateTime.utc(2026, 6, 1, 15, 0),
          endsAt: DateTime.utc(2026, 6, 1, 15, 30),
        ),
      ],
    );
    final container = ProviderContainer(
      overrides: <Override>[
        officeHoursServiceProvider.overrideWithValue(svc),
      ],
    );
    addTearDown(container.dispose);
    final slots = await container.read(upcomingSlotsProvider('h1').future);
    expect(slots, hasLength(1));
    expect(slots.first.id, 's1');
  });
}
