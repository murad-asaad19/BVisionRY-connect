import 'package:connect_mobile/features/office_hours/domain/office_hours_slot.dart';
import 'package:connect_mobile/features/office_hours/presentation/widgets/slot_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/pump.dart';

void main() {
  testWidgets('book button disabled when topic < 5 chars', (tester) async {
    bool fired = false;
    final tree = await wrapWithTheme(
      child: Scaffold(
        body: SlotCard(
          slot: OfficeHoursSlot(
            id: 's1',
            hostId: 'h1',
            startsAt: DateTime.utc(2026, 6, 1, 15, 0),
            endsAt: DateTime.utc(2026, 6, 1, 15, 30),
          ),
          onBook: (_, __) async {
            fired = true;
          },
        ),
      ),
    );
    await pumpWithI18n(tester, tree);
    await tester.tap(find.byKey(const ValueKey<String>('slot-book')));
    await tester.pump();
    expect(fired, isFalse);
  });

  testWidgets(
    'book fires with slot.id and topic when topic >= 5 chars',
    (tester) async {
      String? capturedSlot;
      String? capturedTopic;
      final tree = await wrapWithTheme(
        child: Scaffold(
          body: SlotCard(
            slot: OfficeHoursSlot(
              id: 's1',
              hostId: 'h1',
              startsAt: DateTime.utc(2026, 6, 1, 15, 0),
              endsAt: DateTime.utc(2026, 6, 1, 15, 30),
            ),
            onBook: (slotId, topic) async {
              capturedSlot = slotId;
              capturedTopic = topic;
            },
          ),
        ),
      );
      await pumpWithI18n(tester, tree);
      await tester.enterText(find.byType(TextField), 'My valid topic');
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey<String>('slot-book')));
      await tester.pump();
      expect(capturedSlot, 's1');
      expect(capturedTopic, 'My valid topic');
    },
  );
}
