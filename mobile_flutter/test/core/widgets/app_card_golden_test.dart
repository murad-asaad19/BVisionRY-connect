import 'package:connect_mobile/core/theme/app_theme.dart';
import 'package:connect_mobile/core/widgets/app_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

void main() {
  testGoldens('AppCard variants', (tester) async {
    final builder = GoldenBuilder.column(wrap: _wrapPad)
      ..addScenario(
        'default',
        const AppCard(
          child: Text('Plain content sits inside a 14-radius white card.'),
        ),
      )
      ..addScenario(
        'tappable',
        AppCard(
          onTap: () {},
          child: const Text('I am tappable — InkWell highlight on press.'),
        ),
      )
      ..addScenario(
        'featured',
        const AppCard(
          variant: AppCardVariant.featured,
          child: Text('Featured cards use a goldPale → white gradient.'),
        ),
      );
    await tester.pumpWidgetBuilder(
      builder.build(),
      wrapper: materialAppWrapper(theme: buildAppTheme(Brightness.light)),
      surfaceSize: const Size(360, 600),
    );
    await screenMatchesGolden(tester, 'app_card_variants');
  });
}

Widget _wrapPad(Widget child) =>
    Padding(padding: const EdgeInsets.all(8), child: child);
