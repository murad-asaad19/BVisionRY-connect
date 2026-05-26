import 'package:connect_mobile/core/i18n/locale_loader.dart';
import 'package:connect_mobile/core/i18n/locale_notifier.dart';
import 'package:connect_mobile/core/theme/app_theme.dart';
import 'package:connect_mobile/features/office_hours/domain/office_hours_window.dart';
import 'package:connect_mobile/features/office_hours/presentation/window_editor_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

import '../../../helpers/pump.dart';

void main() {
  testGoldens('WindowEditorSheet new + edit', (tester) async {
    final loader = await primedLocaleLoader();
    final builder = GoldenBuilder.column()
      ..addScenario(
        'new',
        ProviderScope(
          overrides: <Override>[
            localeLoaderProvider.overrideWithValue(loader),
          ],
          child: Material(
            child: WindowEditorSheet(
              timezones: const <String>['UTC', 'Europe/London'],
              deviceTimezone: 'UTC',
              onSave: (_) {},
            ),
          ),
        ),
      )
      ..addScenario(
        'edit',
        ProviderScope(
          overrides: <Override>[
            localeLoaderProvider.overrideWithValue(loader),
          ],
          child: Material(
            child: WindowEditorSheet(
              initial: const OfficeHoursWindow(
                weekday: 2,
                startMinute: 600,
                endMinute: 720,
                timezone: 'UTC',
              ),
              timezones: const <String>['UTC'],
              deviceTimezone: 'UTC',
              onSave: (_) {},
            ),
          ),
        ),
      );
    await tester.pumpWidgetBuilder(
      builder.build(),
      wrapper: materialAppWrapper(theme: buildAppTheme(Brightness.light)),
      surfaceSize: const Size(400, 1100),
    );
    await screenMatchesGolden(tester, 'window_editor_sheet');
  });
}
