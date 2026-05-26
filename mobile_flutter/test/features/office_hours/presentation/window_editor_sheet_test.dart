import 'package:connect_mobile/features/office_hours/domain/office_hours_window.dart';
import 'package:connect_mobile/features/office_hours/presentation/window_editor_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump.dart';

void main() {
  testWidgets(
    'save disabled when end <= start; enabled when valid',
    (tester) async {
      OfficeHoursWindow? saved;
      final tree = await wrapWithTheme(
        child: Material(
          child: WindowEditorSheet(
            initial: const OfficeHoursWindow(
              weekday: 1,
              startMinute: 540,
              endMinute: 540,
              timezone: 'UTC',
            ),
            timezones: const <String>['UTC', 'Europe/London'],
            deviceTimezone: 'UTC',
            onSave: (w) => saved = w,
          ),
        ),
      );
      await pumpWithI18n(tester, tree);

      // While end <= start, the Save button should refuse taps. We tap and
      // verify nothing happened (`saved` stays null).
      await tester.tap(find.byKey(const ValueKey<String>('window-save')));
      await tester.pump();
      expect(saved, isNull);

      // Drive end via the hidden test seam.
      await tester.enterText(
        find.byKey(const ValueKey<String>('end-time-raw')),
        '10:00',
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey<String>('window-save')));
      await tester.pump();
      expect(saved, isNotNull);
      expect(saved!.startMinute, 540);
      expect(saved!.endMinute, 600);
    },
  );
}
