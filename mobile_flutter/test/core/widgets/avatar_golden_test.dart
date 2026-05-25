import 'package:connect_mobile/core/theme/app_theme.dart';
import 'package:connect_mobile/core/widgets/avatar.dart';
import 'package:flutter/material.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

void main() {
  testGoldens('Avatar tones and sizes', (tester) async {
    final builder = GoldenBuilder.column(wrap: _wrapPad)
      ..addScenario('initials-default', const Avatar(name: 'Ada Lovelace'))
      ..addScenario(
        'initials-featured',
        const Avatar(name: 'Ada Lovelace', tone: AvatarTone.featured),
      )
      ..addScenario(
        'initials-muted',
        const Avatar(name: 'Ada Lovelace', tone: AvatarTone.muted),
      )
      ..addScenario('size-32', const Avatar(name: 'Ada Lovelace', size: 32))
      ..addScenario('size-64', const Avatar(name: 'Ada Lovelace', size: 64))
      ..addScenario('size-76', const Avatar(name: 'Ada Lovelace', size: 76))
      ..addScenario('single-letter', const Avatar(name: 'X', size: 48))
      ..addScenario('empty', const Avatar(name: '', size: 48));
    await tester.pumpWidgetBuilder(
      builder.build(),
      wrapper: materialAppWrapper(theme: buildAppTheme(Brightness.light)),
      surfaceSize: const Size(360, 1200),
    );
    await screenMatchesGolden(tester, 'avatar_tones_sizes');
  });
}

Widget _wrapPad(Widget child) =>
    Padding(padding: const EdgeInsets.all(8), child: child);
