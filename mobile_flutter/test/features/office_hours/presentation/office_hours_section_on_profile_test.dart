import 'package:connect_mobile/core/errors/app_exception.dart';
import 'package:connect_mobile/features/office_hours/data/office_hours_service.dart';
import 'package:connect_mobile/features/office_hours/domain/office_hours_slot.dart';
import 'package:connect_mobile/features/office_hours/presentation/office_hours_section_on_profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/pump.dart';

class _MockSvc extends Mock implements OfficeHoursService {}

void main() {
  late _MockSvc svc;
  setUp(() => svc = _MockSvc());

  testWidgets('empty slot list shows EmptyState', (tester) async {
    when(() => svc.listUpcomingSlots('h1')).thenAnswer(
      (_) async => <OfficeHoursSlot>[],
    );
    final tree = await wrapWithTheme(
      child: const Scaffold(
        body: SingleChildScrollView(
          child: OfficeHoursSectionOnProfile(hostId: 'h1'),
        ),
      ),
      overrides: <Override>[
        officeHoursServiceProvider.overrideWithValue(svc),
      ],
    );
    await pumpWithI18n(tester, tree);
    expect(find.textContaining('No upcoming slots'), findsOneWidget);
  });

  testWidgets('renders SlotCards for the host', (tester) async {
    when(() => svc.listUpcomingSlots('h1')).thenAnswer(
      (_) async => <OfficeHoursSlot>[
        OfficeHoursSlot(
          id: 's1',
          hostId: 'h1',
          startsAt: DateTime.utc(2030, 6, 1, 15, 0),
          endsAt: DateTime.utc(2030, 6, 1, 15, 30),
        ),
      ],
    );
    final tree = await wrapWithTheme(
      child: const Scaffold(
        body: SingleChildScrollView(
          child: OfficeHoursSectionOnProfile(hostId: 'h1'),
        ),
      ),
      overrides: <Override>[
        officeHoursServiceProvider.overrideWithValue(svc),
      ],
    );
    await pumpWithI18n(tester, tree);
    expect(find.byKey(const ValueKey<String>('slot-book')), findsOneWidget);
  });

  testWidgets('book SlotUnavailable shows error toast', (tester) async {
    when(() => svc.listUpcomingSlots('h1')).thenAnswer(
      (_) async => <OfficeHoursSlot>[
        OfficeHoursSlot(
          id: 's1',
          hostId: 'h1',
          startsAt: DateTime.utc(2030, 6, 1, 15, 0),
          endsAt: DateTime.utc(2030, 6, 1, 15, 30),
        ),
      ],
    );
    when(
      () => svc.bookSlot(slotId: 's1', topic: any(named: 'topic')),
    ).thenThrow(SlotUnavailableException());

    final tree = await wrapWithTheme(
      child: const Scaffold(
        body: SingleChildScrollView(
          child: OfficeHoursSectionOnProfile(hostId: 'h1'),
        ),
      ),
      overrides: <Override>[
        officeHoursServiceProvider.overrideWithValue(svc),
      ],
    );
    await pumpWithI18n(tester, tree);
    await tester.enterText(find.byType(TextField), 'My valid topic');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey<String>('slot-book')));
    await tester.pumpAndSettle();
    verify(() => svc.bookSlot(slotId: 's1', topic: 'My valid topic')).called(1);
  });
}
