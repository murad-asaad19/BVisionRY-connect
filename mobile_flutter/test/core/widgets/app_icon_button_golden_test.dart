import 'package:connect_mobile/core/theme/app_theme.dart';
import 'package:connect_mobile/core/widgets/app_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

void main() {
  testGoldens('AppIconButton matrix', (tester) async {
    final builder = GoldenBuilder.column(wrap: _wrap)
      ..addScenario(
        'plain-md',
        AppIconButton(icon: Icons.search, label: 'Search', onPressed: () {}),
      )
      ..addScenario(
        'subtle-md',
        AppIconButton(
          icon: Icons.add,
          label: 'Add',
          variant: AppIconButtonVariant.subtle,
          onPressed: () {},
        ),
      )
      ..addScenario(
        'navy-md',
        AppIconButton(
          icon: Icons.message,
          label: 'Message',
          variant: AppIconButtonVariant.navy,
          onPressed: () {},
        ),
      )
      ..addScenario(
        'plain-sm',
        AppIconButton(
          icon: Icons.close,
          label: 'Close',
          size: AppIconButtonSize.sm,
          onPressed: () {},
        ),
      )
      ..addScenario(
        'plain-lg',
        AppIconButton(
          icon: Icons.menu,
          label: 'Menu',
          size: AppIconButtonSize.lg,
          onPressed: () {},
        ),
      )
      ..addScenario(
        'disabled',
        const AppIconButton(
          icon: Icons.settings,
          label: 'Settings',
          disabled: true,
        ),
      );
    await tester.pumpWidgetBuilder(
      builder.build(),
      wrapper: materialAppWrapper(theme: buildAppTheme(Brightness.light)),
      surfaceSize: const Size(360, 700),
    );
    await screenMatchesGolden(tester, 'app_icon_button_matrix');
  });
}

Widget _wrap(Widget child) => Align(
      alignment: Alignment.centerLeft,
      child: Padding(padding: const EdgeInsets.all(8), child: child),
    );
