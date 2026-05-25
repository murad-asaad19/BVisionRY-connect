import 'package:connect_mobile/core/theme/app_theme.dart';
import 'package:connect_mobile/core/widgets/app_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

void main() {
  testGoldens('AppInput states', (tester) async {
    final builder = GoldenBuilder.column(wrap: _wrap)
      ..addScenario(
        'empty-with-label',
        const AppInput(label: 'Headline', value: '', placeholder: 'Your role'),
      )
      ..addScenario(
        'filled',
        const AppInput(label: 'Headline', value: 'Senior PM at Stripe'),
      )
      ..addScenario(
        'with-error',
        const AppInput(
          label: 'Email',
          value: 'bad@',
          errorText: 'Enter a valid email.',
        ),
      )
      ..addScenario(
        'multiline',
        const AppInput(
          label: 'Bio',
          value: 'Building tools for founders.',
          multiline: true,
          minLines: 3,
        ),
      )
      ..addScenario(
        'with-counter',
        const AppInput(
          label: 'Tagline',
          value: 'Short tagline',
          maxLength: 60,
        ),
      );
    await tester.pumpWidgetBuilder(
      builder.build(),
      wrapper: materialAppWrapper(theme: buildAppTheme(Brightness.light)),
      surfaceSize: const Size(360, 1200),
    );
    await screenMatchesGolden(tester, 'app_input_states');
  });
}

Widget _wrap(Widget child) =>
    Padding(padding: const EdgeInsets.all(8), child: child);
