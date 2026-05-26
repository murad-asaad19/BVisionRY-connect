import 'package:connect_mobile/features/office_hours/domain/my_booking.dart';
import 'package:connect_mobile/features/office_hours/presentation/widgets/booking_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/pump.dart';

void main() {
  testWidgets(
    'renders host name and topic; fires onCancel and onTap',
    (tester) async {
      var cancelled = false;
      var tapped = false;
      final tree = await wrapWithTheme(
        child: Scaffold(
          body: BookingCard(
            booking: MyBooking(
              slotId: 's1',
              hostId: 'h1',
              hostHandle: 'rida',
              hostName: 'Rida G',
              startsAt: DateTime.utc(2026, 6, 1, 15, 0),
              endsAt: DateTime.utc(2026, 6, 1, 15, 30),
              topic: 'Career advice',
              meetingProposalId: 'mp1',
            ),
            onCancel: () => cancelled = true,
            onTap: () => tapped = true,
          ),
        ),
      );
      await pumpWithI18n(tester, tree);
      expect(find.text('Rida G'), findsOneWidget);
      expect(find.text('Career advice'), findsOneWidget);
      // Tap on the avatar+date row triggers the card's onTap (the AppCard
      // InkWell wraps the entire card body).
      await tester.tap(find.text('Rida G'));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey<String>('booking-cancel')));
      await tester.pump();
      expect(tapped, isTrue);
      expect(cancelled, isTrue);
    },
  );
}
