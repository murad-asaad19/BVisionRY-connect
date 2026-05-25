import 'package:connect_mobile/core/theme/app_theme.dart';
import 'package:connect_mobile/core/widgets/app_banner.dart';
import 'package:connect_mobile/core/widgets/variants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

void main() {
  testGoldens('AppBanner intents', (tester) async {
    final builder = GoldenBuilder.column(wrap: _wrapPad)
      ..addScenario(
        'info',
        const AppBanner(
          intent: AppIntent.info,
          title: 'Heads up',
          child: Text('You have 3 pending intros.'),
        ),
      )
      ..addScenario(
        'success',
        const AppBanner(
          intent: AppIntent.success,
          title: 'Saved',
          child: Text('Your profile is up to date.'),
        ),
      )
      ..addScenario(
        'warning',
        const AppBanner(
          intent: AppIntent.warning,
          child: Text('Verify your email to keep using BVisionry.'),
        ),
      )
      ..addScenario(
        'danger',
        const AppBanner(
          intent: AppIntent.danger,
          title: 'Could not save',
          child: Text('Please try again.'),
        ),
      )
      ..addScenario(
        'with-close',
        AppBanner(
          intent: AppIntent.neutral,
          title: 'Tip',
          onClose: () {},
          child: const Text('You can dismiss this banner.'),
        ),
      );
    await tester.pumpWidgetBuilder(
      builder.build(),
      wrapper: materialAppWrapper(theme: buildAppTheme(Brightness.light)),
      surfaceSize: const Size(360, 900),
    );
    await screenMatchesGolden(tester, 'app_banner_intents');
  });
}

Widget _wrapPad(Widget child) =>
    Padding(padding: const EdgeInsets.all(8), child: child);
