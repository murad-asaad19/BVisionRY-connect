import 'package:connect_mobile/core/theme/app_theme.dart';
import 'package:connect_mobile/core/widgets/top_bar.dart';
import 'package:flutter/material.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

void main() {
  testGoldens('TopBar variants', (tester) async {
    final builder = GoldenBuilder.column(wrap: _wrap)
      ..addScenario('title only', const TopBar(title: 'Home'))
      ..addScenario(
        'title + subtitle',
        const TopBar(title: 'Profile', subtitle: 'Founder · San Francisco'),
      )
      ..addScenario(
        'with back',
        TopBar(title: 'Edit profile', back: true, onBack: () {}),
      )
      ..addScenario(
        'with actions',
        TopBar(
          title: 'Inbox',
          actions: [
            TopBarAction(
              icon: Icons.search,
              onPressed: () {},
              label: 'Search',
            ),
            TopBarAction(
              icon: Icons.more_horiz,
              onPressed: () {},
              label: 'More',
            ),
          ],
        ),
      )
      ..addScenario(
        'back + actions',
        TopBar(
          title: 'Detail',
          back: true,
          onBack: () {},
          actions: [
            TopBarAction(
              icon: Icons.bookmark_outline,
              onPressed: () {},
              label: 'Save',
            ),
          ],
        ),
      );
    await tester.pumpWidgetBuilder(
      builder.build(),
      wrapper: materialAppWrapper(theme: buildAppTheme(Brightness.light)),
      surfaceSize: const Size(360, 720),
    );
    await screenMatchesGolden(tester, 'top_bar_variants');
  });
}

Widget _wrap(Widget child) =>
    Padding(padding: const EdgeInsets.only(bottom: 12), child: child);
