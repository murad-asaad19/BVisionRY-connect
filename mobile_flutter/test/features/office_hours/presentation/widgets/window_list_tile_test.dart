import 'package:connect_mobile/features/office_hours/domain/office_hours_window.dart';
import 'package:connect_mobile/features/office_hours/presentation/widgets/window_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/pump.dart';

void main() {
  testWidgets('renders weekday + HH:MM range + tz', (tester) async {
    final tree = await wrapWithTheme(
      child: Scaffold(
        body: WindowListTile(
          window: const OfficeHoursWindow(
            weekday: 1,
            startMinute: 540,
            endMinute: 720,
            timezone: 'UTC',
          ),
          onEdit: () {},
          onDelete: () {},
        ),
      ),
    );
    await pumpWithI18n(tester, tree);
    expect(find.text('Monday'), findsOneWidget);
    expect(find.textContaining('09:00'), findsOneWidget);
    expect(find.textContaining('12:00'), findsOneWidget);
    expect(find.textContaining('UTC'), findsOneWidget);
  });

  testWidgets('fires onEdit / onDelete', (tester) async {
    var edited = false;
    var deleted = false;
    final tree = await wrapWithTheme(
      child: Scaffold(
        body: WindowListTile(
          window: const OfficeHoursWindow(
            weekday: 2,
            startMinute: 600,
            endMinute: 660,
            timezone: 'UTC',
          ),
          onEdit: () => edited = true,
          onDelete: () => deleted = true,
        ),
      ),
    );
    await pumpWithI18n(tester, tree);
    await tester.tap(find.byKey(const ValueKey<String>('window-edit')));
    await tester.tap(find.byKey(const ValueKey<String>('window-delete')));
    expect(edited, isTrue);
    expect(deleted, isTrue);
  });
}
