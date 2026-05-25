import 'package:connect_mobile/core/theme/app_theme.dart';
import 'package:connect_mobile/core/widgets/settings_row.dart';
import 'package:flutter/material.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

void main() {
  testGoldens('SettingsRow variants', (tester) async {
    final builder = GoldenBuilder.column(wrap: _wrap)
      ..addScenario(
        'label + chevron',
        SettingsRow(label: 'Profile', onTap: () {}),
      )
      ..addScenario(
        'icon + label + description + chevron',
        SettingsRow(
          icon: Icons.notifications,
          label: 'Notifications',
          description: 'Push, email, in-app',
          onTap: () {},
        ),
      )
      ..addScenario(
        'with trailing toggle',
        SettingsRow(
          icon: Icons.dark_mode,
          label: 'Dark mode',
          trailing: Switch(value: true, onChanged: (_) {}),
        ),
      )
      ..addScenario(
        'destructive',
        SettingsRow(
          icon: Icons.delete,
          label: 'Delete account',
          destructive: true,
          onTap: () {},
        ),
      );
    await tester.pumpWidgetBuilder(
      builder.build(),
      wrapper: materialAppWrapper(theme: buildAppTheme(Brightness.light)),
      surfaceSize: const Size(360, 640),
    );
    await screenMatchesGolden(tester, 'settings_row_variants');
  });
}

Widget _wrap(Widget child) =>
    Padding(padding: const EdgeInsets.all(8), child: child);
