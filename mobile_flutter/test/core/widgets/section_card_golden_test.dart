import 'package:connect_mobile/core/theme/app_theme.dart';
import 'package:connect_mobile/core/widgets/section_card.dart';
import 'package:flutter/material.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

void main() {
  testGoldens('SectionCard layouts', (tester) async {
    final builder = GoldenBuilder.column(wrap: _wrap)
      ..addScenario(
        'with title',
        const SectionCard(
          title: 'About',
          child: Text('Builds connective tissue between operators.'),
        ),
      )
      ..addScenario(
        'no title',
        const SectionCard(child: Text('Bare panel without an eyebrow.')),
      )
      ..addScenario(
        'multi-line body',
        const SectionCard(
          title: 'Highlights',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('• First highlight'),
              SizedBox(height: 4),
              Text('• Second highlight'),
              SizedBox(height: 4),
              Text('• Third highlight'),
            ],
          ),
        ),
      );
    await tester.pumpWidgetBuilder(
      builder.build(),
      wrapper: materialAppWrapper(theme: buildAppTheme(Brightness.light)),
      surfaceSize: const Size(360, 700),
    );
    await screenMatchesGolden(tester, 'section_card_layouts');
  });
}

Widget _wrap(Widget child) =>
    Padding(padding: const EdgeInsets.all(12), child: child);
