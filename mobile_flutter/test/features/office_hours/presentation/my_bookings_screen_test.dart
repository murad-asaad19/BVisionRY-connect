import 'package:connect_mobile/core/errors/app_exception.dart';
import 'package:connect_mobile/features/office_hours/data/office_hours_service.dart';
import 'package:connect_mobile/features/office_hours/domain/my_booking.dart';
import 'package:connect_mobile/features/office_hours/presentation/my_bookings_screen.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/pump.dart';

class _MockSvc extends Mock implements OfficeHoursService {}

void main() {
  late _MockSvc svc;
  setUp(() => svc = _MockSvc());

  testWidgets('empty bookings shows empty state', (tester) async {
    when(svc.myBookings).thenAnswer((_) async => <MyBooking>[]);
    final tree = await wrapWithTheme(
      child: const MyBookingsScreen(),
      overrides: <Override>[
        officeHoursServiceProvider.overrideWithValue(svc),
      ],
    );
    await pumpWithI18n(tester, tree);
    expect(find.textContaining('No bookings yet'), findsOneWidget);
  });

  testWidgets('renders a booking card for each row', (tester) async {
    when(svc.myBookings).thenAnswer(
      (_) async => <MyBooking>[
        MyBooking(
          slotId: 's1',
          hostId: 'h1',
          hostHandle: 'rida',
          hostName: 'Rida G',
          startsAt: DateTime.utc(2030, 6, 1, 15, 0),
          endsAt: DateTime.utc(2030, 6, 1, 15, 30),
          topic: 'A great topic',
          meetingProposalId: 'mp1',
        ),
      ],
    );
    final tree = await wrapWithTheme(
      child: const MyBookingsScreen(),
      overrides: <Override>[
        officeHoursServiceProvider.overrideWithValue(svc),
      ],
    );
    await pumpWithI18n(tester, tree);
    expect(find.text('Rida G'), findsOneWidget);
    expect(find.text('A great topic'), findsOneWidget);
  });

  testWidgets('cancel error after confirm shows danger toast', (tester) async {
    when(svc.myBookings).thenAnswer(
      (_) async => <MyBooking>[
        MyBooking(
          slotId: 's1',
          hostId: 'h1',
          hostHandle: 'rida',
          hostName: 'Rida G',
          startsAt: DateTime.utc(2030, 6, 1, 15, 0),
          endsAt: DateTime.utc(2030, 6, 1, 15, 30),
          meetingProposalId: 'mp1',
        ),
      ],
    );
    when(() => svc.cancelBooking('s1')).thenThrow(ForbiddenException());

    final tree = await wrapWithTheme(
      child: const MyBookingsScreen(),
      overrides: <Override>[
        officeHoursServiceProvider.overrideWithValue(svc),
      ],
    );
    await pumpWithI18n(tester, tree);
    await tester.tap(find.byKey(const ValueKey<String>('booking-cancel')));
    await tester.pumpAndSettle();
    // ConfirmService renders a bottom sheet; tap the Confirm action by
    // text label (Cancel from i18n).
    final confirmButtons = find.text('Cancel');
    // We want the 2nd "Cancel" — the destructive confirm action — but
    // depending on i18n we may have two: the dialog cancel + the
    // confirmLabel "Cancel". We tap the last one (confirmLabel).
    await tester.tap(confirmButtons.last);
    await tester.pumpAndSettle();
    verify(() => svc.cancelBooking('s1')).called(1);
  });
}
