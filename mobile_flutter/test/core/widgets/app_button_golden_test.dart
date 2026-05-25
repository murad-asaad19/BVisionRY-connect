import 'package:connect_mobile/core/theme/app_theme.dart';
import 'package:connect_mobile/core/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

void main() {
  testGoldens('AppButton variants', (tester) async {
    // Note: `loading` is intentionally omitted — its CircularProgressIndicator
    // animates indefinitely and stalls `pumpAndSettle` used by the golden
    // harness. Loading is covered by the widget test instead.
    final builder = GoldenBuilder.column(wrap: _wrapPad)
      ..addScenario(
        'primary',
        AppButton(label: 'Send intro', onPressed: () {}),
      )
      ..addScenario(
        'gold',
        AppButton(
          label: 'Send intro',
          onPressed: () {},
          variant: AppButtonVariant.gold,
        ),
      )
      ..addScenario(
        'outline',
        AppButton(
          label: 'Cancel',
          onPressed: () {},
          variant: AppButtonVariant.outline,
        ),
      )
      ..addScenario(
        'outlineDanger',
        AppButton(
          label: 'Remove',
          onPressed: () {},
          variant: AppButtonVariant.outlineDanger,
        ),
      )
      ..addScenario(
        'danger',
        AppButton(
          label: 'Delete',
          onPressed: () {},
          variant: AppButtonVariant.danger,
        ),
      )
      ..addScenario(
        'apple',
        AppButton(
          label: 'Sign in with Apple',
          onPressed: () {},
          variant: AppButtonVariant.apple,
        ),
      )
      ..addScenario('disabled', const AppButton(label: 'Send', disabled: true))
      ..addScenario(
        'small',
        AppButton(
          label: 'Edit',
          onPressed: () {},
          size: AppButtonSize.small,
          fullWidth: false,
        ),
      );
    await tester.pumpWidgetBuilder(
      builder.build(),
      wrapper: materialAppWrapper(theme: buildAppTheme(Brightness.light)),
      surfaceSize: const Size(360, 900),
    );
    await screenMatchesGolden(tester, 'app_button_variants');
  });
}

Widget _wrapPad(Widget child) =>
    Padding(padding: const EdgeInsets.all(8), child: child);
