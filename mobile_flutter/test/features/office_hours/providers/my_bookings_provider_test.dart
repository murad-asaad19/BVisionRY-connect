import 'package:connect_mobile/features/office_hours/data/office_hours_service.dart';
import 'package:connect_mobile/features/office_hours/domain/my_booking.dart';
import 'package:connect_mobile/features/office_hours/providers/my_bookings_provider.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSvc extends Mock implements OfficeHoursService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('myBookings reads from service', () async {
    final svc = _MockSvc();
    when(svc.myBookings).thenAnswer((_) async => <MyBooking>[]);
    final container = ProviderContainer(
      overrides: <Override>[
        officeHoursServiceProvider.overrideWithValue(svc),
      ],
    );
    addTearDown(container.dispose);
    final result = await container.read(myBookingsProvider.future);
    expect(result, isEmpty);
  });

  test('foreground resume invalidates and re-fetches', () async {
    final svc = _MockSvc();
    when(svc.myBookings).thenAnswer((_) async => <MyBooking>[]);
    final container = ProviderContainer(
      overrides: <Override>[
        officeHoursServiceProvider.overrideWithValue(svc),
      ],
    );
    addTearDown(container.dispose);

    await container.read(myBookingsProvider.future);
    // Simulate a resume — the registered observer should invalidateSelf
    // which causes the provider to re-call myBookings on next read.
    WidgetsBinding.instance.handleAppLifecycleStateChanged(
      AppLifecycleState.resumed,
    );
    await Future<void>.delayed(const Duration(milliseconds: 16));
    await container.read(myBookingsProvider.future);
    verify(svc.myBookings).called(2);
  });
}
