import 'package:connect_mobile/core/i18n/locale_loader.dart';
import 'package:connect_mobile/core/i18n/locale_notifier.dart';
import 'package:connect_mobile/core/theme/app_theme.dart';
import 'package:connect_mobile/features/office_hours/domain/my_booking.dart';
import 'package:connect_mobile/features/office_hours/presentation/widgets/booking_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

import '../../../../helpers/pump.dart';

void main() {
  testGoldens('BookingCard default', (tester) async {
    final loader = await primedLocaleLoader();
    await tester.pumpWidgetBuilder(
      ProviderScope(
        overrides: <Override>[
          localeLoaderProvider.overrideWithValue(loader),
        ],
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: BookingCard(
            booking: MyBooking(
              slotId: 's1',
              hostId: 'h1',
              hostHandle: 'rida',
              hostName: 'Rida Garcia',
              startsAt: DateTime.utc(2030, 6, 1, 15, 0),
              endsAt: DateTime.utc(2030, 6, 1, 15, 30),
              topic: 'Career advice for an early-stage builder',
              meetingProposalId: 'mp1',
            ),
            onCancel: () {},
            onTap: () {},
          ),
        ),
      ),
      wrapper: materialAppWrapper(theme: buildAppTheme(Brightness.light)),
      surfaceSize: const Size(390, 200),
    );
    await screenMatchesGolden(tester, 'booking_card_default');
  });
}
